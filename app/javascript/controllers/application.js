// Stimulus application. Page-specific jQuery widget init remains in
// app/javascript/application.js (turbo:load) until migrated controller
// by controller.
import { Application } from "@hotwired/stimulus";

const application = Application.start();

// Configure Stimulus development experience
application.debug = false;
window.Stimulus = application;

export { application };
