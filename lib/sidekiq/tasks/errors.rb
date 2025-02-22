module Sidekiq
  module Tasks
    class NotFoundError < StandardError
    end

    class ArgumentError < StandardError
    end

    class NotImplementedError < StandardError
    end
  end
end
