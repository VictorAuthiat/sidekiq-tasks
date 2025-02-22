Capybara.register_driver(:selenium_chrome) do |app|
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: Selenium::WebDriver::Chrome::Options.new(
      args: [
        "--disable-search-engine-choice-screen",
      ]
    )
  )
end

Capybara.register_driver(:selenium_chrome_headless) do |app|
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: Selenium::WebDriver::Chrome::Options.new(
      args: [
        "--headless=new",
        "--no-sandbox",
        "--disable-gpu",
        "--disable-search-engine-choice-screen",
      ]
    )
  )
end

rack_app_builder = Rack::Builder.new do
  use Rack::Session::Cookie, secret: "fake_secret_key" * 10, same_site: true, max_age: 86_400
  run Sidekiq::Web
end

Capybara.app = rack_app_builder.to_app
Capybara.server = ENV.fetch("CAPYBARA_SERVER", "webrick").to_sym
Capybara.default_driver = ENV.fetch("CAPYBARA_DRIVER", "selenium_chrome").to_sym
