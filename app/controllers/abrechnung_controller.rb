class AbrechnungController < ApplicationController
  before_action :authorize

  def index
    redirect_to :action => "jahresstatistik"
  end
  
  def jahresstatistik
    @listed_year = extract_year
    stats = User.all.map do |user|
      user_res = Reservation.reservations_for_user_in_year(user, @listed_year)
      unless user_res.empty?
        fee_sum = user_res.inject(0) { |sum, reservation| reservation.billed_fee + sum }
        [user, user_res.size, fee_sum]
      end    
    end
    @stats = stats.compact.sort {|a,b| (a[0]<=>b[0])}  # We don't want to show nil-values, and we sort by Name
    respond_to_html_and_excel "brüschhüsli_abrechnung_#{@listed_year.year}"
  end

  def detailliste
    @listed_year = extract_year
    @reservations = Reservation.find_reservations_beginning_in_year(@listed_year).sort
    respond_to_html_and_excel "brüschhüsli_nutzungen_#{@listed_year.year}"
  end

  def benutzer
    @listed_year = extract_year
    @user = User.find(params[:id])
    @reservations = Reservation.reservations_for_user_in_year(@user, @listed_year).sort
    respond_to_html_and_excel "brüschhüsli_nutzungen_#{(@user.name)}_#{@listed_year.year}"
  end


private
  def respond_to_html_and_excel(filename)
    Mime::Type.register "application/excel", :xls
    respond_to do |format|
      format.html # show.html.erb
      format.xls   {
                    headers['Content-Type'] = "application/vnd.ms-excel"
                    headers['Content-Disposition'] = "attachment; filename=\"#{filename}.xls\""
                    headers['Cache-Control'] = ''
                    render :layout => false
                    }
    end
  end

  def extract_year
    if params[:date]
      Date.parse(params[:date])
    elsif params[:year] 
      Date.new(params[:year].to_i)
    else 
      Date.today
    end
  end
  
end
