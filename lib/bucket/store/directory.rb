require 'fileutils'

class Bucket
  class Store
    class Directory
      def initialize(directory_name)
        @directory_name = directory_name

        if !File.exists?(@directory_name)
          Bucket.logger.error("Creating missing Bucket configuration directory: #{@directory_name}")
          FileUtils.mkdir_p(@directory_name)
        end
      end

      def get_test(name)
        create_test_from_file(filename_for(name))
      end

      def has_test?(name)
        File.exists?(filename_for(name))
      end

      def put_test(test)
        File.open(filename_for(test.name), 'w') do |file|
          file.write test.to_yaml
        end
      end

      def all_tests
        tests = {}

        all_test_filenames.each do |filename|
          test = create_test_from_file(filename)
          tests[test.name]  = test
        end

        tests
      end

      def clear!
        all_test_filenames.each do |filename|
          File.delete(filename)
        end
      end

      def number_of_tests
        all_tests.length
      end

      protected
      def all_test_filenames
        Dir.glob(File.join(@directory_name, "test_*"))
      end

      def create_test_from_file(filename)
        return nil if !File.exists?(filename)
        Bucket::Test.from_yaml File.read(filename)
      end

      def filename_for(name)
        File.join(@directory_name, "test_#{name}.rb")
      end
    end
  end
end
