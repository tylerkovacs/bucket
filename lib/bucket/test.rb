require File.join(File.dirname(__FILE__), 'test', 'validation')
require File.join(File.dirname(__FILE__), 'test', 'serialization')

class Bucket
  class Test
    include Bucket::Test::Validation
    include Bucket::Test::Serialization

    class DuplicateTestNameException < StandardError; end
    class UnknownTestException < StandardError; end
    class InvalidTestConfigurationException < StandardError; end

    # Class variable storing all defined tests.
    @@tests = {}

    MAGIC_DEFAULT_VALUE = :bucket_test_magic_default_value

    # Bucket::Test DSL
    #
    # The Bucket::Test DSL defines tests.
    #
    # Example:
    # create_bucket_test :color_test do
    #   values ['red', 'green', 'blue']
    #   default 'red'
    #   start_at '2010/07/20 03:00:00'
    #   end_at '2010/07/20 07:00:00'
    # end
    #
    # Supported Attributes:
    # name       : The name of the test.
    # values : Test options.
    ATTRIBUTE_NAMES = [:name, :values, :default, :start_at, :end_at]

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

    def value
      Bucket.assignments[name]
    end

    def values_include?(value)
      values.each do |v|
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

    def force_assign(value=MAGIC_DEFAULT_VALUE, options={})
      assign(value, options.merge({:force => true}))
    end

    def assign(value=MAGIC_DEFAULT_VALUE, options={})
      return default_value if !active? && !options[:force]

      if !Bucket.assignments.has_key?(name) || options[:force]
        if value = values_include?(value)
          Bucket.assignments[name] = value
        else
          Bucket.assignments[name] = assign_uncached
        end

        unless options[:previously_assigned]
          Bucket.new_assignments[name] = Bucket.assignments[name]
        end
      end

      Bucket.assignments[name]
    end

    def assign_uncached
      if !@weights.empty?
        random = (0..values.length-1).to_a.inject(0.0) do |t,i| 
          t + @weights[i]
        end * rand

        (0..values.length-1).to_a.map{|i| [i, @weights[i]]}.each do |i,w|
          return values[i] if w >= random
          random -= w
        end
      else
        values[rand(values.length)]
      end
    end

    def add_value(value)
      @attributes['values'] << value
    end

    def default_value
      default || values.first
    end

    def encoded_name
      self.class.encoded_name(name)
    end

    def cookie_name
      self.class.cookie_name(name)
    end

    # Class Methods
    class << self
      def get(name)
        @@tests[name]
      end

      def all
        @@tests
      end

      def number_of_tests
        @@tests.length
      end

      def clear!
        @@tests.clear
      end

      def add_test_to_local_cache(test)
        if @@tests[test.name]
          raise Bucket::Test::DuplicateTestNameException, 
            "test named #{name} already exists"
        end

        @@tests[test.name] = test
      end

      def from_file(filename)
        from_string(File.read(filename))
      end

      def from_string(data)
        instance_eval(data)
      end

      def create_bucket_test(name, &block)
        test = Test.add_test(name, &block)
        Test.add_test_to_local_cache(test)
      end

      def add_test(name, &block)
        test = self.new
        test.instance_eval(&block)
        test.name(name) if name
        test.validate
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

        test.assign
        test
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
