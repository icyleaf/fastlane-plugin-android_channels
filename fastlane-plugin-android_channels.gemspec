# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/android_channels/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-android_channels'
  spec.version       = Fastlane::AndroidChannels::VERSION
  spec.author        = 'icyleaf'
  spec.email         = 'icyleaf.cn@gmail.com'

  spec.summary       = 'Package unsign apk with channels'
  spec.homepage      = "https://github.com/icyleaf/fastlane-plugin-android_channels"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'rubyzip', '~> 1.2.2'

  spec.add_development_dependency('pry')
  spec.add_development_dependency('bundler')
  spec.add_development_dependency('rspec')
  spec.add_development_dependency('rspec_junit_formatter')
  spec.add_development_dependency('rake')
  spec.add_development_dependency('rubocop', '0.49.1')
  spec.add_development_dependency('rubocop-require_tools')
  spec.add_development_dependency('simplecov')
  spec.add_development_dependency('fastlane', '>= 2.107.0')
end
