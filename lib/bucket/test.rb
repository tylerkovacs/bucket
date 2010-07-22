require File.join(File.dirname(__FILE__), 'test', 'validation')
require File.join(File.dirname(__FILE__), 'test', 'serialization')

class Bucket
  class Test
    include Bucket::Test::Validation
    include Bucket::Test::Serialization::Dsl
    include Bucket::Test::Serialization::Yaml
    include Bucket::Test::Serialization::Marshal

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
    # bucket_test :color_test do
    #   values ['red', 'green', 'blue']
    #   default 'red'
    #   start_at '2010/07/20 03:00:00'
    #   end_at '2010/07/20 07:00:00'
    # end
    #
    # Supported Attributes:
    # name       : The name of the test.
    # values : Test options.
    ATTRIBUTE_NAMES = [:name, :values, :default, :start_at, :end_at, :paused]

    # Create get/set methods for all methods supported in the DSL.
    ATTRIBUTE_NAMES.each do |attribute_name|
      class_eval <<-EOF
        def #{attribute_name}(value=MAGIC_DEFAULT_VALUE)
          if value != MAGIC_DEFAULT_VALUE
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

    def paused?
      paused
    end

    def pause
      paused true
      save
    end

    def resume
      paused false
      save
    end

    def active?
      if paused?
        false
      elsif !within_time_range?
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

    def save
      Bucket.store.put_test(self)
    end

    # Class Methods
    class << self
      def get_test(name)
        Bucket.store.get_test(name)
      end

      def all_tests
        Bucket.store.all_tests
      end

      def number_of_tests
        Bucket.store.number_of_tests
      end

      def create_bucket_test(name, &block)
        Test.add_test(name, &block)
      end

      def define_test(name, &block)
        test = self.new
        test.instance_eval(&block)
        test.name(name) if name
        test.validate
        test
      end

      def add_test(name, &block)
        test = define_test(name, &block)

        if Bucket.store.has_test?(test.name)
          raise Bucket::Test::DuplicateTestNameException, 
            "test named #{name} already exists"
        else
          Bucket.store.put_test(test)
        end

        test
      end

      def bucket_test(name, &block)
        test = get_test(name)

        if !test
          raise Bucket::Test::UnknownTestException if !block_given?
          test = create_bucket_test(name, &block)
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
