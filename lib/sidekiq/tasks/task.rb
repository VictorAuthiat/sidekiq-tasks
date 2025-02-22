require "forwardable"

module Sidekiq
  module Tasks
    class Task
      extend Forwardable

      def_delegators :metadata, :name, :desc, :file, :args

      attr_reader :metadata, :strategy

      # @param metadata [Sidekiq::Tasks::TaskMetadata] The metadata for the task.
      # @param strategy [Sidekiq::Tasks::Strategies::Base] The strategy to use to execute the task.
      def initialize(metadata:, strategy:)
        @metadata = metadata
        @strategy = strategy
      end

      def enqueue(params = {})
        strategy.enqueue_task(name, params)
      end

      def execute(params = {})
        strategy.execute_task(name, params)
      end
    end
  end
end
