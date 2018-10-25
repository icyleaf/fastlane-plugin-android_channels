require 'fastlane/action'
require 'fileutils'

require_relative '../helper/android_channels_helper'

module Fastlane
  module Actions
    class AndroidChannelsAction < Action
      def self.run(params)
        apk_file = Helper::AndroidChannelsHelper.determine_apk_file!(params)
        channels = Helper::AndroidChannelsHelper.determine_channels!(params)
        output_path = Helper::AndroidChannelsHelper.determine_output_path!(params)

        signed = Helper::AndroidChannelsHelper.is_signed?(apk_file)
        summary_params = {
          apk_file: apk_file,
          signed: signed,
          channels: channels,
          output_path: output_path,
        }

        unless signed
          keystore = Helper::AndroidChannelsHelper.determine_keystore!(params)
          apksigner = Helper::AndroidChannelsHelper.determine_apksigner!(params)
          keystore_password = Helper::AndroidChannelsHelper.determine_keystore_password!(params)
          key_alias = params[:key_alias]
          key_password = params[:key_password]

          summary_params.merge!({
            apksigner: apksigner,
            keystore: keystore,
            keystore_password: keystore_password,
            key_alias: key_alias,
            key_password: key_password
          })
        end

        FastlaneCore::PrintTable.print_values(
          title: "Summary for android_channels #{AndroidChannels::VERSION}",
          config: summary_params,
          mask_keys: %i[keystore_password key_password]
        )

        if signed
          UI.verbose "Packaging channel apk ..."
          Helper::AndroidChannelsHelper.write_apk_with_channels(output_path, apk_file, channels)
        else
          UI.verbose "Signing apk ..."
          signed_file = Helper::AndroidChannelsHelper.sign_apk(apksigner, keystore, keystore_password, apk_file, key_alias, key_password)

          UI.verbose "Packaging channel apk ..."
          Helper::AndroidChannelsHelper.write_apk_with_channels(output_path, signed_file.path, channels)
          signed_file.unlink
        end

        total = Dir["#{output_path}/*"].size
        UI.success "Packaged done, total: #{total} apk file(s)."

        output_path
      end

      def self.description
        "Package unsign apk with channels"
      end

      def self.authors
        ["icyleaf"]
      end

      def self.return_value
        'The output of signed apk path'
      end

      def self.details
        "Apply for QYER mobile team for now"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :apk_file,
                                  env_name: "ANDROID_CHANNELS_APK_FILE",
                               description: "The path of apk file",
                             default_value: Dir['**/*'].select{|f|f.end_with?('signed.apk')}.last,
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :channels,
                                  env_name: "ANDROID_CHANNELS_CHANNELS",
                               description: "The key password of keystore",
                                  optional: false,
                                      type: Array),
          FastlaneCore::ConfigItem.new(key: :output_path,
                                  env_name: "ANDROID_CHANNELS_OUTPUT_PATH",
                               description: "The output path of channels apk files",
                                  optional: true,
                             default_value: "channels_apk",
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :android_sdk_path,
                                  env_name: "ANDROID_CHANNELS_ANDROID_SDK_PATH",
                               description: "The path of android sdk",
                             default_value: ENV["ANDROID_SDK_ROOT"] || ENV["ANDROID_HOME"],
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :build_tools_version,
                                  env_name: "ANDROID_CHANNELS_BUILD_TOOLS_VERSION",
                               description: "The version of build tools (by default, always use latest version)",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :keystore,
                                  env_name: "ANDROID_CHANNELS_KEYSTORE",
                               description: "The path of keystore file",
                             default_value: Dir['**/*'].select{|f|f.end_with?('.keystore')}.last,
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :keystore_password,
                                  env_name: "ANDROID_CHANNELS_KEYSTORE_PASSWORD",
                               description: "The password of keystore",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :key_alias,
                                  env_name: "ANDROID_CHANNELS_KEY_ALIAS",
                               description: "The key alias of keystore",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :key_password,
                                  env_name: "ANDROID_CHANNELS_KEY_PASSWORD",
                               description: "The key password of keystore",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :clean,
                                  env_name: "ANDROID_CHANNELS_CLEAN",
                               description: "Should the signed files to be clean before signing it?",
                                  optional: true,
                             default_value: false,
                                      type: Boolean)
        ]
      end

      def self.is_supported?(platform)
        [:android].include?(platform)
      end

      def self.category
        :building
      end

      def self.example_code
        [
          'android_channels(
            apk_file: "app-signed.apk",
            channels: ["xiaomi", "huawei", "qq"],
            output_path: "/tmp/output_path",
          )',
          'android_channels(
            apk_file: "app-unsigned.apk",
            signed: false,
            channels: ["xiaomi", "huawei", "qq"],
            keystore: "release.keystore",
            keystore_password: "p@ssword",
            clean: true
          )'
        ]
      end
    end
  end
end
