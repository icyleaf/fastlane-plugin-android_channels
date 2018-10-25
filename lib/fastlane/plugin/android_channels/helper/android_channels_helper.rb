require 'fastlane_core/ui/ui'
require 'shellwords'
require 'tempfile'
require 'zip'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    module AndroidChannelsHelper
      def self.sign_apk(apksigner, keystore, keystore_password, apk_file, key_alias = nil, key_password = nil)
        signed_file = Tempfile.new([File.basename(apk_file.sub("unsigned", "signed")), File.extname(apk_file)])
        FileUtils.cp(apk_file, signed_file.path)

        command_args = [apksigner.shellescape, "sign", "--ks-pass", "pass:#{keystore_password}", "--ks", keystore.shellescape]
        command_args << "--ks-key-alias" << key_alias unless key_alias.to_s.empty?
        command_args << "--key-pass" << "pass:#{key_password}" unless key_password.to_s.empty?
        command_args << signed_file.path
        Action.sh(command_args.join(" "), print_command: FastlaneCore::Globals.verbose?)

        signed_file
      end

      def self.write_apk_with_channels(output_path, apk, channels)
        Zip.warn_invalid_date = false
        with_channel_file do |file|
          channels.each do |name|
            write_channel_to_apk(output_path, apk, name, file.path)
          end
        end
      end

      def self.write_channel_to_apk(output_path, signed_file, name, channel_file)
        output_file = File.join(output_path, "#{name}.apk")
        FileUtils.cp(signed_file, output_file)

        Zip::File.open(output_file, Zip::File::CREATE) do |zip_file|
          zip_file.add("META-INF/cztchannel_#{name}", channel_file)
        end
      rescue Zip::EntryExistsError => ex
        UI.build_failure!([ex.message].concat(ex.backtrace).join("\n"))
      end

      def self.with_channel_file(filename = "android_channel", &block)
        Tempfile.open(filename) do |file|
          yield file
        end
      end

      def self.determine_apk_file!(params)
        apk_file = find_file(params[:apk_file])
        UI.user_error!("Not found apk file: #{params[:apk_file]}") unless apk_file
        apk_file
      end

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

      def self.determine_keystore!(params)
        keystore = find_file(params[:keystore])
        UI.user_error!("Not found keystore file: #{params[:keystore]}") unless keystore
        keystore
      end

      def self.determine_channels!(params)
        channels = params[:channels]
        UI.user_error!("Empty channels") if channels.size.zero?
        channels
      end

      def self.determine_keystore_password!(params)
        password = params[:keystore_password]
        UI.user_error!("Missing keystore_password") unless password
        password
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
