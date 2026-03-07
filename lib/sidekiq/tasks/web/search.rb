module Sidekiq
  module Tasks
    module Web
      class Search
        DEFAULT_COUNT = 15
        SORT_COLUMNS = ["name", "last_enqueued"].freeze
        SORT_DIRECTIONS = ["asc", "desc"].freeze

        def self.count_options
          (0..3).map { |index| DEFAULT_COUNT * (2**index) }
        end

        attr_reader :params

        def initialize(params)
          @params = params
        end

        def tasks
          @_tasks ||= sorted_collection.slice(offset, count) || []
        end

        def filtered_collection
          @_filtered_collection ||= Sidekiq::Tasks.tasks.where(name: filter)
        end

        def filter
          request_filter = params[:filter]

          ["", nil].include?(request_filter) ? nil : request_filter
        end

        def count
          requested_count = params[:count].to_i

          requested_count.positive? ? requested_count : DEFAULT_COUNT
        end

        def page
          requested_page = params[:page].to_i

          requested_page.positive? ? requested_page : 1
        end

        def sort
          SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : SORT_COLUMNS.first
        end

        def direction
          SORT_DIRECTIONS.include?(params[:direction]) ? params[:direction] : SORT_DIRECTIONS.first
        end

        def toggle_direction(column)
          return "asc" unless sort == column
          return "desc" if direction == "asc"

          nil
        end

        def sorted_by?(column)
          sort == column
        end

        def total_pages
          (filtered_collection.size.to_f / count).ceil
        end

        def offset
          (page - 1) * count
        end

        private

        def sorted_collection
          sorted = filtered_collection.sort_by { |task| sort_value(task) }
          direction == "desc" ? sorted.reverse : sorted
        end

        def sort_value(task)
          case sort
          when "name"
            task.name.to_s.downcase
          when "last_enqueued"
            sort_value_for_time(task.last_enqueue_at)
          end
        end

        def sort_value_for_time(time)
          return time.to_f if time

          direction == "asc" ? Float::INFINITY : -Float::INFINITY
        end
      end
    end
  end
end
