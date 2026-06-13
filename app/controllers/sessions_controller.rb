class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
  end

  def create
    user = User.authenticate(params[:name], params[:password])
    if user
      start_new_session_for(user)
      if user.has_to_change_password
        flash[:notice] = "Ein neues Passwort muss gesetzt werden"
        redirect_to edit_password_path
      else
        redirect_to root_path
      end
    else
      flash.now[:notice] = "Ungültige Benutzer/Passwort Kombination"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    flash[:notice] = "Logged out"
    redirect_to new_session_path
  end
end
