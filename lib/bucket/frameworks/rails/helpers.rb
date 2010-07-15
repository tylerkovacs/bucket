class Bucket
  module Frameworks
    module Rails
      module Helpers
        def bucket_test(name, &block)
          Bucket::Test.bucket_test(name, &block)
        end
      end
    end
  end
end
