class Bucket
  module Frameworks
    module Rails
      module Helpers
        def bucket_test(name, &block)
          Bucket::Test.bucket_test(name, &block)
        end

        def bucket_initialize_javascript(key, options={})
          inner = [ "Bucket.recorder.initialize({" ]
          options.merge({'key' => key}).each do |key, value|
            inner << "  #{key}: '#{escape_javascript(value)}'"
          end
          inner << "});"
          inner.join("\n")
        end
      end
    end
  end
end
