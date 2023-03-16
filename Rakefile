# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/test_*.rb"]
end

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new(:rubocop) do |t|
    t.requires << "rubocop-minitest"
    t.requires << "rubocop-rake"
    t.options = ["--display-cop-names"]
  end
rescue LoadError
  # rubocop task disabled
end

task default: [:test]
