module FactoryHelper
  def build_strategy(rules: [])
    FakeStrategy.new(rules: rules)
  end

  def build_task(name: "foo", file: nil, desc: nil, args: [], strategy: nil, metadata: nil)
    Sidekiq::Tasks::Task.new(
      metadata: metadata || build_task_metadata(name: name, file: file, desc: desc, args: args),
      strategy: strategy || Sidekiq::Tasks::Strategies::RakeTask.new
    )
  end

  def build_task_metadata(name: "foo", file: nil, desc: nil, args: [])
    Sidekiq::Tasks::TaskMetadata.new(name: name, file: file, desc: desc, args: args)
  end

  def build_strategy_rule(&block)
    Class.new(Sidekiq::Tasks::Strategies::Rules::Base, &block).new
  end

  def build_rake_task(name: "foo:bar", full_comment: "Bar", locations: ["foo.rb:2"], arg_names: ["bar"])
    instance_double(Rake::Task, name: name, full_comment: full_comment, locations: locations, arg_names: arg_names)
  end
end
