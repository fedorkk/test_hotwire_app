import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  country_change(event) {
    console.log("here");
    let country_id = event.target.selectedOptions[0].value;

    fetch(`/addresses/country_change?country_id=${country_id}`, {
      method: "GET",
      headers: {
        Accept: 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml',
        'X-Requested-With': 'XMLHttpRequest',
        // 'X-CSRF-Token': this.getMetaContent('csrf-token'),
        'Cache-Control': 'no-cache',
      },
    })
    .then(response => response.ok ? response.text() : Promise.reject('Response not OK'))
    .then(html => Turbo.renderStreamMessage(html))
    .catch(error => console.error('Error:', error));
  }

  city_change(event) {
    let city_id = event.target.selectedOptions[0].value;

    fetch(`/addresses/city_change?city_id=${city_id}`, {
      method: "GET",
      headers: {
        Accept: 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml',
        'X-Requested-With': 'XMLHttpRequest',
        // 'X-CSRF-Token': this.getMetaContent('csrf-token'),
        'Cache-Control': 'no-cache',
      },
    })
    .then(response => response.ok ? response.text() : Promise.reject('Response not OK'))
    .then(html => Turbo.renderStreamMessage(html))
    .catch(error => console.error('Error:', error));
  }

  // getMetaContent(name) {
  //   return document.querySelector(`meta[name="${name}"]`).getAttribute('content');
  // }
}
