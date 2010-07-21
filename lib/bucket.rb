unless defined?(Bucket)
  require File.join(File.dirname(__FILE__), 'bucket', 'base')
  require File.join(File.dirname(__FILE__), 'bucket', 'test')
  require File.join(File.dirname(__FILE__), 'bucket', 'store')

  class Bucket
    include Bucket::Base
  end

  if defined?(Rails)
    require File.join(File.dirname(__FILE__), 'bucket', 'frameworks', 'rails')
  end

  if ENV["BUCKET_ENV"] == "test"
    Bucket.config_path = File.join("spec", "config", "bucket")
  end

  Bucket.store ||= Bucket::Store::Directory.new(Bucket.config_path)
  Bucket.init
end
