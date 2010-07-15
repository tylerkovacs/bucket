require "rubygems"
require "bundler"
Bundler.setup

require 'spec/autorun'
require 'ruby-debug'

# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] = "test"
ENV["BUCKET_ENV"] = "test"

require File.join(File.dirname(__FILE__), '..', 'lib', 'bucket')

Spec::Runner.configure do |config|
  config.before(:each) { }
  config.before(:all) { }
  config.after(:each) { }
end
