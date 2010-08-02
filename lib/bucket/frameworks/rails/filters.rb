class Bucket
  module Frameworks
    module Rails
      module Filters
        # Before filters
        def bucket_before_filters
          bucket_clear_state
          bucket_participant
          bucket_restore_participations
          bucket_participation_though_url_parameters
        end

        def bucket_clear_state
          cookies.delete(Bucket.cookie_name(:participations))
          Bucket.clear_all_but_test_definitions!
        end

        def bucket_participant
          Bucket.participant = cookies[Bucket.cookie_name(:participant)] || 
            ActiveSupport::SecureRandom.base64(10)
        end

        def bucket_restore_participations
          Bucket::Test.all_tests.each do |test_name, test|
            value = cookies[Bucket::Test.cookie_name(test_name)]
            value = value[:value] if value.is_a?(Hash)
            test.participate(value, {:previously_participated => true}) if value
          end
        end

        def bucket_participation_though_url_parameters
          Bucket::Test.all_tests.each do |test_name, test|
            value = params[Bucket::Test.cookie_name(test_name)]
            test.force_participate(value) if value
          end
        end

        # After filters
        def bucket_after_filters
          expiry_timestamp = Bucket::Test.cookie_expires
          bucket_persist_participant(expiry_timestamp)
          bucket_persist_participations(expiry_timestamp)
          bucket_persist_conversions(expiry_timestamp)
        end

        def bucket_persist_participant(expiry_timestamp)
          cookies[Bucket.cookie_name(:participant)] = {
            :value => Bucket.participant,
            :expires => expiry_timestamp
          }
        end

        def bucket_persist_participations(expiry_timestamp)
          Bucket.participations.each do |test_name, value|
            cookies[Bucket::Test.cookie_name(test_name)] = {
              :value => value,
              :expires => expiry_timestamp
            }
          end

          value = Bucket.new_participations.keys.map do |test_name| 
            Bucket::Test.get_test(test_name).cookie_name
          end.join(',')
          cookies[Bucket.cookie_name(:participations)] = {
            :value => value,
            :expires => expiry_timestamp
          }
        end

        def bucket_persist_conversions(expiry_timestamp)
          value = Bucket.conversions.map do |test|
            test.cookie_name
          end.join(',')

          cookies[Bucket.cookie_name(:conversions)] = {
            :value => value,
            :expires => expiry_timestamp
          }
        end
      end
    end
  end
end
