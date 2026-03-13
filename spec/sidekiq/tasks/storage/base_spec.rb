require "spec_helper"

RSpec.describe Sidekiq::Tasks::Storage::Base do
  let(:storage) { described_class.new("foo:bar") }

  describe "#initialize" do
    it "sets the task name" do
      expect(storage.task_name).to eq("foo:bar")
    end

    it "sets the history limit" do
      storage = described_class.new("foo:bar", history_limit: 25)
      expect(storage.history_limit).to eq(25)
    end

    it "defaults history limit to nil" do
      expect(storage.history_limit).to be_nil
    end
  end

  describe "#last_enqueue_at" do
    it "raises NotImplementedError" do
      expect { storage.last_enqueue_at }.to raise_error(
        Sidekiq::Tasks::NotImplementedError,
        "Storage must implement #last_enqueue_at"
      )
    end
  end

  describe "#history" do
    it "raises NotImplementedError" do
      expect { storage.history }.to raise_error(
        Sidekiq::Tasks::NotImplementedError,
        "Storage must implement #history"
      )
    end
  end

  describe "#store_enqueue" do
    it "raises NotImplementedError" do
      expect { storage.store_enqueue("jid", {}) }.to raise_error(
        Sidekiq::Tasks::NotImplementedError,
        "Storage must implement #store_enqueue"
      )
    end
  end

  describe "#store_execution" do
    it "raises NotImplementedError" do
      expect { storage.store_execution("jid", "executed_at") }.to raise_error(
        Sidekiq::Tasks::NotImplementedError,
        "Storage must implement #store_execution"
      )
    end
  end

  describe "#store_execution_error" do
    it "raises NotImplementedError" do
      expect { storage.store_execution_error("jid", StandardError.new) }.to raise_error(
        Sidekiq::Tasks::NotImplementedError,
        "Storage must implement #store_execution_error"
      )
    end
  end
end
