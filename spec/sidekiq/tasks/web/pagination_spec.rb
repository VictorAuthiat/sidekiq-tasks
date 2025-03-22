require "spec_helper"

RSpec.describe Sidekiq::Tasks::Web::Pagination do
  describe "#links" do
    it "returns an empty array when there is only one page" do
      expect(described_class.new(1, 1).links).to eq([])
    end

    it "returns the correct links for the first page with few pages" do
      expect(described_class.new(1, 3).links).to eq(
        [
          {page: nil, text: "«", disabled: true},
          {page: 1, text: "1", active: true},
          {page: 2, text: "2", active: false},
          {page: 3, text: "3", active: false},
          {page: 2, text: "»"},
        ]
      )
    end

    it "returns the correct links for the last page with few pages" do
      expect(described_class.new(5, 5).links).to eq(
        [
          {page: 4, text: "«"},
          {page: 1, text: "1", active: false},
          {page: 2, text: "2", active: false},
          {page: 3, text: "3", active: false},
          {page: 4, text: "4", active: false},
          {page: 5, text: "5", active: true},
          {page: nil, text: "»", disabled: true},
        ]
      )
    end

    it "returns the correct links for a middle page with few pages" do
      expect(described_class.new(3, 5).links).to eq(
        [
          {page: 2, text: "«"},
          {page: 1, text: "1", active: false},
          {page: 2, text: "2", active: false},
          {page: 3, text: "3", active: true},
          {page: 4, text: "4", active: false},
          {page: 5, text: "5", active: false},
          {page: 4, text: "»"},
        ]
      )
    end

    it "returns the correct links for the first page with many pages" do
      expect(described_class.new(1, 10).links).to eq(
        [
          {page: nil, text: "«", disabled: true},
          {page: 1, text: "1", active: true},
          {page: 2, text: "2", active: false},
          {page: 3, text: "3", active: false},
          {page: 1, text: "...", disabled: true},
          {page: 10, text: "10", active: false},
          {page: 2, text: "»"},
        ]
      )
    end

    it "returns the correct links for a middle page with many pages" do
      expect(described_class.new(5, 10).links).to eq(
        [
          {page: 4, text: "«"},
          {page: 1, text: "1", active: false},
          {page: 1, text: "...", disabled: true},
          {page: 3, text: "3", active: false},
          {page: 4, text: "4", active: false},
          {page: 5, text: "5", active: true},
          {page: 6, text: "6", active: false},
          {page: 7, text: "7", active: false},
          {page: 1, text: "...", disabled: true},
          {page: 10, text: "10", active: false},
          {page: 6, text: "»"},
        ]
      )
    end

    it "returns the correct links for the last page with many pages" do
      expect(described_class.new(10, 10).links).to eq(
        [
          {page: 9, text: "«"},
          {page: 1, text: "1", active: false},
          {page: 1, text: "...", disabled: true},
          {page: 8, text: "8", active: false},
          {page: 9, text: "9", active: false},
          {page: 10, text: "10", active: true},
          {page: nil, text: "»", disabled: true},
        ]
      )
    end

    it "returns the correct links for a near-end page with many pages" do
      expect(described_class.new(8, 10).links).to eq(
        [
          {page: 7, text: "«"},
          {page: 1, text: "1", active: false},
          {page: 1, text: "...", disabled: true},
          {page: 6, text: "6", active: false},
          {page: 7, text: "7", active: false},
          {page: 8, text: "8", active: true},
          {page: 9, text: "9", active: false},
          {page: 10, text: "10", active: false},
          {page: 9, text: "»"},
        ]
      )
    end
  end
end
