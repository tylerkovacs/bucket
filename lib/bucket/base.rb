require 'logger'

class Bucket
  module Base
    @@config_path = File.join("config", "bucket")
    @@logger = Logger.new(STDOUT)
    @@assignments = {}
    @@new_assignments = {}
    @@participant_cookie_name = 'bucket_participant'
    @@new_assignments_cookie_name = 'bucket_atr'

    ACCESSOR_NAMES = [
      :logger, 
      :config_path, 
      :participant,
      :assignments,
      :new_assignments,
      :participant_cookie_name,
      :new_assignments_cookie_name
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
        Bucket.assignments.clear
        Bucket.new_assignments.clear
      end

      def clear_tests!
        Bucket::Test.clear!
      end
    end
  end
end
