require "sidekiq/tasks"

module Sidekiq
  module Tasks
    module Web
      autoload :Extension, "sidekiq/tasks/web/extension"

      ROOT = File.expand_path("../../../web", File.dirname(__FILE__))
      SIDEKIQ_GTE_7_3_0 = Gem::Version.new(Sidekiq::VERSION) >= Gem::Version.new("7.3.0")
    end
  end
end

if Sidekiq::Tasks::Web::SIDEKIQ_GTE_7_3_0
  Sidekiq::Web.configure do |config|
    config.register(
      Sidekiq::Tasks::Web::Extension,
      name: "tasks",
      tab: ["Tasks"],
      index: ["tasks"],
      root_dir: Sidekiq::Tasks::Web::ROOT,
      asset_paths: ["js", "css"]
    )
  end
else
  Sidekiq::Web.tabs["Tasks"] = "tasks"
  Sidekiq::Web.register(Sidekiq::Tasks::Web::Extension)
  Sidekiq::Web.locales << "#{Sidekiq::Tasks::Web::ROOT}/locales"

  Sidekiq::Web.use(
    Rack::Static,
    urls: ["/tasks/css", "/tasks/js"],
    root: "#{Sidekiq::Tasks::Web::ROOT}/assets",
    cascade: true,
    header_rules: [[:all, {"cache-control" => "private, max-age=86400"}]]
  )
end
