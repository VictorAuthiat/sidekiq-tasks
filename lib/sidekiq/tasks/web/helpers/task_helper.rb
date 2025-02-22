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

          def find_task!(parameterized_name)
            name = unparameterize_task_name(parameterized_name)

            Sidekiq::Tasks.tasks.find_by!(name: name)
          end

          def task_url(root_path, task)
            "#{root_path}tasks/#{parameterize_task_name(task.name)}"
          end
        end
      end
    end
  end
end
