import { Controller } from "@hotwired/stimulus"

// Toggles a navigation menu open/closed and closes it again on Escape, on an
// outside click, and after navigating (Turbo visit).
// Usage:
//   <nav data-controller="navbar-toggle">
//     <button data-navbar-toggle-target="button"
//             data-action="click->navbar-toggle#toggle" aria-expanded="false">...</button>
//     <ul data-navbar-toggle-target="menu">...</ul>
//   </nav>
export default class extends Controller {
  static targets = ["menu", "button"]

  connect() {
    this.closeOnOutsideClick = this.closeOnOutsideClick.bind(this)
    this.closeOnEscape = this.closeOnEscape.bind(this)
    this.close = this.close.bind(this)
    document.addEventListener("click", this.closeOnOutsideClick)
    document.addEventListener("keydown", this.closeOnEscape)
    document.addEventListener("turbo:before-visit", this.close)
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnOutsideClick)
    document.removeEventListener("keydown", this.closeOnEscape)
    document.removeEventListener("turbo:before-visit", this.close)
  }

  toggle() {
    this.setOpen(!this.menuTarget.classList.contains("is-open"))
  }

  close() {
    this.setOpen(false)
  }

  setOpen(open) {
    this.menuTarget.classList.toggle("is-open", open)
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", open ? "true" : "false")
    }
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close()
  }
}
