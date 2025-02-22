module Sidekiq
  module Tasks
    module Web
      module Helpers
        module TaskHelper
          extend self

          def parameterize_task_name(task_name)
            task_name.gsub(":", "-")
          end

          def unparameterize_task_name(task_name)
            task_name.gsub("-", ":")
          end

          def task_url(root_path, task)
            "#{root_path}tasks/#{parameterize_task_name(task.name)}"
          end
        end
      end
    end
  end
end
