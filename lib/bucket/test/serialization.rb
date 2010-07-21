require 'yaml'

class Bucket
  class Test
    module Serialization
      def self.included(base)
        base.extend(ClassMethods)
      end

      def marshal
        Marshal.dump(self)
      end

      def to_dsl
        dsl = [ "create_bucket_test #{name.inspect}" ]
        ATTRIBUTE_NAMES.each do |attribute_name|
          dsl << "  #{attribute_name} #{serialize_attribute(attribute_name)}"
        end
        dsl << "end\n"

        dsl.join("\n")
      end

      def serialize_attribute(name)
        value = send(name)
        case name
        when :start_at, :end_at
          value.to_s.inspect
        else
          value.inspect
        end
      end

      module ClassMethods
        def from_dsl(dsl)
          instance_eval(dsl)
        end
      end
    end
  end
end
