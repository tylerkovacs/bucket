class Bucket
  module Frameworks
    module Rails
      module Filters
        def clear_and_restore_bucket_state
          Bucket.clear_all_but_tests!
          restore_bucket_state
          test_assignment_through_url_override
        end

        def persist_bucket_state
          expiry_timestamp = Bucket::Test.cookie_expires
          persist_bucket_participant(expiry_timestamp)
          persist_bucket_test_assignment(expiry_timestamp)
        end

        def persist_bucket_participant(expiry_timestamp)
          cookies['bucket_participant'] = {
            :value => Bucket.participant,
            :expires => expiry_timestamp
          }
        end

        def persist_bucket_test_assignment(expiry_timestamp)
          Bucket.assigned_variations.each do |test_name, variation|
            cookies[Bucket::Test.cookie_name(test_name)] = {
              :value => variation,
              :expires => expiry_timestamp
            }
          end
        end

        def restore_bucket_state
          bucket_participant
          restore_bucket_test_assignment
        end

        def restore_bucket_test_assignment
          Bucket::Test.all.each do |test_name, test|
            value = cookies[Bucket::Test.cookie_name(test_name)]
            value = value[:value] if value.is_a?(Hash)
            test.assign_variation(value) if value
          end
        end

        def bucket_participant
          Bucket.participant = cookies['bucket_participant'] || 
            ActiveSupport::SecureRandom.base64(10)
        end

        def test_assignment_through_url_override
          Bucket::Test.all.each do |test_name, test|
            value = params[Bucket::Test.cookie_name(test_name)]
            test.assign_variation(value, {:force => true}) if value
          end
        end
      end
    end
  end
end
