module Sidekiq
  module Tasks
    module Web
      module Helpers
        module PaginationHelper
          extend self

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

          def build_tag(tag, content = nil, **attributes, &block)
            attr_string = attributes.map { |key, value| "#{key}=\"#{value}\"" }.join(" ")

            "<#{tag} #{attr_string}>#{block&.call || content}</#{tag}>"
          end

          def build_classes(*classes, **conditions)
            condition_classes = conditions.select { |_, value| value }.keys

            (classes + condition_classes).join(" ")
          end

          def pagination_url(root_path, search, page)
            "#{root_path}tasks?filter=#{ERB::Util.url_encode(search.filter)}&count=#{search.count}&page=#{page}"
          end
        end
      end
    end
  end
end
