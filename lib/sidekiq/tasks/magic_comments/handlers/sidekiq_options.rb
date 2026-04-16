require "yaml"

module Sidekiq
  module Tasks
    module MagicComments
      module Handlers
        class SidekiqOptions < Base
          def self.name_token
            "sidekiq_options"
          end

          def self.cast(raw_value)
            return {} if raw_value.nil? || raw_value.strip.empty?

            parsed = parse_yaml(raw_value)

            unless parsed.is_a?(Hash)
              raise Sidekiq::Tasks::ArgumentError,
                    "'sidekiq_options' magic comment must parse to a Hash but received #{parsed.class}"
            end

            Sidekiq::Tasks::SidekiqOptionsValidator.validate!(parsed, allow_partial: true)

            parsed
          end

          def self.parse_yaml(raw_value)
            YAML.safe_load("{#{raw_value}}", permitted_classes: [Symbol], symbolize_names: true)
          rescue Psych::SyntaxError => e
            raise Sidekiq::Tasks::ArgumentError,
                  "'sidekiq_options' magic comment is not valid YAML: #{e.message}"
          end
          private_class_method :parse_yaml
        end
      end
    end
  end
end
