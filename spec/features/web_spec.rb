require "spec_helper"

RSpec.describe "Sidekiq::Tasks::Web", type: :feature do
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

  describe "Visiting the tasks page" do
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

  describe "When visiting the task details page" do
    it "is accessible when clicking on a task", :aggregate_failures do
      visit "/tasks"
      click_on "users:create"

      expect(page).not_to have_content("Filter")
      expect(page).to have_content("Run task")
    end

    it "displays the task details", :aggregate_failures do
      visit "/tasks/users-create"

      expect(page).to have_content("users:create")
      expect(page).to have_content("Create user")
      expect(page).to have_content("RakeTask")
    end

    describe "When submitting the form" do
      before { clear_redis }

      it "can enqueue with arguments" do
        strategy = Sidekiq::Tasks.tasks.find_by!(name: "users:create").strategy
        expect(strategy).to receive(:enqueue_task).with("users:create", {"name" => "Foo"}).and_return("a1b2c3")

        visit "/tasks/users-create"

        aggregate_failures do
          expect(page).to have_content("No history")
          expect(page).to have_css("input[type='text'][name='args[name]']")
        end

        fill_in "name", with: "Foo"
        find_button("Enqueue").click

        aggregate_failures do
          expect(find_field("name").value).to be_empty
          expect(page).not_to have_content("No history")
          expect(page).to have_content("JID")
          expect(page).to have_content("Arguments")
          expect(page).to have_content({"name" => "Foo"}.to_s)
          expect(page).to have_content("a1b2c3")
        end
      end

      it "can enqueue without arguments" do
        strategy = Sidekiq::Tasks.tasks.find_by!(name: "users:destroy").strategy
        expect(strategy).to receive(:enqueue_task).with("users:destroy", {}).and_return("a1b2c3")

        visit "/tasks/users-destroy"

        aggregate_failures do
          expect(page).to have_content("No history")
          expect(page).not_to have_css("input[type='text']")
        end

        find_button("Enqueue").click

        aggregate_failures do
          expect(page).not_to have_content("No history")
          expect(page).to have_content("JID")
          expect(page).to have_content("Arguments")
          expect(page).to have_content("{}")
          expect(page).to have_content("a1b2c3")
        end
      end
    end
  end
end
