module Sidekiq
  module Tasks
    module Strategies
      module Rules
        class EnableWithComment < Base
          def respected?(task)
            lines = relevant_lines(task)

            return false if lines.first.match?(/namespace/)

            lines.any? { |line| line.strip.match?(magic_comment_regex) }
          end

          protected

          def magic_comment_regex
            /sidekiq-tasks:enable/
          end

          private

          def relevant_lines(task)
            file, start_line = task.locations.first.split(":")
            start_line_counting_desc = start_line.to_i > 2 ? start_line.to_i - 3 : 0
            File.read(file).split("\n")[start_line_counting_desc..start_line_counting_desc + 1].reverse
          rescue Errno::ENOENT
            raise ArgumentError, "File '#{file}' not found"
          end
        end
      end
    end
  end
end
