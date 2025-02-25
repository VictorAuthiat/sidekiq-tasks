module Sidekiq
  module Tasks
    module Web
      class Extension
        LOCALES_PATH = File.expand_path("../web/locales", __dir__).freeze

        def self.registered(app)
          app.settings.locales << File.join(LOCALES_PATH)

          app.helpers do
            include Sidekiq::Tasks::Web::Helpers::ApplicationHelper
            include Sidekiq::Tasks::Web::Helpers::TaskHelper
          end

          app.get "/tasks" do
            @search = Sidekiq::Tasks::Web::Search.new(params)

            erb(read_view(:tasks), locals: {search: @search})
          end

          app.get "/tasks/:name" do
            @task = find_task!(params["name"])

            erb(read_view(:task), locals: {task: @task})
          rescue Sidekiq::Tasks::NotFoundError
            throw :halt, [404, {Rack::CONTENT_TYPE => "text/plain"}, ["Task not found"]]
          end

          app.post "/tasks/:name/enqueue" do
            if params["env_confirmation"] != current_env
              throw :halt, [400, {Rack::CONTENT_TYPE => "text/plain"}, ["Invalid confirm"]]
            end

            task = find_task!(params["name"])
            args = Sidekiq::Tasks::Web::Params.new(task, params["args"]).permit!

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
