# android_channels plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-android_channels)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-android_channels`, add it to your project by running:

```bash
fastlane add_plugin android_channels
```

## About android_channels

Package unsign apk with channels and write empty file to META-INF with channel in general way

## Configuration

```
+-------------------------+-------------------------------------------------+------------------------------------------+-------------------------------------------------+
|                                                                        android_channels Options                                                                        |
+-------------------------+-------------------------------------------------+------------------------------------------+-------------------------------------------------+
| Key                     | Description                                     | Env Var                                  | Default                                         |
+-------------------------+-------------------------------------------------+------------------------------------------+-------------------------------------------------+
| apk_file                | The path of apk file                            | ANDROID_CHANNELS_APK_FILE                | builds/output/apk/app-unsigned.apk              |
| channels                | The key password of keystore                    | ANDROID_CHANNELS_CHANNELS                | []                                              |
| channel_file            | The path of channel file, accepts json, yaml    | ANDROID_CHANNELS_CHANNEL_FILE            |                                                 |
|                         | and plain text file (split with space, comma    |                                          |                                                 |
|                         | and newline)                                    |                                          |                                                 |
| channel_filename_prefix | The prefix of empty channel file to write to    | ANDROID_CHANNELS_CHANNEL_FILENAME_PREFIX |                                                 |
|                         | METE-INF folder                                 |                                          |                                                 |
| channel_filename_suffix | The suffix of empty channel file to write to    | ANDROID_CHANNELS_CHANNEL_FILENAME_SUFFIX |                                                 |
|                         | METE-INF folder                                 |                                          |                                                 |
| output_path             | The output path of channel apk files            | ANDROID_CHANNELS_OUTPUT_PATH             | channel_apks                                    |
| android_sdk_path        | The path of android sdk                         | ANDROID_CHANNELS_ANDROID_SDK_PATH        | /usr/local/share/android-sdk                    |
| build_tools_version     | The version of build tools (by default, always  | ANDROID_CHANNELS_BUILD_TOOLS_VERSION     |                                                 |
|                         | use latest version)                             |                                          |                                                 |
| keystore                | The path of keystore file                       | ANDROID_CHANNELS_KEYSTORE                | release.keystore                                |
| keystore_password       | The password of keystore                        | ANDROID_CHANNELS_KEYSTORE_PASSWORD       |                                                 |
| key_alias               | The key alias of keystore                       | ANDROID_CHANNELS_KEY_ALIAS               |                                                 |
| key_password            | The key password of keystore                    | ANDROID_CHANNELS_KEY_PASSWORD            |                                                 |
| apksigner_extra_args    | The extra arguments of apksigner command        | ANDROID_CHANNELS_APKSIGNER_EXTRA_ARGS    |                                                 |
| verify                  | Do or not verify signed apk file                | ANDROID_CHANNELS_VERIFY                  | false                                           |
| clean                   | Should the signed files to be clean before      | ANDROID_CHANNELS_CLEAN                   | false                                           |
|                         | signing it?                                     |                                          |                                                 |
+-------------------------+-------------------------------------------------+------------------------------------------+-------------------------------------------------+
* = default value is dependent on the user's system
```

Here has some example [channel files](examples/).

## Return value

```
+-------------------------------+
| android_channels Return Value |
+-------------------------------+
| The output of signed apk path |
+-------------------------------+
```

## Example


Check out the [example `Fastfile`](fastlane/Fastfile) to see how to use this plugin. Try it by cloning the repo, running `fastlane install_plugins` and `bundle exec fastlane test`.

**Note to author:** Please set up a sample project to make it easy for users to explore what your plugin does. Provide everything that is necessary to try out the plugin in this project (including a sample Xcode/Android project if necessary)

## Run tests for this plugin

To run both the tests, and code style validation, run

```
rake
```

To automatically fix many of the styling issues, use
```
rubocop -a
```

## Issues and Feedback

For any other issues and feedback about this plugin, please submit it to this repository.

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
