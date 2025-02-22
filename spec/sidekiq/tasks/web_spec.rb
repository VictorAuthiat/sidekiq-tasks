require "spec_helper"

RSpec.describe "Sidekiq::Tasks::Web", type: :request do
  include Rack::Test::Methods

  let(:app) { Sidekiq::Web }

  describe "GET /tasks" do
    it "correctly renders the tasks page when no tasks are found", :aggregate_failures do
      expect(Sidekiq::Tasks.tasks).to(
        receive(:where)
          .with(name: nil)
          .and_return(build_task_set)
      )

      get "/tasks"

      expect(last_response.status).to eq(200)
    end

    it "correctly renders the tasks page when tasks are found", :aggregate_failures do
      expect(Sidekiq::Tasks.tasks).to(
        receive(:where)
          .with(name: nil)
          .and_return(build_task_set(build_task(name: "foo:bar")))
      )

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

  describe "POST /tasks/:name/enqueue" do
    it "redirects to /tasks when the task is not found", :aggregate_failures do
      expect(Sidekiq::Tasks.tasks).to(
        receive(:find_by!)
          .with(name: "foo:bar")
          .and_raise(Sidekiq::Tasks::NotFoundError)
      )

      post "/tasks/foo-bar/enqueue"

      expect(last_response.status).to eq(404)
      expect(last_response.body).to include("Task not found")
    end

    it "enqueues the task with permitted params and redirects to the task", :aggregate_failures do
      task = build_task(name: "foo:bar", args: ["bar"])
      expect(Sidekiq::Tasks.tasks).to receive(:find_by!).twice.and_return(task) # twice because of redirect
      expect(task).to receive(:enqueue).with({"bar" => "baz"})

      post "/tasks/foo-bar/enqueue", {"name" => "foo", "args" => {"bar" => "baz"}}

      expect(last_response).to be_redirect
      follow_redirect!
      expect(last_request.path).to eq("/tasks/foo-bar")
    end

    it "returns a 400 error and does not enqueue the task when the params are invalid", :aggregate_failures do
      task = build_task(name: "foo:bar", args: ["bar"])
      expect(Sidekiq::Tasks.tasks).to receive(:find_by!).and_return(task)
      expect(task).not_to receive(:enqueue)

      post(
        "/tasks/foo-bar/enqueue",
        {
          "name" => "foo",
          "args" => {
            "bar" => "baz",
            "an_invalid_param" => "qux",
            "another_invalid_param" => "qux",
          },
        }
      )

      expect(last_response.status).to eq(400)
      expect(last_response.body).to include("Invalid parameters: an_invalid_param, another_invalid_param")
    end
  end
end
