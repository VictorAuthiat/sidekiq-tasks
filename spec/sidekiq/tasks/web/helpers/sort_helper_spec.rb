require "spec_helper"

RSpec.describe Sidekiq::Tasks::Web::Helpers::SortHelper do
  describe ".sort_header_url" do
    it "generates a sort URL with the toggled direction for the current column" do
      search = Sidekiq::Tasks::Web::Search.new({filter: "foo", count: 30, sort: "name", direction: "asc"})

      expect(described_class.sort_header_url(search, "/sidekiq/", "name")).to eq(
        "/sidekiq/tasks?filter=foo&count=30&sort=name&direction=desc"
      )
    end

    it "generates a reset URL when the column is already sorted desc" do
      search = Sidekiq::Tasks::Web::Search.new({filter: "foo", count: 30, sort: "name", direction: "desc"})

      expect(described_class.sort_header_url(search, "/sidekiq/", "name")).to eq(
        "/sidekiq/tasks?filter=foo&count=30"
      )
    end

    it "defaults to asc direction for a different column" do
      search = Sidekiq::Tasks::Web::Search.new({sort: "name", direction: "desc"})

      expect(described_class.sort_header_url(search, "/sidekiq/", "last_enqueued")).to eq(
        "/sidekiq/tasks?filter=&count=15&sort=last_enqueued&direction=asc"
      )
    end

    it "encodes the filter parameter" do
      search = Sidekiq::Tasks::Web::Search.new({filter: "foo bar"})

      expect(described_class.sort_header_url(search, "/", "name")).to include("filter=foo+bar")
    end
  end

  describe ".sort_header_classes" do
    it "returns the base class when the column is not the current sort" do
      search = Sidekiq::Tasks::Web::Search.new({sort: "name"})

      expect(described_class.sort_header_classes(search, "last_enqueued")).to eq("st-sortable")
    end

    it "includes the direction modifier when the column is the current sort", :aggregate_failures do
      asc_search = Sidekiq::Tasks::Web::Search.new({sort: "name", direction: "asc"})
      desc_search = Sidekiq::Tasks::Web::Search.new({sort: "name", direction: "desc"})

      expect(described_class.sort_header_classes(asc_search, "name")).to eq("st-sortable st-sorted-asc")
      expect(described_class.sort_header_classes(desc_search, "name")).to eq("st-sortable st-sorted-desc")
    end
  end
end
