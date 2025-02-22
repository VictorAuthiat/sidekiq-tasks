require "spec_helper"

RSpec.describe Sidekiq::Tasks::Web::Params do
  describe "#permit!" do
    it "returns an empty hash with nil params" do
      task = build_task(args: %w[foo bar])
      permitted_params = described_class.new(task, nil).permit!
      expect(permitted_params).to eq({})
    end

    it "returns the permitted params with valid hash params" do
      task = build_task(args: %w[foo bar])
      params = {"foo" => "baz", "bar" => "qux"}
      permitted_params = described_class.new(task, params).permit!
      expect(permitted_params).to eq(params)
    end

    it "raises an error with invalid hash params" do
      task = build_task(args: %w[foo bar])
      params = {"foo" => "baz", "bar" => "qux", "an_invalid_param" => "qux"}
      expect { described_class.new(task, params).permit! }.to raise_error(Sidekiq::Tasks::ArgumentError)
    end

    it "raises an error without hash or nil params" do
      task = build_task(args: %w[foo bar])
      params = "invalid_params"
      expect { described_class.new(task, params).permit! }.to raise_error(Sidekiq::Tasks::ArgumentError)
    end
  end
end
