require 'logger'

class Bucket
  module Base
    @@config_path = File.join("config", "bucket")
    @@logger = Logger.new(STDOUT)
    @@assignments = {}
    @@new_assignments = {}
    @@participant_cookie_name = 'bucket_participant'
    @@new_assignments_cookie_name = 'bucket_atr'
    @@store = nil

    ACCESSOR_NAMES = [
      :logger, 
      :config_path, 
      :store, 
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
        Bucket.store.read_all_tests
      end

      def clear!
        clear_all_but_test_definitions!
        clear_test_definitions!
      end

      def clear_all_but_test_definitions!
        Bucket.participant = nil
        Bucket.assignments.clear
        Bucket.new_assignments.clear
      end

      def clear_test_definitions!
        Bucket::Test.clear!
      end
    end
  end
end
