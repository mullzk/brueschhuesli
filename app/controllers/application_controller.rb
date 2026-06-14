# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authentication
  include Authorization

  layout "reservation"

  protect_from_forgery # See ActionController::RequestForgeryProtection for details
end
