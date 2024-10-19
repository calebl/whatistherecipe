class CreateScrapes < ActiveRecord::Migration[8.0]
  def change
    create_table :scrapes do |t|
      t.text :text
      t.string :url

      t.timestamps
    end
  end
end
