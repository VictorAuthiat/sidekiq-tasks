require "sidekiq"

module Sidekiq
  module Tasks
    class Job
      include Sidekiq::Job

      # @param name [String] The name of the task to execute.
      # @param args [Hash] The arguments to pass to the task.
      def perform(name, args)
        Sidekiq::Tasks.tasks.find_by!(name: name).execute(JSON.parse(args))
      end
    end
  end
end
