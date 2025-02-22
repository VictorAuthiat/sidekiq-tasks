module Sidekiq
  module Tasks
    module Web
      class Search
        DEFAULT_COUNT = 25

        def self.count_options
          (1..4).map { |index| index * DEFAULT_COUNT }
        end

        attr_reader :params

        def initialize(params)
          @params = params
        end

        def tasks
          @_tasks ||= filtered_collection.sort_by(&:file).slice(offset, count) || []
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

        def total_pages
          (filtered_collection.size.to_f / count).ceil
        end

        def offset
          (page - 1) * count
        end
      end
    end
  end
end
