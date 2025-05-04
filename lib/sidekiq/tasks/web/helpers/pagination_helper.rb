module Sidekiq
  module Tasks
    module Web
      module Helpers
        module PaginationHelper
          extend self
          include Sidekiq::Tasks::Web::Helpers::TagHelper

          def pagination_link(root_path, link, search)
            build_tag(:li, class: "st-page-item") do
              build_tag(
                :a,
                link[:text],
                class: build_classes("st-page-link", disabled: link[:disabled], active: link[:active]),
                href: pagination_url(root_path, search, link[:page])
              )
            end
          end

          private

          def pagination_url(root_path, search, page)
            "#{root_path}tasks?filter=#{ERB::Util.url_encode(search.filter)}&count=#{search.count}&page=#{page}"
          end
        end
      end
    end
  end
end
