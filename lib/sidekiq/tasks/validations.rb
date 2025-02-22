module Sidekiq
  module Tasks
    module Validations
      def validate_class!(object, classes, name = nil)
        return if classes.any? { |klass| object.is_a?(klass) }

        expected_classes = classes.map(&:name).join(" or ")
        name ||= object

        raise Sidekiq::Tasks::ArgumentError,
              "'#{name}' must be an instance of #{expected_classes} but received #{object.class}"
      end
      module_function :validate_class!

      def validate_array_classes!(objects, classes, name = nil)
        validate_class!(objects, [Array], name)

        objects.each { |object| validate_class!(object, classes) }
      end
      module_function :validate_array_classes!

      def validate_hash_option!(options, key, classes = [])
        validate_class!(options, [Hash])
        validate_class!(options[key], classes, key)
      end
      module_function :validate_hash_option!

      def validate_expected_values!(value, expected_values, name = nil)
        return if expected_values.any? { |expected_value| value == expected_value }

        raise Sidekiq::Tasks::ArgumentError,
              "'#{name}' must be one of #{expected_values.map(&:inspect).join(" or ")} but received #{value.inspect}"
      end
      module_function :validate_expected_values!
    end
  end
end
