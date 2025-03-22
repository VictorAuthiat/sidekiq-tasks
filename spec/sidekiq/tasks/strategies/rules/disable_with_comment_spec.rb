require "spec_helper"

RSpec.describe Sidekiq::Tasks::Strategies::Rules::DisableWithComment do
  describe "#respected?" do
    it "is respected when the task has no magic comment", :aggregate_failures do
      task = instance_double(Rake::Task, name: "foo:bar", locations: ["foo.rb:2"])

      expect(File).to receive(:read).with("foo.rb").and_return <<~RUBY
        namespace :foo do
          task :bar do
            puts "bar"
          end
        end
      RUBY

      expect(described_class.new.respected?(task)).to eq(true)
    end

    it "is not respected when the task has a magic comment before the task", :aggregate_failures do
      task = instance_double(Rake::Task, name: "foo:bar", locations: ["foo.rb:3"])

      expect(File).to receive(:read).with("foo.rb").and_return <<~RUBY
        namespace :foo do
          # sidekiq-tasks:disable
          task :bar do
            puts "bar"
          end
        end
      RUBY

      expect(described_class.new.respected?(task)).to eq(false)
    end

    it "is not respected when the task has a magic comment before the desc", :aggregate_failures do
      task = instance_double(Rake::Task, name: "foo:bar", locations: ["foo.rb:3"])

      expect(File).to receive(:read).with("foo.rb").and_return <<~RUBY
        namespace :foo do
          # sidekiq-tasks:disable
          desc "Bar"
          task :bar do
            puts "bar"
          end
        end
      RUBY

      expect(described_class.new.respected?(task)).to eq(false)
    end

    it "is not respected when the task has a magic comment after the desc", :aggregate_failures do
      task = instance_double(Rake::Task, name: "foo:bar", locations: ["foo.rb:4"])

      expect(File).to receive(:read).with("foo.rb").and_return <<~RUBY
        namespace :foo do
          desc "Bar"
          # sidekiq-tasks:disable
          task :bar do
            puts "bar"
          end
        end
      RUBY

      expect(described_class.new.respected?(task)).to eq(false)
    end

    it "is respected when the task has a magic comment after the task", :aggregate_failures do
      task = instance_double(Rake::Task, name: "foo:bar", locations: ["foo.rb:2"])

      expect(File).to receive(:read).with("foo.rb").and_return <<~RUBY
        namespace :foo do
          task :bar do
            puts "bar"
          end
          # sidekiq-tasks:disable
        end
      RUBY

      expect(described_class.new.respected?(task)).to eq(true)
    end

    it "is respected when the task has a magic comment before the namespace", :aggregate_failures do
      task = instance_double(Rake::Task, name: "foo:bar", locations: ["foo.rb:3"])

      expect(File).to receive(:read).with("foo.rb").and_return <<~RUBY
        # sidekiq-tasks:disable
        namespace :foo do
          task :bar do
            puts "bar"
          end
        end
      RUBY

      expect(described_class.new.respected?(task)).to eq(true)
    end

    it "works with multiple tasks", :aggregate_failures do
      enabled_task_before_disabled_task = instance_double(Rake::Task, name: "foo:bar", locations: ["foo.rb:3"])
      disabled_task = instance_double(Rake::Task, name: "foo:baz", locations: ["foo.rb:8"])
      enabled_task_after_disabled_task = instance_double(Rake::Task, name: "foo:buz", locations: ["foo.rb:12"])

      expect(File).to receive(:read).with("foo.rb").exactly(3).times.and_return <<~RUBY
        namespace :foo do
          desc "Send an order confirmation email"
          task :bar do
            puts "bar"
          end

          # sidekiq-tasks:disable
          task :baz do
            puts "baz"
          end

          task :buz do
            puts "buz"
          end
        end
      RUBY

      expect(described_class.new.respected?(enabled_task_before_disabled_task)).to eq(true)
      expect(described_class.new.respected?(disabled_task)).to eq(false)
      expect(described_class.new.respected?(enabled_task_after_disabled_task)).to eq(true)
    end

    it "raises an error when the file is not found" do
      task = instance_double(Rake::Task, name: "foo:bar", locations: ["foo.rb:2"])
      expect { described_class.new.respected?(task) }.to raise_error(
        Sidekiq::Tasks::ArgumentError,
        "File 'foo.rb' not found"
      )
    end
  end
end
