class ApplicationController < ActionController::Base
  before_filter :authenticate_user!, :unless => :devise_controller?

  protect_from_forgery
end
