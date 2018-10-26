require 'fastlane_core/ui/ui'
require 'shellwords'
require 'tempfile'
require 'zip'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    module AndroidChannelsHelper
      APKSIGNER_COMMAND_KEYS = {
        keystore: "--ks",
        keystore_password: "--ks-pass",
        key_alias: "--ks-key-alias",
        key_password: "--key-pass",
      }

      # 签名接收的各渠道包
      def self.packing_apk(apk_file, channels, output_path, options = {})
        Zip.warn_invalid_date = false

        UI.message "Packaing apk ..."
        Tempfile.open("android_channel_name_file") do |empty_channel_file|
          channels.each do |channel_name|
            signed_and_write_channel_to_apk(apk_file, channel_name, output_path, empty_channel_file.path, options)
          end
        end
      end

      # 写入渠道并签名 apk 文件
      def self.signed_and_write_channel_to_apk(apk_file, channel_name, output_path, write_file, options)
        output_file = File.join(output_path, "#{channel_name}.apk")
        Action.sh("cp #{apk_file} #{output_file}", print_command: false)

        channel_filename = [options[:prefix], channel_name, options[:suffix]].compact.join("")
        UI.verbose "Writing 'META-INF/#{channel_filename}' file to #{output_file}"
        Zip::File.open(output_file, Zip::File::CREATE) do |zip_file|
          zip_file.add("META-INF/#{channel_filename}", write_file)
        end

        UI.verbose "Signing ..."
        sign_apk(output_file, options)

        if options[:verify] && !verify_apk(output_file, options[:apksigner])
          UI.build_failure! "Verify failure apk file: #{output_file}"
        end
      rescue Zip::EntryExistsError => ex
        UI.build_failure!([ex.message].concat(ex.backtrace).join("\n"))
      end

      # 签名 apk 文件
      def self.sign_apk(apk_file, options = {})
        command = "#{options[:apksigner].shellescape} sign #{options[:apksigner_args]} #{apk_file}"
        Action.sh(command, print_command: false, print_command_output: verbose?)
      end

      # 验证 apk 签名是否正确
      def self.verify_apk(apk_file, apksigner)
        command_args = [apksigner.shellescape, "verify"]
        command_args << "--verbose" if verbose?
        command_args << apk_file

        UI.verbose "Verifing ..."
        result = Action.sh(command_args.join(" "), print_command: false, print_command_output: verbose?)
        !result.include?("DOES NOT VERIFY")
      end

      # 验证 apk 是否签名
      def self.is_signed?(apk_file)
        Zip.warn_invalid_date = false
        Zip::File.open(apk_file, Zip::File::CREATE) do |zip_file|
          file = zip_file.find_entry("META-INF/MANIFEST.MF")
          if file
            encrypt_keys = 0
            file.get_input_stream do |io|
              io.each_line do |line|
                return true if encrypt_keys >= 2
                encrypt_keys += 1 if line.start_with?("Name:")
              end
            end
          end
        end

        false
      end

      def self.verbose?
        FastlaneCore::Globals.verbose?
      end

      # 解析并合并 apksigner 的参数， 额外的参数会覆盖之前设置过的值
      def self.apksigner_args(params)
        command = {}
        params.all_keys.each do |key|
          if APKSIGNER_COMMAND_KEYS.has_key?(key)
            if command_value = params[key]
              command_key = APKSIGNER_COMMAND_KEYS[key].to_s
              command_value = "pass:#{command_value}" if command_key.end_with?("pass")
              command[command_key] = command_value.shellescape
            end
          end
        end

        if extra_args = params[:apksigner_extra_args]
          extra_args.split(" ").each_slice(2) do |part|
            key = part[0].to_s.strip.shellescape
            if value = part[1]
              command[key.to_s] = value.strip.shellescape
            end
          end
        end

        command.flatten.join(" ")
      end

      def self.determine_apk_file!(params)
        apk_file = find_file(params[:apk_file])
        UI.user_error!("Not found apk file: #{params[:apk_file]}") unless apk_file
        apk_file
      end

      def self.determine_channels!(params)
        channels = params[:channels]
        UI.user_error!("Empty channels") if channels.size.zero?
        channels.map{|n| n.strip}.uniq
      end

      def self.determine_keystore!(params)
        keystore = find_file(params[:keystore])
        UI.user_error!("Not found keystore file: #{params[:keystore]}") unless keystore
        keystore
      end

      def self.determine_output_path!(params)
        output_path = params[:output_path]
        if Dir.exist?(output_path)
          if params[:clean]
            FileUtils.rm_rf(output_path)
          else
            UI.user_error!("output path was exists: #{File.expand_path(output_path)}。 \nyou can use `clean:true` to force clean.")
          end
        end

        FileUtils.mkdir_p(output_path)
        output_path
      end

      def self.determine_apksigner!(params)
        android_sdk_path = params[:android_sdk_path]
        build_tools_version = params[:build_tools_version]
        UI.user_error!("Not found android SDK path: #{android_sdk_path}") unless android_sdk_path

        build_tools_path = build_tools_path(android_sdk_path, build_tools_version)
        apksigner_path(build_tools_path)
      end

      def self.find_file(default_file)
        return default_file if File.file?(default_file)

        Dir['**/*'].each do |file|
          return file if File.basename(file) == default_file
        end

        nil
      end

      def self.build_tools_path(android_sdk_path, version = nil)
        build_tools_path = File.join(android_sdk_path, "build-tools")
        unless version
          latest_path = Dir.glob("#{build_tools_path}/*").inject {|latest, current| File.basename(latest) > File.basename(current) ? latest : current }
          version = File.basename(latest_path)
        end
        path = File.join(build_tools_path, version)

        UI.user_error!("Not found build tools path: #{build_tools_path}") unless path && Dir.exist?(path)
        path
      end

      def self.apksigner_path(build_tools_path)
        file = File.join(build_tools_path, "apksigner")

        UI.user_error!("Not found apksigner: #{params[:android_sdk_path]}") unless file && File.file?(file)
        file
      end
    end
  end
end
