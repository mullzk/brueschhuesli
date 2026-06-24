import { Controller } from "@hotwired/stimulus"

// Drives the reservations calendar:
// - appends the following month when scrolled near the bottom (infinite scroll),
// - prepends the previous month via the "Früher" link, keeping the scroll
//   position anchored,
// - reveals a "Heute" button only while today is scrolled out of view below
//   (i.e. one has browsed into the past) and scrolls back to it on click.
export default class extends Controller {
  static targets = ["months", "hint", "today"]

  connect() {
    this.loading = false
    this.updateTodayButton()
  }

  onScroll() {
    if (this.nearBottom()) this.loadNext()
    this.updateTodayButton()
  }

  earlier(event) {
    event.preventDefault()
    this.loadPrevious()
  }

  today(event) {
    event.preventDefault()
    this.todayCell()?.scrollIntoView({ behavior: "smooth", block: "center" })
  }

  loadNext() {
    const links = this.monthsTarget.querySelectorAll("[data-next-month-url]")
    const url = links.length ? links[links.length - 1].dataset.nextMonthUrl : null
    if (url) this.insert("beforeend", url)
  }

  loadPrevious() {
    const link = this.monthsTarget.querySelector("[data-prev-month-url]")
    if (link) this.insert("afterbegin", link.dataset.prevMonthUrl)
  }

  insert(position, url) {
    if (this.loading) return
    this.loading = true
    this.showHint()
    const heightBefore = document.body.scrollHeight
    fetch(url, { credentials: "same-origin" })
      .then((response) => response.text())
      .then((html) => {
        this.monthsTarget.insertAdjacentHTML(position, html)
        if (position === "afterbegin") {
          window.scrollBy(0, document.body.scrollHeight - heightBefore)
        }
      })
      .finally(() => {
        this.hideHint()
        this.loading = false
      })
  }

  updateTodayButton() {
    if (!this.hasTodayTarget) return
    const cell = this.todayCell()
    const belowViewport = cell && cell.getBoundingClientRect().top > window.innerHeight
    this.todayTarget.hidden = !belowViewport
  }

  todayCell() {
    return this.monthsTarget.querySelector(".calendar__cell--today")
  }

  nearBottom() {
    return window.innerHeight + window.scrollY > document.body.scrollHeight - 400
  }

  showHint() {
    if (this.hasHintTarget) this.hintTarget.style.display = "block"
  }

  hideHint() {
    if (this.hasHintTarget) this.hintTarget.style.display = "none"
  }
}
