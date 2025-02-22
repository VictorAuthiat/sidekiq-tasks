module Sidekiq
  module Tasks
    module Strategies
      module Rules
        class TaskFromLib < Base
          def respected?(task)
            task.locations.first.start_with?("#{Rake.application.original_dir}/lib")
          end
        end
      end
    end
  end
end
