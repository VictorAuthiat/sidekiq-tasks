module Sidekiq
  module Tasks
    class TaskMetadata
      include Sidekiq::Tasks::Validations

      attr_reader :name, :desc, :file, :args, :sidekiq_options

      def initialize(name:, file:, desc: "", args: [], sidekiq_options: {})
        @name = name
        @file = file
        @desc = desc
        @args = args
        @sidekiq_options = sidekiq_options

        validate_params!
      end

      private

      def validate_params!
        validate_class!(name, [String, Symbol], "name")
        validate_class!(file, [String, NilClass], "file")
        validate_class!(desc, [String, NilClass], "desc")
        validate_array_classes!(args, [String, Symbol], "args")
        Sidekiq::Tasks::SidekiqOptionsValidator.validate!(sidekiq_options, allow_partial: true)
      end
    end
  end
end
