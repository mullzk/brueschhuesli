var Day = createReactClass({
  propTypes: {
    reservations: PropTypes.array,
    inMonth: PropTypes.bool,
    date: PropTypes.string
  },

  render: function() {
	var reservationNodes = this.props.reservations.map(function (reservation, index) {
		return <Reservation isExclusive={reservation.isExclusive} userName={reservation.userName} key={index} />
	});
	  
    return (
      <React.Fragment>
		<td>
			{this.props.date}
			<small>{this.props.inMonth}</small>
			{reservationNodes}
		</td>
      </React.Fragment>
    );
  }
});

