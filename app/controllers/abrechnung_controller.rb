# frozen_string_literal: true

class AbrechnungController < ApplicationController
  before_action :require_abrechnung_access

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
    @user = User.find(params.expect(:id))
    @reservations = Reservation.reservations_for_user_in_year(@user, @listed_year).includes(:user).sort
    respond_to_html_and_excel "brüschhüsli_nutzungen_#{@user.name}_#{@listed_year.year}"
  end

  private

  def require_abrechnung_access
    deny_access if current_user.external?
  end

  def respond_to_html_and_excel(filename)
    respond_to do |format|
      format.html
      format.xlsx { render xlsx: action_name, filename: "#{filename}.xlsx" }
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
