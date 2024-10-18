require "uri"
require "net/http"

class SearchController < ApplicationController
  before_action :rate_limit, only: [:index]

  def index
    @query = params[:query]
    if @query.present?
      if valid_url?(@query)
        @result = Rails.cache.fetch("jina_text_#{@query}", expires_in: 1.day) do
          retrieve_text_from_jina(@query)
        end
      else
        @error = "Invalid URL provided"
      end
    end
  end

  private

  def rate_limit
    last_request_time = Rails.cache.read("last_request_#{request.remote_ip}")
    if last_request_time && last_request_time > 1.second.ago
      render json: { error: "Rate limit exceeded. Please wait before making another request." }, status: :too_many_requests
    else
      Rails.cache.write("last_request_#{request.remote_ip}", Time.current)
    end
  end

  def valid_url?(url)
    uri = URI.parse(url)
    uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    false
  end

  def retrieve_text_from_jina(url)
    jina_url = "https://r.jina.ai/#{url}"
    response = Net::HTTP.get_response(URI(jina_url))

    if response.is_a?(Net::HTTPSuccess)
      response.body
    else
      ""
    end
  rescue StandardError => e
    Rails.logger.error("Error fetching text from Jina: #{e.message}")
    ""
  end
end
