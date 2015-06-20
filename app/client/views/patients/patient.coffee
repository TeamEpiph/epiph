Template.patient.created = ->
  @subscribe "studyForPatient", @data._id
