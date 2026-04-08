import { Application, Controller } from "@hotwired/stimulus"

const app = Application.start()
app.register("js-tag-editor", class extends Controller {
  static targets = ["input", "tagList", "tagTemplate", "clearButton", "emptyMessage"]

  addTag() {
    const value = this.inputTarget.value.trim()
    if (!value) return

    this.#addTag(value)
    this.#updateVisibility()
    this.clear()
  }

  removeTag(e) {
    e.target.closest("li").remove()
    this.#updateVisibility()
  }

  clear() {
    this.inputTarget.value = ""
    this.inputTarget.focus()
    this.toggleClearButton()
  }

  toggleClearButton() {
    this.clearButtonTarget.classList.toggle("hidden", this.inputTarget.value === "")
  }

  #addTag(name) {
    const clone = this.tagTemplateTarget.content.cloneNode(true)
    clone.querySelector("slot[name='tag-name']").textContent = name
    this.tagListTarget.appendChild(clone)
  }

  #updateVisibility() {
    const tags = this.tagListTarget.querySelectorAll("li")
    const hasTags = tags.length > 0
    const isOnly = tags.length === 1

    this.emptyMessageTarget.classList.toggle("hidden", hasTags)
    this.tagListTarget.classList.toggle("hidden", !hasTags)
    tags.forEach(tag => tag.classList.toggle("only-tag", isOnly))
  }
})
