class Bucket
  class Test
    module Serialization
      module Dsl
        def self.included(base)
          base.extend(ClassMethods)
        end

        def to_dsl
          dsl = [ "define_test #{name.inspect} do" ]
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
            value ? value.to_s.inspect : value.inspect
          else
            value.inspect
          end
        end

        module ClassMethods
          def from_dsl(string)
            instance_eval(string)
          end
        end
      end
    end
  end
end
