document.addEventListener "turbolinks:load", (event) ->
	window.addEventListener "scroll", (scrollEvent) ->
		if window.scrollY < -5
			loader = document.querySelector("[data-loading-preceding-month-link]")
			if loader && (loader.getAttribute("data-loading-preceding-month-link") != "true")
				console.log "Loading previous month"
				document.querySelector("#loadinghint").style.display="block"
				loader.setAttribute "data-loading-preceding-month-link", "true"
				$.ajax(url: loader.getAttribute("href")).done (html) ->
					document.querySelector("#reservationskalender").insertAdjacentHTML("afterbegin", html)
					window.scrollBy(0, document.querySelector(".calendar").scrollHeight)
					previousMonthUrl = document.querySelector("[data-prev-month-url]").getAttribute("data-prev-month-url")
					loader.setAttribute("href", previousMonthUrl)
					loader.setAttribute "data-loading-preceding-month-link", "false"
					document.querySelector("#loadinghint").style.display="none"

				
		if (window.innerHeight + window.scrollY) >  document.body.scrollHeight - 150
			loader = document.querySelector("[data-loading-succeeding-month-link]")
			if loader && (loader.getAttribute("data-loading-succeeding-month-link") != "true")
				console.log "Loading succeding month"
				document.querySelector("#loadinghint").style.display="block"
				loader.setAttribute "data-loading-succeeding-month-link", "true"

				$.ajax(url: loader.getAttribute("href")).done (html) ->
					document.querySelector("#reservationskalender").insertAdjacentHTML("beforeend", html)
					nextMonthNodes = document.querySelectorAll("[data-next-month-url]")					
					nextMonthUrl = nextMonthNodes[nextMonthNodes.length- 1].getAttribute("data-next-month-url")
					loader.setAttribute("href", nextMonthUrl)
					loader.setAttribute "data-loading-succeeding-month-link", "false"
					document.querySelector("#loadinghint").style.display="none"
									
		