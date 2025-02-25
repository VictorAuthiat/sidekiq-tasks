require "spec_helper"

RSpec.describe "Tasks page", type: :feature do
  before do
    allow(Sidekiq::Tasks).to receive(:tasks).and_return(tasks)
  end

  let(:tasks) do
    build_task_set(
      build_task(name: "posts:create", desc: "Create post", args: ["title"]),
      build_task(name: "users:create", desc: "Create user", args: ["name"]),
      build_task(name: "users:destroy", desc: "Destroy users")
    )
  end

  it "displays the tasks list", :aggregate_failures do
    visit "/tasks"
    tasks.each { |task| expect(page).to have_content(task.name) }
  end

  it "shows an empty state message when no tasks exist" do
    allow(Sidekiq::Tasks).to receive(:tasks).and_return(build_task_set)
    visit "/tasks"
    expect(page).to have_content("No tasks found")
    tasks.each { |task| expect(page).not_to have_content(task.name) }
  end

  it "is accessible from the header" do
    visit "/"
    click_on "Tasks"

    expect(page).to have_content("3 / 3")
    tasks.each { |task| expect(page).to have_content(task.name) }
  end

  it "has a button to view the task details", :aggregate_failures do
    visit "/tasks"
    click_on "users:create"

    expect(page).not_to have_content("Filter")
    expect(page).to have_content("Run task")
  end

  it "paginates when exceeding the given count", :aggregate_failures do
    visit "/tasks?count=2"

    expect(page).to have_content("posts:create")
    expect(page).to have_content("users:create")
    expect(page).not_to have_content("users:destroy")
    expect(page).to have_content("2 / 3")
    expect(page).not_to have_content("Prev")
    expect(page).to have_content("Next")

    click_on "Next"

    expect(page).to have_content("users:destroy")
    expect(page).to have_content("1 / 3")
    expect(page).to have_content("Prev")
    expect(page).not_to have_content("Next")
  end

  it "does not show pagination when there's only one page" do
    visit "/tasks?count=3"
    expect(page).to have_content("3 / 3")
    expect(page).not_to have_content("Prev")
    expect(page).not_to have_content("Next")
  end

  it "updates the collection count when changed", :aggregate_failures do
    stub_const("Sidekiq::Tasks::Web::Search::DEFAULT_COUNT", 2)

    visit "/tasks"

    expect(page).to have_content("2 / 3")
    expect(page).to have_content("posts:create")
    expect(page).to have_content("users:create")
    expect(page).not_to have_content("users:destroy")

    select "4", from: "count"
    click_on "Filter"

    expect(page).to have_content("3 / 3")
    tasks.each { |task| expect(page).to have_content(task.name) }
  end

  it "filters the tasks list when a filter is provided, and shows all tasks when cleared", :aggregate_failures do
    visit "/tasks"
    fill_in "filter", with: "users"
    click_on "Filter"

    expect(page).to have_content("2 / 3")
    expect(page).to have_content("users:create")
    expect(page).to have_content("users:destroy")
    expect(page).not_to have_content("posts:create")

    fill_in "filter", with: ""
    click_on "Filter"

    expect(page).to have_content("3 / 3")
    tasks.each { |task| expect(page).to have_content(task.name) }
  end
end
