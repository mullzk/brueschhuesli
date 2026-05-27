import { Controller } from "@hotwired/stimulus"

// Infinite-scroll for the reservations calendar.
// Loads the preceding month when scrolled to the top and the following
// month when scrolled near the bottom. Inserted HTML is auto-wired by
// Stimulus, so newly inserted day cells get their enter-href controller
// without any manual re-binding.
export default class extends Controller {
  check() {
    if (window.scrollY < 1) {
      this.hideMonthNavigation()
      this.loadPrecedingMonth()
    }
    if ((window.innerHeight + window.scrollY) > document.body.scrollHeight - 150) {
      this.loadSucceedingMonth()
    }
  }

  hideMonthNavigation() {
    const nav = document.querySelector(".month-navigation")
    if (nav) nav.style.display = "none"
  }

  loadPrecedingMonth() {
    const loader = document.querySelector("[data-loading-preceding-month-link]")
    if (!loader || loader.getAttribute("data-loading-preceding-month-link") === "true") return

    this.showHint()
    loader.setAttribute("data-loading-preceding-month-link", "true")
    fetch(loader.getAttribute("href"), { credentials: "same-origin" })
      .then((response) => response.text())
      .then((html) => {
        const calendar = document.querySelector("#reservationskalender")
        calendar.insertAdjacentHTML("afterbegin", html)
        window.scrollBy(0, document.querySelector(".calendar").scrollHeight)

        const prevUrl = document.querySelector("[data-prev-month-url]").getAttribute("data-prev-month-url")
        loader.setAttribute("href", prevUrl)
        loader.setAttribute("data-loading-preceding-month-link", "false")
        this.hideHint()
      })
  }

  loadSucceedingMonth() {
    const loader = document.querySelector("[data-loading-succeeding-month-link]")
    if (!loader || loader.getAttribute("data-loading-succeeding-month-link") === "true") return

    this.showHint()
    loader.setAttribute("data-loading-succeeding-month-link", "true")
    fetch(loader.getAttribute("href"), { credentials: "same-origin" })
      .then((response) => response.text())
      .then((html) => {
        document.querySelector("#reservationskalender").insertAdjacentHTML("beforeend", html)

        const nextNodes = document.querySelectorAll("[data-next-month-url]")
        const nextUrl = nextNodes[nextNodes.length - 1].getAttribute("data-next-month-url")
        loader.setAttribute("href", nextUrl)
        loader.setAttribute("data-loading-succeeding-month-link", "false")
        this.hideHint()
      })
  }

  showHint() {
    const hint = document.querySelector("#loadinghint")
    if (hint) hint.style.display = "block"
  }

  hideHint() {
    const hint = document.querySelector("#loadinghint")
    if (hint) hint.style.display = "none"
  }
}
