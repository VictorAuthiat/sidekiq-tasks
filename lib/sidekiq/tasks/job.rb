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
        Sidekiq::Tasks.tasks.find_by!(name: name).execute(JSON.parse(args), jid: jid)
      end
    end
  end
end
