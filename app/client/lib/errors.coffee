Meteor.startup ->
  #http://stackoverflow.com/questions/951791/javascript-global-error-handling
  window.onerror = (msg, url, line, col, error) ->
    # Note that col & error are new to the HTML 5 spec and may not be
    # supported in every browser.  It worked for me in Chrome.
    extra = if !col then '' else ' column: ' + col

    throwError 'Error: ' + msg + '\n\nat: ' + url + '\n\nline: ' + line + extra

    #throw errors to console
    throw error

    # return true, so error alerts (like in older versions of
    # Internet Explorer) will be suppressed.
    return true

@throwError = (error) ->
  if typeof error is "string"
    reason = error
  else
    reason = error.reason
  if !reason? or reason.length is 0
    reason = "unknown reason"
  if error.reason? and error.reason is "validationErrorQuestionInUse"
    swal {
      title: 'Error'
      html: true
      customClass: "text-left"
      text: """Error: This question is in use. Changing question type, codes, values or selection-mode is therefore not allowed. Your changes will be discarded.<br><br>
You might:
<ul>
<li>Use a copy of the questionnaire (e.g. in a new study or for new patients)</li>
<li>Remove all patients from the study and then change the code or value</li>
<li>Rename/remove the column or values manually after the export</li>
<li>Ask an administrator to make this change in the data base</li>
</ul>"""
      type: 'error'
      showCancelButton: false
      confirmButtonText: 'OK'
    }
  else if error.reason? and error.reason is "validationErrorQuestionnaireInUse"
    console.log "swal"
    swal {
      title: 'Error'
      html: true
      customClass: "text-left"
      text: """Error: This questionnaire is in use by the following studies: #{error.details}. Removing it is therefore not allowed.<br><br>
You might:
<ul>
<li>Remove the questionnaire from the study designs.</li>
<li>Ask an administrator to make this change in the data base</li>
</ul>"""
      type: 'error'
      showCancelButton: false
      confirmButtonText: 'OK'
    }
  else if error.reason? and error.reason is "validationErrorAnswersExistForStudy"
    console.log "swal"
    swal {
      title: 'Error'
      html: true
      customClass: "text-left"
      text: """Error: This questionnaire is in use by the following studies: #{error.details}. Removing it is therefore not allowed.<br><br>
You might:
<ul>
<li>Remove the questionnaire from the study designs.</li>
<li>Ask an administrator to make this change in the data base</li>
</ul>"""
      type: 'error'
      showCancelButton: false
      confirmButtonText: 'OK'
    }
  else
    swal {
      title: 'Error'
      text: reason
      type: 'error'
      customClass: "text-left" if reason.length > 100
      showCancelButton: false
      confirmButtonText: 'OK'
    }
  return

