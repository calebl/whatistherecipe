require "uri"
require "net/http"

class SearchController < ApplicationController
  include TextSummarizer

  before_action :rate_limit, only: [ :index ]

  def index
    @query = params[:query]&.squish
    if @query.present?
      if valid_url?(@query)
        @result = fetch_and_summarize(@query)
        break_cache_on_error
      else
        @error = "Invalid URL provided"
      end
    end

    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, no_links: true)
    @result = markdown.render(@result) if @result

    @text = markdown.render(@text) if @text
  end

  private

  def fetch_and_summarize(url)
    scrape = WebScraperService.new(url).scrape_to_markdown(save_to_db: true)
    @text = scrape.text
    summary = summarize_text(@text)

    # Save the LLM response
    if scrape.persisted?
      LlmResponse.create(
        content: summary,
        scrape: scrape,
        model: ENV.fetch("GROQ_MODEL_ID")
      )
    end

    summary
  rescue => e
    Rails.logger.error("Error fetching and summarizing text: #{e.message}")
    @error = "There was a problem scraping the provided url. Could not retrieve text."
    ""
  end

  def cache_key
    "summarized_text_#{@query}"
  end

  def break_cache_on_error
    Rails.cache.delete(cache_key) if @error
  end

  def rate_limit
    last_request_time = Rails.cache.read("last_request_#{request.remote_ip}")
    if last_request_time && last_request_time > 1.second.ago
      render json: { error: "Rate limit exceeded. Please wait before making another request." }, status: :too_many_requests
    else
      Rails.cache.write("last_request_#{request.remote_ip}", Time.current)
    end
  end

  def valid_url?(url)
    Rails.logger.info("Verifying URL")
    uri = URI.parse(url)
    uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    false
  end
end
