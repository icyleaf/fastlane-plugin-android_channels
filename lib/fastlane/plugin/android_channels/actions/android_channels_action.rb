require 'fastlane/action'
require 'fileutils'

require_relative '../helper/android_channels_helper'

module Fastlane
  module Actions
    class AndroidChannelsAction < Action
      def self.run(params)
        unsigned_apk = Helper::AndroidChannelsHelper.determine_unsigned_apk!(params)
        keystore = Helper::AndroidChannelsHelper.determine_keystore!(params)
        output_path = Helper::AndroidChannelsHelper.determine_output_path!(params)
        channels = Helper::AndroidChannelsHelper.determine_channels!(params)
        apksigner = Helper::AndroidChannelsHelper.determine_apksigner!(params)
        keystore_password = Helper::AndroidChannelsHelper.determine_keystore_password!(params)
        key_alias = params[:key_alias]
        key_password = params[:key_password]

        FastlaneCore::PrintTable.print_values(
          title: "Summary for android_channels #{AndroidChannels::VERSION}",
          config: {
            apksigner: apksigner,
            unsigned_apk: unsigned_apk,
            channels: channels,
            keystore: keystore,
            keystore_password: keystore_password,
            key_alias: key_alias,
            key_password: key_password,
            output_path: output_path,
            clean: params[:clean]
          },
          mask_keys: %i[keystore_password key_password]
        )

        UI.verbose "Signing apk ..."
        signed_file = Helper::AndroidChannelsHelper.sign_apk(apksigner, keystore, keystore_password, unsigned_apk, key_alias, key_password)

        UI.verbose "Packaging channel apk ..."
        Helper::AndroidChannelsHelper.write_apk_with_channels(output_path, signed_file.path, channels)

        total = Dir["#{output_path}/*"].size
        UI.success "Packaged done, total: #{total} apk file(s)."

        signed_file.close
        signed_file.unlink

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
          FastlaneCore::ConfigItem.new(key: :android_sdk_path,
                                  env_name: "ANDROID_CHANNELS_ANDROID_SDK_PATH",
                               description: "The path of android sdk",
                                  optional: false,
                             default_value: ENV["ANDROID_SDK_ROOT"] || ENV["ANDROID_HOME"],
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :build_tools_version,
                                  env_name: "ANDROID_CHANNELS_BUILD_TOOLS_VERSION",
                               description: "The version of build tools (by default, use latest one)",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :unsigned_apk,
                                  env_name: "ANDROID_CHANNELS_UNSIGNED_APK",
                               description: "The path of unsigned apk file",
                             default_value: Dir['**/*'].select{|f|f.end_with?('-unsigned.apk')}.last,
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :channels,
                                  env_name: "ANDROID_CHANNELS_CHANNELS",
                               description: "The key password of keystore",
                                  optional: false,
                                      type: Array),
          FastlaneCore::ConfigItem.new(key: :keystore,
                                  env_name: "ANDROID_CHANNELS_KEYSTORE",
                               description: "The path of keystore file",
                             default_value: Dir['**/*'].select{|f|f.end_with?('.keystore')}.last,
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :keystore_password,
                                  env_name: "ANDROID_CHANNELS_KEYSTORE_PASSWORD",
                               description: "The password of keystore",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :key_alias,
                                  env_name: "ANDROID_CHANNELS_KEY_ALIAS",
                               description: "The key alias of keystore",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :key_password,
                                  env_name: "ANDROID_CHANNELS_KEY_PASSWORD",
                               description: "The key password of keystore",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :output_path,
                                  env_name: "ANDROID_CHANNELS_OUTPUT_PATH",
                               description: "The output of signed files",
                                  optional: true,
                             default_value: "signed_apk",
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
            unsigned_apk: "app-unsigned.apk",
            keystore: "release.keystore",
            keystore_password: "p@ssword",
            clean: true
          )'
        ]
      end
    end
  end
end
