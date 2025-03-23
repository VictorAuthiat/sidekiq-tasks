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

  describe "#fetch_param" do
    it "returns the value of the given key from the params hash" do
      stub_const("Sidekiq::Tasks::Web::SIDEKIQ_GTE_8_0_0", false)
      expect(described_class).to receive(:params).and_return("foo" => "bar")
      expect(described_class.fetch_param("foo")).to eq("bar")
    end

    it "returns the value of the given key from the url_params hash when Sidekiq >= 8.0.0" do
      stub_const("Sidekiq::Tasks::Web::SIDEKIQ_GTE_8_0_0", true)
      expect(described_class).to receive(:url_params).with("foo").and_return("bar")
      expect(described_class.fetch_param("foo")).to eq("bar")
    end
  end

  describe "#fetch_params" do
    it "returns a hash of key-value pairs from the params hash" do
      expect(described_class).to receive(:fetch_param).with(:foo).and_return("bar")
      expect(described_class).to receive(:fetch_param).with(:baz).and_return("qux")
      expect(described_class.fetch_params(:foo, :baz)).to eq(foo: "bar", baz: "qux")
    end
  end
end
