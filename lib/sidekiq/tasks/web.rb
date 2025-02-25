require "sidekiq/tasks/web/helpers/application_helper"
require "sidekiq/tasks/web/helpers/task_helper"
require "sidekiq/tasks/web/search"
require "sidekiq/tasks/task"

module Sidekiq
  module Tasks
    module Web
      ASSET_PATH = File.expand_path("web/assets", __dir__).freeze

      autoload :Extension, "sidekiq/tasks/web/extension"
      autoload :Params, "sidekiq/tasks/web/params"
    end
  end
end

if defined?(Sidekiq::Web)
  Sidekiq::Web.use(
    Rack::Static,
    urls: ["/javascripts"],
    root: File.expand_path("web/assets", __dir__),
    cascade: true,
    header_rules: [[:all, {"cache-control" => "private, max-age=86400"}]]
  )

  Sidekiq::Web.register(Sidekiq::Tasks::Web::Extension)
  Sidekiq::Web.tabs["Tasks"] = "tasks"
end
