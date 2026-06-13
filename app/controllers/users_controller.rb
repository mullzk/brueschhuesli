class UsersController < ApplicationController
  def index
    @all_users = User.all.sort
  end

  def new
    @user = User.new
  end

  def edit
    @user = User.find(params.expect(:id))
  end

  def create
    @user = User.new(user_params)
    if @user.save
      flash[:notice] = "Benutzer #{@user.name} erstellt"
      redirect_to users_path
    else
      flash.now[:notice] = "Benutzer konnte nicht erstellt werden"
      render :new, status: :unprocessable_content
    end
  end

  def update
    @user = User.find(params.expect(:id))
    if @user.update(user_update_params)
      flash[:notice] = "Benutzer-Angaben gespeichert."
      redirect_to users_path
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    user = User.find(params.expect(:id))
    if user.destroy
      flash[:notice] = "Benutzer #{user.name} gelöscht"
    else
      flash[:notice] = "#{user.name} kann nicht gelöscht werden, solange Reservationen bestehen."
    end
    redirect_to users_path
  end

  private

  def user_params
    params.fetch(:user, {}).permit(:name, :email, :telefon, :miteigentuemer, :password, :password_confirmation)
  end

  # On edit, blank password fields mean "keep the current password".
  def user_update_params
    user_params[:password].blank? ? user_params.except(:password, :password_confirmation) : user_params
  end
end
