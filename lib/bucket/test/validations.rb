class Bucket
  class Test
    module Validations
      def validate
        # Reject test if there are no values supplied
        if !values
          raise InvalidTestConfigurationException, "values missing"
        end
      end

      # Reject the default value if the supplied default is not a valid
      # value.
      def validate_default_attribute
        if !values_include?(@attributes['default'])
          @attributes.delete('default')
        end
      end

      def validate_start_at_attribute
        if !@attributes['start_at']
          raise InvalidTestConfigurationException, "start_at missing"
        end

        # Accept Time objects
        return if @attributes['start_at'].is_a?(Time)

        if @attributes['start_at'].is_a?(String)
          begin
            @attributes['start_at'] = Time.parse(@attributes['start_at'])
          rescue Exception => err
            raise InvalidTestConfigurationException, 
              "start_at could not be Time.parse'd: #{err.message} "
          end
        else
          raise InvalidTestConfigurationException, "start_at must be a String"
        end
      end

      def validate_end_at_attribute
        if !@attributes['end_at']
          raise InvalidTestConfigurationException, "end_at missing"
        end

        # Accept Time objects
        return if @attributes['end_at'].is_a?(Time)

        if @attributes['end_at'].is_a?(String)
          begin
            @attributes['end_at'] = Time.parse(@attributes['end_at'])
          rescue Exception => err
            raise InvalidTestConfigurationException, 
              "end_at could not be Time.parse'd: #{err.message} "
          end
        else
          raise InvalidTestConfigurationException, "end_at must be a String"
        end
      end

      def validate_values_attribute
        if !values
          raise InvalidTestConfigurationException, "values missing"
        elsif !values.is_a?(Array)
          raise InvalidTestConfigurationException, "values not an Array"
        elsif values.empty?
          raise InvalidTestConfigurationException, "values empty"
        end

        _values, @attributes['values'] = @attributes['values'], []

        _values.each_with_index do |value, index|
          if value.is_a?(Hash)
            if !value.has_key?(:value)
              raise InvalidTestConfigurationException, "values missing :value"
            end
            add_value(value[:value])

            if value[:weight]
              @weights[index] = value[:weight].to_f
            end
          else
            add_value(value)
          end
        end
      end
    end
  end
end
