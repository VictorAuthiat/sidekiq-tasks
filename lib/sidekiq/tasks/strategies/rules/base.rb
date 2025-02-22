module Sidekiq
  module Tasks
    module Strategies
      module Rules
        class Base
          # Checks if the given task respects the rule
          #
          # @abstract Subclasses must implement this method.
          # @param task [Sidekiq::Tasks::Task] The task to validate.
          # @return [Boolean] `true` if the task respects the rule, `false` otherwise.
          # @raise [NotImplementedError] If the method is not implemented in a subclass.
          def respected?(_task)
            raise NotImplementedError, "Rule must implement #respected?"
          end
        end
      end
    end
  end
end
