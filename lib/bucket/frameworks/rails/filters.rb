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
          cookies.delete(Bucket.new_assignments_cookie_name)
          Bucket.clear_all_but_test_definitions!
        end

        def bucket_participant
          Bucket.participant = cookies[Bucket.participant_cookie_name] || 
            ActiveSupport::SecureRandom.base64(10)
        end

        def bucket_restore_assignments
          Bucket::Test.all.each do |test_name, test|
            value = cookies[Bucket::Test.cookie_name(test_name)]
            value = value[:value] if value.is_a?(Hash)
            test.assign(value, {:previously_assigned => true}) if value
          end
        end

        def bucket_assignment_though_url_parameters
          Bucket::Test.all.each do |test_name, test|
            value = params[Bucket::Test.cookie_name(test_name)]
            test.force_assign(value) if value
          end
        end

        # After filters
        def bucket_after_filters
          expiry_timestamp = Bucket::Test.cookie_expires
          bucket_persist_participant(expiry_timestamp)
          bucket_persist_assignments(expiry_timestamp)
        end

        def bucket_persist_participant(expiry_timestamp)
          cookies[Bucket.participant_cookie_name] = {
            :value => Bucket.participant,
            :expires => expiry_timestamp
          }
        end

        def bucket_persist_assignments(expiry_timestamp)
          Bucket.assignments.each do |test_name, value|
            cookies[Bucket::Test.cookie_name(test_name)] = {
              :value => value,
              :expires => expiry_timestamp
            }
          end

          s = Bucket.new_assignments.keys.map do |test_name| 
            Bucket::Test.get(test_name).cookie_name
          end.join(',')
          cookies[Bucket.new_assignments_cookie_name] = s if s && !s.empty?
        end
      end
    end
  end
end
