require "spec_helper"

RSpec.describe Sidekiq::Tasks::Strategies::Rules::EnableWithComment do
  describe "#respected?" do
    it "is not respected when the task has no magic comment", :aggregate_failures do
      task = instance_double(Rake::Task, name: "foo:bar", locations: ["foo.rb:2"])

      expect(File).to receive(:read).with("foo.rb").and_return <<~RUBY
        namespace :foo do
          task :bar do
            puts "bar"
          end
        end
      RUBY

      expect(described_class.new.respected?(task)).to be(false)
    end

    it "is respected when the task has a magic comment before the task", :aggregate_failures do
      task = instance_double(Rake::Task, name: "foo:bar", locations: ["foo.rb:3"])

      expect(File).to receive(:read).with("foo.rb").and_return <<~RUBY
        namespace :foo do
          # sidekiq-tasks:enable
          task :bar do
            puts "bar"
          end
        end
      RUBY

      expect(described_class.new.respected?(task)).to be(true)
    end

    it "is respected when the task has a magic comment before the desc", :aggregate_failures do
      task = instance_double(Rake::Task, name: "foo:bar", locations: ["foo.rb:3"])

      expect(File).to receive(:read).with("foo.rb").and_return <<~RUBY
        namespace :foo do
          # sidekiq-tasks:enable
          desc "Bar"
          task :bar do
            puts "bar"
          end
        end
      RUBY

      expect(described_class.new.respected?(task)).to be(true)
    end

    it "is respected when the task has a magic comment after the desc", :aggregate_failures do
      task = instance_double(Rake::Task, name: "foo:bar", locations: ["foo.rb:4"])

      expect(File).to receive(:read).with("foo.rb").and_return <<~RUBY
        namespace :foo do
          desc "Bar"
          # sidekiq-tasks:enable
          task :bar do
            puts "bar"
          end
        end
      RUBY

      expect(described_class.new.respected?(task)).to be(true)
    end

    it "is not respected when the task has a magic comment after the task", :aggregate_failures do
      task = instance_double(Rake::Task, name: "foo:bar", locations: ["foo.rb:2"])

      expect(File).to receive(:read).with("foo.rb").and_return <<~RUBY
        namespace :foo do
          task :bar do
            puts "bar"
          end
          # sidekiq-tasks:enable
        end
      RUBY

      expect(described_class.new.respected?(task)).to be(false)
    end

    it "is respected when the task has a magic comment before the namespace", :aggregate_failures do
      bar_task = instance_double(Rake::Task, name: "foo:bar", locations: ["foo.rb:3"])
      baz_task = instance_double(Rake::Task, name: "foo:baz", locations: ["foo.rb:8"])

      expect(File).to receive(:read).exactly(2).times.with("foo.rb").and_return <<~RUBY
        # sidekiq-tasks:enable
        namespace :foo do
          task :bar do
            puts "bar"
          end

          task :baz do
            puts "baz"
          end
        end
      RUBY

      expect(described_class.new.respected?(bar_task)).to be(true)
      expect(described_class.new.respected?(baz_task)).to be(true)
    end

    it "works with multiple tasks", :aggregate_failures do
      not_enabled_task_before_enabled_task = instance_double(Rake::Task, name: "foo:bar", locations: ["foo.rb:3"])
      enabled_task = instance_double(Rake::Task, name: "foo:baz", locations: ["foo.rb:8"])
      not_enabled_task_after_enabled_task = instance_double(Rake::Task, name: "foo:buz", locations: ["foo.rb:12"])

      expect(File).to receive(:read).with("foo.rb").exactly(3).times.and_return <<~RUBY
        namespace :foo do
          desc "Send an order confirmation email"
          task :bar do
            puts "bar"
          end

          # sidekiq-tasks:enable
          task :baz do
            puts "baz"
          end

          task :buz do
            puts "buz"
          end
        end
      RUBY

      expect(described_class.new.respected?(not_enabled_task_before_enabled_task)).to be(false)
      expect(described_class.new.respected?(enabled_task)).to be(true)
      expect(described_class.new.respected?(not_enabled_task_after_enabled_task)).to be(false)
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
