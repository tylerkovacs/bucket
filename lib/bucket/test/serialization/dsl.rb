require 'yaml'

class Bucket
  class Test
    module Serialization
      module Yaml
        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          def from_yaml(string)
            YAML.load(string)
          end
        end
      end
    end
  end
end
