class Api::CitiesController < ApplicationController
  before_action :authenticate_user_from_token!

  def search
    cities = CitySearchService.search(params[:query])
    render json: { cities: cities }
  end
end
