# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authentication
  include Authorization

  layout "reservation"

  before_action { Current.request_host = request.host_with_port }

  protect_from_forgery # See ActionController::RequestForgeryProtection for details
end
