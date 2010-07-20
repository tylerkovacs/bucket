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
    #   default 'red'
    #   start_at '2010/07/20 03:00:00'
    #   end_at '2010/07/20 07:00:00'
    # end
    #
    # Supported Attributes:
    # name       : The name of the test.
    # variations : Test options.
    ATTRIBUTE_NAMES = [:name, :variations, :default, :start_at, :end_at]

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
      Bucket.assignments[name]
    end

    def variations_include?(value)
      variations.each do |v|
        return v if (v == value || v.to_s == value)
        return v if (v.respond_to?(:to_sym) && v.to_sym == value)
      end

      return nil
    end

    def within_time_range?(time=Time.now)
      if !start_at && !end_at
        true
      elsif start_at && end_at
        (time > start_at) && (time < end_at)
      elsif start_at 
        time > start_at
      elsif end_at 
        time < end_at
      else
        false
      end
    end

    def active?
      if !within_time_range?
        false
      else
        true
      end
    end

    def assign_variation(variation=:magic_default_value, options={})
      return default_variation if !active? && !options[:force]

      if !Bucket.assignments.has_key?(name) || options[:force]
        if variation = variations_include?(variation)
          Bucket.assignments[name] = variation
        else
          Bucket.assignments[name] = assign_variation_uncached
        end

        unless options[:previously_assigned]
          Bucket.new_assignments[name] = Bucket.assignments[name]
        end
      end

      Bucket.assignments[name]
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

    def add_variation(value)
      @attributes['variations'] << value
    end

    def default_variation
      default || variations.first
    end

    def encoded_name
      self.class.encoded_name(name)
    end

    def cookie_name
      self.class.cookie_name(name)
    end

    # Validations
    def validate
      # Reject test if there are no variations supplied
      if !variations
        raise InvalidTestConfigurationException, "variations missing"
      end
    end

    # Reject the default value if the supplied default is not a valid
    # variation.
    def validate_default_attribute
      if !variations_include?(@attributes['default'])
        @attributes.delete('default')
      end
    end

    def validate_start_at_attribute
      if !@attributes['start_at']
        raise InvalidTestConfigurationException, "start_at missing"
      end

      # Accept Time objects
      return if @attributes['start_at'].is_a?(Time)

      if @attributes['start_at'].is_a?(String)
        begin
          @attributes['start_at'] = Time.parse(@attributes['start_at'])
        rescue Exception => err
          raise InvalidTestConfigurationException, 
            "start_at could not be Time.parse'd: #{err.message} "
        end
      else
        raise InvalidTestConfigurationException, "start_at must be a String"
      end
    end

    def validate_end_at_attribute
      if !@attributes['end_at']
        raise InvalidTestConfigurationException, "end_at missing"
      end

      # Accept Time objects
      return if @attributes['end_at'].is_a?(Time)

      if @attributes['end_at'].is_a?(String)
        begin
          @attributes['end_at'] = Time.parse(@attributes['end_at'])
        rescue Exception => err
          raise InvalidTestConfigurationException, 
            "end_at could not be Time.parse'd: #{err.message} "
        end
      else
        raise InvalidTestConfigurationException, "end_at must be a String"
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

    # Class Methods
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

      def create_bucket_test(name, &block)
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

      def bucket_test(name, &block)
        test = Bucket::Test.get(name)

        test = if !test
          if block_given?
            Bucket::Test.create_bucket_test(name, &block)
          else
            raise Bucket::Test::UnknownTestException
          end
        else
          test
        end

        test.assign_variation
        test
      end

      def number_of_tests
        @@tests.length
      end

      def clear!
        @@tests.clear
      end

      def cookie_name(name)
        "bucket_test_#{encoded_name(name)}"
      end

      def encoded_name(name)
        Digest::MD5.hexdigest(name.to_s)[0,8]
      end

      def cookie_expires
        Time.now + 7776000 # 3 months from now
      end
    end
  end
end
