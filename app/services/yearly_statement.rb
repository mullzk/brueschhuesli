class YearlyStatement
  Line = Data.define(:user, :reservation_count, :fee)

  def self.for(year)
    new(Reservation.find_reservations_beginning_in_year(year).includes(:user))
  end

  def initialize(reservations)
    @reservations = reservations
  end

  def lines
    @lines ||= @reservations.group_by(&:user).map do |user, reservations|
      Line.new(user:, reservation_count: reservations.size, fee: reservations.sum(&:billed_fee))
    end.sort_by(&:user)
  end
end
