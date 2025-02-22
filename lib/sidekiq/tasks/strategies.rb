require_relative "strategies/rules"

module Sidekiq
  module Tasks
    module Strategies
      autoload :Base, "sidekiq/tasks/strategies/base"
      autoload :RakeTask, "sidekiq/tasks/strategies/rake_task"
    end
  end
end
