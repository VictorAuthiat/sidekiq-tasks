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
            @tasks = Sidekiq::Tasks.tasks

            erb(read_view(:tasks), locals: {tasks: @tasks})
          end

          app.get "/tasks/:name" do
            @task = Sidekiq::Tasks.tasks.find_by!(name: unparameterize_task_name(params["name"]))

            erb(read_view(:_task), locals: {task: @task})
          rescue Sidekiq::Tasks::NotFoundError
            throw :halt, [404, {Rack::CONTENT_TYPE => "text/plain"}, ["Task not found"]]
          end
        end
      end
    end
  end
end
