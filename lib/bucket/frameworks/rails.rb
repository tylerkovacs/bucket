require File.join(File.dirname(__FILE__), 'rails', 'filters')
require File.join(File.dirname(__FILE__), 'rails', 'helpers')

# Default to the Rails logger.
Bucket.logger = RAILS_DEFAULT_LOGGER

# Set config path based on RAILS_ROOT
Bucket.config_path = File.join(RAILS_ROOT, "config", "bucket")

# Keep all interactions with Rails classes here so that the individual
# libraries under rails/ can be unit tests without pulling in the whole 
# framework.
ActionController::Base.send(:include, Bucket::Frameworks::Rails::Filters)
ActionController::Base.send(:before_filter, :bucket_before_filters)
ActionController::Base.send(:after_filter, :bucket_after_filters)
ActionController::Base.send(:helper, Bucket::Frameworks::Rails::Helpers)
