class FakeStrategy < Sidekiq::Tasks::Strategies::Base
  def load_tasks
    []
  end

  def build_task_metadata(_task)
    Sidekiq::Tasks::TaskMetadata.new(name: "foo", file: "foo.rb")
  end

  def execute_task(_name, _params = {})
    nil
  end

  def enqueue_task(_name, _params = {})
    nil
  end
end
