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

    markdown = markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, no_links: true)
    @result = markdown.render(@result) if @result

    @text = markdown.render(@text) if @text
  end

  private

  def fetch_and_summarize(url)
    # Rails.cache.fetch(cache_key, expires_in: 1.day) do
    @text = retrieve_text_from_jina(url)
    @text  if @error

    summarize_text(@text)
    # end
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

  def retrieve_text_from_jina(url, streaming: true)
    Rails.logger.info("retrieving text from url")

    request = setup_webscraper_request(url, streaming)

    uri = request.uri

    existing_scrape = Scrape.find_by(hostname: uri.hostname, request_uri: uri.request_uri)
    if existing_scrape
      Rails.logger.info("found existing scrape: #{existing_scrape.id}")
      return existing_scrape.text
    end

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end

    # accumulated_text = ""
    # for streaming responses received a chunk at a time
    # response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
    #   http.request(request) do |response|
    #     response.read_body do |chunk|
    #       Rails.logger.debug("chunk: #{chunk}")
    #       if chunk.start_with?("data: ")
    #         event_data = chunk[6..-1] # remove "data: " prefix
    #       else
    #         event_data = chunk
    #       end
    #       accumulated_text += event_data
    #     end
    #   end
    # end

    if response.is_a?(Net::HTTPSuccess)
      Rails.logger.debug("retrieved text: #{response.body}")
      parsed_text = parse_jina_response(response)
      scrape = Scrape.create(url: url, text: parsed_text, hostname: uri.hostname, request_uri: uri.request_uri, uri_hash: uri.hash)
      if !scrape.persisted?
        Rails.logger.warn("could not save the scrape, but will continue anyway...")
      end

      parsed_text
    else
      Rails.logger.debug("failed to retrieve text with response: #{response}")
      ""
    end
  rescue JSON::ParserError => e
    Rails.logger.error("Error parsing Jina response into JSON: #{e.message}")
    @error = "There was a problem scraping the provided url. We retrieved the text but had an issue parsing it into a useable format."
    ""
  rescue StandardError => e
    Rails.logger.error("Error fetching text from Jina: #{e.message}")
    @error = "There was a problem scraping the provided url. Could not retrieve text."
    ""
  end

  def setup_webscraper_request(url, streaming)
    jina_url = "https://r.jina.ai/#{url}"
    uri = URI(jina_url)
    request = Net::HTTP::Get.new(uri)

    # set headers
    if ENV.fetch("JINA_API_KEY").present?
      request["Authorization"] = "Bearer #{ENV.fetch("JINA_API_KEY", "")}"
    end
    request["X-No-Cache"] = "true"
    request["X-With-Images-Summary"] = "false"
    request["X-With-Links-Summary"] = "false"
    request["X-Return-Format"] = "text"

    if streaming
      request["Accept"] = "text/event-stream"
    end

    request
  end

  def parse_jina_response(response)
    accumulated_text = response.body
    accumulated_text = accumulated_text.split("event: data\ndata: ").compact.last
    utf8_text = accumulated_text.force_encoding(Encoding::UTF_8)
    JSON.parse(utf8_text).fetch("text", accumulated_text)
  end
end
