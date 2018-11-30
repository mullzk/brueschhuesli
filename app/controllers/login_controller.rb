class LoginController < ApplicationController
  layout "reservation"
  
  before_filter :authorize, :except => :login
  
  def add_user
    @user = User.new(params[:user])
    initial_password = ActiveSupport::SecureRandom.base64(6)
    if request.post? and @user.save
      @user.password = params[:user][:password] || initial_password
      flash.now[:notice] = "Benutzer #{@user.name} erstellt"
      redirect_to :action => "list_users"
    else 
      @user.password = initial_password
    end
  end

  def login
    session[:user_id] = nil
    if request.post?
      user = User.authenticate(params[:name], params[:password])
      if user
        session[:user_id] = user.id
        if user.hasToChangePassword
          flash[:notice] = "Ein neues Passwort muss gesetzt werden"
          redirect_to :action => "change_password"
        else
          redirect_to :controller => "reservation", :action => "index"
        end
      else
        flash[:notice] = "Ungültige Benutzer/Passwort Kombination"
      end
    end
  end

  def logout
    session[:user_id] = nil
    flash[:notice] = "Logged out"
    redirect_to :action => "login"
  end

  def edit_user
    @user = User.find(params[:id])
  end
  
  def update_user
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      flash.now[:notice] = 'Benutzer-Angaben gespeichert.'
      redirect_to :action => "list_users"
    else
      render :action => "edit_user"
    end
  end
  
  def delete_user
    if request.post?
      user = User.find(params[:id])
      begin
        user.destroy
        flash[:notice] = "Benutzer #{user.name} gelöscht"
      rescue Exception => e
        flash[:notice] = "#{e.message}"
      end
    end
    redirect_to :action => "list_users"
  end

  def list_users
    @all_users = User.find(:all).sort
  end
  
  def change_password
    @user = User.find_by_id(session[:user_id])    
    if request.post?
      user = User.authenticate(@user.name, params[:old_password])
      if user
        if @user.update_attributes(params[:user])
          @user.hasToChangePassword = false
          @user.save
          flash[:notice] = 'Password geändert'
          redirect_to :action => 'list_users'
        end
      else
        flash[:notice] = "Altes Passwort ist ungültig"
      end
    end
  end
end
