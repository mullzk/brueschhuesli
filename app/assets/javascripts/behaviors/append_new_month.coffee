# this does not work yet. not at all
document.addEventListener "turbolinks:load", (event) ->
	document.querySelectorAll("[data-js-replace-month]").forEach (node) ->
		node.addEventListener "click", (e) -> 
			url = node.getAttribute("data-js-replace-month")
			data = await (await fetch(url))
			content = document.createTextNode(data.content)
			
			document.getElementById("reservationskalender").appendChild(content)
