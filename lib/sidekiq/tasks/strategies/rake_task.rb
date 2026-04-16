module Sidekiq
  module Tasks
    module Strategies
      class RakeTask < Base
        def initialize(rules: [], scanner: Sidekiq::Tasks::MagicComments::Scanner.new)
          super(rules: rules)
          @scanner = scanner
        end

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
            args: task.arg_names,
            sidekiq_options: extract_sidekiq_options(task)
          )
        rescue Sidekiq::Tasks::ArgumentError => e
          Sidekiq::Tasks::TaskMetadata.new(
            name: task.name,
            file: task.locations.first&.split(":")&.first,
            error: e.message
          )
        end

        def execute_task(name, args = nil)
          Rake::Task[name].execute(args)
        end

        private

        def extract_sidekiq_options(task)
          @scanner.scan(task).fetch(
            Sidekiq::Tasks::MagicComments::Handlers::SidekiqOptions.name_token,
            default: {}
          )
        end
      end
    end
  end
end
