require "spec_helper"

RSpec.describe Sidekiq::Tasks::MagicComments::Handlers::SidekiqOptions do
  describe ".name_token" do
    it { expect(described_class.name_token).to eq("sidekiq_options") }
  end

  describe ".cast" do
    it "returns an empty Hash when raw_value is nil" do
      expect(described_class.cast(nil)).to eq({})
    end

    it "returns an empty Hash when raw_value is blank" do
      expect(described_class.cast("   ")).to eq({})
    end

    it "parses a single key-value pair" do
      expect(described_class.cast("queue: critical")).to eq(queue: "critical")
    end

    it "parses multiple key-value pairs", :aggregate_failures do
      result = described_class.cast("queue: critical, retry: 5")

      expect(result).to eq(queue: "critical", retry: 5)
    end

    it "parses an array value" do
      expect(described_class.cast("tags: [daily, critical]")).to eq(tags: ["daily", "critical"])
    end

    it "raises when YAML is invalid" do
      expect { described_class.cast("queue: 'unterminated") }.to raise_error(
        Sidekiq::Tasks::ArgumentError,
        /not valid YAML/
      )
    end

    it "raises when value type is invalid for a known key" do
      expect { described_class.cast("queue: 123") }.to raise_error(
        Sidekiq::Tasks::ArgumentError,
        /'queue' must be an instance of String/
      )
    end

    it "accepts a partial hash (no queue required)" do
      expect(described_class.cast("retry: 3")).to eq(retry: 3)
    end
  end
end
