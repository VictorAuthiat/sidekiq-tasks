# frozen_string_literal: true

require "capybara/rspec"
require "webdrivers"

require "rack/test"
require "rack/session"

require "sidekiq"
require "sidekiq/web"
require "sidekiq/tasks"
require "sidekiq/tasks/web"

Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |file| require file }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include FactoryHelper
  config.include RedisHelper
end
