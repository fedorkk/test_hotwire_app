# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

countries = {
  Germany: {
    Berlin: ["Unter den Linden", "Friedrichstraße", "Kurfürstendamm"],
    Munich: ["Marienplatz", "Neuhauser Straße", "Leopoldstraße"],
    Hamburg: ["Reeperbahn", "Jungfernstieg", "Mönckebergstraße"]
  },
  France: {
    Paris: ["Champs-Élysées", "Rue de Rivoli", "Boulevard Saint-Germain"],
    Lyon: ["Rue de la République", "Rue Victor Hugo", "Rue Mercière"],
    Marseille: ["La Canebière", "Rue Saint-Ferréol", "Rue d'Aubagne"]
  },
  Netherlands: {
    Amsterdam: ["Damrak", "Kalverstraat", "Leidsestraat"],
    Rotterdam: ["Coolsingel", "Lijnbaan", "Oude Binnenweg"],
    Utrecht: ["Oudegracht", "Neude", "Vredenburg"]
  }
}

countries.each do |country, cities|
  country = Country.find_or_create_by(name: country)
  cities.each do |city, streets|
    city = City.find_or_create_by(name: city, country: country)
    streets.each { |street| city.streets.find_or_create_by(name: street) }
  end
end
