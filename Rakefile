require 'rubygems'
require 'rake'
require 'rake/testtask'

# Required for Hudson to show build log
if ENV['CI_REPORTS']
 system("cp spec/ci.spec.opts spec/spec.opts")
end

gem 'ci_reporter'
require 'ci/reporter/rake/rspec'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "bucket"
    gem.summary = %Q{A/B testing.}
    gem.email = "tyler.kovacs@gmail.com"
    gem.homepage = "http://github.com/tylerkovacs/bucket"
    gem.description = "See README"
    gem.authors = ["tylerkovacs"]
    gem.files.exclude 'TODO'
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

# Prevent tests from getting executed twice when running rake.
module Rake
  class TestTask
    def define
      lib_path = @libs.join(File::PATH_SEPARATOR)
      desc "Run tests" + (@name==:test ? "" : " for #{@name}")
      task @name do
        RakeFileUtils.verbose(@verbose) do
          @ruby_opts.unshift( "-I\"#{lib_path}\"" )
          @ruby_opts.unshift( "-w" ) if @warning
          ruby @ruby_opts.join(" ") +
            " " + 
            file_list.collect { |fn| "\"#{fn}\"" }.join(' ') +
            " #{option_list}"
        end
      end
      self
    end
  end
end

Rake::TestTask.new do |t|
  t.libs << 'spec'
  t.test_files = FileList['spec/**/*_spec.rb']
  t.verbose = true
end

task :default => :test
