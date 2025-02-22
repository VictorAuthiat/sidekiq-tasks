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
end
