class Bucket
  module Frameworks
    module Rails
      module Helpers
        def bucket_test(name, &block)
          Bucket::Test.bucket_test(name, &block)
        end

        def bucket_initialize_javascript(key, options={}, cookie_names={})
          Bucket.initialize_javascript(key, options, cookie_names)
        end
      end
    end
  end
end
