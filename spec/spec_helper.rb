begin
  require 'bundler'
rescue LoadError
  require 'rubygems'
  require 'bundler'
end
Bundler.setup

require 'spec/autorun'

# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] = "test"
ENV["BUCKET_ENV"] = "test"

require File.join(File.dirname(__FILE__), '..', 'lib', 'bucket')

# Use the memory store by default so that tests run faster
Bucket.store = Bucket::Store::Memory.new

Spec::Runner.configure do |config|
  config.before(:each) { }
  config.before(:all) { }
  config.after(:each) { }
end

# Mock classes that are used framework-specific features are used when the
# framework is not available.  The unit tests are run without the framework
# but still exercise some framework-specific features.
class Base64
  def self.b64encode(string)
    string
  end
end

class ActiveSupport
  class JSON
    def self.encode(value)
      value
    end
  end
end
