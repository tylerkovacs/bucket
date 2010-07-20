class Bucket
  class Test
    module Validations
      def validate
        # Reject test if there are no variations supplied
        if !variations
          raise InvalidTestConfigurationException, "variations missing"
        end
      end

      # Reject the default value if the supplied default is not a valid
      # variation.
      def validate_default_attribute
        if !variations_include?(@attributes['default'])
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

      def validate_variations_attribute
        if !variations
          raise InvalidTestConfigurationException, "variations missing"
        elsif !variations.is_a?(Array)
          raise InvalidTestConfigurationException, "variations not an Array"
        elsif variations.empty?
          raise InvalidTestConfigurationException, "variations empty"
        end

        _variations, @attributes['variations'] = @attributes['variations'], []

        _variations.each_with_index do |variation, index|
          if variation.is_a?(Hash)
            if !variation.has_key?(:value)
              raise InvalidTestConfigurationException, "variations missing :value"
            end
            add_variation(variation[:value])

            if variation[:weight]
              @weights[index] = variation[:weight].to_f
            end
          else
            add_variation(variation)
          end
        end
      end
    end
  end
end
