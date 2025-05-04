module Sidekiq
  module Tasks
    module Web
      module Helpers
        module TaskHelper
          extend self
          include Sidekiq::Tasks::Web::Helpers::TagHelper

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

          def task_status(jid_history)
            if jid_history["error"]
              :failure
            elsif jid_history["finished_at"]
              :success
            elsif jid_history["executed_at"]
              :running
            else
              :pending
            end
          end

          def format_task_duration(start_time, end_time)
            return "-" unless start_time && end_time

            duration_in_milliseconds = ((end_time - start_time) * 1000).to_i

            if duration_in_milliseconds >= 1000
              duration_in_seconds = (duration_in_milliseconds / 1000.0).round
              "#{[duration_in_seconds, 1].max}s"
            else
              "#{[duration_in_milliseconds, 1].max}ms"
            end
          end
        end
      end
    end
  end
end
