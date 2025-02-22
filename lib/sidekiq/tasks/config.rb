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

      include Sidekiq::Tasks::Validations

      attr_reader :strategies, :sidekiq_options

      def initialize
        @sidekiq_options = DEFAULT_SIDEKIQ_OPTIONS
        @strategies = DEFAULT_STRATEGIES
      end

      # TODO: Validate other sidekiq options
      def sidekiq_options=(options)
        validate_class!(options, [Hash], "sidekiq_options")
        validate_hash_option!(options, :queue, [String])
        validate_hash_option!(options, :retry, [TrueClass, FalseClass])

        @sidekiq_options = options
      end

      def strategies=(strategies)
        validate_array_classes!(strategies, [Sidekiq::Tasks::Strategies::Base], "strategies")

        @strategies = strategies
      end
    end
  end
end
