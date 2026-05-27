import { Controller } from "@hotwired/stimulus"

// Navigates to a URL when the element is clicked.
// Usage: <td data-controller="enter-href" data-enter-href-url-value="/foo">
export default class extends Controller {
  static values = { url: String }

  connect() {
    this.element.addEventListener("click", this.go)
  }

  disconnect() {
    this.element.removeEventListener("click", this.go)
  }

  go = () => {
    if (this.urlValue) {
      window.location.href = this.urlValue
    }
  }
}
