require 'logger'

class Bucket
  module Base
    @@config_path = File.join("config", "bucket")
    @@logger = Logger.new(STDOUT)
    @@participations = {}
    @@new_participations = {}
    @@conversions = []
    @@cookie_names = {
      :participant => 'bucket_participant',
      :participations => 'bucket_np',
      :conversions => 'bucket_conv'
    }
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
      :cookie_names,
      :conversions
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

      # From Rails ActionView::Helper.escape_javascript
      JS_ESCAPE_MAP = { '\\' => '\\\\', '</' => '<\/', "\r\n" => '\n', "\n" => '\n', "\r" => '\n', '"' => '\\"', "'" => "\\'" }
      def escape_javascript(js)
        if js
          js.gsub(/(\\|<\/|\r\n|[\n\r"'])/) { JS_ESCAPE_MAP[$1] }
        else
          ''
        end
      end

      def cookie_name(name)
        cookie_names[name]
      end

      def initialize_javascript(key, options={})
        inner = [ "Bucket.recorder.initialize({" ]
        options.merge({'key' => key}).each do |key, value|
          inner << "  #{key}: '#{escape_javascript(value)}'"
        end
        if !cookie_names.empty?
          inner << "}, {"
          cookie_names.each do |key, value|
            inner << "  #{key}: '#{escape_javascript(value)}'"
          end
        end
        inner << "});"
        inner.join("\n")
      end
    end
  end
end
