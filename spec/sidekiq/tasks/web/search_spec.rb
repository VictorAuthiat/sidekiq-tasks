require "spec_helper"

RSpec.describe Sidekiq::Tasks::Web::Search do
  describe ".count_options" do
    it "returns the count options based on the default count" do
      stub_const("Sidekiq::Tasks::Web::Search::DEFAULT_COUNT", 25)

      expect(described_class.count_options).to eq([25, 50, 100, 200])
    end
  end

  describe "#tasks" do
    it "returns sorted tasks with correct pagination", :aggregate_failures do
      collection = [
        build_task(name: "foo"),
        build_task(name: "foobar"),
        build_task(name: "foobarbaz"),
        build_task(name: "foobarbazqux"),
      ]
      allow(Sidekiq::Tasks).to receive_message_chain(:tasks, :where).and_return(collection)

      expect(described_class.new({count: 2, page: 1, filter: "foo"}).tasks).to eq(collection.slice(0, 2))
      expect(described_class.new({count: 2, page: 2, filter: "foo"}).tasks).to eq(collection.slice(2, 2))
      expect(described_class.new({count: 2, page: 3, filter: "foo"}).tasks).to eq([])
    end

    it "sorts tasks by name", :aggregate_failures do
      collection = [build_task(name: "foo"), build_task(name: "baz"), build_task(name: "bar")]
      allow(Sidekiq::Tasks).to receive_message_chain(:tasks, :where).and_return(collection)

      expect(described_class.new({}).tasks.map(&:name)).to eq(["bar", "baz", "foo"])
      expect(described_class.new({sort: "name", direction: "desc"}).tasks.map(&:name)).to eq(["foo", "baz", "bar"])
    end

    it "sorts tasks by last_enqueued with nil values last", :aggregate_failures do
      now = Time.now
      task_old = build_task(name: "old")
      task_recent = build_task(name: "recent")
      task_never = build_task(name: "never")

      allow(task_old).to receive(:last_enqueue_at).and_return(now - 3600)
      allow(task_recent).to receive(:last_enqueue_at).and_return(now)
      allow(task_never).to receive(:last_enqueue_at).and_return(nil)
      allow(Sidekiq::Tasks).to receive_message_chain(:tasks, :where).and_return([task_recent, task_old, task_never])

      asc_search = described_class.new({sort: "last_enqueued", direction: "asc"})
      desc_search = described_class.new({sort: "last_enqueued", direction: "desc"})

      expect(asc_search.tasks.map(&:name)).to eq(["old", "recent", "never"])
      expect(desc_search.tasks.map(&:name)).to eq(["recent", "old", "never"])
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

  describe "#sort" do
    it "returns the provided sort when valid", :aggregate_failures do
      expect(described_class.new({sort: "name"}).sort).to eq("name")
      expect(described_class.new({sort: "last_enqueued"}).sort).to eq("last_enqueued")
    end

    it "returns the default sort when not provided or invalid", :aggregate_failures do
      expect(described_class.new({}).sort).to eq("name")
      expect(described_class.new({sort: "invalid"}).sort).to eq("name")
      expect(described_class.new({sort: ""}).sort).to eq("name")
    end
  end

  describe "#direction" do
    it "returns the provided direction when valid", :aggregate_failures do
      expect(described_class.new({direction: "asc"}).direction).to eq("asc")
      expect(described_class.new({direction: "desc"}).direction).to eq("desc")
    end

    it "returns the default direction when not provided or invalid", :aggregate_failures do
      expect(described_class.new({}).direction).to eq("asc")
      expect(described_class.new({direction: "invalid"}).direction).to eq("asc")
      expect(described_class.new({direction: ""}).direction).to eq("asc")
    end
  end

  describe "#toggle_direction" do
    it "cycles through asc, desc, then nil for the current sort column", :aggregate_failures do
      expect(described_class.new({sort: "name", direction: "asc"}).toggle_direction("name")).to eq("desc")
      expect(described_class.new({sort: "name", direction: "desc"}).toggle_direction("name")).to be_nil
    end

    it "returns 'asc' when the column is not the current sort" do
      expect(described_class.new({sort: "name", direction: "desc"}).toggle_direction("last_enqueued")).to eq("asc")
    end
  end

  describe "#sorted_by?" do
    it "returns whether the column is the current sort", :aggregate_failures do
      expect(described_class.new({sort: "name"}).sorted_by?("name")).to be true
      expect(described_class.new({sort: "name"}).sorted_by?("last_enqueued")).to be false
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
