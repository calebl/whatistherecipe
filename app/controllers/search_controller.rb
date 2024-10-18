require "uri"
require "net/http"

class SearchController < ApplicationController
  include Groq::Helpers

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
    response = Net::HTTP.get_response(URI(jina_url))

    if response.is_a?(Net::HTTPSuccess)
      response.body
    else
      ""
    end
  rescue StandardError => e
    Rails.logger.error("Error fetching text from Jina: #{e.message}")
    @error = "There was a problem scraping the provided url. Could not retrieve text."
    ""
  end

  def summarize_text(text)
    prompt = "Retrieve the recipe from the provided text:\n\n#{text}"

    client = Groq::Client.new
    response = client.chat([
        S("You are a helpful assistant that can recognize and summarize recipes."),
        U(prompt)
      ]
    )

    Rails.logger.debug("LLM Response: #{response}")

    response.choices[0].message.content
  rescue StandardError => e
    Rails.logger.error("Error summarizing text with Groq: #{e.message}")
    @error = "Error: Unable to summarize the text. Providing raw text instead."
    text
  end
end
