module Sidekiq
  module Tasks
    module Strategies
      module Rules
        class EnableWithComment < Base
          def respected?(task)
            file, line_number = task.locations.first.split(":")
            line_number = line_number.to_i

            lines = read_file_lines(file)

            return false if lines.nil?

            return true if task_has_magic_comment?(lines, line_number)

            namespace_line_index = find_namespace_line_index(lines, task)
            return false unless namespace_line_index

            namespace_has_magic_comment?(lines, namespace_line_index)
          end

          protected

          def magic_comment_regex
            /sidekiq-tasks:enable/
          end

          private

          def read_file_lines(file)
            File.read(file).split("\n")
          rescue Errno::ENOENT
            raise ArgumentError, "File '#{file}' not found"
          end

          def task_has_magic_comment?(lines, task_line)
            context_range = (task_line - 3..task_line).to_a.select { |i| i >= 0 }
            context_range.reverse.any? do |i|
              lines[i]&.strip&.match?(magic_comment_regex)
            end
          end

          def find_namespace_line_index(lines, task)
            namespace = namespace_name(task)
            lines.find_index { |line| line.strip.match?(/^namespace\s+:#{Regexp.escape(namespace)}/) }
          end

          def namespace_has_magic_comment?(lines, namespace_line_index)
            comment_line = lines[namespace_line_index - 1]&.strip
            comment_line&.match?(magic_comment_regex)
          end

          def namespace_name(task)
            task.name.split(":").first
          end
        end
      end
    end
  end
end
