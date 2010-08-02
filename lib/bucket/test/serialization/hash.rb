class Bucket
  class Test
    module Serialization
      module Hash
        def self.included(base)
          base.extend(ClassMethods)
        end

        def to_hash
          h = {}
          ATTRIBUTE_NAMES.each do |attribute_name|
            h[attribute_name] = self.send(attribute_name)
          end
          h
        end

        module ClassMethods
          def from_hash(hash)
            t = Bucket::Test.new
            hash.each do |key, value|
              t.send(key, value)
            end
            t
          end
        end
      end
    end
  end
end
