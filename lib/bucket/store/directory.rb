class Bucket
  class Store
    class Directory
      def initialize(directory_name)
        @directory_name = directory_name

        if !File.exists?(@directory_name)
          Bucket.logger.error("Bucket directory missing: #{@directory_name}")
        end
      end

      def read_all_tests
        Dir.glob(File.join(@directory_name, "test_*")) do |filename|
          Test.from_file(filename)
        end
      end

      def get_test(name)
      end

      def put_test(test)
      end

      def all_tests
      end

      def number_of_tests
      end
    end
  end
end
