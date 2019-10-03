document.addEventListener "turbolinks:load", (event) ->
	document.querySelectorAll("[data-js-append-new-month]").forEach (node) ->
		node.addEventListener "click", (e) -> 
			node.getAttribute("data-js-append-new-month")
			