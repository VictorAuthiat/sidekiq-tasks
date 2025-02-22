# frozen_string_literal: true

require "rake"

require_relative "tasks/errors"
require_relative "tasks/strategies"
require_relative "tasks/version"

module Sidekiq
  module Tasks
    autoload :Config, "sidekiq/tasks/config"
    autoload :Job, "sidekiq/tasks/job"
    autoload :Set, "sidekiq/tasks/set"
    autoload :Task, "sidekiq/tasks/task"
    autoload :TaskMetadata, "sidekiq/tasks/task_metadata"

    class << self
      def configure
        yield(config)
      end

      def config
        @_config ||= Sidekiq::Tasks::Config.new
      end

      def strategies
        @_strategies ||= Sidekiq::Tasks::Set.new(config.strategies)
      end

      def tasks
        @_tasks ||= Sidekiq::Tasks::Set.new(strategies.flat_map(&:tasks))
      end
    end
  end
end
