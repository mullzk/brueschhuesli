class ApplicationController < ActionController::Base
  include Authentication

  layout "reservation"

  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
end
