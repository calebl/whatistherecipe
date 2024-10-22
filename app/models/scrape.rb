class Scrape < ApplicationRecord
  validates :hostname, presence: true
  validates :request_uri, presence: true
  validates :hostname, uniqueness: { scope: :request_uri, message: "should be unique for each request URI" }

  has_many :llm_responses
end
