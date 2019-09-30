class ReservationsController < ApplicationController
  require "DateGermanAdditions"
  before_action :authorize
  
  def index
    @listed_month = parse_date_param
    
    presented_months = (0..2).collect { |i| Date.today.at_beginning_of_month + i.months }
    @months = presented_months.collect {|month| get_calendar_for_month month}
  end
  
  def month
    @listed_month = parse_date_param
    @month = get_calendar_for_month @listed_month
    render partial:"month", object:@month
  end
  
 
  def on_day
    if params[:date]
      @day = Date.parse(params[:date])
    else
      flash[:notice] = "Etwas ist schief gelaufen, on_day benötigt einen Datums-Parameter"
      redirect_to :action => "index"
    end
    @reservations = Reservation.find_reservations_on_date @day
  end
  
  def new
    @users = User.all.sort.map {|user| [user.name, user.id]}
    if params[:date]
      day = Date.parse(params[:date])
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
    @reservation = Reservation.new(reservation_params)
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
    @users = User.all.sort.map {|user| [user.name, user.id]}
    if @reservation.update(reservation_params)
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
  
  def reservation_params
    params.fetch(:reservation, {}).permit(:user_id, :start, :finish, :type_of_reservation, :is_exclusive, :comment)
  end
  
  def parse_date_param
    if params[:date]
      return Date.parse(params[:date])
    elsif params[:month] 
      return month_and_year_as_time(params[:month])
    else 
      return Date.today
    end
  end
  
  def get_calendar_for_month (first_of_month)
    all_days_in_calendar = first_of_month.beginning_of_month.beginning_of_week.upto first_of_month.end_of_month.end_of_week
  
    all_days_in_calendar = all_days_in_calendar.collect { |day|
      reservations = Reservation.find_reservations_on_date(day)
      {date:day, in_month:day.month.equal?(first_of_month.month), reservations:reservations}
    }
  
    weeks = all_days_in_calendar.in_groups_of(7)
    return {first_of_month:first_of_month, name:first_of_month.german_month, weeks:weeks }
  end
  
end
