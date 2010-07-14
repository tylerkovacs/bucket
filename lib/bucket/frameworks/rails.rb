require File.join(File.dirname(__FILE__), 'rails', 'filters')
require File.join(File.dirname(__FILE__), 'rails', 'helpers')

# Default to the Rails logger.
Bucket.logger = RAILS_DEFAULT_LOGGER

# Set config path based on RAILS_ROOT
Bucket.config_path = File.join(RAILS_ROOT, "config", "bucket")

# Keep all interactions with Rails classes here so that the individual
# libraries under rails/ can be unit tests without pulling in the whole 
# framework.
ApplicationController.send(:include, Bucket::Frameworks::Rails::Filters)
ApplicationController.send(:before_filter, :clear_and_restore_bucket_state)
ApplicationController.send(:after_filter, :persist_bucket_state)
ApplicationController.send(:helper, Bucket::Frameworks::Rails::Helpers)
