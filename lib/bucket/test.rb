class Bucket
  class Test
    class DuplicateTestNameException < StandardError; end
    class UnknownTestException < StandardError; end
    class InvalidTestConfigurationException < StandardError; end

    # Class variable storing all defined tests.
    @@tests = {}

    # Bucket::Test DSL
    #
    # The Bucket::Test DSL defines tests.
    #
    # Example:
    # create_bucket_test do
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
            method = "validate_#{attribute_name}_attribute"
            send(method) if respond_to?(method)
          else
            @attributes['#{attribute_name}']
          end
        end
      EOF
    end

    def initialize
      @attributes = {}
      @weights = Hash.new(1)
    end

    def assigned_variation
      Bucket.assigned_variations[name]
    end

    def assign_variation(variation=:magic_default_value)
      if !Bucket.assigned_variations.has_key?(name)
        if variations.include?(variation)
          Bucket.assigned_variations[name] = variation
        else
          Bucket.assigned_variations[name] = assign_variation_uncached
        end
      end

      Bucket.assigned_variations[name]
    end

    def assign_variation_uncached
      if !@weights.empty?
        random = (0..variations.length-1).to_a.inject(0.0) do |t,i| 
          t + @weights[i]
        end * rand

        (0..variations.length-1).to_a.map{|i| [i, @weights[i]]}.each do |i,w|
          return variations[i] if w >= random
          random -= w
        end
      else
        variations[rand(variations.length)]
      end
    end

    def validate
      if !variations
        raise InvalidTestConfigurationException, "variations missing"
      end
    end

    def validate_variations_attribute
      if !variations
        raise InvalidTestConfigurationException, "variations missing"
      elsif !variations.is_a?(Array)
        raise InvalidTestConfigurationException, "variations not an Array"
      elsif variations.empty?
        raise InvalidTestConfigurationException, "variations empty"
      end

      _variations, @attributes['variations'] = @attributes['variations'], []

      _variations.each_with_index do |variation, index|
        if variation.is_a?(Hash)
          if !variation.has_key?(:value)
            raise InvalidTestConfigurationException, "variations missing :value"
          end
          add_variation(variation[:value])

          if variation[:weight]
            @weights[index] = variation[:weight].to_f
          end
        else
          add_variation(variation)
        end
      end
    end

    def add_variation(value)
      @attributes['variations'] << value
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

      def create_bucket_test(name=nil, &block)
        Test.add_test(name, &block)
      end

      def add_test(name, &block)
        test = self.new
        test.instance_eval(&block)
        test.name(name) if name
        test.validate

        if @@tests[test.name]
          raise Bucket::Test::DuplicateTestNameException, 
            "test named #{name} already exists"
        end

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
