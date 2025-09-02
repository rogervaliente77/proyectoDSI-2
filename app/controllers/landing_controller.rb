class LandingController < ApplicationController
  def index
    @products = Product.includes(:category).all
  end
end
