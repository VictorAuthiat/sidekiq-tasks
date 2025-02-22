module Sidekiq
  module Tasks
    module Strategies
      class RakeTask < Base
        def load_tasks
          Rake::TaskManager.record_task_metadata = true
          Rake.application.load_rakefile
          Rake::Task.tasks
        end

        def build_task_metadata(task)
          Sidekiq::Tasks::TaskMetadata.new(
            name: task.name,
            desc: task.full_comment,
            file: task.locations.first.split(":").first,
            args: task.arg_names
          )
        end

        def execute_task(name, args = nil)
          Rake::Task[name].execute(args)
        end
      end
    end
  end
end
