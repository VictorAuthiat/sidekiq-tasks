require "spec_helper"

RSpec.describe "Task page", type: :feature do
  before do
    stub_env("RAILS_ENV", "development")
    allow(Sidekiq::Tasks).to receive(:tasks).and_return(tasks)
    allow(Sidekiq::Tasks::Job).to receive(:perform_async).and_return("a1b2c3")
  end

  let(:tasks) do
    build_task_set(
      build_task(name: "tests:task_with_args", desc: "Task with arg", args: ["name"]),
      build_task(name: "tests:task_without_args", desc: "Task without arg")
    )
  end

  it "display error when task not found" do
    visit "/tasks/unknown"
    expect(page).to have_content("Task not found")
  end

  it "displays the task details" do
    visit "/tasks/tests-task_with_args"

    aggregate_failures do
      expect(page).to have_content("tests:task_with_args")
      expect(page).to have_content("Task with arg")
      expect(page).to have_content("RakeTask")
    end
  end

  it "displays an empty state when history is not found" do
    clear_redis
    visit "/tasks/tests-task_with_args"
    expect(page).to have_content("No history")
  end

  it "displays history when exist" do
    allow(Sidekiq::Tasks.tasks.find_by!(name: "task_with_args")).to receive(:history).and_return(
      [
        {
          "jid" => "a1b2c3",
          "name" => "foo:bar",
          "args" => {"foo" => "bar"},
          "enqueued_at" => Time.now,
        },
      ]
    )

    visit "/tasks/task_with_args"

    aggregate_failures do
      expect(page).not_to have_content("No history")
      expect(page).to have_content("a1b2c3")
      expect(page).to have_content("foo")
      expect(page).to have_content("bar")
      expect(page).to have_content("Enqueued")
    end
  end

  it "requires confirmation to enabled submission" do
    visit "/tasks/tests-task_with_args"

    expect(page).to have_css("input[type='text'][name='env_confirmation']")
    expect(page).to have_button("Enqueue", disabled: true)

    fill_in "env_confirmation", with: "foo"
    expect(page).to have_button("Enqueue", disabled: true)

    fill_in "env_confirmation", with: "development"
    expect(page).to have_button("Enqueue", disabled: false)

    fill_in "env_confirmation", with: "developmen"
    expect(page).to have_button("Enqueue", disabled: true)
  end

  it "can be enqueued with arguments" do
    clear_redis
    strategy = Sidekiq::Tasks.tasks.find_by!(name: "tests:task_with_args").strategy
    expect(strategy).to receive(:enqueue_task).with("tests:task_with_args", {"name" => "Foo"}).and_call_original

    visit "/tasks/tests-task_with_args"
    fill_in "env_confirmation", with: "development"
    fill_in "name", with: "Foo"
    click_button("Enqueue")
    expect(page).to have_current_path("/tasks/tests-task_with_args")

    aggregate_failures do
      expect(page).not_to have_content("No history")
      expect(page).to have_content({"name" => "Foo"}.to_s)
      expect(find_field("name").value).to be_empty
    end
  end

  it "can be enqueued without arguments" do
    clear_redis
    strategy = Sidekiq::Tasks.tasks.find_by!(name: "tests:task_without_args").strategy
    expect(strategy).to receive(:enqueue_task).with("tests:task_without_args", {}).and_call_original

    visit "/tasks/tests-task_without_args"
    fill_in "env_confirmation", with: "development"
    click_button("Enqueue")
    expect(page).to have_current_path("/tasks/tests-task_without_args")

    aggregate_failures do
      expect(page).not_to have_content("No history")
      expect(page).to have_content({}.to_s)
    end
  end
end
