class CreateCities < ActiveRecord::Migration[8.0]
  def change
    create_table :cities do |t|
      t.belongs_to :country
      t.string :name

      t.timestamps
    end
  end
end
