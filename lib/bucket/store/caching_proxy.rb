class Bucket
  class Store
    class CachingProxy
      def initialize(duration)
        @duration = duration
        @hash = Hash.new
        @timestamp = nil
      end

      def get_test(name)
        refresh_from_store if stale?
        @hash[name]
      end

      def has_test?(name)
        refresh_from_store if stale?
        @hash.has_key?(name) && !@hash[name].nil?
      end

      def put_test(test)
        Bucket.store.put_test(test)
        @hash[test.name] = test
      end

      def all_tests
        refresh_from_store if stale?
        @hash.clone
      end

      def clear!
        Bucket.store.clear!
        @hash.clear
      end

      def number_of_tests
        refresh_from_store if stale?
        @hash.length
      end

      def stale?
        !@timestamp || (Time.now - @timestamp > @duration)
      end

      def refresh_from_store
        @hash = Bucket.store.all_tests
        @timestamp = Time.now
      end
    end
  end
end
