require "spec_helper"

RSpec.describe Sidekiq::Tasks::MagicComments::Scanner do
  describe "#scan" do
    it "returns an empty Comments when no magic comment is present" do
      task = instance_double(Rake::Task, name: "foo:bar", locations: ["foo.rb:2"], full_comment: nil)

      expect(File).to receive(:read).with("foo.rb").and_return <<~RUBY
        namespace :foo do
          task :bar do
            puts "bar"
          end
        end
      RUBY

      result = described_class.new.scan(task)

      expect(result.to_a).to be_empty
    end

    it "captures a magic comment placed before the task", :aggregate_failures do
      task = instance_double(Rake::Task, name: "foo:bar", locations: ["foo.rb:3"], full_comment: nil)

      expect(File).to receive(:read).with("foo.rb").and_return <<~RUBY
        namespace :foo do
          # sidekiq-tasks:enable
          task :bar do
          end
        end
      RUBY

      result = described_class.new.scan(task).to_a

      expect(result.size).to eq(1)
      expect(result.first.name).to eq("enable")
      expect(result.first.location).to eq(:task)
      expect(result.first.raw_value).to be_nil
    end

    it "captures a magic comment placed before the desc", :aggregate_failures do
      task = instance_double(Rake::Task, name: "foo:bar", locations: ["foo.rb:4"], full_comment: "Bar")

      expect(File).to receive(:read).with("foo.rb").and_return <<~RUBY
        namespace :foo do
          # sidekiq-tasks:enable
          desc "Bar"
          task :bar do
          end
        end
      RUBY

      result = described_class.new.scan(task).to_a
      enable = result.find { |c| c.location == :desc }

      expect(enable).not_to be_nil
      expect(enable.name).to eq("enable")
    end

    it "captures a magic comment placed before the namespace", :aggregate_failures do
      task = instance_double(Rake::Task, name: "foo:bar", locations: ["foo.rb:3"], full_comment: nil)

      expect(File).to receive(:read).with("foo.rb").and_return <<~RUBY
        # sidekiq-tasks:enable
        namespace :foo do
          task :bar do
          end
        end
      RUBY

      result = described_class.new.scan(task).to_a

      expect(result.first.location).to eq(:namespace)
      expect(result.first.name).to eq("enable")
    end

    it "captures a magic comment with a value", :aggregate_failures do
      task = instance_double(Rake::Task, name: "foo:bar", locations: ["foo.rb:3"], full_comment: nil)

      expect(File).to receive(:read).with("foo.rb").and_return <<~RUBY
        namespace :foo do
          # sidekiq-tasks:sidekiq_options: queue: critical, retry: 5
          task :bar do
          end
        end
      RUBY

      result = described_class.new.scan(task).to_a

      expect(result.first.name).to eq("sidekiq_options")
      expect(result.first.raw_value).to eq("queue: critical, retry: 5")
    end

    it "captures multiple magic comments around a task", :aggregate_failures do
      task = instance_double(Rake::Task, name: "foo:bar", locations: ["foo.rb:4"], full_comment: nil)

      expect(File).to receive(:read).with("foo.rb").and_return <<~RUBY
        namespace :foo do
          # sidekiq-tasks:enable
          # sidekiq-tasks:sidekiq_options: queue: critical
          task :bar do
          end
        end
      RUBY

      result = described_class.new.scan(task).to_a

      names = result.map(&:name)
      expect(names).to include("enable", "sidekiq_options")
    end

    it "raises an error when the file is not found" do
      task = instance_double(Rake::Task, name: "foo:bar", locations: ["missing.rb:2"], full_comment: nil)

      expect { described_class.new.scan(task) }.to raise_error(
        Sidekiq::Tasks::ArgumentError,
        "File 'missing.rb' not found"
      )
    end

    it "ignores lines that look like comments inside other code" do
      task = instance_double(Rake::Task, name: "foo:bar", locations: ["foo.rb:3"], full_comment: nil)

      expect(File).to receive(:read).with("foo.rb").and_return <<~RUBY
        namespace :foo do
          puts "sidekiq-tasks:enable"
          task :bar do
          end
        end
      RUBY

      expect(described_class.new.scan(task).to_a).to be_empty
    end
  end
end
