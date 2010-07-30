unless defined?(Bucket)
  require File.join(File.dirname(__FILE__), 'bucket', 'store')
  require File.join(File.dirname(__FILE__), 'bucket', 'base')
  require File.join(File.dirname(__FILE__), 'bucket', 'test')

  class Bucket
    include Bucket::Base
  end

  if defined?(Rails)
    # Rails 2 loads the gem after the Rails framework is initialized
    # Rails 3 loads the gem before the Rails framewor is initialized, so
    #   add the following line to config/environment.rb in Rails 3:
    #   require 'bucket/frameworks/rails'
    if Rails::VERSION::STRING =~ /^2/
      require File.join(File.dirname(__FILE__), 'bucket', 'frameworks', 'rails')
    end
  end

  if ENV["BUCKET_ENV"] == "test"
    Bucket.config_path = File.join("spec", "config", "bucket")
  end

  Bucket.store ||= Bucket::Store::Directory.new(Bucket.config_path)
end
