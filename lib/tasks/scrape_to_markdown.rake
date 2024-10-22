namespace :scrape do
  desc "Visit a URL, capture all text, and convert to markdown"
  task :to_markdown, [ :url ] => :environment do |t, args|
    url = args[:url]
    scraper = WebScraperService.new(url)
    scrape_result = scraper.scrape_to_markdown(save_to_db: false)

    markdown = scrape_result.text

    output_file = "tmp/scrape_output_#{Time.now.to_i}.md"
    File.write(output_file, markdown)

    if output_file
      puts "Scrape completed. Output saved to #{output_file}"
    else
      puts "Scrape failed. Check the logs for more information."
    end
  end
end
