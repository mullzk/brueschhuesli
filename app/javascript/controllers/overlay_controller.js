import { Controller } from "@hotwired/stimulus"

// Shows the day-detail / form sheet whenever its turbo-frame ("modal") loads
// content, and closes again on the close button, a backdrop click, or Escape.
// Without JS the same links navigate to full pages, so the calendar stays
// usable.
export default class extends Controller {
  static targets = ["frame"]

  connect() {
    this.show = this.show.bind(this)
    this.frameTarget.addEventListener("turbo:frame-load", this.show)
  }

  disconnect() {
    this.frameTarget.removeEventListener("turbo:frame-load", this.show)
  }

  show() {
    if (this.frameTarget.innerHTML.trim() === "") return
    this.element.hidden = false
    document.body.style.overflow = "hidden"
  }

  close() {
    this.element.hidden = true
    document.body.style.overflow = ""
    this.frameTarget.innerHTML = ""
    this.frameTarget.removeAttribute("src")
    this.frameTarget.removeAttribute("complete")
  }

  closeOnBackdrop(event) {
    if (event.target === this.element) this.close()
  }

  closeOnEscape(event) {
    if (event.key === "Escape" && !this.element.hidden) this.close()
  }
}
