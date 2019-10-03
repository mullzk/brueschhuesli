var Reservation = createReactClass({
  propTypes: {
    isExlusive: PropTypes.bool,
    username: PropTypes.string
  },

  render: function() {
    return (
      <React.Fragment>
        Is Exlusive: {this.props.isExlusive}
        Username: {this.props.username}
      </React.Fragment>
    );
  }
});

