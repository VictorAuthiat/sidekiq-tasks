module Sidekiq
  module Tasks
    module Web
      module Helpers
        module ApplicationHelper
          extend self

          VIEW_PATH = File.expand_path("../../web/views", __dir__).freeze

          def read_view(name)
            File.read(File.join(VIEW_PATH, "#{name}.html.erb"))
          end

          def current_env
            ENV["RAILS_ENV"] || ENV["RACK_ENV"]
          end
        end
      end
    end
  end
end
