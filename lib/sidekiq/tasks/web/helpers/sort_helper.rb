module Sidekiq
  module Tasks
    module Web
      module Helpers
        module SortHelper
          extend self

          def sort_header_url(search, root_path, column)
            next_direction = search.toggle_direction(column)

            query_params = {filter: search.filter.to_s, count: search.count}
            query_params.merge!(sort: column, direction: next_direction) if next_direction

            "#{root_path}tasks?#{URI.encode_www_form(query_params)}"
          end

          def sort_header_classes(search, column)
            css = "st-sortable"
            css += " st-sorted-#{search.direction}" if search.sorted_by?(column)
            css
          end
        end
      end
    end
  end
end
