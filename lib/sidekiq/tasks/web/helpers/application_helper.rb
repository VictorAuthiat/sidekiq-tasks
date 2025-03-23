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

          def fetch_param(key)
            if Sidekiq::Tasks::Web::SIDEKIQ_GTE_8_0_0
              url_params(key.to_s)
            else
              params[key.to_s]
            end
          end

          def fetch_params(*keys)
            keys.to_h { |key| [key.to_sym, fetch_param(key)] }
          end
        end
      end
    end
  end
end
