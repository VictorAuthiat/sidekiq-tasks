require "sidekiq/tasks/web/helpers/application_helper"
require "sidekiq/tasks/web/helpers/task_helper"
require "sidekiq/tasks/task"

module Sidekiq
  module Tasks
    module Web
      autoload :Extension, "sidekiq/tasks/web/extension"
    end
  end
end

if defined?(Sidekiq::Web)
  Sidekiq::Web.register(Sidekiq::Tasks::Web::Extension)
  Sidekiq::Web.tabs["Tasks"] = "tasks"
end
