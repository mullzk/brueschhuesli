import { Controller } from "@hotwired/stimulus"

// Toggles a navigation menu open/closed.
// Usage:
//   <nav data-controller="navbar-toggle">
//     <button data-action="click->navbar-toggle#toggle" aria-expanded="false">...</button>
//     <ul data-navbar-toggle-target="menu">...</ul>
//   </nav>
export default class extends Controller {
  static targets = ["menu"]

  toggle(event) {
    const button = event.currentTarget
    const isOpen = this.menuTarget.classList.toggle("is-open")
    button.setAttribute("aria-expanded", isOpen ? "true" : "false")
  }
}
