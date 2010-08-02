require 'logger'

class Bucket
  module Base
    @@config_path = File.join("config", "bucket")
    @@logger = Logger.new(STDOUT)
    @@participations = {}
    @@new_participations = {}
    @@conversions = []
    @@participant_cookie_name = 'bucket_participant'
    @@new_participation_cookie_name = 'bucket_np'
    @@conversion_cookie_name = 'bucket_conv'
    @@store = nil
    @@store_proxy_cache = Bucket::Store::CachingProxy.new(60)

    ACCESSOR_NAMES = [
      :logger, 
      :config_path, 
      :store, 
      :store_proxy_cache, 
      :participant,
      :participations,
      :new_participations,
      :participant_cookie_name,
      :new_participation_cookie_name,
      :conversions,
      :conversion_cookie_name
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
      def clear!
        clear_all_but_test_definitions!
        clear_test_definitions!
      end

      def clear_all_but_test_definitions!
        Bucket.participant = nil
        Bucket.participations.clear
        Bucket.conversions.clear
        Bucket.new_participations.clear
      end

      def clear_test_definitions!
        Bucket.store_proxy_cache.clear!
      end
    end
  end
end
