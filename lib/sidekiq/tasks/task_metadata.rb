module Sidekiq
  module Tasks
    class TaskMetadata
      include Sidekiq::Tasks::Validations

      attr_reader :name, :desc, :file, :args, :sidekiq_options, :error

      def initialize(name:, file:, desc: "", args: [], sidekiq_options: {}, error: nil)
        @name = name
        @file = file
        @desc = desc
        @args = args
        @sidekiq_options = sidekiq_options
        @error = error

        validate_params!
      end

      def error?
        !@error.nil?
      end

      private

      def validate_params!
        validate_class!(name, [String, Symbol], "name")
        validate_class!(file, [String, NilClass], "file")
        validate_class!(error, [String, NilClass], "error")
        return if error?

        validate_class!(desc, [String, NilClass], "desc")
        validate_array_classes!(args, [String, Symbol], "args")
        validate_class!(sidekiq_options, [Hash], "sidekiq_options")
      end
    end
  end
end
