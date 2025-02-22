module Sidekiq
  module Tasks
    class Config
      DEFAULT_SIDEKIQ_OPTIONS = {
        queue: "default",
        retry: false,
      }.freeze

      DEFAULT_STRATEGIES = [
        Sidekiq::Tasks::Strategies::RakeTask.new(
          rules: [
            Sidekiq::Tasks::Strategies::Rules::TaskFromLib.new,
            Sidekiq::Tasks::Strategies::Rules::EnableWithComment.new,
          ]
        ),
      ].freeze

      include Sidekiq::Tasks::Validations

      attr_reader :strategies, :sidekiq_options

      def initialize
        @sidekiq_options = DEFAULT_SIDEKIQ_OPTIONS
        @strategies = DEFAULT_STRATEGIES
      end

      # @see https://github.com/sidekiq/sidekiq/wiki/Advanced-Options#jobs
      def sidekiq_options=(options)
        validate_class!(options, [Hash], "sidekiq_options")
        validate_hash_option!(options, :queue, [String])
        validate_hash_option!(options, :retry, [TrueClass, FalseClass])
        validate_hash_option!(options, :dead, [NilClass, TrueClass, FalseClass])
        validate_hash_option!(options, :backtrace, [NilClass, TrueClass, FalseClass, Integer])
        validate_hash_option!(options, :pool, [NilClass, String])
        validate_hash_option!(options, :tags, [NilClass, Array])

        @sidekiq_options = options
      end

      def strategies=(strategies)
        validate_array_classes!(strategies, [Sidekiq::Tasks::Strategies::Base], "strategies")

        @strategies = strategies
      end
    end
  end
end
