require "spec_helper"

RSpec.describe Sidekiq::Tasks::Web::Helpers::PaginationHelper do
  describe ".pagination_link" do
    it "generates a standard pagination link" do
      search = double("search", filter: "foo", count: 10)
      link = {page: 2, text: "2"}

      expect(described_class.pagination_link("/sidekiq/", link, search)).to eq(
        "<li class=\"st-page-item\"><a class=\"st-page-link\" href=\"/sidekiq/tasks?filter=foo&count=10&page=2\">2</a></li>"
      )
    end

    it "generates a disabled pagination link" do
      search = double("search", filter: "bar", count: 5)
      link = {page: nil, text: "«", disabled: true}

      expect(described_class.pagination_link("/sidekiq/", link, search)).to eq(
        "<li class=\"st-page-item\"><a class=\"st-page-link disabled\" href=\"/sidekiq/tasks?filter=bar&count=5&page=\">«</a></li>"
      )
    end

    it "generates an active pagination link" do
      search = double("search", filter: "baz", count: 7)
      link = {page: 1, text: "1", active: true}

      expect(described_class.pagination_link("/sidekiq/", link, search)).to eq(
        "<li class=\"st-page-item\"><a class=\"st-page-link active\" href=\"/sidekiq/tasks?filter=baz&count=7&page=1\">1</a></li>"
      )
    end

    it "generates a pagination link with explicit false flags" do
      search = double("search", filter: "qux", count: 3)
      link = {page: 3, text: "3", active: false, disabled: false}

      expect(described_class.pagination_link("/sidekiq/", link, search)).to eq(
        "<li class=\"st-page-item\"><a class=\"st-page-link\" href=\"/sidekiq/tasks?filter=qux&count=3&page=3\">3</a></li>"
      )
    end

    it "encodes the filter parameter in the URL" do
      search = double("search", filter: "hello world", count: 12)
      link = {page: 4, text: "4"}

      expect(described_class.pagination_link("/sidekiq/", link, search)).to eq(
        "<li class=\"st-page-item\"><a class=\"st-page-link\" href=\"/sidekiq/tasks?filter=hello%20world&count=12&page=4\">4</a></li>"
      )
    end
  end
end
