require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop)

require 'securerandom'
require 'zip'

task(default: [:spec, :rubocop])

task :zip do
  channels = []
  23.times do |i|
    channels << SecureRandom.hex
  end

  thread_number = 4.0
  part = channels.size / thread_number

  ranges = []
  p 1.step(part).to_a

  puts part

end
