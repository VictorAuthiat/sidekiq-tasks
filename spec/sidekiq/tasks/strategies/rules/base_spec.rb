require "spec_helper"

RSpec.describe Sidekiq::Tasks::Strategies::Rules::Base do
  describe "#respected?" do
    subject(:respected?) { described_class.new.respected?(build_task(name: "foo:bar")) }

    it "raises an error when the rule is not implemented" do
      expect { respected? }.to raise_error(
        Sidekiq::Tasks::NotImplementedError,
        "Rule must implement #respected?"
      )
    end
  end
end
