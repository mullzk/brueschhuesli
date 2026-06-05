class ReservationsController < ApplicationController
  before_action :authorize

  def index
    @listed_month = parse_date_param

    presented_months = (0..2).collect { |i| @listed_month.at_beginning_of_month + i.months }
    @months = presented_months.collect { |month| get_calendar_for_month month }
  end

  def month
    @listed_month = parse_date_param
    @month = get_calendar_for_month @listed_month
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
    startDateTime = DateTime.new(day.year, day.month, day.day, Time.current.hour)
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

  def get_calendar_for_month (day_in_month)
    # Get 4-6 complete weeks in our calendar, meaning als the last days of the previous and the first days of the next months
    days = day_in_month.beginning_of_month.beginning_of_week.upto(day_in_month.end_of_month.end_of_week).to_a
    reservations = reservations_covering(days.first, days.last)

    weeks = days.collect { |day| calendar_day(day, day_in_month, reservations) }.in_groups_of(7)
    { first_of_month: day_in_month.beginning_of_month, name: day_in_month.german_month, weeks: weeks }
  end

  def reservations_covering(first_day, last_day)
    Reservation.where("start <= ? AND finish > ?", last_day.end_of_day, first_day.beginning_of_day)
               .includes(:user).order(:start).to_a
  end

  def calendar_day(day, day_in_month, reservations)
    on_day = reservations.select { |reservation| reservation.on_day?(day) }.sort_by { |reservation| reservation.begin_on_day(day) }
    { date: day, in_month: day.month.equal?(day_in_month.month), reservations: on_day }
  end
end
