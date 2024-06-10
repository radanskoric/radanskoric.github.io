// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

addEventListener("turbo:render", (event) => {
  console.log("Turbo Rendered with: ", event.detail.renderMethod, (event.detail.isPreview ? "(preview)" : ""));
})

Turbo.StreamActions.full_page_redirect = function() {
  document.location = this.getAttribute("target")
}

