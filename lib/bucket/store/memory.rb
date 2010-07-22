class Bucket
  class Store
    class Memory
      def initialize
        @hash = Hash.new
      end

      def get_test(name)
        @hash[name]
      end

      def has_test?(name)
        @hash.has_key?(name) && !@hash[name].nil?
      end

      def put_test(test)
        @hash[test.name] = test
      end

      def all_tests
        @hash.clone
      end

      def clear!
        @hash.clear
      end

      def number_of_tests
        @hash.length
      end
    end
  end
end
