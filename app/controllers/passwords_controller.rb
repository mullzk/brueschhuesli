class PasswordsController < ApplicationController
  def edit
    @user = Current.user
  end

  def update
    @user = Current.user
    unless User.authenticate(@user.name, params[:old_password])
      flash.now[:notice] = "Altes Passwort ist ungültig"
      return render :edit, status: :unprocessable_content
    end

    if @user.update(password_params.merge(has_to_change_password: false))
      reset_other_sessions
      flash[:notice] = "Passwort geändert"
      redirect_to users_path
    else
      flash.now[:notice] = "Passwort konnte nicht geändert werden"
      render :edit, status: :unprocessable_content
    end
  end

  private

  def password_params
    params.fetch(:user, {}).permit(:password, :password_confirmation)
  end

  def reset_other_sessions
    @user.sessions.where.not(id: Current.session.id).destroy_all
  end
end
