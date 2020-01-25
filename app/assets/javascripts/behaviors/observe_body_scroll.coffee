document.addEventListener "turbolinks:load", (event) ->
	window.addEventListener "scroll", (scrollEvent) ->
		if window.scrollY < 1
			# Once the user initiated infite scrolling to the top, we do not show the Month-Navigation-Links anymore
			document.querySelector(".month-navigation").style.display="none"

			# We get the Link for the preceding month, where the URL and the loading-state is stored. We check wether a loading is already in progress
			loader = document.querySelector("[data-loading-preceding-month-link]")
			if loader && (loader.getAttribute("data-loading-preceding-month-link") != "true")

				# We set the state to loading, logically and visible to the user and then start to load the previous month
				document.querySelector("#loadinghint").style.display="block"
				loader.setAttribute "data-loading-preceding-month-link", "true"
				$.ajax(url: loader.getAttribute("href")).done (html) ->

					# We insert the previous month at the top and scroll down the height of the inserted calendar
					document.querySelector("#reservationskalender").insertAdjacentHTML("afterbegin", html)
					window.scrollBy(0, document.querySelector(".calendar").scrollHeight)

					# We search for the first calendar-item and add event-listeners to its href-nodes
					allCalendars = document.querySelectorAll("#reservationskalender .calendar")
					firstCalendar = allCalendars[0]
					firstCalendar.querySelectorAll("[data-js-enter-reservation-href]").forEach (node) ->
						node.addEventListener "click", (e) -> 
							window.location.href = node.getAttribute("data-js-enter-reservation-href")


					# We adjust the URL of the [data-loading-preceding-month-link]-Link to one month before the newly inserted month
					previousMonthUrl = document.querySelector("[data-prev-month-url]").getAttribute("data-prev-month-url")
					loader.setAttribute("href", previousMonthUrl)

					# We set the loading-state to Not Loading
					loader.setAttribute "data-loading-preceding-month-link", "false"
					document.querySelector("#loadinghint").style.display="none"

				
		if (window.innerHeight + window.scrollY) >  document.body.scrollHeight - 150
			# We get the Link for the next month, where the URL and the loading-state is stored. We check wether a loading is already in progress
			loader = document.querySelector("[data-loading-succeeding-month-link]")
			if loader && (loader.getAttribute("data-loading-succeeding-month-link") != "true")

				# We set the state to loading, logically and visible to the user and then start to load the next month
				document.querySelector("#loadinghint").style.display="block"
				loader.setAttribute "data-loading-succeeding-month-link", "true"
				$.ajax(url: loader.getAttribute("href")).done (html) ->

					# We insert the next month at the bottom
					document.querySelector("#reservationskalender").insertAdjacentHTML("beforeend", html)
					
					# We search for the last calendar-item and add event-listeners to its href-nodes
					allCalendars = document.querySelectorAll("#reservationskalender .calendar")
					lastCalendar = allCalendars[allCalendars.length-1]
					lastCalendar.querySelectorAll("[data-js-enter-reservation-href]").forEach (node) ->
						node.addEventListener "click", (e) -> 
							window.location.href = node.getAttribute("data-js-enter-reservation-href")


					# We adjust the URL of the [data-loading-succeding-month-link]-Link to one month after the newly inserted month
					nextMonthNodes = document.querySelectorAll("[data-next-month-url]")					
					nextMonthUrl = nextMonthNodes[nextMonthNodes.length- 1].getAttribute("data-next-month-url")
					loader.setAttribute("href", nextMonthUrl)

					# We set the loading-state to Not Loading
					loader.setAttribute "data-loading-succeeding-month-link", "false"
					document.querySelector("#loadinghint").style.display="none"
									
		