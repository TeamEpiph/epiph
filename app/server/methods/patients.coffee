Meteor.methods
  "createPatient": (studyId) ->
    checkIfAdmin()
    check(studyId, String)
    _id = null
    tries = 0
    loop
      try
        _id = Patients.insert
          id: readableRandom(6)
          creatorId: Meteor.userId()
          studyId: studyId
      catch e
        console.log "Error: createPatient"
        console.log e
      finally
        tries += 1
        break if _id or tries >= 3
    throw new Meteor.Error(500, "Can't create patient, id space seems to be full.") unless _id?
    _id
