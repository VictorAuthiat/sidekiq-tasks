require "sidekiq"

module Sidekiq
  module Tasks
    class Job
      include Sidekiq::Job

      sidekiq_options Sidekiq::Tasks.config.sidekiq_options

      # @param name [String] The name of the task to execute.
      # @param args [Hash] The arguments to pass to the task.
      # @raise [Sidekiq::Tasks::TaskNotFoundError] If the task is not found.
      def perform(name, args)
        symbolized_args = JSON.parse(args, symbolize_names: true)
        Sidekiq::Tasks.tasks.find_by!(name: name).execute(symbolized_args, jid: jid)
      end
    end
  end
end
