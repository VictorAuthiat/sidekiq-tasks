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

  describe "#storage" do
    it "returns a memoized instance of Sidekiq::Tasks::Storage" do
      task = build_task(name: "foo:bar", args: ["bar"])
      storage = task.storage
      expect(storage).to be_a(Sidekiq::Tasks::Storage)
      expect(storage.object_id).to eq(task.storage.object_id)
    end
  end

  describe "#last_enqueue_at" do
    it "returns the last enqueue at time from the storage", :aggregate_failures do
      task = build_task(name: "foo:bar", args: ["bar"])
      storage_last_enqueue_at = Time.new(2025, 1, 1, 12, 0, 0, "+00:00")
      storage = double(last_enqueue_at: storage_last_enqueue_at)
      expect(task).to receive(:storage).and_return(storage)
      expect(task.last_enqueue_at).to eq(storage_last_enqueue_at)
    end
  end

  describe "#history" do
    it "returns the history from the storage", :aggregate_failures do
      task = build_task(name: "foo:bar", args: ["bar"])

      storage_history = [
        {
          "jid" => "a1b2c3",
          "name" => "foo:bar",
          "args" => {"bar" => "baz"},
          "enqueued_at" => "2025-01-01 12:00:00 +0000",
        },
      ]

      storage = double(history: storage_history)
      expect(task).to receive(:storage).and_return(storage)
      expect(task.history).to eq(storage_history)
    end
  end

  describe "#enqueue" do
    before { clear_redis }

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

      aggregate_failures do
        expect(task.last_enqueue_at).to eq(current_time)
        expect(task.history.size).to eq(1)
        expect(task.history.first).to eq(
          {
            "jid" => "a1b2c3",
            "name" => "foo:bar",
            "args" => {"foo" => "bar"},
            "enqueued_at" => current_time.to_s,
          }
        )
      end
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
