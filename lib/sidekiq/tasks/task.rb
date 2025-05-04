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
        jid = strategy.enqueue_task(name, params)

        storage.store_enqueue(jid, params)
      end

      def execute(params = {}, jid: nil)
        storage.store_execution(jid, "executed_at")

        begin
          strategy.execute_task(name, params)
        rescue => e
          storage.store_execution(jid, "finished_at")
          storage.store_execution_error(jid, e)
          raise
        end

        storage.store_execution(jid, "finished_at")
      end

      def storage
        @_storage ||= Sidekiq::Tasks::Storage.new(name)
      end
    end
  end
end
