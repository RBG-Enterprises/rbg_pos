// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
import "core-js/stable";
import "regenerator-runtime/runtime";
require("@rails/ujs").start()
require('jquery')
require("turbolinks").start()
require("@rails/activestorage").start()
require('adminlte')
require('jquery')
require("chartkick")
require("chart.js")
import "bootstrap"
import "bootstrap-datepicker"
import 'chosen-js'

document.addEventListener("turbolinks:load", () => {
  $('[data-toggle="tooltip"]').tooltip()
  $('[data-toggle="popover"]').popover()
  $('.datepicker').datepicker(
    {
      format: 'dd/mm/yyyy',
      defaultDate: new Date(),
      immediateUpdates: true,
      todayBtn: true,
      todayHighlight: true,
      autoclose: true

    }).datepicker("setDate", "0");;
  $('.chosen-select').chosen({width: "95%"});

  document.querySelectorAll('[data-live-search]').forEach((input) => {
    var delay = parseInt(input.dataset.liveSearchDelay, 10) || 300
    var timeout
    var submitForm = () => {
      if (input.form) {
        input.form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
      }
    }
    input.addEventListener('keyup', () => {
      clearTimeout(timeout)
      timeout = setTimeout(submitForm, delay)
    })
    input.addEventListener('search', () => {
      clearTimeout(timeout)
      submitForm()
    })
  })
})

// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)


document.addEventListener('turbolinks:load', ready);
var ready = function () {
    return $(window).trigger('resize');
};

document.addEventListener('turbolinks:load', ready);
