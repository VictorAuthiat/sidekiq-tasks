require "spec_helper"

RSpec.describe Sidekiq::Tasks::Job do
  describe "#perform" do
    subject(:perform) { described_class.new.perform("foo:bar", "{\"baz\":\"qux\"}") }

    it "finds the task and executes it", :aggregate_failures do
      task = build_task(name: "foo:bar", args: ["baz"])
      expect(Sidekiq::Tasks).to receive(:tasks).and_return(Sidekiq::Tasks::Set.new([task]))
      expect(task).to receive(:execute).with({"baz" => "qux"})
      perform
    end

    it "raises an error if the task is not found", :aggregate_failures do
      expect(Sidekiq::Tasks).to receive(:tasks).and_return(Sidekiq::Tasks::Set.new([]))
      expect { perform }.to raise_error(Sidekiq::Tasks::NotFoundError, "'foo:bar' not found")
    end
  end
end
