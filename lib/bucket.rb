unless defined?(Bucket)
  require File.join(File.dirname(__FILE__), 'bucket', 'base')
  require File.join(File.dirname(__FILE__), 'bucket', 'test')

  class Bucket
    include Bucket::Base
  end

  if defined?(Rails)
    require File.join(File.dirname(__FILE__), 'bucket', 'frameworks', 'rails')
  end

  if ENV["BUCKET_ENV"] == "test"
    Bucket.config_path = File.join("spec", "config", "bucket")
  end

  Bucket.init
end
