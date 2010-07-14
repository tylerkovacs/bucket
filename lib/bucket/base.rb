require 'logger'

class Bucket
  module Base
    @@config_path = File.join("config", "bucket")
    @@logger = Logger.new(STDOUT)
    @@assigned_variations = {}

    ACCESSOR_NAMES = [
      :logger, 
      :config_path, 
      :participant,
      :assigned_variations
    ]
  
    def self.included(base)
      base.extend(ClassMethods)

      ACCESSOR_NAMES.each do |accessor_name|
        base.class_eval <<-EOF
          def self.#{accessor_name}
            @@#{accessor_name}
          end

          def self.#{accessor_name}=(value)
            @@#{accessor_name} = value
          end
        EOF
      end
    end

    module ClassMethods
      def init
        if !File.exists?(config_path)
          logger.error("Bucket configuration directory missing: #{config_path}")
        else
          Dir.glob(File.join(config_path, "test_*")) do |filename|
            Test.from_file(filename)
          end
        end
      end

      def clear!
        clear_all_but_tests!
        clear_tests!
      end

      def clear_all_but_tests!
        Bucket.participant = nil
        Bucket.assigned_variations.clear
      end

      def clear_tests!
        Bucket::Test.clear!
      end
    end
  end
end
