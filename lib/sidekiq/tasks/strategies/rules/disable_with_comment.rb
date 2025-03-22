module Sidekiq
  module Tasks
    module Strategies
      module Rules
        class DisableWithComment < EnableWithComment
          def respected?(task)
            !super
          end

          protected

          def magic_comment_regex
            /sidekiq-tasks:disable/
          end
        end
      end
    end
  end
end
