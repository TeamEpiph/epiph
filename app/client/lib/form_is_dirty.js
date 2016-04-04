/**
 * Determines if a form is dirty by comparing the current value of each element
 * with its default value.
 *
 * @param {Form} form the form to be checked.
 * @return {Boolean} <code>true</code> if the form is dirty, <code>false</code>
 *                   otherwise.
 */
formIsDirty = function formIsDirty(form) {
  for (var i = 0; i < form.elements.length; i++) {
    var element = form.elements[i];
    var type = element.type;
    if (type == "checkbox" || type == "radio") {
      if (element.checked != element.defaultChecked) {
        return true;
      }
    }
    else if (type == "hidden" || type == "password" ||
             type == "text" || type == "textarea" ||
             type == "number" ) {
      if (element.value != element.defaultValue) {
        return true;
      }
    }
    else if (type == "select-one" || type == "select-multiple") {
      for (var j = 0; j < element.options.length; j++) {
        if (element.options[j].selected !=
            element.options[j].defaultSelected) {
          return true;
        }
      }
    }
  }
  return false;
}
