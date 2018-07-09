"use strict";

(function () {
  var canonicalUrl, img, loc, separator, titleEl, titleText, url;

  if (!window.pixel_ping_tracked) {
    loc = window.location;
    titleEl = document.getElementsByTagName("title").item(0);
    separator = "|pixel-ping-break|";
    titleText = titleEl.text.replace(/#{"\" + separator}/g, "") || "";
    try {
      canonicalUrl = document.currentScript.dataset.bgaCanonical;
    } catch (error) {
      canonicalUrl = document.querySelector('script[data-bga-canonical]').dataset.bgaCanonical;
    } finally {
      canonicalUrl = canonicalUrl.length > 0 ? canonicalUrl : 'https://www.bettergov.org';
    }
    url = encodeURIComponent("" + titleText + separator + loc.protocol + "//" + loc.host + loc.pathname + separator + canonicalUrl);
    img = document.createElement('img');
    img.setAttribute('src', "<%= root %>/pixel.gif?key=" + url);
    img.setAttribute('width', '1');
    img.setAttribute('height', '1');
    document.body.appendChild(img);
    window.pixel_ping_tracked = true;
  }
}).call(undefined);