require "spec_helper"

RSpec.describe Sidekiq::Tasks::Validations do
  describe "#validate_class!" do
    it "raises an error when the object is not an instance of the given classes" do
      expect { described_class.validate_class!(:foo, [String, Integer]) }.to raise_error(
        Sidekiq::Tasks::ArgumentError,
        "'foo' must be an instance of String or Integer but received Symbol"
      )
    end

    it "raises an error with the given name when present" do
      expect { described_class.validate_class!(:foo, [String, Integer], "bar") }.to(
        raise_error(
          Sidekiq::Tasks::ArgumentError,
          "'bar' must be an instance of String or Integer but received Symbol"
        )
      )
    end

    it "does not raise an error when the object is an instance of the given classes" do
      expect { described_class.validate_class!(:foo, [String, Symbol]) }.not_to raise_error
    end
  end

  describe "#validate_array_classes!" do
    it "raises an error when the given objects are not an array" do
      expect { described_class.validate_array_classes!("foo", [String]) }.to raise_error(
        Sidekiq::Tasks::ArgumentError,
        "'foo' must be an instance of Array but received String"
      )
    end

    it "raises an error with the given name when present" do
      expect { described_class.validate_array_classes!("foo", [String], "bar") }.to(
        raise_error(
          Sidekiq::Tasks::ArgumentError,
          "'bar' must be an instance of Array but received String"
        )
      )
    end

    it "raises an error when the objects are not all instances of the given classes" do
      expect { described_class.validate_array_classes!([:foo, "bar"], [String]) }.to raise_error(
        Sidekiq::Tasks::ArgumentError,
        "'foo' must be an instance of String but received Symbol"
      )
    end

    it "does not raise an error when the objects are all instances of the given classes" do
      expect { described_class.validate_array_classes!(%w[foo bar], [String]) }.not_to raise_error
    end

    it "does not raise an error when the objects are aļl instances of one of the given classes" do
      expect { described_class.validate_array_classes!([1, "2"], [Integer, String]) }.not_to raise_error
    end
  end

  describe "#validate_hash_option!" do
    it "raises an error when the given object is not a Hash" do
      expect { described_class.validate_hash_option!("foo", :bar, [String]) }.to raise_error(
        Sidekiq::Tasks::ArgumentError,
        "'foo' must be an instance of Hash but received String"
      )
    end

    it "raises an error when the given key is not present in the Hash" do
      expect { described_class.validate_hash_option!({foo: "bar"}, :baz, [String]) }.to raise_error(
        Sidekiq::Tasks::ArgumentError,
        "'baz' must be an instance of String but received NilClass"
      )
    end

    it "raises an error when the given key is present in the Hash but is not an instance of the given classes" do
      expect { described_class.validate_hash_option!({foo: "bar"}, :foo, [Symbol]) }.to raise_error(
        Sidekiq::Tasks::ArgumentError,
        "'foo' must be an instance of Symbol but received String"
      )
    end

    it "does not raise an error when the given key is present in the Hash and is an instance of the given classes" do
      expect { described_class.validate_hash_option!({foo: "bar"}, :foo, [String]) }.not_to raise_error
    end
  end
end
