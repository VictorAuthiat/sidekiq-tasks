module Sidekiq
  module Tasks
    class Config
      DEFAULT_STRATEGIES = [
        Sidekiq::Tasks::Strategies::RakeTask.new,
      ].freeze

      attr_accessor :strategies

      def initialize
        @strategies = DEFAULT_STRATEGIES
      end
    end
  end
end
