class CreateAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :addresses do |t|
      t.belongs_to :country
      t.belongs_to :city
      t.belongs_to :street

      t.timestamps
    end
  end
end
