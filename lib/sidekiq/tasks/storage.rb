module Sidekiq
  module Tasks
    module Storage
      autoload :Base, "sidekiq/tasks/storage/base"
      autoload :Redis, "sidekiq/tasks/storage/redis"
    end
  end
end
