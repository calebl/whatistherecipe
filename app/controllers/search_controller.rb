require "uri"
require "net/http"

class SearchController < ApplicationController
  include TextSummarizer

  before_action :rate_limit, only: [ :index ]

  def index
    @query = params[:query]
    if @query.present?
      if valid_url?(@query.squish)
        @result = fetch_and_summarize(@query)
        break_cache_on_error
      else
        @error = "Invalid URL provided"
      end
    end

    markdown = markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, no_links: true)
    @result = markdown.render(@result)
  end

  private

  def fetch_and_summarize(url)
    Rails.cache.fetch(cache_key, expires_in: 1.day) do
      text = retrieve_text_from_jina(url)
      return text if @error

      summarize_text(text)
    end
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

  def retrieve_text_from_jina(url)
    Rails.logger.info("retrieving text from url")
    jina_url = "https://r.jina.ai/#{url}"
    uri = URI(jina_url)
    request = Net::HTTP::Get.new(uri)
    request["X-No-Cache"] = "true"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      Rails.logger.debug("retrieved text: #{response.body}")
      response.body
    else
      ""
    end
  rescue StandardError => e
    Rails.logger.error("Error fetching text from Jina: #{e.message}")
    @error = "There was a problem scraping the provided url. Could not retrieve text."
    ""
  end
end
