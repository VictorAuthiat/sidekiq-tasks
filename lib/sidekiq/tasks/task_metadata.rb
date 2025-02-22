module Sidekiq
  module Tasks
    class TaskMetadata
      attr_reader :name, :desc, :file, :args

      def initialize(name:, file:, desc: "", args: [])
        @name = name
        @file = file
        @desc = desc
        @args = args
      end
    end
  end
end
