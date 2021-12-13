require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

desc "Runs default tests"

task default: [:run]

task test: [:spec] 

desc "Runs temporary driver code"
task :run do
  ruby "lib/id3v2.rb"
end
