class AbrechnungController < ApplicationController
  def index
    redirect_to action: "jahresstatistik"
  end

  def jahresstatistik
    @listed_year = extract_year
    @statement = YearlyStatement.for(@listed_year)
    respond_to_html_and_excel "brüschhüsli_abrechnung_#{@listed_year.year}"
  end

  def detailliste
    @listed_year = extract_year
    @reservations = Reservation.find_reservations_beginning_in_year(@listed_year).includes(:user).sort
    respond_to_html_and_excel "brüschhüsli_nutzungen_#{@listed_year.year}"
  end

  def benutzer
    @listed_year = extract_year
    @user = User.find(params[:id])
    @reservations = Reservation.reservations_for_user_in_year(@user, @listed_year).includes(:user).sort
    respond_to_html_and_excel "brüschhüsli_nutzungen_#{(@user.name)}_#{@listed_year.year}"
  end


private
  def respond_to_html_and_excel(filename)
    respond_to do |format|
      format.html # show.html.erb
      format.xls   {
                    headers["Content-Type"] = "application/vnd.ms-excel"
                    headers["Content-Disposition"] = "attachment; filename=\"#{filename}.xls\""
                    headers["Cache-Control"] = ""
                    render layout: false
                    }
    end
  end

  def extract_year
    if params[:date]
      Date.parse(params[:date])
    elsif params[:year]
      Date.new(params[:year].to_i)
    else
      Date.current
    end
  end
end
