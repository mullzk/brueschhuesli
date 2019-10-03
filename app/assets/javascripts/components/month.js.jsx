var Month = createReactClass({
  propTypes: {
    weeks: PropTypes.array,
    name: PropTypes.string
  },

  render: function() {
	  
     var weekNodes = this.props.weeks.map(function (week, index) {
		 return (<Week days={week} key={index} />);
	 });
	  
    return (
      <React.Fragment>
		<h2>{this.props.name}</h2>
		<table className="calendar">
			<thead>
				<tr>
					<th>Mo</th>
					<th>Di</th>
					<th>Mi</th>
					<th>Do</th>
					<th>Fr</th>
					<th>Sa</th>
					<th>So</th>
				</tr>
			</thead>
			<tbody>
				{weekNodes}
			</tbody>
		</table>
      </React.Fragment>
    );
  }
});

