class ReservationBilling
  RATE_PER_BLOCK = 15
  FLAT_GROSSANLASS = 200
  RATE_PER_DAY_EXTERN = 100
  FREE_BLOCKS_MITEIGENTUEMER = 6

  def initialize(type:, blocks:, days:, miteigentuemer:, exclusive:)
    @type = type
    @blocks = blocks
    @days = days
    @miteigentuemer = miteigentuemer
    @exclusive = exclusive
  end

  def paid_blocks
    if @miteigentuemer && !@exclusive
      [ @blocks - FREE_BLOCKS_MITEIGENTUEMER, 0 ].max
    else
      @blocks
    end
  end

  def fee
    case @type
    when Reservation::KURZAUFENTHALT, Reservation::FERIENAUFENTHALT
      paid_blocks * RATE_PER_BLOCK
    when Reservation::GROSSANLASS
      FLAT_GROSSANLASS
    when Reservation::EXTERNE_NUTZUNG
      @days * RATE_PER_DAY_EXTERN
    end
  end
end
