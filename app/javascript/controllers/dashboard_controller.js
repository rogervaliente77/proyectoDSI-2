import { Controller } from "@hotwired/stimulus";
// import Rails from '@rails/ujs';
// Rails.start();

export default class extends Controller {
  connect() {
    this.toggle = this.element.querySelector(".toggle");
    this.menuDashboard = this.element.querySelector(".menu-dashboard");
    this.enlacesMenu = this.element.querySelectorAll(".enlace");
    
    if (this.toggle) {
      this.toggle.addEventListener("click", () => {
        this.menuDashboard.classList.toggle("open");
      });
    }
    
    this.enlacesMenu.forEach(enlace => {
      enlace.addEventListener("click", () => {
        this.menuDashboard.classList.add("open");
      });
    });
    
    console.log("Dashboard controller connected");
  }
}
