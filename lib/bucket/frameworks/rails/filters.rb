class Bucket
  module Frameworks
    module Rails
      module Filters
        # Before filters
        def bucket_before_filters
          bucket_clear_state
          bucket_participant
          bucket_restore_assignments
          bucket_assignment_though_url_parameters
        end

        def bucket_clear_state
          Bucket.clear_all_but_tests!
        end

        def bucket_participant
          Bucket.participant = cookies['bucket_participant'] || 
            ActiveSupport::SecureRandom.base64(10)
        end

        def bucket_restore_assignments
          Bucket::Test.all.each do |test_name, test|
            value = cookies[Bucket::Test.cookie_name(test_name)]
            value = value[:value] if value.is_a?(Hash)
            test.assign_variation(value, {
              :previously_assigned => true
            }) if value
          end
        end

        def bucket_assignment_though_url_parameters
          Bucket::Test.all.each do |test_name, test|
            value = params[Bucket::Test.cookie_name(test_name)]
            test.assign_variation(value, {:force => true}) if value
          end
        end

        # After filters
        def bucket_after_filters
          expiry_timestamp = Bucket::Test.cookie_expires
          bucket_persist_participant(expiry_timestamp)
          bucket_persist_assignments(expiry_timestamp)
        end

        def bucket_persist_participant(expiry_timestamp)
          cookies['bucket_participant'] = {
            :value => Bucket.participant,
            :expires => expiry_timestamp
          }
        end

        def bucket_persist_assignments(expiry_timestamp)
          Bucket.assignments.each do |test_name, variation|
            cookies[Bucket::Test.cookie_name(test_name)] = {
              :value => variation,
              :expires => expiry_timestamp
            }
          end
        end
      end
    end
  end
end
