class AddressesController < ApplicationController
  def new
    @address = Address.new
    @countries = Country.all.map { |c| [c.name, c.id] }
    @cities = []
    @streets = []
  end

  def country_change
    @address = Address.new
    @cities = City.where(country_id: params[:country_id]).map { |c| [c.name, c.id] }

    respond_to do |format|
      format.turbo_stream
    end
  end

  def city_change
    @address = Address.new
    @streets = Street.where(city_id: params[:city_id]).map { |s| [s.name, s.id] }

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def address_params
    params.require(:address).permit(:country_id, :city_id, :street_id)
  end
end
