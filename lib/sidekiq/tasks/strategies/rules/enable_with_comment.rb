module Sidekiq
  module Tasks
    module Strategies
      module Rules
        class EnableWithComment < Base
          MAGIC_COMMENT_REGEX = /sidekiq-tasks:enable/

          def respected?(task)
            file, start_line = task.locations.first.split(":")
            start_line_counting_desc = start_line.to_i > 2 ? start_line.to_i - 3 : 0
            lines = File.read(file).split("\n")[start_line_counting_desc..start_line_counting_desc + 1].reverse

            valid_magic_comment_line?(lines)
          rescue Errno::ENOENT
            raise ArgumentError, "File '#{file}' not found"
          end

          private

          def valid_magic_comment_line?(lines)
            return false if lines.first.match?(/namespace/)

            lines.any? { |line| line.strip.match?(MAGIC_COMMENT_REGEX) }
          end
        end
      end
    end
  end
end
