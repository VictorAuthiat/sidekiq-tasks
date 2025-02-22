require "spec_helper"

RSpec.describe Sidekiq::Tasks::TaskMetadata do
  describe "readers" do
    it "has name, desc, file and args", :aggregate_failures do
      metadata = build_task_metadata(name: "foo", file: "foo.rb", desc: "foo", args: ["bar"])
      expect(metadata.name).to eq("foo")
      expect(metadata.desc).to eq("foo")
      expect(metadata.file).to eq("foo.rb")
      expect(metadata.args).to eq(["bar"])
    end
  end
end
