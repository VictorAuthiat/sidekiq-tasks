require "spec_helper"

RSpec.describe Sidekiq::Tasks::Web::Helpers::TagHelper do
  describe ".build_tag" do
    it "builds a tag with attributes and content" do
      expect(described_class.build_tag(:div, "Hello", class: "foo")).to eq("<div class=\"foo\">Hello</div>")
    end

    it "builds a tag with block content" do
      expect(described_class.build_tag(:span, class: "foo") { "Hello" }).to eq("<span class=\"foo\">Hello</span>")
    end

    it "works with nested tags" do
      tag = described_class.build_tag(:div) { described_class.build_tag(:span, "Hello") }
      expect(tag).to eq("<div><span>Hello</span></div>")
    end
  end

  describe ".build_classes" do
    it "joins classes into a single string" do
      expect(described_class.build_classes("class1", "class2")).to eq("class1 class2")
    end

    it "includes conditionally added classes" do
      expect(described_class.build_classes("class1", class2: true, class3: false)).to eq("class1 class2")
    end

    it "handles nil values" do
      expect(described_class.build_classes("class1", class2: nil)).to eq("class1")
    end
  end
end
