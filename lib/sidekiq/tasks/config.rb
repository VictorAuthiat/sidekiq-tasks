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

      DEFAULT_HISTORY_LIMIT = 10

      include Sidekiq::Tasks::Validations

      attr_reader :strategies, :sidekiq_options, :authorization, :history_limit, :current_user

      def initialize
        @sidekiq_options = DEFAULT_SIDEKIQ_OPTIONS
        @strategies = DEFAULT_STRATEGIES
        @authorization = ->(_env) { true }
        @history_limit = DEFAULT_HISTORY_LIMIT
        @current_user = nil
      end

      # @see https://github.com/sidekiq/sidekiq/wiki/Advanced-Options#jobs
      def sidekiq_options=(options)
        validate_class!(options, [Hash], "sidekiq_options")
        validate_hash_option!(options, :queue, [String])
        validate_hash_option!(options, :retry, [NilClass, TrueClass, FalseClass, Integer])
        validate_hash_option!(options, :retry_for, [NilClass, Integer, Float])
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

      def history_limit=(limit)
        validate_class!(limit, [Integer], "history_limit")

        raise Sidekiq::Tasks::ArgumentError, "'history_limit' must be greater than 0" if limit <= 0

        @history_limit = limit
      end

      def authorization=(authorization_proc)
        validate_class!(authorization_proc, [Proc], "authorization")

        @authorization = authorization_proc
      end

      def current_user=(current_user_proc)
        validate_class!(current_user_proc, [Proc], "current_user")

        @current_user = current_user_proc
      end
    end
  end
end
