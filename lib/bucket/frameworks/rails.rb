require File.join(File.dirname(__FILE__), 'rails', 'filters')
require File.join(File.dirname(__FILE__), 'rails', 'helpers')

# Default to the Rails logger.
Bucket.logger = Rails.logger

# Set config path based on Rails.root
Bucket.config_path = Rails.root.join("config", "bucket").to_s

# Keep all interactions with Rails classes here so that the individual
# libraries under rails/ can be unit tests without pulling in the whole 
# framework.
ActionController::Base.send(:include, Bucket::Frameworks::Rails::Filters)
ActionController::Base.send(:before_filter, :bucket_before_filters)
ActionController::Base.send(:after_filter, :bucket_after_filters)
ActionController::Base.send(:helper, Bucket::Frameworks::Rails::Helpers)
