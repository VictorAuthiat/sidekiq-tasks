require "forwardable"

module Sidekiq
  module Tasks
    class Task
      extend Forwardable
      include Sidekiq::Tasks::Validations

      def_delegators :metadata, :name, :desc, :file, :args
      def_delegators :storage, :last_enqueue_at, :history

      attr_reader :metadata, :strategy

      # @param metadata [Sidekiq::Tasks::TaskMetadata] The metadata for the task.
      # @param strategy [Sidekiq::Tasks::Strategies::Base] The strategy to use to execute the task.
      # @raise [Sidekiq::Tasks::ArgumentError] If the metadata or strategy are not valid instances.
      def initialize(metadata:, strategy:)
        @metadata = metadata
        @strategy = strategy

        validate_class!(metadata, [Sidekiq::Tasks::TaskMetadata], "metadata")
        validate_class!(strategy, [Sidekiq::Tasks::Strategies::Base], "strategy")
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
