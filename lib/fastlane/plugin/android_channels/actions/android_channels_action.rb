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
        apksigner = Helper::AndroidChannelsHelper.determine_apksigner!(params)
        apksigner_args = nil

        signed = Helper::AndroidChannelsHelper.is_signed?(apk_file)
        summary_params = {
          apk_file: apk_file,
          signed: signed,
          channels: channels,
          output_path: output_path,
        }

        unless signed
          keystore = Helper::AndroidChannelsHelper.determine_keystore!(params)
          apksigner_args = Helper::AndroidChannelsHelper.apksigner_args(params)

          summary_params.merge!({
            keystore: keystore,
            apksigner: apksigner,
            apksigner_args: apksigner_args
          })
        end

        FastlaneCore::PrintTable.print_values(
          title: "Summary for android_channels #{AndroidChannels::VERSION}",
          config: summary_params,
          mask_keys: %i[keystore_password key_password]
        )

        Helper::AndroidChannelsHelper.packing_apk(apk_file, channels, output_path, {
          apksigner: apksigner,
          apksigner_args: apksigner_args,
          prefix: params[:channel_filename_prefix],
          suffix: params[:channel_filename_suffix],
          verify: params[:verify]
        })

        # total = Dir["#{output_path}/*"].size
        # UI.success "Packaged done, total: #{total} apk file(s)."

        # output_path
      end

      def self.description
        "Package apk file with channels"
      end

      def self.details
        "Write empty file to META-INF with channel in general way"
      end

      def self.authors
        ["icyleaf"]
      end

      def self.return_value
        'The output of signed apk path'
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
          FastlaneCore::ConfigItem.new(key: :channel_filename_prefix,
                                  env_name: "ANDROID_CHANNELS_CHANNEL_FILENAME_PREFIX",
                               description: "The prefix of empty channel file to write to METE-INF folder",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :channel_filename_suffix,
                                  env_name: "ANDROID_CHANNELS_CHANNEL_FILENAME_SUFFIX",
                               description: "The suffix of empty channel file to write to METE-INF folder",
                                  optional: true,
                                      type: String),
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
          FastlaneCore::ConfigItem.new(key: :apksigner_extra_args,
                                  env_name: "ANDROID_CHANNELS_APKSIGNER_EXTRA_ARGS",
                               description: "The extra arguments of apksigner command",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :verify,
                                  env_name: "ANDROID_CHANNELS_VERIFY",
                               description: "Do or not verify signed apk file",
                                  optional: true,
                             default_value: false,
                                      type: Boolean),
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
            apk_file: "app.apk",
            channels: ["xiaomi", "huawei", "qq"],
            output_path: "/tmp/output_path",
            verify: true
          )',
          'android_channels(
            apk_file: "app-unsigned.apk",
            channels: ["xiaomi", "huawei", "qq"],
            keystore: "release.keystore",
            keystore_password: "p@ssword",
            clean: true
          )',
          'android_channels(
            apk_file: "app-unsigned.apk",
            channels: ["xiaomi", "huawei", "qq"],
            channel_filename_prefix: "channel_",
            keystore: "release.keystore",
            keystore_extra_args: "--ks-pass env:app.env --key-alias app",
            clean: true
          )'
        ]
      end
    end
  end
end
