class CreateScrapes < ActiveRecord::Migration[8.0]
  def change
    create_table :scrapes do |t|
      t.text :text
      t.string :url
      t.string :hostname
      t.string :request_uri
      t.string :uri_hash

      t.timestamps
    end

    add_index :scrapes, [ :hostname, :request_uri ], unique: true
  end
end
