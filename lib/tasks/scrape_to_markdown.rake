require "selenium-webdriver"
require "redcarpet"

namespace :scrape do
  desc "Visit a URL, capture all text, and convert to markdown"
  task :to_markdown, [ :url ] => :environment do |t, args|
    url = args[:url]
    raise ArgumentError, "URL is required" if url.nil? || url.empty?

    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("--headless")
    options.add_argument("--disable-gpu")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--window-size=1920,1080")
    options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")

    driver = Selenium::WebDriver.for :chrome, options: options

    begin
      Rails.logger.info("navigating to #{url}")
      driver.get(url)

      # Wait for the page to load
      sleep 5

      text = driver.find_element(tag_name: "body").text

      Rails.logger.debug(text)

      # Convert to HTML
      renderer = Redcarpet::Render::HTML.new
      html = Redcarpet::Markdown.new(renderer).render(text)

      # Strip HTML tags
      plain_text = html.gsub(/<\/?[^>]*>/, "")

      # Apply basic markdown formatting
      markdown = "# #{url}\n\n#{plain_text}"

      output_file = "scrape_output_#{Time.now.to_i}.md"
      File.write(output_file, markdown)

      puts "Scrape completed. Output saved to #{output_file}"
    rescue => e
      puts "An error occurred: #{e.message}"
    ensure
      driver.quit
    end
  end
end
