require "spec_helper"

RSpec.describe Sidekiq::Tasks::Strategies::Rules::TaskFromLib do
  describe "#respected?" do
    it "is respected when the task is from lib directory", :aggregate_failures do
      expect(Rake).to receive(:application).twice.and_return(double(original_dir: "/foo"))

      task_from_lib = instance_double(Rake::Task, locations: ["/foo/lib/foo.rb:2"])
      task_not_from_lib = instance_double(Rake::Task, locations: ["/bar/lib/foo.rb:2"])

      expect(described_class.new.respected?(task_from_lib)).to be(true)
      expect(described_class.new.respected?(task_not_from_lib)).to be(false)
    end
  end
end
