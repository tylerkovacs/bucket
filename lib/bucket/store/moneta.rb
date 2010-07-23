require 'moneta'

class Bucket
  class Store
    class Moneta
      TEST_LIST_KEY_NAME = 'bucket_test_names'
      SEPARATOR = ','

      def initialize(moneta_store=nil)
        @moneta_store = moneta_store
      end

      def get_test(name)
        @moneta_store[moneta_key(name)]
      end

      def has_test?(name)
        @moneta_store.has_key?(moneta_key(name)) && 
          !@moneta_store[moneta_key(name)].nil?
      end

      def put_test(test)
        @moneta_store[moneta_key(test.name)] = test
        add_test_name(test.name)
        test
      end

      def all_tests
        tests = {}

        get_all_test_names.each do |test_name|
          test = get_test(test_name)
          tests[test.name] = test if test
        end

        tests
      end

      def clear!
        get_all_test_names.each do |test_name|
          @moneta_store.delete(moneta_key(test_name))
        end
        set_all_test_names([])
      end

      def number_of_tests
        get_all_test_names.length
      end

      protected
      def moneta_key(name)
        name.to_s
      end

      def get_all_test_names
        @moneta_store[TEST_LIST_KEY_NAME].to_s.split(SEPARATOR)
      end

      def set_all_test_names(value)
        @moneta_store[TEST_LIST_KEY_NAME] = value.join(SEPARATOR)
      end

      def add_test_name(name)
        names = [ get_all_test_names, moneta_key(name) ].flatten.uniq
        set_all_test_names(names)
      end

      def remove_test_name(name)
        names = get_all_test_names
        names.delete(name)
        set_all_test_names(names)
      end
    end
  end
end
