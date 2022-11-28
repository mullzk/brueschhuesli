# frozen_string_literal: true

class ReservationsController < ApplicationController
  require 'DateGermanAdditions'
  before_action :authorize

  def index
    @listed_month = parse_date_param

    presented_months = (0..2).collect { |i| @listed_month.at_beginning_of_month + i.months }
    @months = presented_months.collect { |month| get_calendar_for_month month }
  end

  def month
    @listed_month = parse_date_param
    @month = get_calendar_for_month @listed_month
    render partial: 'month', object: @month, template: 'reservations'
  end

  def on_day
    if params[:date]
      @day = Date.parse(params[:date])
    else
      flash[:notice] = 'Etwas ist schief gelaufen, on_day benötigt einen Datums-Parameter'
      redirect_to action: 'index'
    end
    @reservations = Reservation.find_reservations_on_date @day
  end

  def new
    @users = User.all.sort.map { |user| [user.name, user.id] }
    day = if params[:date]
            Date.parse(params[:date])
          else
            Date.today
          end
    startDateTime = DateTime.new(day.year, day.month, day.day, Time.now.hour)
    finishDateTime = startDateTime + 1.day

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
      flash[:notice] = 'Reservation wurde gespeichert'
      redirect_to action: 'index', date: @reservation.start
    else
      flash[:notice] = 'Reservation konnte nicht gespeichert werden'
    end
  end

  def show
    @reservation = Reservation.find(params[:id])
  end

  def edit
    @reservation = Reservation.find(params[:id])
    @users = User.all.sort.map { |user| [user.name, user.id] }
  end

  def update
    @reservation = Reservation.find(params[:id])
    @users = User.all.sort.map { |user| [user.name, user.id] }
    if @reservation.update(reservation_params)
      flash[:notice] = 'Änderungen gespeichert.'
      redirect_to action: 'index', date: @reservation.start
    else
      flash.now[:notice] = 'Änderungen konnten nicht gespeichert werden.'
      render action: 'edit'
    end
  end

  def destroy
    Reservation.find(params[:id]).destroy
    flash[:notice] = 'Reservierung gelöscht'
    redirect_to action: 'index'
  end

  private

  def month_and_year_as_time(string)
    begin
      date = Date.strptime(string, '%Y-%m')
    rescue StandardError
      return nil
    end
    date
  end

  def reservation_params
    params.fetch(:reservation, {}).permit(:user_id, :start, :finish, :type_of_reservation, :is_exclusive, :comment)
  end

  def parse_date_param
    return Date.parse(params[:date]) if params[:date]
    return month_and_year_as_time(params[:month]) if params[:month]

    Date.today
  end

  def get_calendar_for_month(day_in_month)
    # Get 4-6 complete weeks in our calendar, meaning als the last days of the previous and the first days of the next months
    all_days_in_calendar = day_in_month.beginning_of_month.beginning_of_week.upto day_in_month.end_of_month.end_of_week

    # For each day, get the reservations. Days of the pre- or succedding month should be marked.
    all_days_in_calendar = all_days_in_calendar.collect do |day|
      reservations = Reservation.find_reservations_on_date(day)
      { date: day, in_month: day.month.equal?(day_in_month.month), reservations: }
    end

    # Create 2D-Array of weeks
    weeks = all_days_in_calendar.in_groups_of(7)
    { first_of_month: day_in_month.beginning_of_month, name: day_in_month.german_month, weeks: }
  end
end
