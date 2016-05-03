Meteor.startup ->
  #http://stackoverflow.com/questions/951791/javascript-global-error-handling
  window.onerror = (msg, url, line, col, error) ->
    # Note that col & error are new to the HTML 5 spec and may not be 
    # supported in every browser.  It worked for me in Chrome.
    extra = if !col then '' else ' column: ' + col

    throwError 'Error: ' + msg + '\n\nat: ' + url + '\n\nline: ' + line + extra
    # return true, so error alerts (like in older versions of 
    # Internet Explorer) will be suppressed.
    return true

@throwError = (error) ->
  if typeof error is "string"
    reason = error
  else
    reason = error.reason
  swal {
    title: 'Error'
    text: reason
    type: 'error'
    customClass: "text-left" if reason.length > 100
    showCancelButton: false
    confirmButtonText: 'OK'
  }
  return
