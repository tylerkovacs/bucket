require File.join(File.dirname(__FILE__), 'test', 'validations')

class Bucket
  class Test
    include Bucket::Test::Validations

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

    def force_assign(variation=MAGIC_DEFAULT_VALUE, options={})
      assign(variation, options.merge({:force => true}))
    end

    def assign(variation=MAGIC_DEFAULT_VALUE, options={})
      return default_variation if !active? && !options[:force]

      if !Bucket.assignments.has_key?(name) || options[:force]
        if variation = variations_include?(variation)
          Bucket.assignments[name] = variation
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

        test.assign
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
