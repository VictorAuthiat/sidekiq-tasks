$TESTING = true

Sidekiq.logger.level = Logger::ERROR

Sidekiq.configure_client do |config|
  config.redis = {url: ENV.fetch("REDIS_URL", "redis://0.0.0.0:6379")}
end
