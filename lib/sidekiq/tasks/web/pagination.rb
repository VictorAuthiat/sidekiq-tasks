module Sidekiq
  module Tasks
    module Web
      class Pagination
        PREV_LABEL = "«".freeze
        NEXT_LABEL = "»".freeze
        ELLIPSIS_LABEL = "...".freeze
        MIN_PAGE_DISPLAY = 7
        PAGE_OFFSET = 2

        attr_reader :current_page, :total_pages

        def initialize(current_page, total_pages)
          @current_page = current_page
          @total_pages = total_pages
        end

        def links
          return [] if total_pages <= 1

          build_links.flatten.compact
        end

        private

        def build_links
          [
            navigation_link(PREV_LABEL, current_page - 1, current_page > 1),
            first_page_link,
            leading_ellipsis,
            middle_page_links,
            trailing_ellipsis,
            last_page_link,
            navigation_link(NEXT_LABEL, current_page + 1, current_page < total_pages),
          ]
        end

        def navigation_link(text, page, enabled)
          enabled ? {page: page, text: text} : {page: nil, text: text, disabled: true}
        end

        def page_link(page)
          {page: page, text: page.to_s, active: page == current_page}
        end

        def ellipsis
          {page: 1, text: ELLIPSIS_LABEL, disabled: true}
        end

        def first_page_link
          return nil if total_pages <= MIN_PAGE_DISPLAY

          page_link(1)
        end

        def last_page_link
          return nil if total_pages <= MIN_PAGE_DISPLAY

          page_link(total_pages)
        end

        def leading_ellipsis
          return nil if total_pages <= MIN_PAGE_DISPLAY || current_page <= PAGE_OFFSET + 2

          ellipsis
        end

        def trailing_ellipsis
          return nil if total_pages <= MIN_PAGE_DISPLAY || current_page >= total_pages - (PAGE_OFFSET + 1)

          ellipsis
        end

        def middle_page_links
          if total_pages <= MIN_PAGE_DISPLAY
            (1..total_pages).map { |page| page_link(page) }
          else
            start_page = [current_page - PAGE_OFFSET, 2].max
            end_page   = [current_page + PAGE_OFFSET, total_pages - 1].min
            (start_page..end_page).map { |page| page_link(page) }
          end
        end
      end
    end
  end
end
