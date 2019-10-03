var Week = createReactClass({
  propTypes: {
    days: PropTypes.array
  },

  render: function() {
	  var daynodes = this.props.days.map(function (day, index) {
	  	  return <Day reservations={day.reservations} inMonth={day.inMonth} date={day.date} key={index} />
	  });
	  
    return (
      <React.Fragment>
		<tr>
			{daynodes}
		</tr>
      </React.Fragment>
    );
  }
});

