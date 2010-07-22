class Bucket
  class Test
    module Serialization
      module Marshal
        def self.included(base)
          base.extend(ClassMethods)
        end

        def marshal
          ::Marshal.dump(self)
        end

        module ClassMethods
          def from_marshal(string)
            ::Marshal.load(string)
          end
        end
      end
    end
  end
end
