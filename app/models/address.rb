class Address < ApplicationRecord
  belongs_to :country
  belongs_to :city
  belongs_to :street
end
