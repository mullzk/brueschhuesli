# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :require_user_reader, only: :index
  before_action :require_owner, only: %i[new create destroy]
  before_action :require_owner_or_self, only: %i[edit update]

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
    apply_role(@user)
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
    apply_role(@user)
    if @user.update(user_update_params)
      flash[:notice] = "Benutzer-Angaben gespeichert."
      redirect_to users_path
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    user = User.find(params.expect(:id))
    flash[:notice] = if user.destroy
      "Benutzer #{user.name} gelöscht"
    else
      "#{user.name} kann nicht gelöscht werden, solange Reservationen bestehen."
    end
    redirect_to users_path
  end

  private

  def require_user_reader
    deny_access if current_user.external?
  end

  # Owners manage anyone; everyone else may only touch their own account, and
  # the shared house account has no self-service at all.
  def require_owner_or_self
    return if current_user.owner?

    deny_access if current_user.shared_account? || current_user.id != params.expect(:id).to_i
  end

  def user_params
    params.fetch(:user, {}).permit(:name, :email, :telefon, :password, :password_confirmation)
  end

  # Role is assigned explicitly (never mass-assigned) and only by owners; a
  # role submitted by anyone else is ignored.
  def apply_role(user)
    return unless current_user.owner?

    role = params.dig(:user, :role)
    user.role = role if role.present?
  end

  # On edit, blank password fields mean "keep the current password".
  def user_update_params
    user_params[:password].blank? ? user_params.except(:password, :password_confirmation) : user_params
  end
end
