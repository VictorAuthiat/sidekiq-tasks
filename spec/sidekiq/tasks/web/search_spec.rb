require "spec_helper"

RSpec.describe Sidekiq::Tasks::Web::Search do
  describe ".count_options" do
    it "returns the count options based on the default count" do
      stub_const("Sidekiq::Tasks::Web::Search::DEFAULT_COUNT", 25)

      expect(described_class.count_options).to eq([25, 50, 100, 200])
    end
  end

  describe "#tasks" do
    before do
      allow(Sidekiq::Tasks).to receive_message_chain(:tasks, :where).and_return(filtered_collection)
    end

    let(:filtered_collection) do
      [
        build_task(name: "foo"),
        build_task(name: "foobar"),
        build_task(name: "foobarbaz"),
        build_task(name: "foobarbazqux"),
      ]
    end

    it "returns sorted tasks with correct pagination", :aggregate_failures do
      expect(described_class.new({count: 2, page: 1, filter: "foo"}).tasks).to eq(filtered_collection.slice(0, 2))
      expect(described_class.new({count: 2, page: 2, filter: "foo"}).tasks).to eq(filtered_collection.slice(2, 2))
      expect(described_class.new({count: 2, page: 3, filter: "foo"}).tasks).to eq([])
    end
  end

  describe "#filtered_collection" do
    subject(:filtered_collection) { search.filtered_collection }

    let(:search) { described_class.new({filter: "my_task"}) }

    it "filters tasks based on the name" do
      collection = [build_task(name: "my_task")]
      expect(Sidekiq::Tasks).to receive_message_chain(:tasks, :where).with(name: "my_task").and_return(collection)
      expect(filtered_collection).to eq(collection)
    end
  end

  describe "#filter" do
    it "returns the filter value from params when present" do
      expect(described_class.new({filter: "test"}).filter).to eq("test")
    end

    it "returns nil when filter is absent" do
      expect(described_class.new({}).filter).to be_nil
    end

    it "returns nil when filter is an empty string" do
      expect(described_class.new({filter: ""}).filter).to be_nil
    end
  end

  describe "#count" do
    before do
      stub_const("Sidekiq::Tasks::Web::Search::DEFAULT_COUNT", default_count)
    end

    let(:default_count) { 10 }

    it "returns the provided count when positive", :aggregate_failures do
      expect(described_class.new({count: "5"}).count).to eq(5)
      expect(described_class.new({count: 5}).count).to eq(5)
    end

    it "returns default count when count is not provided or non-positive", :aggregate_failures do
      expect(described_class.new({count: "0"}).count).to eq(default_count)
      expect(described_class.new({count: -1}).count).to eq(default_count)
      expect(described_class.new({}).count).to eq(default_count)
    end
  end

  describe "#page" do
    it "returns the provided page when positive", :aggregate_failures do
      expect(described_class.new({page: "3"}).page).to eq(3)
      expect(described_class.new({page: 3}).page).to eq(3)
    end

    it "returns 1 when page is not provided or non-positive", :aggregate_failures do
      expect(described_class.new({page: "0"}).page).to eq(1)
      expect(described_class.new({page: -1}).page).to eq(1)
      expect(described_class.new({}).page).to eq(1)
    end
  end

  describe "#total_pages" do
    it "calculates the total number of pages correctly", :aggregate_failures do
      stub_const("Sidekiq::Tasks::Web::Search::DEFAULT_COUNT", 25)
      allow(Sidekiq::Tasks).to receive_message_chain(:tasks, :where).and_return(double(size: 45))
      expect(described_class.new({count: 15}).total_pages).to eq(3)
      expect(described_class.new({count: 10}).total_pages).to eq(5)
      expect(described_class.new({count: 0}).total_pages).to eq(2)
    end
  end

  describe "#offset" do
    it "calculates the correct offset for pagination", :aggregate_failures do
      expect(described_class.new({count: "25", page: "5"}).offset).to eq(100)
      expect(described_class.new({count: "10", page: "2"}).offset).to eq(10)
      expect(described_class.new({count: "10", page: "1"}).offset).to eq(0)
    end
  end
end
