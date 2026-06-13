class LoginController < ApplicationController
  layout "reservation"

  def change_password
    @user = Current.user
    if request.post?
      unless User.authenticate(@user.name, params[:old_password])
        flash.now[:notice] = "Altes Passwort ist ungültig"
        return render :change_password, status: :unprocessable_entity
      end
      if @user.update(user_params)
        @user.has_to_change_password = false
        @user.save
        flash[:notice] = "Passwort geändert"
        redirect_to users_path
      else
        flash.now[:notice] = "Passwort konnte nicht geändert werden"
        render :change_password, status: :unprocessable_entity
      end
    end
  end

  private
  def user_params
    params.fetch(:user, {}).permit(:name, :email, :password, :password_confirmation)
  end
end
