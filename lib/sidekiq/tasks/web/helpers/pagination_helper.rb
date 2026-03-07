module Sidekiq
  module Tasks
    module Web
      module Helpers
        module PaginationHelper
          extend self
          include Sidekiq::Tasks::Web::Helpers::TagHelper

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
