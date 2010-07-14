class Bucket
  module Frameworks
    module Rails
      module Helpers
        def bucket_test(name, &block)
          test = Bucket::Test.get(name)

          test = if !test
            if block_given?
              Bucket::Test.bucket_test(name, &block)
            else
              raise Bucket::Test::UnknownTestException
            end
          else
            test
          end

          test.assign_variation
          test
        end
      end
    end
  end
end
