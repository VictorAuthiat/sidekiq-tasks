require "spec_helper"

class InMemoryStorage < Sidekiq::Tasks::Storage::Base
  attr_reader :history

  def initialize(task_name, history_limit: nil)
    super
    @store = {}
    @history = []
  end

  def last_enqueue_at
    @store[:last_enqueue_at]
  end

  def store_enqueue(jid, args, user: nil)
    entry = {"jid" => jid, "name" => task_name, "args" => args, "enqueued_at" => Time.now}
    entry["user"] = user if user
    @history.prepend(entry)
    @history = @history.first(history_limit) if history_limit
    @store[:last_enqueue_at] = entry["enqueued_at"]
  end

  def store_execution(jid, time_key)
    entry = @history.find { |e| e["jid"] == jid }
    entry[time_key] = Time.now if entry
  end

  def store_execution_error(jid, error)
    entry = @history.find { |e| e["jid"] == jid }
    return unless entry

    entry["error"] = truncate_message("#{error.class}: #{error.message}", ERROR_MESSAGE_MAX_LENGTH)
  end
end

RSpec.describe "Custom storage implementation" do
  let(:storage) { InMemoryStorage.new("my_task", history_limit: 3) }

  it "can be set as config storage" do
    original = Sidekiq::Tasks.config.storage
    expect { Sidekiq::Tasks.config.storage = InMemoryStorage }.not_to raise_error
  ensure
    Sidekiq::Tasks.config.storage = original
  end

  describe "#store_enqueue" do
    it "stores an entry in history" do
      storage.store_enqueue("jid1", {name: "foo"})

      expect(storage.history.size).to eq(1)
      expect(storage.history.first["jid"]).to eq("jid1")
      expect(storage.history.first["args"]).to eq({name: "foo"})
    end

    it "stores the user when provided" do
      storage.store_enqueue("jid1", {}, user: {id: 1, email: "user@example.com"})

      expect(storage.history.first["user"]).to eq({id: 1, email: "user@example.com"})
    end

    it "does not include user key when not provided" do
      storage.store_enqueue("jid1", {})

      expect(storage.history.first).not_to have_key("user")
    end

    it "updates last_enqueue_at" do
      storage.store_enqueue("jid1", {})

      expect(storage.last_enqueue_at).to be_a(Time)
    end

    it "respects history_limit" do
      4.times { |i| storage.store_enqueue("jid#{i}", {}) }

      expect(storage.history.size).to eq(3)
    end
  end

  describe "#store_execution" do
    before { storage.store_enqueue("jid1", {}) }

    it "sets executed_at on the matching entry" do
      storage.store_execution("jid1", "executed_at")

      expect(storage.history.first["executed_at"]).to be_a(Time)
    end

    it "sets finished_at on the matching entry" do
      storage.store_execution("jid1", "finished_at")

      expect(storage.history.first["finished_at"]).to be_a(Time)
    end
  end

  describe "#store_execution_error" do
    before { storage.store_enqueue("jid1", {}) }

    it "stores the error message" do
      storage.store_execution_error("jid1", RuntimeError.new("something went wrong"))

      expect(storage.history.first["error"]).to eq("RuntimeError: something went wrong")
    end

    it "truncates long error messages" do
      long_message = "x" * 300
      storage.store_execution_error("jid1", RuntimeError.new(long_message))

      expect(storage.history.first["error"].length).to eq(Sidekiq::Tasks::Storage::Base::ERROR_MESSAGE_MAX_LENGTH)
      expect(storage.history.first["error"]).to end_with("...")
    end
  end
end
