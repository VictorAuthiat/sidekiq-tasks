require "spec_helper"

RSpec.describe Sidekiq::Tasks::Web::Helpers::ApplicationHelper do
  describe "#read_view" do
    it "returns the contents of the given view file" do
      expect(described_class.read_view(:tasks)).to be_a(String)
    end

    it "raises an error when the view file is not found" do
      expect { described_class.read_view(:foo) }.to raise_error(Errno::ENOENT)
    end
  end

  describe "#current_env" do
    it "returns the RAILS_ENV environment variable when present" do
      stub_env("RAILS_ENV", "development")
      expect(described_class.current_env).to eq("development")
    end

    it "returns the RACK_ENV environment variable when present and RAILS_ENV is not" do
      stub_env("RAILS_ENV", nil)
      stub_env("RACK_ENV", "development")
      expect(described_class.current_env).to eq("development")
    end

    it "returns nil when neither RAILS_ENV nor RACK_ENV are present" do
      stub_env("RAILS_ENV", nil)
      stub_env("RACK_ENV", nil)
      expect(described_class.current_env).to be_nil
    end
  end
end
