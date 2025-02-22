module Sidekiq
  module Tasks
    module Strategies
      module Rules
        autoload :Base, "sidekiq/tasks/strategies/rules/base"
        autoload :TaskFromLib, "sidekiq/tasks/strategies/rules/task_from_lib"
        autoload :EnableWithComment, "sidekiq/tasks/strategies/rules/enable_with_comment"
      end
    end
  end
end
