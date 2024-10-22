require "selenium-webdriver"
require "redcarpet"

class WebScraperService
  def initialize(url)
    @url = url
  end

  def scrape(skip_existing: false)
    raise ArgumentError, "URL is required" if @url.nil? || @url.empty?

    Rails.logger.info("Scraping #{@url}")

    uri = URI.parse(@url)
    existing_scrape = skip_existing ? nil : Scrape.find_by(hostname: uri.hostname, request_uri: uri.request_uri)

    if existing_scrape
      Rails.logger.info("found existing scrape: #{existing_scrape.id}")
      return existing_scrape
    end

    driver = Selenium::WebDriver.for :chrome, options: driver_options

    begin
      # Set emulated media type to 'print'
      driver.execute_cdp("Emulation.setEmulatedMedia", media: "print")

      Rails.logger.info("navigating to #{@url}")
      driver.get(@url)

      # Wait for the page to load
      # Wait for the page to load dynamically
      wait = Selenium::WebDriver::Wait.new(timeout: 10)
      wait.until { driver.execute_script("return document.readyState") == "complete" }

      text = driver.find_element(tag_name: "body").text

      Rails.logger.debug("scraped text: #{text}")

      Scrape.new(url: @url, text: text, hostname: uri.hostname,
        request_uri: uri.request_uri, uri_hash: uri.hash)

    rescue => e
      Rails.logger.error "An error occurred: #{e.message}"
      raise e
    ensure
      driver.quit
    end
  end

  private

  def driver_options
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("--headless")
    options.add_argument("--disable-gpu")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--window-size=1920,1080")
    options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")

    options
  end
end
