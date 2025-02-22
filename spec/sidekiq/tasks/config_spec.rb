require "spec_helper"

RSpec.describe Sidekiq::Tasks::Config do
  describe "#initialize" do
    it "sets the default sidekiq options" do
      expect(described_class.new.sidekiq_options).to eq({queue: "default", retry: false})
    end

    it "sets the default strategies" do
      expect(described_class.new.strategies).to match_array(
        [
          an_instance_of(Sidekiq::Tasks::Strategies::RakeTask).and(
            have_attributes(
              rules: [
                an_instance_of(Sidekiq::Tasks::Strategies::Rules::TaskFromLib),
                an_instance_of(Sidekiq::Tasks::Strategies::Rules::EnableWithComment),
              ]
            )
          ),
        ]
      )
    end
  end

  describe "#sidekiq_options=" do
    let(:config) { described_class.new }

    it "sets the sidekiq options" do
      sidekiq_options = {
        queue: "foo",
        retry: true,
        dead: true,
        backtrace: true,
        pool: "default",
        tags: ["foo"],
      }

      config.sidekiq_options = sidekiq_options
      expect(config.sidekiq_options).to eq(sidekiq_options)
    end

    it "raises an error when the sidekiq options are not a Hash" do
      expect { config.sidekiq_options = "foo" }.to(
        raise_error(
          Sidekiq::Tasks::ArgumentError,
          "'sidekiq_options' must be an instance of Hash but received String"
        )
      )
    end

    it "raises an error when the queue key is invalid", :aggregate_failures do
      expect { config.sidekiq_options = {queue: nil, retry: true} }.to(
        raise_error(
          Sidekiq::Tasks::ArgumentError,
          "'queue' must be an instance of String but received NilClass"
        )
      )

      expect { config.sidekiq_options = {queue: :foo, retry: true} }.to(
        raise_error(
          Sidekiq::Tasks::ArgumentError,
          "'queue' must be an instance of String but received Symbol"
        )
      )
    end

    it "raises an error when the retry key is invalid", :aggregate_failures do
      expect { config.sidekiq_options = {queue: "foo", retry: nil} }.to(
        raise_error(
          Sidekiq::Tasks::ArgumentError,
          "'retry' must be an instance of TrueClass or FalseClass but received NilClass"
        )
      )

      expect { config.sidekiq_options = {queue: "foo", retry: 1} }.to(
        raise_error(
          Sidekiq::Tasks::ArgumentError,
          "'retry' must be an instance of TrueClass or FalseClass but received Integer"
        )
      )
    end

    it "raises an error when the dead key is invalid" do
      expect { config.sidekiq_options = {queue: "foo", retry: false, dead: "foo"} }.to(
        raise_error(
          Sidekiq::Tasks::ArgumentError,
          "'dead' must be an instance of NilClass or TrueClass or FalseClass but received String"
        )
      )
    end

    it "does not raise an error when the dead key is nil", :aggregate_failures do
      expect { config.sidekiq_options = {queue: "foo", retry: false, dead: nil} }.not_to raise_error
      expect { config.sidekiq_options = {queue: "foo", retry: false, dead: false} }.not_to raise_error
      expect { config.sidekiq_options = {queue: "foo", retry: false, dead: true} }.not_to raise_error
    end

    it "raises an error when the backtrace key is invalid" do
      expect { config.sidekiq_options = {queue: "foo", retry: false, backtrace: "foo"} }.to(
        raise_error(
          Sidekiq::Tasks::ArgumentError,
          "'backtrace' must be an instance of NilClass or TrueClass or FalseClass or Integer but received String"
        )
      )
    end

    it "does not raise an error when the backtrace key is nil", :aggregate_failures do
      expect { config.sidekiq_options = {queue: "foo", retry: false, backtrace: nil} }.not_to raise_error
      expect { config.sidekiq_options = {queue: "foo", retry: false, backtrace: false} }.not_to raise_error
      expect { config.sidekiq_options = {queue: "foo", retry: false, backtrace: true} }.not_to raise_error
      expect { config.sidekiq_options = {queue: "foo", retry: false, backtrace: 0} }.not_to raise_error
    end

    it "raises an error when the pool key is invalid" do
      expect { config.sidekiq_options = {queue: "foo", retry: false, pool: 1} }.to(
        raise_error(
          Sidekiq::Tasks::ArgumentError,
          "'pool' must be an instance of NilClass or String but received Integer"
        )
      )
    end

    it "does not raise an error when the pool key is nil", :aggregate_failures do
      expect { config.sidekiq_options = {queue: "foo", retry: false, pool: nil} }.not_to raise_error
      expect { config.sidekiq_options = {queue: "foo", retry: false, pool: "default"} }.not_to raise_error
    end

    it "raises an error when the tags key is invalid" do
      expect { config.sidekiq_options = {queue: "foo", retry: false, tags: 1} }.to(
        raise_error(
          Sidekiq::Tasks::ArgumentError,
          "'tags' must be an instance of NilClass or Array but received Integer"
        )
      )
    end

    it "does not raise an error when the tags key is nil", :aggregate_failures do
      expect { config.sidekiq_options = {queue: "foo", retry: false, tags: nil} }.not_to raise_error
      expect { config.sidekiq_options = {queue: "foo", retry: false, tags: []} }.not_to raise_error
      expect { config.sidekiq_options = {queue: "foo", retry: false, tags: ["foo"]} }.not_to raise_error
    end
  end

  describe "#strategies=" do
    let(:config) { described_class.new }

    it "sets the strategies" do
      strategies = [Sidekiq::Tasks::Strategies::RakeTask.new]
      config.strategies = strategies
      expect(config.strategies).to eq(strategies)
    end

    it "raises an error when the strategies are not an array" do
      expect { config.strategies = "foo" }.to(
        raise_error(
          Sidekiq::Tasks::ArgumentError,
          "'strategies' must be an instance of Array but received String"
        )
      )
    end

    it "raises an error when the strategies are not instances of Sidekiq::Tasks::Strategies::Base" do
      expect { config.strategies = ["foo"] }.to(
        raise_error(
          Sidekiq::Tasks::ArgumentError,
          "'foo' must be an instance of Sidekiq::Tasks::Strategies::Base but received String"
        )
      )
    end
  end
end
