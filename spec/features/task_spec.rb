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

  it(
    "does not display the live poll button",
    skip: !Sidekiq::Tasks::Web::SIDEKIQ_GTE_7_0_1 && "requires Sidekiq >= 7.0.1"
  ) do
    visit "/tasks/tests-task_with_args"
    expect(page).not_to have_css(".live-poll-start", visible: :all)
  end

  it "display error when task not found" do
    visit "/tasks/unknown"
    expect(page).to have_content("Task not found")
  end

  it "display error when task name is a partial match" do
    visit "/tasks/tests"
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
    allow(Sidekiq::Tasks.tasks.find_by!(name: "tests:task_with_args")).to receive(:history).and_return(
      [
        {
          "jid" => "a1b2c3",
          "task_name" => "foo:bar",
          "args" => {"foo" => "bar"},
          "enqueued_at" => Time.now,
          "executed_at" => Time.now,
        },
      ]
    )

    visit "/tasks/tests-task_with_args"

    aggregate_failures do
      expect(page).not_to have_content("No history")
      expect(page).to have_content("a1b2c3")
      expect(page).to have_content(/\{"foo"\s*=>\s*"bar"\}/)
      expect(page).to have_content("Running")
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
    expect(page).to have_button("Enqueue", disabled: false)
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
    expect(page).to have_button("Enqueue", disabled: false)
    click_button("Enqueue")
    expect(page).to have_current_path("/tasks/tests-task_without_args")

    aggregate_failures do
      expect(page).not_to have_content("No history")
      expect(page).to have_content({}.to_s)
    end
  end

  it "paginates history when exceeding per page limit" do
    history_entries = 12.times.map do |index|
      {
        "jid" => "jid_#{index}",
        "name" => "foo:bar",
        "args" => {},
        "enqueued_at" => Time.now,
        "executed_at" => Time.now,
        "finished_at" => Time.now,
      }
    end

    allow(Sidekiq::Tasks.tasks.find_by!(name: "tests:task_with_args")).to receive(:history).and_return(history_entries)

    visit "/tasks/tests-task_with_args"

    aggregate_failures do
      expect(page).to have_content("jid_0")
      expect(page).to have_content("jid_9")
      expect(page).not_to have_content("jid_10")
      expect(page).to have_content("10 / 12")
      expect(page).to have_content("»")
    end

    click_on "»"

    aggregate_failures do
      expect(page).to have_content("jid_10")
      expect(page).to have_content("jid_11")
      expect(page).not_to have_content("jid_0")
      expect(page).to have_content("2 / 12")
      expect(page).to have_content("«")
    end
  end

  it "does not show history pagination when there is only one page" do
    history_entries = 3.times.map do |index|
      {
        "jid" => "jid_#{index}",
        "name" => "foo:bar",
        "args" => {},
        "enqueued_at" => Time.now,
      }
    end

    allow(Sidekiq::Tasks.tasks.find_by!(name: "tests:task_with_args")).to receive(:history).and_return(history_entries)

    visit "/tasks/tests-task_with_args"

    aggregate_failures do
      expect(page).to have_content("jid_0")
      expect(page).not_to have_css(".st-pagination")
    end
  end

  it "displays the 'Enqueued by' column with user info when current_user is configured", :aggregate_failures do
    allow(Sidekiq::Tasks.config).to receive(:current_user).and_return(
      ->(_env) { {"id" => 1, "email" => "admin@example.com"} }
    )

    allow(Sidekiq::Tasks.tasks.find_by!(name: "tests:task_with_args")).to receive(:history).and_return(
      [
        {
          "jid" => "a1b2c3",
          "task_name" => "foo:bar",
          "args" => {"foo" => "bar"},
          "enqueued_at" => Time.now,
          "user" => {"id" => 1, "email" => "admin@example.com"},
        },
      ]
    )

    visit "/tasks/tests-task_with_args"

    expect(page).to have_content("Enqueued by")
    expect(page).to have_content("admin@example.com")
  end

  it "displays '-' for old entries without user when current_user is configured", :aggregate_failures do
    allow(Sidekiq::Tasks.config).to receive(:current_user).and_return(
      ->(_env) { {"id" => 1, "email" => "admin@example.com"} }
    )

    allow(Sidekiq::Tasks.tasks.find_by!(name: "tests:task_with_args")).to receive(:history).and_return(
      [
        {
          "jid" => "a1b2c3",
          "task_name" => "foo:bar",
          "args" => {},
          "enqueued_at" => Time.now,
        },
      ]
    )

    visit "/tasks/tests-task_with_args"

    expect(page).to have_content("Enqueued by")
    expect(page).to have_css("code", text: "-")
  end

  it "stores and displays user after enqueuing when current_user is configured", :aggregate_failures do
    clear_redis

    allow(Sidekiq::Tasks.config).to receive(:current_user).and_return(
      ->(_env) { {"id" => 1, "email" => "admin@example.com"} }
    )

    visit "/tasks/tests-task_with_args"
    fill_in "env_confirmation", with: "development"
    fill_in "name", with: "Foo"
    expect(page).to have_button("Enqueue", disabled: false)
    click_button("Enqueue")

    expect(page).to have_content("Enqueued by")
    expect(page).to have_content("admin@example.com")
  end

  it "does not display the 'Enqueued by' column when current_user is not configured" do
    allow(Sidekiq::Tasks.tasks.find_by!(name: "tests:task_with_args")).to receive(:history).and_return(
      [
        {
          "jid" => "a1b2c3",
          "task_name" => "foo:bar",
          "args" => {"foo" => "bar"},
          "enqueued_at" => Time.now,
        },
      ]
    )

    visit "/tasks/tests-task_with_args"

    expect(page).not_to have_content("Enqueued by")
  end

  it "displays error message in a tooltip when the task failed" do
    allow(Sidekiq::Tasks.tasks.find_by!(name: "tests:task_with_args")).to receive(:history).and_return(
      [
        {
          "jid" => "a1b2c3",
          "task_name" => "foo:bar",
          "args" => {"foo" => "bar"},
          "enqueued_at" => Time.now,
          "executed_at" => Time.now,
          "error" => "StandardError: Task failed",
        },
      ]
    )

    visit "/tasks/tests-task_with_args"

    expect(page).to have_css(
      ".st-status-badge.failure[data-tooltip=\"StandardError: Task failed\"]",
      text: "Failure"
    )
  end
end
