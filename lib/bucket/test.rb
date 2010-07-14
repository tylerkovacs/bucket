class Bucket
  class Test
    class UnknownTestException < StandardError; end

    # Class variable storing all defined tests.
    @@tests = {}

    # Bucket::Test DSL
    #
    # The Bucket::Test DSL defines tests.
    #
    # Example:
    # bucket_test do
    #   name 'color test'
    #   variations ['red', 'green', 'blue']
    # end
    #
    # Supported Attributes:
    # name       : The name of the test.
    # variations : Test options.
    ATTRIBUTE_NAMES = [:name, :variations]

    # Create get/set methods for all methods supported in the DSL.
    ATTRIBUTE_NAMES.each do |attribute_name|
      class_eval <<-EOF
        def #{attribute_name}(value=nil)
          if value
            @attributes['#{attribute_name}'] = value
          else
            @attributes['#{attribute_name}']
          end
        end
      EOF
    end

    def initialize
      @attributes = {}
    end

    def assigned_variation
      Bucket.assigned_variations[name]
    end

    def assign_variation(variation=nil)
      if !Bucket.assigned_variations[name]
        if variation && variations.include?(variation)
          Bucket.assigned_variations[name] = variation
        else
          Bucket.assigned_variations[name] = assign_variation_uncached
        end
      end

      Bucket.assigned_variations[name]
    end

    def assign_variation_uncached
      variations[rand(variations.length)]
    end

    class << self
      def get(name)
        @@tests[name]
      end

      def all
        @@tests
      end

      def from_file(filename)
        from_string(File.read(filename))
      end

      def from_string(data)
        instance_eval(data)
      end

      def bucket_test(name=nil, &block)
        Test.add_test(name, &block)
      end

      def add_test(name=nil, &block)
        test = self.new
        test.instance_eval(&block)
        test.name(name) if name
        @@tests[test.name] = test
        test
      end

      def number_of_tests
        @@tests.length
      end

      def clear!
        @@tests.clear
      end

      def cookie_name(name)
        "bucket_test_#{Digest::MD5.hexdigest(name.to_s)}"
      end

      def cookie_expires
        Time.now + 7776000 # 3 months from now
      end
    end
  end
end
