module Sidekiq
  module Tasks
    module Strategies
      module Rules
        class EnableWithComment < Base
          MAGIC_COMMENT_REGEX = /sidekiq-tasks:enable/

          def respected?(task)
            file, start_line = task.locations.first.split(":")
            lines = File.read(file).split("\n")[0..start_line.to_i - 2].reverse
            !lines.first.match?(/namespace/) && lines.any? { |line| line.strip.match?(MAGIC_COMMENT_REGEX) }
          rescue Errno::ENOENT
            raise ArgumentError, "File '#{file}' not found"
          end
        end
      end
    end
  end
end
