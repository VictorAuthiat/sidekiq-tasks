require "spec_helper"

RSpec.describe Sidekiq::Tasks::Web::Helpers::TaskHelper do
  describe "#parameterize_task_name" do
    it "replaces colons with dashes" do
      expect(described_class.parameterize_task_name("foo")).to eq("foo")
      expect(described_class.parameterize_task_name("foo:bar")).to eq("foo-bar")
      expect(described_class.parameterize_task_name("foo:bar:baz")).to eq("foo-bar-baz")
    end
  end

  describe "#unparameterize_task_name" do
    it "replaces dashes with colons" do
      expect(described_class.unparameterize_task_name("foo")).to eq("foo")
      expect(described_class.unparameterize_task_name("foo-bar")).to eq("foo:bar")
      expect(described_class.unparameterize_task_name("foo-bar-baz")).to eq("foo:bar:baz")
    end
  end

  describe "#find_task!" do
    it "finds the task by name" do
      task = build_task(name: "foo:bar")
      allow(Sidekiq::Tasks).to receive(:tasks).and_return(build_task_set(task))
      expect(described_class.find_task!("foo:bar")).to eq(task)
    end

    it "raises an error when the task is not found" do
      allow(Sidekiq::Tasks).to receive(:tasks).and_return(build_task_set)
      expect { described_class.find_task!("foo:bar") }.to raise_error(Sidekiq::Tasks::NotFoundError)
    end
  end

  describe "#task_url" do
    it "returns the URL for the given task and root path replacing the colon with a dash" do
      expect(described_class.task_url("/sidekiq/", build_task(name: "foo:bar"))).to eq("/sidekiq/tasks/foo-bar")
    end
  end

  describe "#task_last_enqueue_at" do
    it "returns the last enqueue at time for the given task", :aggregate_failures do
      task = build_task(name: "foo:bar")
      last_enqueue_at = Time.new(2025, 1, 1, 12, 0, 0, "+00:00")
      expect(task).to receive(:last_enqueue_at).and_return(last_enqueue_at)
      expect(described_class.task_last_enqueue_at(task)).to eq(last_enqueue_at)
    end

    it "returns a dash when the last enqueue at time is nil", :aggregate_failures do
      task = build_task(name: "foo:bar")
      expect(task).to receive(:last_enqueue_at).and_return(nil)
      expect(described_class.task_last_enqueue_at(task)).to eq("-")
    end
  end
end
