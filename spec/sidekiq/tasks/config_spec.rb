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

    it "sets the default authorization proc" do
      expect(described_class.new.authorization).to be_a(Proc)
      expect(described_class.new.authorization.call({})).to eq(true)
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

    it "does not raise an error when the retry key is valid", :aggregate_failures do
      expect { config.sidekiq_options = {queue: "foo", retry: nil} }.not_to raise_error
      expect { config.sidekiq_options = {queue: "foo", retry: true} }.not_to raise_error
      expect { config.sidekiq_options = {queue: "foo", retry: false} }.not_to raise_error
      expect { config.sidekiq_options = {queue: "foo", retry: 5} }.not_to raise_error
    end

    it "raises an error when the retry key is invalid" do
      expect { config.sidekiq_options = {queue: "foo", retry: "foo"} }.to(
        raise_error(
          Sidekiq::Tasks::ArgumentError,
          "'retry' must be an instance of NilClass or TrueClass or FalseClass or Integer but received String"
        )
      )
    end

    it "does not raise an error when the retry_for key is valid", :aggregate_failures do
      expect { config.sidekiq_options = {queue: "foo", retry_for: nil} }.not_to raise_error
      expect { config.sidekiq_options = {queue: "foo", retry_for: 3600} }.not_to raise_error
      expect { config.sidekiq_options = {queue: "foo", retry_for: 172_800.0} }.not_to raise_error
    end

    it "raises an error when the retry_for key is invalid" do
      expect { config.sidekiq_options = {queue: "foo", retry_for: "foo"} }.to(
        raise_error(
          Sidekiq::Tasks::ArgumentError,
          "'retry_for' must be an instance of NilClass or Integer or Float but received String"
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

  describe "#authorization=" do
    let(:config) { described_class.new }

    it "sets the authorization proc" do
      authorization_proc = ->(_env) { true }
      config.authorization = authorization_proc
      expect(config.authorization).to eq(authorization_proc)
    end

    it "raises an error when the authorization is not a Proc" do
      expect { config.authorization = "foo" }.to(
        raise_error(
          Sidekiq::Tasks::ArgumentError,
          "'authorization' must be an instance of Proc but received String"
        )
      )
    end
  end
end
