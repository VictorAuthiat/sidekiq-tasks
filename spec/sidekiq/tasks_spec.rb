require "spec_helper"

RSpec.describe Sidekiq::Tasks::Task do
  describe "validations" do
    it "accepts Sidekiq::Tasks::TaskMetadata as metadata", :aggregate_failures do
      expect(build_task(metadata: build_task_metadata).metadata).to be_a(Sidekiq::Tasks::TaskMetadata)

      expect { build_task(metadata: "foo") }.to(
        raise_error(
          Sidekiq::Tasks::ArgumentError,
          "'metadata' must be an instance of Sidekiq::Tasks::TaskMetadata but received String"
        )
      )
    end

    it "accepts Sidekiq::Tasks::Strategies::Base as strategy", :aggregate_failures do
      expect(build_task(strategy: build_strategy).strategy).to be_a(Sidekiq::Tasks::Strategies::Base)

      expect { build_task(strategy: "foo") }.to(
        raise_error(
          Sidekiq::Tasks::ArgumentError,
          "'strategy' must be an instance of Sidekiq::Tasks::Strategies::Base but received String"
        )
      )
    end
  end

  describe "#enqueue" do
    it "enqueues the task through the strategy with params and stores the task trace" do
      current_time = Time.new(2025, 1, 1, 12, 0, 0, "+00:00")
      allow(Time).to receive(:now).and_return(current_time)

      task = build_task(name: "foo:bar", args: ["foo"])

      expect(task.strategy).to(
        receive(:enqueue_task)
          .with("foo:bar", {"foo" => "bar"})
          .and_return("a1b2c3")
      )

      task.enqueue({"foo" => "bar"})
    end
  end

  describe "#execute" do
    it "executes the task through the strategy with params", :aggregate_failures do
      task = build_task(name: "foo:bar", args: ["foo"])
      execution_result = double
      expect(task.strategy).to receive(:execute_task).with("foo:bar", {"foo" => "bar"}).and_return(execution_result)
      expect(task.execute({"foo" => "bar"})).to eq(execution_result)
    end
  end
end
