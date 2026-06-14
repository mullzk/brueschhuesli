# frozen_string_literal: true

module Authorization
  extend ActiveSupport::Concern

  private

  def deny_access
    flash[:notice] = "Dazu hast du keine Berechtigung."
    redirect_to root_path
  end

  def require_owner
    deny_access unless current_user.owner?
  end
end
