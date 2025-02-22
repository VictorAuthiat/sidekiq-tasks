require "spec_helper"

RSpec.describe Sidekiq::Tasks::Set do
  describe ".match?" do
    it "returns true when the object matches the attributes", :aggregate_failures do
      task = build_task(name: "foo:bar", desc: "foo", args: ["baz"], file: "foo.rb")

      expect(described_class.match?(task, name: "foo:bar")).to be(true)
      expect(described_class.match?(task, desc: "foo")).to be(true)
      expect(described_class.match?(task, file: "foo.rb")).to be(true)
    end
  end

  describe "#each" do
    it "yields each object" do
      tasks = [build_task(name: "foo:bar"), build_task(name: "bar:baz")]
      set = described_class.new(tasks)
      expect { |block| set.each(&block) }.to yield_successive_args(*tasks)
    end
  end

  describe "#where" do
    let(:set) do
      described_class.new(
        [
          build_task(name: "foo:bar", desc: "foo", args: ["baz"], file: "foo.rb"),
          build_task(name: "bar:baz", desc: "bar", args: ["qux"], file: "bar.rb"),
        ]
      )
    end

    it "returns a new instance of Sidekiq::Tasks::Set", :aggregate_failures do
      search = set.where(name: "toto")
      expect(search).to be_a(Sidekiq::Tasks::Set)
      expect(search.object_id).not_to eq(set.object_id)
    end

    it "returns the filtered objects", :aggregate_failures do
      expect(set.where(name: "toto").to_a).to eq([])
      expect(set.where(name: "foo").map(&:name)).to eq(["foo:bar"])
      expect(set.where(name: "bar").map(&:name)).to eq(["foo:bar", "bar:baz"])
      expect(set.where(desc: "foo").map(&:name)).to eq(["foo:bar"])
      expect(set.where(desc: "bar").map(&:name)).to eq(["bar:baz"])
      expect(set.where(file: "foo.rb").map(&:name)).to eq(["foo:bar"])
      expect(set.where(file: "bar.rb").map(&:name)).to eq(["bar:baz"])
    end
  end

  describe "#find_by" do
    let(:set) do
      described_class.new(
        [
          build_task(name: "foo:bar", desc: "foo", args: ["baz"], file: "foo.rb"),
          build_task(name: "bar:baz", desc: "bar", args: ["qux"], file: "bar.rb"),
        ]
      )
    end

    it "returns the first object matching the given name", :aggregate_failures do
      expect(set.find_by(name: "toto")).to be_nil
      expect(set.find_by(name: "foo").name).to eq("foo:bar")
      expect(set.find_by(name: "bar").name).to eq("foo:bar")
      expect(set.find_by(name: "baz").name).to eq("bar:baz")
    end
  end

  describe "#find_by!" do
    let(:set) do
      described_class.new(
        [
          build_task(name: "foo:bar", desc: "foo", args: ["baz"], file: "foo.rb"),
          build_task(name: "bar:baz", desc: "bar", args: ["qux"], file: "bar.rb"),
        ]
      )
    end

    it "returns the first object matching the given name and raises an error if not found", :aggregate_failures do
      expect { set.find_by!(name: "toto") }.to(
        raise_error(Sidekiq::Tasks::NotFoundError, "'toto' not found")
      )

      expect(set.find_by!(name: "foo").name).to eq("foo:bar")
      expect(set.find_by!(name: "bar").name).to eq("foo:bar")
      expect(set.find_by!(name: "baz").name).to eq("bar:baz")
    end
  end

  describe "#size" do
    it "returns the number of tasks", :aggregate_failures do
      expect(described_class.new([double, double]).size).to eq(2)
      expect(described_class.new([]).size).to eq(0)
    end
  end

  describe "#first" do
    it "returns the first object", :aggregate_failures do
      expect(described_class.new([1, 2]).first).to eq(1)
      expect(described_class.new([]).first).to be_nil
    end
  end

  describe "#last" do
    it "returns the last object", :aggregate_failures do
      expect(described_class.new([1, 2]).last).to eq(2)
      expect(described_class.new([]).last).to be_nil
    end
  end
end
