module Sidekiq
  module Tasks
    module Web
      class Params
        attr_reader :task, :params

        # @param task [Sidekiq::Tasks::Task] The task to validate the params against.
        # @param params [Hash] The params to validate.
        def initialize(task, params)
          @task = task
          @params = params
        end

        # Returns the permitted params.
        #
        # @return [Hash] The permitted params.
        # @raise [Sidekiq::Tasks::ArgumentError] If the params are not NilClass or Hash.
        def permit!
          case params
          when NilClass then {}
          when Hash then permit_hash!
          else
            raise Sidekiq::Tasks::ArgumentError, "Invalid parameters: #{params.inspect}"
          end
        end

        private

        # Validates and returns the permitted params as a hash.
        #
        # @return [Hash] The permitted params as a hash.
        # @raise [Sidekiq::Tasks::ArgumentError] If given params does not match the task args.
        def permit_hash!
          permitted_keys = task.args.map(&:to_s)
          invalid_keys = params.keys - permitted_keys

          raise Sidekiq::Tasks::ArgumentError, "Invalid parameters: #{invalid_keys.join(", ")}" if invalid_keys.any?

          params.slice(*permitted_keys)
        end
      end
    end
  end
end
