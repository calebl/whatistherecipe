require "selenium-webdriver"
require "redcarpet"

class WebScraperService
  def initialize(url)
    @url = url
  end

  def scrape_to_markdown(save_to_db: false)
    raise ArgumentError, "URL is required" if @url.nil? || @url.empty?

    Rails.logger.info("Scraping #{@url}")

    uri = URI.parse(@url)
    existing_scrape = Scrape.find_by(hostname: uri.hostname, request_uri: uri.request_uri)

    if existing_scrape
      Rails.logger.info("found existing scrape: #{existing_scrape.id}")
      return existing_scrape
    end

    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("--headless")
    options.add_argument("--disable-gpu")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--window-size=1920,1080")
    options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")

    driver = Selenium::WebDriver.for :chrome, options: options

    begin
      Rails.logger.info("navigating to #{@url}")
      driver.get(@url)

      # Wait for the page to load
      sleep 5

      text = driver.find_element(tag_name: "body").text

      Rails.logger.debug("scraped text: #{text}")

      # Convert to HTML
      renderer = Redcarpet::Render::HTML.new
      html = Redcarpet::Markdown.new(renderer).render(text)

      # Strip HTML tags
      plain_text = html.gsub(/<\/?[^>]*>/, "")

      # Apply basic markdown formatting
      markdown = "# #{@url}\n\n#{plain_text}"

      scrape = Scrape.new(url: @url, text: markdown, hostname: uri.hostname,
        request_uri: uri.request_uri, uri_hash: uri.hash)
      
      scrape.save! if save_to_db

      scrape
    rescue => e
      Rails.logger.error "An error occurred: #{e.message}"
      raise e
    ensure
      driver.quit
    end
  end
end
