module Sidekiq
  module Tasks
    class TaskMetadata
      include Sidekiq::Tasks::Validations

      attr_reader :name, :desc, :file, :args

      def initialize(name:, file:, desc: "", args: [])
        @name = name
        @file = file
        @desc = desc
        @args = args

        validate_params!
      end

      private

      def validate_params!
        validate_class!(name, [String, Symbol], "name")
        validate_class!(file, [String, NilClass], "file")
        validate_class!(desc, [String, NilClass], "desc")
        validate_array_classes!(args, [String, Symbol], "args")
      end
    end
  end
end
