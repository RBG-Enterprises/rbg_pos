// RBG POS application bundle (esbuild, see package.json "build").
//
// Stack: Turbo Drive (navigation) + rails-ujs (remote forms, data-method
// deletes, data-confirm) + jQuery plugins + AdminLTE + Chartkick.
//
// UJS/Turbo coexistence: UJS-owned elements keep their exact legacy
// behavior by opting out of Turbo Drive at runtime (data-turbo="false").
// Do NOT remove the excludeUjsFromTurbo() calls until each remote flow is
// individually migrated to Turbo Frames/Streams.
import "core-js/stable";
import "regenerator-runtime/runtime";
import "@hotwired/turbo-rails";
import * as ActiveStorage from "@rails/activestorage";
ActiveStorage.start();
import Rails from "@rails/ujs";
Rails.start();
import jquery from "jquery";
window.jQuery = window.$ = jquery;
import "popper.js";
import "bootstrap";
import "bootstrap-datepicker";
import "chosen-js";
import "./adminlte";
import Chart from "chart.js";
window.Chart = Chart;
import Chartkick from "chartkick";
window.Chartkick = Chartkick;
import "./controllers";

function excludeUjsFromTurbo(root) {
  (root || document).querySelectorAll(
    'form[data-remote="true"], a[data-remote="true"], a[data-method]'
  ).forEach(function (el) {
    el.setAttribute("data-turbo", "false");
  });
}

function initWidgets() {
  excludeUjsFromTurbo();
  $('[data-toggle="tooltip"]').tooltip();
  $('[data-toggle="popover"]').popover();
  $('.datepicker').datepicker(
    {
      format: 'dd/mm/yyyy',
      defaultDate: new Date(),
      immediateUpdates: true,
      todayBtn: true,
      todayHighlight: true,
      autoclose: true

    }).datepicker("setDate", "0");;
  $('.datepicker-no-default').datepicker(
    {
      format: 'dd/mm/yyyy',
      immediateUpdates: true,
      todayBtn: true,
      todayHighlight: true,
      autoclose: true
    });
  $('.chosen-select').chosen({width: "95%"});

  var tabsNav = document.getElementById('session-detail-tabs')
  if (tabsNav) {
    var hash = window.location.hash
    if (hash) {
      var trigger = tabsNav.querySelector('a[href="' + hash + '"]')
      if (trigger) { $(trigger).tab('show') }
    }
    $(tabsNav).on('shown.bs.tab', 'a[data-toggle="tab"]', function (e) {
      history.replaceState(null, null, e.target.getAttribute('href'))
    })
  }

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
}

document.addEventListener("turbo:load", initWidgets);

var resizeWindow = function () {
    return $(window).trigger('resize');
};

document.addEventListener('turbo:load', resizeWindow);
