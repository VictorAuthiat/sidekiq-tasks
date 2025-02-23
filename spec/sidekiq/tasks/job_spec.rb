require "spec_helper"

RSpec.describe Sidekiq::Tasks::Job do
  describe "#perform" do
    subject(:perform) { job.perform("foo:bar", "{\"baz\":\"qux\"}") }

    let(:job) { described_class.new }

    it "finds the task and executes it with params and jid", :aggregate_failures do
      task = build_task(name: "foo:bar", args: ["baz"])
      expect(Sidekiq::Tasks).to receive(:tasks).and_return(Sidekiq::Tasks::Set.new([task]))
      expect(job).to receive(:jid).and_return("a1b2c3")
      expect(task).to receive(:execute).with({"baz" => "qux"}, jid: "a1b2c3")
      perform
    end

    it "raises an error if the task is not found", :aggregate_failures do
      expect(Sidekiq::Tasks).to receive(:tasks).and_return(Sidekiq::Tasks::Set.new([]))
      expect { perform }.to raise_error(Sidekiq::Tasks::NotFoundError, "'foo:bar' not found")
    end

    it "returns the correct Sidekiq options" do
      expect(described_class.sidekiq_options).to eq(Sidekiq::Tasks.config.sidekiq_options.transform_keys(&:to_s))
    end
  end
end
