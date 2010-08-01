class Bucket
  module Frameworks
    module Rails
      module Helpers
        def bucket_test(name, &block)
          Bucket::Test.bucket_test(name, &block)
        end

        def bucket_include_javascript
          javascript_include_tag :bucket
        end

        def bucket_initialize_javascript(key, options={})
          javascript_tag(bucket_initialize_inner(key, options))
        end

        def bucket_initialize_inner(key, options={})
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
