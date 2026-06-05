class LoginController < ApplicationController
  layout "reservation"

  allow_unauthenticated_access only: :login

  def add_user
    @user = User.new(user_params)

    initial_password = SecureRandom.hex(8)
    if request.post? and @user.save
      @user.password = user_params[:password] || initial_password
      flash.now[:notice] = "Benutzer #{@user.name} erstellt"
      redirect_to action: "list_users"
    else
      @user.password = initial_password
      if request.post?
        flash.now[:notice] = "Benutzer konnte nicht erstellt werden"
        render :add_user, status: :unprocessable_entity
      end
    end
  end

  def login
    if request.post?
      user = User.authenticate(params[:name], params[:password])
      if user
        start_new_session_for(user)
        if user.has_to_change_password
          flash[:notice] = "Ein neues Passwort muss gesetzt werden"
          redirect_to action: "change_password"
        else
          redirect_to controller: "reservations", action: "index"
        end
      else
        flash.now[:notice] = "Ungültige Benutzer/Passwort Kombination"
        render :login, status: :unprocessable_entity
      end
    end
  end

  def logout
    terminate_session
    flash[:notice] = "Logged out"
    redirect_to action: "login"
  end

  def edit_user
    @user = User.find(params[:id])
  end

  def update_user
    @user = User.find(params[:id])
    if @user.update(user_params)
      flash.now[:notice] = "Benutzer-Angaben gespeichert."
      redirect_to action: "list_users"
    else
      render :edit_user, status: :unprocessable_entity
    end
  end

  def delete_user
    if request.post?
      user = User.find(params[:id])
      begin
        user.destroy
        flash[:notice] = "Benutzer #{user.name} gelöscht"
      rescue ActiveRecord::ActiveRecordError => e
        Rails.logger.warn("User ##{user.id} could not be deleted: #{e.message}")
        flash[:notice] = e.message
      end
    end
    redirect_to action: "list_users"
  end

  def list_users
    @all_users = User.all.sort
  end

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
        redirect_to action: "list_users"
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
