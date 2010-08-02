class Bucket
  class Test
    module Serialization
      module Hash
        def self.included(base)
          base.extend(ClassMethods)
        end

        def to_hash(options={})
          h = {}

          fields = if options[:include] && !options[:include].empty?
            options[:include] 
          else
            ATTRIBUTE_NAMES
          end

          fields.each do |attribute_name|
            h[attribute_name] = self.send(attribute_name)
          end

          h
        end

        module ClassMethods
          def from_hash(hash)
            t = Bucket::Test.new
            hash.each do |key, value|
              t.send(key, value) if t.respond_to?(key)
            end
            t
          end
        end
      end
    end
  end
end
