require_relative "registry"
require_relative "handlers/base"
require_relative "handlers/enable"
require_relative "handlers/disable"
require_relative "handlers/sidekiq_options"

Sidekiq::Tasks::MagicComments::Registry.register(Sidekiq::Tasks::MagicComments::Handlers::Enable)
Sidekiq::Tasks::MagicComments::Registry.register(Sidekiq::Tasks::MagicComments::Handlers::Disable)
Sidekiq::Tasks::MagicComments::Registry.register(Sidekiq::Tasks::MagicComments::Handlers::SidekiqOptions)
