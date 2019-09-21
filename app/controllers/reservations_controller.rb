class ReservationsController < ApplicationController
  require "DateGermanAdditions"
  before_action :authorize
  
  def index
    if params[:date]
      @listed_month = Date.parse(params[:date])
    elsif params[:month] 
      @listed_month = month_and_year_as_time(params[:month])
    else 
      @listed_month = Date.today
    end
    
    first_day = @listed_month.at_beginning_of_month.at_beginning_of_week
    last_day = @listed_month.at_end_of_month.at_beginning_of_week + 6.days
    
    @days = []
    first_day.to_date.upto(last_day.to_date) { |date|
      reservation_day = {}
      reservation_day[:datum] = date
      reservation_day[:reservations] = Reservation.find_reservations_on_date(date)
      reservation_day[:empty_day] = reservation_day[:reservations].empty?
      @days << reservation_day
    }
  end
  
  def new
    # See also #new_reservation_in_ajax
    @users = User.all.sort.map {|user| [user.name, user.id]}
    if params[:date]
      day = Date.params[:date]
    else 
      day = Date.today
    end
    startDateTime = DateTime.new(day.year, day.month, day.day, Time.now.hour)
    finishDateTime = startDateTime+1.day

    @reservation = Reservation.new(
      start: startDateTime,
      finish: finishDateTime,
      user_id: session[:user_id],
      type_of_reservation: Reservation::KURZAUFENTHALT,
      is_exclusive: true
    )
  end


  def create
    @reservation = Reservation.new(params[:reservation])
    if @reservation.save
      flash[:notice] = "Reservation wurde gespeichert"
      redirect_to :action => "index", :date => @reservation.start
    else
      flash[:notice] = "Reservation konnte nicht gespeichert werden"
    end
    
    
  end
  

  def show
    @reservation = Reservation.find(params[:id])
  end

  def edit
    @reservation = Reservation.find(params[:id])
    @users = User.all.sort.map {|user| [user.name, user.id]}
  end

  def update
    @reservation = Reservation.find(params[:id])
    @users = User.find(:all).sort.map {|user| [user.name, user.id]}
    if @reservation.update_attributes(params[:reservation])
      flash[:notice] = 'Änderungen gespeichert.'
      redirect_to :action => "index", :date => @reservation.start
    else
      flash.now[:notice] = "Änderungen konnten nicht gespeichert werden."
      render :action => "edit"
    end
  end
    
    
  def destroy
    Reservation.find(params[:id]).destroy
    flash[:notice] = "Reservierung gelöscht"
    redirect_to :action => "index"
  end
  
  
  
  private

  def month_and_year_as_time(string)
    begin
      date = Date.strptime(string, "%Y-%m")
    rescue 
      return nil
    end
    date
  end
end
