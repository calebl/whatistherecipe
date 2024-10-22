class LlmResponse < ApplicationRecord
  belongs_to :scrape
  validates :content, presence: true
  validates :model, presence: true
end
