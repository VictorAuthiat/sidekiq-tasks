require "spec_helper"

RSpec.describe Sidekiq::Tasks::TaskMetadata do
  describe "validations" do
    it "accepts a symbol or string as name", :aggregate_failures do
      expect(build_task_metadata(name: "foo").name).to eq("foo")
      expect(build_task_metadata(name: :foo).name).to eq(:foo)
      expect { build_task_metadata(name: 1) }.to raise_error(Sidekiq::Tasks::ArgumentError)
    end

    it "accepts a string or nil as desc", :aggregate_failures do
      expect(build_task_metadata(desc: "foo").desc).to eq("foo")
      expect(build_task_metadata(desc: nil).desc).to be_nil
      expect { build_task_metadata(desc: 1) }.to raise_error(Sidekiq::Tasks::ArgumentError)
    end

    it "accepts a string or nil as file", :aggregate_failures do
      expect(build_task_metadata(file: "foo.rb").file).to eq("foo.rb")
      expect(build_task_metadata(file: nil).file).to be_nil
      expect { build_task_metadata(file: 1) }.to raise_error(Sidekiq::Tasks::ArgumentError)
    end

    it "accepts an array of strings or symbols as args", :aggregate_failures do
      expect(build_task_metadata(args: ["foo"]).args).to eq(["foo"])
      expect(build_task_metadata(args: [:foo]).args).to eq([:foo])
      expect { build_task_metadata(args: [1]) }.to raise_error(Sidekiq::Tasks::ArgumentError)
    end

    it "accepts a partial sidekiq_options hash", :aggregate_failures do
      expect(build_task_metadata(sidekiq_options: {}).sidekiq_options).to eq({})
      expect(build_task_metadata(sidekiq_options: {queue: "low"}).sidekiq_options).to eq({queue: "low"})
      expect { build_task_metadata(sidekiq_options: {queue: 1}) }.to raise_error(Sidekiq::Tasks::ArgumentError)
    end
  end

  describe "readers" do
    it "has name, desc, file, args and sidekiq_options", :aggregate_failures do
      metadata = build_task_metadata(
        name: "foo", file: "foo.rb", desc: "foo", args: ["bar"], sidekiq_options: {retry: 5}
      )
      expect(metadata.name).to eq("foo")
      expect(metadata.desc).to eq("foo")
      expect(metadata.file).to eq("foo.rb")
      expect(metadata.args).to eq(["bar"])
      expect(metadata.sidekiq_options).to eq({retry: 5})
    end

    it "defaults sidekiq_options to an empty hash" do
      expect(build_task_metadata.sidekiq_options).to eq({})
    end
  end
end
