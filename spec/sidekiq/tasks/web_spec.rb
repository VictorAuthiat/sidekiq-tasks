require "spec_helper"

RSpec.describe "Sidekiq::Tasks::Web", type: :request do
  include Rack::Test::Methods

  let(:app) { Sidekiq::Web }

  describe "GET /tasks" do
    it "correctly renders the tasks page when no tasks are found", :aggregate_failures do
      expect(Sidekiq::Tasks).to receive(:tasks).and_return(build_task_set)

      get "/tasks"

      expect(last_response.status).to eq(200)
    end

    it "correctly renders the tasks page when tasks are found", :aggregate_failures do
      expect(Sidekiq::Tasks).to receive(:tasks).and_return(build_task_set(build_task(name: "foo:bar")))

      get "/tasks"

      expect(last_response.status).to eq(200)
    end
  end

  describe "GET /tasks/:name" do
    it "returns a 404 error when the task is not found", :aggregate_failures do
      expect(Sidekiq::Tasks.tasks).to(
        receive(:find_by!)
          .with(name: "foo")
          .and_raise(Sidekiq::Tasks::NotFoundError)
      )

      get "/tasks/foo"

      expect(last_response.status).to eq(404)
      expect(last_response.body).to include("Task not found")
    end

    it "renders the task details page when the task is found", :aggregate_failures do
      expect(Sidekiq::Tasks.tasks).to(
        receive(:find_by!)
          .with(name: "foo:bar")
          .and_return(build_task(name: "foo:bar"))
      )

      get "/tasks/foo-bar"

      expect(last_response.status).to eq(200)
    end
  end
end
