# frozen_string_literal: true

class ReservationsController < ApplicationController
  before_action :require_reservation_manager, only: %i[new create edit update destroy]
  before_action :require_own_reservation, only: %i[edit update destroy]
  before_action :set_user_options, only: %i[new create edit update]

  def index
    @listed_month = parse_date_param
    @months = (0..2).map { |i| CalendarMonth.for(@listed_month.beginning_of_month + i.months) }
  end

  def month
    @listed_month = parse_date_param
    @month = CalendarMonth.for(@listed_month)
    render partial: "month", object: @month, template: "reservations"
  end

  def on_day
    unless params[:date]
      flash[:notice] = "Etwas ist schief gelaufen, on_day benötigt einen Datums-Parameter"
      return redirect_to action: "index"
    end
    @day = Date.parse(params[:date])
    @reservations = Reservation.find_reservations_on_date @day
    @schedule = DaySchedule.for(@day, @reservations)
  end

  def show
    @reservation = Reservation.find(params.expect(:id))
  end

  def new
    day = params[:date] ? Date.parse(params[:date]) : Date.current
    @reservation = Reservation.new(
      **prefilled_period(day),
      user_id: Current.user.id,
      type_of_reservation: Reservation::KURZAUFENTHALT,
      is_exclusive: true
    )
  end

  def edit
    @reservation = Reservation.find(params.expect(:id))
  end

  def create
    @reservation = Reservation.new(reservation_params)
    if @reservation.save
      flash[:notice] = "Reservation wurde gespeichert"
      redirect_to action: "index", date: @reservation.start
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    @reservation = Reservation.find(params.expect(:id))
    if @reservation.update(reservation_params)
      flash[:notice] = "Änderungen gespeichert."
      redirect_to action: "index", date: @reservation.start
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    Reservation.find(params.expect(:id)).destroy
    flash[:notice] = "Reservierung gelöscht"
    redirect_to action: "index"
  end

  private

  def require_reservation_manager
    deny_access unless current_user.may_reserve?
  end

  def require_own_reservation
    deny_access unless Reservation.find(params.expect(:id)).editable_by?(current_user)
  end

  def set_user_options
    users = current_user.owner? ? User.all.sort : [ current_user ]
    @users = users.map { |user| [ user.name, user.id ] }
  end

  def month_and_year_as_time(string)
    Date.strptime(string, "%Y-%m")
  rescue ArgumentError, TypeError => e
    Rails.logger.debug { "Unparseable month param #{string.inspect}: #{e.message}" }
    nil
  end

  def parse_time(value)
    Time.zone.parse(value) if value.present?
  rescue ArgumentError
    nil
  end

  def prefilled_period(day)
    start_at = parse_time(params[:start]) || DateTime.new(day.year, day.month, day.day, Time.current.hour)
    finish_at = parse_time(params[:finish]) || (start_at + 1.day)
    { start: start_at, finish: finish_at }
  end

  def reservation_params
    permitted = params.fetch(:reservation, {}).permit(:user_id, :start, :finish, :type_of_reservation, :is_exclusive,
                                                      :comment)
    permitted[:user_id] = current_user.id unless current_user.owner?
    permitted
  end

  def parse_date_param
    if params[:date]
      Date.parse(params[:date])
    elsif params[:month]
      month_and_year_as_time(params[:month])
    else
      Date.current
    end
  end
end
