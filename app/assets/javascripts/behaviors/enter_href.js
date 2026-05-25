document.addEventListener("turbolinks:load", function(event) {
	document.querySelectorAll("[data-js-enter-reservation-href]").forEach(function(node) {
		node.addEventListener("click", function(e) {
			window.location.href = node.getAttribute("data-js-enter-reservation-href");
		});
	});
});
