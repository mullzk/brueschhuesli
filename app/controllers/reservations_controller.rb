class ReservationsController < ApplicationController
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
    if params[:date]
      @day = Date.parse(params[:date])
    else
      flash[:notice] = "Etwas ist schief gelaufen, on_day benötigt einen Datums-Parameter"
      redirect_to action: "index"
    end
    @reservations = Reservation.find_reservations_on_date @day
  end

  def new
    @users = User.all.sort.map { |user| [ user.name, user.id ] }
    if params[:date]
      day = Date.parse(params[:date])
    else
      day = Date.current
    end
    start_date_time = DateTime.new(day.year, day.month, day.day, Time.current.hour)
    finish_date_time = start_date_time + 1.day

    @reservation = Reservation.new(
      start: start_date_time,
      finish: finish_date_time,
      user_id: Current.user.id,
      type_of_reservation: Reservation::KURZAUFENTHALT,
      is_exclusive: true
    )
  end


  def create
    @reservation = Reservation.new(reservation_params)
    if @reservation.save
      flash[:notice] = "Reservation wurde gespeichert"
      redirect_to action: "index", date: @reservation.start
    else
      @users = User.all.sort.map { |user| [ user.name, user.id ] }
      flash.now[:notice] = "Reservation konnte nicht gespeichert werden"
      render :new, status: :unprocessable_entity
    end
  end


  def show
    @reservation = Reservation.find(params[:id])
  end

  def edit
    @reservation = Reservation.find(params[:id])
    @users = User.all.sort.map { |user| [ user.name, user.id ] }
  end

  def update
    @reservation = Reservation.find(params[:id])
    @users = User.all.sort.map { |user| [ user.name, user.id ] }
    if @reservation.update(reservation_params)
      flash[:notice] = "Änderungen gespeichert."
      redirect_to action: "index", date: @reservation.start
    else
      flash.now[:notice] = "Änderungen konnten nicht gespeichert werden."
      render :edit, status: :unprocessable_entity
    end
  end


  def destroy
    Reservation.find(params[:id]).destroy
    flash[:notice] = "Reservierung gelöscht"
    redirect_to action: "index"
  end



  private

  def month_and_year_as_time(string)
    Date.strptime(string, "%Y-%m")
  rescue ArgumentError, TypeError => e
    Rails.logger.debug("Unparseable month param #{string.inspect}: #{e.message}")
    nil
  end

  def reservation_params
    params.fetch(:reservation, {}).permit(:user_id, :start, :finish, :type_of_reservation, :is_exclusive, :comment)
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
