require "spec_helper"

RSpec.describe Sidekiq::Tasks::Storage do
  describe "#jid_key" do
    it "returns the task name with the prefix" do
      expect(described_class.new("foo").jid_key).to eq("task:foo")
      expect(described_class.new("foo:bar").jid_key).to eq("task:foo:bar")
    end
  end

  describe "#history_key" do
    it "returns the history key with the jid key as prefix", :aggregate_failures do
      expect(described_class.new("foo").history_key).to eq("task:foo:history")
      expect(described_class.new("foo:bar").history_key).to eq("task:foo:bar:history")
    end
  end

  describe "#last_enqueue_at" do
    it "returns nil when the last enqueue at key is not found", :aggregate_failures do
      expect(Sidekiq).to receive(:redis).and_yield(double(hget: nil))
      expect(described_class.new("foo:bar").last_enqueue_at).to be_nil
    end

    it "returns the formatted last enqueue at time when present", :aggregate_failures do
      time = Time.new(2025, 1, 1, 12, 0, 0, "+00:00")
      expect(Sidekiq).to receive(:redis).and_yield(double(hget: time.to_i.to_s))
      expect(described_class.new("foo:bar").last_enqueue_at).to eq(time)
    end
  end

  describe "#last_execution_at" do
    it "returns nil when the last execution at key is not found", :aggregate_failures do
      expect(Sidekiq).to receive(:redis).and_yield(double(hget: nil))
      expect(described_class.new("foo:bar").last_execution_at).to be_nil
    end

    it "returns the formatted last execution at time when present", :aggregate_failures do
      time = Time.new(2025, 1, 1, 12, 0, 0, "+00:00")
      expect(Sidekiq).to receive(:redis).and_yield(double(hget: time.to_i.to_s))
      expect(described_class.new("foo:bar").last_execution_at).to eq(time)
    end
  end

  describe "#history" do
    it "returns an empty array when the history is empty" do
      allow(Sidekiq).to receive(:redis).and_yield(double(lrange: [], ltrim: []))
      expect(described_class.new("foo:bar").history).to eq([])
    end

    it "returns the history, with parsed times, when present" do
      first_task_trace = {
        jid: "foo",
        name: "foo",
        args: {"bar" => "baz"},
        enqueued_at: Time.new(2025, 1, 1, 13, 0, 0, "+00:00").to_i,
      }

      second_task_trace = {
        jid: "bar",
        name: "bar",
        args: {"baz" => "qux"},
        enqueued_at: Time.new(2025, 1, 1, 12, 0, 0, "+00:00").to_i,
      }

      tasks_history = [first_task_trace, second_task_trace].map { |task_trace| Sidekiq.dump_json(task_trace) }
      allow(Sidekiq).to receive(:redis).and_yield(double(lrange: tasks_history, ltrim: []))

      expect(described_class.new("foo:bar").history).to eq(
        [
          {
            "jid" => "foo",
            "name" => "foo",
            "args" => {"bar" => "baz"},
            "enqueued_at" => Time.at(first_task_trace[:enqueued_at]),
          },
          {
            "jid" => "bar",
            "name" => "bar",
            "args" => {"baz" => "qux"},
            "enqueued_at" => Time.at(second_task_trace[:enqueued_at]),
          },
        ]
      )
    end
  end

  describe "#store_history" do
    before do
      clear_redis
      stub_const("Sidekiq::Tasks::Storage::HISTORY_LIMIT", 3)
    end

    let(:storage) { described_class.new("foo:bar") }

    it "stores the task history" do
      current_time = Time.now
      storage.store_history("a1b2c3", {"bar" => "baz"}, current_time)

      expect(storage.history).to eq(
        [
          {
            "jid" => "a1b2c3",
            "name" => "foo:bar",
            "args" => {"bar" => "baz"},
            "enqueued_at" => Time.at(current_time.to_i),
          },
        ]
      )
    end

    it "trims the history to HISTORY_LIMIT entries", :aggregate_failures do
      current_time = Time.now

      Sidekiq.redis do |conn|
        Sidekiq::Tasks::Storage::HISTORY_LIMIT.times do |index|
          task_trace = Sidekiq.dump_json(
            {
              jid: "jid_#{index}",
              name: "task_#{index}",
              args: {},
              enqueued_at: current_time.to_i,
            }
          )

          conn.lpush("task:foo:bar:history", task_trace)
        end
      end

      storage.store_history("a1b2c3", {"bar" => "baz"}, current_time)
      expect(storage.history.size).to eq(Sidekiq::Tasks::Storage::HISTORY_LIMIT)
      expect(storage.history.map { |task_trace| task_trace["jid"] }).to eq(%w[a1b2c3 jid_2 jid_1])
    end
  end

  describe "#store" do
    before { clear_redis }

    it "stores the task history and last enqueue at time", :aggregate_failures do
      current_time = Time.now
      expect(Time).to receive(:now).and_return(current_time)
      storage = described_class.new("foo:bar")
      storage.store_enqueue("a1b2c3", {"bar" => "baz"})

      expect(storage.last_enqueue_at).to eq(Time.at(current_time.to_i))
      expect(storage.history.size).to eq(1)
      expect(storage.history.first).to eq(
        {
          "jid" => "a1b2c3",
          "name" => "foo:bar",
          "args" => {"bar" => "baz"},
          "enqueued_at" => Time.at(current_time.to_i),
        }
      )
    end
  end

  describe "#store_execution" do
    before { clear_redis }

    it "stores the task history and last execution at time", :aggregate_failures do
      current_time = Time.now
      expect(Time).to receive(:now).twice.and_return(current_time)
      storage = described_class.new("foo:bar")
      storage.store_enqueue("a1b2c3", {"bar" => "baz"})

      storage.store_execution("a1b2c3")

      expect(storage.last_execution_at.to_s).to eq(current_time.to_s)
      expect(storage.history.size).to eq(1)
      expect(storage.history.first).to eq(
        {
          "jid" => "a1b2c3",
          "name" => "foo:bar",
          "args" => {"bar" => "baz"},
          "enqueued_at" => Time.at(current_time.to_i),
          "executed_at" => Time.at(current_time.to_i),
        }
      )
    end

    it "does nothing when the task is not found", :aggregate_failures do
      current_time = Time.now
      expect(Time).to receive(:now).twice.and_return(current_time)
      storage = described_class.new("foo:bar")
      storage.store_enqueue("a1b2c3", {"bar" => "baz"})

      storage.store_execution("b1b2c3")

      expect(storage.last_execution_at.to_s).to eq(current_time.to_s)
      expect(storage.history.size).to eq(1)
      expect(storage.history.first).to eq(
        {
          "jid" => "a1b2c3",
          "name" => "foo:bar",
          "args" => {"bar" => "baz"},
          "enqueued_at" => Time.at(current_time.to_i),
        }
      )
    end
  end
end
