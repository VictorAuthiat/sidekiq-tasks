require "sidekiq/tasks/web/helpers/application_helper"
require "sidekiq/tasks/web/helpers/task_helper"
require "sidekiq/tasks/web/helpers/pagination_helper"
require "sidekiq/tasks/web/search"
require "sidekiq/tasks/web/pagination"
require "sidekiq/tasks/web/params"

module Sidekiq
  module Tasks
    module Web
      class Extension
        def self.registered(app)
          app.helpers(Sidekiq::Tasks::Web::Helpers::ApplicationHelper)
          app.helpers(Sidekiq::Tasks::Web::Helpers::TaskHelper)
          app.helpers(Sidekiq::Tasks::Web::Helpers::PaginationHelper)

          app.get "/tasks" do
            @search = Sidekiq::Tasks::Web::Search.new(fetch_params(:count, :page, :filter))

            erb(read_view(:tasks), locals: {search: @search})
          end

          app.get "/tasks/:name" do
            @task = find_task!(env["rack.route_params"][:name])

            erb(read_view(:task), locals: {task: @task})
          rescue Sidekiq::Tasks::NotFoundError
            throw :halt, [404, {Rack::CONTENT_TYPE => "text/plain"}, ["Task not found"]]
          end

          app.post "/tasks/:name/enqueue" do
            if fetch_param("env_confirmation") != current_env
              throw :halt, [400, {Rack::CONTENT_TYPE => "text/plain"}, ["Invalid confirm"]]
            end

            task = find_task!(env["rack.route_params"][:name])
            args = Sidekiq::Tasks::Web::Params.new(task, fetch_param("args")).permit!

            task.enqueue(args)

            redirect(task_url(root_path, task))
          rescue Sidekiq::Tasks::ArgumentError => e
            throw :halt, [400, {Rack::CONTENT_TYPE => "text/plain"}, [e.message]]
          rescue Sidekiq::Tasks::NotFoundError
            throw :halt, [404, {Rack::CONTENT_TYPE => "text/plain"}, ["Task not found"]]
          end
        end
      end
    end
  end
end
