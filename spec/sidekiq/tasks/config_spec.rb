require "spec_helper"

RSpec.describe Sidekiq::Tasks::Config do
  describe "#initialize" do
    it "sets the default sidekiq options" do
      expect(described_class.new.sidekiq_options).to eq({queue: "default", retry: false})
    end

    it "sets the default strategies" do
      expect(described_class.new.strategies).to match_array(
        [an_instance_of(Sidekiq::Tasks::Strategies::RakeTask)]
      )
    end
  end
end
