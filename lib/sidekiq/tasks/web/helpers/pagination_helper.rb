module Sidekiq
  module Tasks
    module Web
      module Helpers
        module PaginationHelper
          extend self
          include Sidekiq::Tasks::Web::Helpers::TagHelper

          def pagination_base_url(search, root_path)
            query_params = {
              filter: search.filter.to_s,
              count: search.count,
              sort: search.sort,
              direction: search.direction,
            }

            "#{root_path}tasks?#{URI.encode_www_form(query_params)}"
          end

          def build_pagination_link(link, base_url)
            separator = base_url.include?("?") ? "&" : "?"

            build_tag(:li, class: "st-page-item") do
              build_tag(
                :a,
                link[:text],
                class: build_classes("st-page-link", disabled: link[:disabled], active: link[:active]),
                href: "#{base_url}#{separator}page=#{link[:page]}"
              )
            end
          end
        end
      end
    end
  end
end
