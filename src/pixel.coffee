# If you're embedding the pixel on other sites where you can't be sure that a DOM 
# library exists, you can point your users to this branch and js file.
#
# Each call to this file collects the window location and title for the request to
# pixel.gif.
if not window.pixel_ping_tracked
  loc       = window.location
  titleEl   = document.getElementsByTagName("title").item(0)
  separator = "|pixel-ping-break|"
  titleText = titleEl.text.replace(/#{"\" + separator}/g, "") or ""
  try
    canonicalUrl = document.currentScript.dataset.bgaCanonical
  catch
    canonicalUrl = document.querySelector('script[data-bga-canonical]').dataset.bgaCanonical
  finally
    canonicalUrl = if canonicalUrl.length > 0 then canonicalUrl else 'https://www.bettergov.org'
  url       = encodeURIComponent "#{titleText}#{separator}#{loc.protocol}//#{loc.host}#{loc.pathname}#{separator}#{canonicalUrl}"
  img       = document.createElement 'img'
  img.setAttribute 'src', "https://pixel.bettergov.org/pixel.gif?key=#{url}"
  img.setAttribute 'width', '1'
  img.setAttribute 'height', '1'
  document.body.appendChild img
  window.pixel_ping_tracked = yes
