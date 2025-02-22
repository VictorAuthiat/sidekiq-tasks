# frozen_string_literal: true

require "simplecov_json_formatter"
require "sidekiq/tasks"

SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::JSONFormatter,
  ]
)

SimpleCov.start do
  add_filter "spec/"
  add_group "Sidekiq-Tasks", "lib/"
end
