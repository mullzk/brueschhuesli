# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Every authenticated user has full access. Role-based authorization was a
  # deliberate non-goal: the user base is a small, trusted family. Add roles
  # here (e.g. restricting user management to Miteigentuemer) if that changes.
  include Authentication

  layout "reservation"

  protect_from_forgery # See ActionController::RequestForgeryProtection for details
end
