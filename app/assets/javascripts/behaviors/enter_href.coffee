document.addEventListener "turbolinks:load", (event) ->
	document.querySelectorAll("[data-js-enter-reservation-href]").forEach (node) ->
		node.addEventListener "click", (e) -> 
			window.location.href = node.getAttribute("data-js-enter-reservation-href")
