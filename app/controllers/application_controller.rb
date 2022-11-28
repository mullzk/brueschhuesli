# frozen_string_literal: true

class ApplicationController < ActionController::Base
  layout 'reservation'

  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  private

  def authorize
    return if User.find_by_id(session[:user_id])

    flash[:notice] = 'Please log in'
    redirect_to controller: 'login', action: 'login'
  end
end
