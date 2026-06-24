import { Controller } from "@hotwired/stimulus"

// Drives the reservations calendar:
// - appends the following month when scrolled near the bottom (infinite scroll),
// - prepends the previous month via the "Früher" link, keeping the scroll
//   position anchored,
// - reveals a "Heute" button only while today is scrolled out of view below
//   (i.e. one has browsed into the past) and scrolls back to it on click,
// - lets a pointer drag across several days open the new-reservation form for
//   that range, while a plain click keeps its single-day behaviour.
export default class extends Controller {
  static targets = ["months", "hint", "today"]
  static values = { newUrl: String }

  connect() {
    this.loading = false
    this.startDate = null
    this.lastDate = null
    this.dragged = false

    this.pointerDown = this.pointerDown.bind(this)
    this.pointerMove = this.pointerMove.bind(this)
    this.pointerUp = this.pointerUp.bind(this)
    this.suppressClick = this.suppressClick.bind(this)
    this.suppressDragStart = (event) => event.preventDefault()

    this.element.addEventListener("pointerdown", this.pointerDown)
    window.addEventListener("pointermove", this.pointerMove)
    window.addEventListener("pointerup", this.pointerUp)
    this.element.addEventListener("click", this.suppressClick, true)
    this.element.addEventListener("dragstart", this.suppressDragStart)

    this.updateTodayButton()
  }

  disconnect() {
    this.element.removeEventListener("pointerdown", this.pointerDown)
    window.removeEventListener("pointermove", this.pointerMove)
    window.removeEventListener("pointerup", this.pointerUp)
    this.element.removeEventListener("click", this.suppressClick, true)
    this.element.removeEventListener("dragstart", this.suppressDragStart)
  }

  onScroll() {
    if (this.nearBottom()) this.loadNext()
    this.updateTodayButton()
  }

  pointerDown(event) {
    if (!event.isPrimary || event.button > 0) return
    const cell = event.target.closest("[data-date]")
    if (!cell) return
    this.startDate = cell.dataset.date
    this.lastDate = this.startDate
    this.dragged = false
  }

  pointerMove(event) {
    if (!this.startDate) return
    const cell = document.elementFromPoint(event.clientX, event.clientY)?.closest("[data-date]")
    if (!cell) return
    this.lastDate = cell.dataset.date
    if (this.lastDate !== this.startDate) this.dragged = true
    this.highlight(this.startDate, this.lastDate)
  }

  pointerUp() {
    if (!this.startDate) return
    const dragged = this.dragged
    const [from, to] = [this.startDate, this.lastDate].sort()
    this.startDate = null
    this.clearHighlight()
    if (dragged) this.openRange(from, to)
  }

  // After a drag the pointerdown cell still receives a click; swallow it so the
  // single-day link does not fire on top of the range we just opened.
  suppressClick(event) {
    if (!this.dragged) return
    event.preventDefault()
    event.stopImmediatePropagation()
    this.dragged = false
  }

  openRange(from, to) {
    const hour = String(new Date().getHours()).padStart(2, "0")
    const url = new URL(this.newUrlValue, window.location.origin)
    url.searchParams.set("date", from)
    url.searchParams.set("start", `${from}T${hour}:00`)
    url.searchParams.set("finish", `${to}T${hour}:00`)
    document.getElementById("modal").src = url.pathname + url.search
  }

  highlight(from, to) {
    const [min, max] = [from, to].sort()
    this.cells().forEach((cell) => {
      const inRange = cell.dataset.date >= min && cell.dataset.date <= max
      cell.classList.toggle("calendar__cell--selecting", inRange)
    })
  }

  clearHighlight() {
    this.cells().forEach((cell) => cell.classList.remove("calendar__cell--selecting"))
  }

  cells() {
    return this.monthsTarget.querySelectorAll("[data-date]")
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
