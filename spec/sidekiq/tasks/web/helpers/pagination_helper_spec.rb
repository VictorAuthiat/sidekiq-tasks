require "spec_helper"

RSpec.describe Sidekiq::Tasks::Web::Helpers::PaginationHelper do
  describe ".build_pagination_link" do
    it "generates a pagination link" do
      link = {page: 2, text: "2"}

      expect(described_class.build_pagination_link(link, "/sidekiq/tasks")).to eq(
        "<li class=\"st-page-item\"><a class=\"st-page-link\" href=\"/sidekiq/tasks?page=2\">2</a></li>"
      )
    end

    it "generates a disabled pagination link" do
      link = {page: nil, text: "«", disabled: true}

      expect(described_class.build_pagination_link(link, "/sidekiq/tasks")).to eq(
        "<li class=\"st-page-item\"><a class=\"st-page-link disabled\" href=\"/sidekiq/tasks?page=\">«</a></li>"
      )
    end

    it "generates an active pagination link" do
      link = {page: 1, text: "1", active: true}

      expect(described_class.build_pagination_link(link, "/sidekiq/tasks")).to eq(
        "<li class=\"st-page-item\"><a class=\"st-page-link active\" href=\"/sidekiq/tasks?page=1\">1</a></li>"
      )
    end

    it "generates a pagination link with explicit false flags" do
      link = {page: 3, text: "3", active: false, disabled: false}

      expect(described_class.build_pagination_link(link, "/sidekiq/tasks")).to eq(
        "<li class=\"st-page-item\"><a class=\"st-page-link\" href=\"/sidekiq/tasks?page=3\">3</a></li>"
      )
    end

    it "appends page with & when base_url already has query params" do
      link = {page: 2, text: "2"}
      base_url = "/sidekiq/tasks?filter=foo&count=10"
      expected = %(<li class="st-page-item"><a class="st-page-link" href="#{base_url}&page=2">2</a></li>)

      expect(described_class.build_pagination_link(link, base_url)).to eq(expected)
    end
  end
end
