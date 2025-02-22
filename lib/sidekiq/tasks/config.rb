module Sidekiq
  module Tasks
    class Config
      DEFAULT_SIDEKIQ_OPTIONS = {
        queue: "default",
        retry: false,
      }.freeze

      DEFAULT_STRATEGIES = [
        Sidekiq::Tasks::Strategies::RakeTask.new,
      ].freeze

      attr_accessor :sidekiq_options, :strategies

      def initialize
        @sidekiq_options = DEFAULT_SIDEKIQ_OPTIONS
        @strategies = DEFAULT_STRATEGIES
      end
    end
  end
end
