require "spec_helper"

RSpec.describe Sidekiq::Tasks::Task do
  describe "#enqueue" do
    it "enqueues the task through the strategy with params" do
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
