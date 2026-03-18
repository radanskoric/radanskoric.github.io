import { Application, Controller } from "@hotwired/stimulus"

const app = Application.start()
app.register("tag-editor", class extends Controller {
  static targets = ["input", "tagList", "tagTemplate"]

  addTag() {
    const value = this.inputTarget.value.trim()
    if (!value) return

    this.#addTag(value)
    this.clear()
  }

  removeTag(e) {
    e.target.closest("li").remove()
  }

  clear() {
    this.inputTarget.value = ""
    this.inputTarget.focus()
  }

  #addTag(name) {
    const clone = this.tagTemplateTarget.content.cloneNode(true)
    clone.querySelector("slot[name='tag-name']").textContent = name
    this.tagListTarget.appendChild(clone)
  }
})
