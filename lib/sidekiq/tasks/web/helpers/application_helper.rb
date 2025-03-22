module Sidekiq
  module Tasks
    module Web
      module Helpers
        module ApplicationHelper
          extend self

          def read_view(name)
            File.read(File.join(Sidekiq::Tasks::Web::ROOT, "views", "#{name}.erb"))
          end

          def current_env
            ENV["RAILS_ENV"] || ENV["RACK_ENV"]
          end
        end
      end
    end
  end
end
