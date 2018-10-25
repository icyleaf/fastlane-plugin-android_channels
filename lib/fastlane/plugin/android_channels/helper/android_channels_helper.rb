require 'fastlane_core/ui/ui'
require 'shellwords'
require 'tempfile'
require 'zip'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    module AndroidChannelsHelper
      def self.sign_apk(apksigner, keystore, keystore_password, unsigned_apk, key_alias = nil, key_password = nil)
        signed_file = Tempfile.new([File.basename(unsigned_apk.sub("unsigned", "signed")), File.extname(unsigned_apk)])
        FileUtils.cp(unsigned_apk, signed_file.path)

        command_args = [apksigner.shellescape, "sign", "--ks-pass", "pass:#{keystore_password}", "--ks", keystore.shellescape]
        command_args << "--ks-key-alias" << key_alias unless key_alias.empty?
        command_args << "--key-pass" << "pass:#{key_password}" unless key_password.empty?
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

        Zip::File.open(output_file, Zip::File::CREATE) do |zf|
          zf.add("META-INF/cztchannel_#{name}", channel_file)
        end
      end

      def self.with_channel_file(filename = "android_channel", &block)
        Tempfile.open(filename) do |file|
          yield file
        end
      end

      def self.determine_unsigned_apk!(params)
        unsigned_apk = find_file(params[:unsigned_apk])
        UI.user_error!("Not found unsigned apk file: #{params[:unsigned_apk]}") unless unsigned_apk
        unsigned_apk
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
