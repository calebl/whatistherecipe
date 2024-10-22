class CreateLlmResponses < ActiveRecord::Migration[8.0]
  def change
    create_table :llm_responses do |t|
      t.text :content
      t.references :scrape, null: false, foreign_key: true
      t.string :model

      t.timestamps
    end
  end
end
