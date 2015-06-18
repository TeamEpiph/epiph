Meteor.methods
  moveQuestion: (questionnaireId, oldIndex, newIndex) ->
    #checkIfAdmin()
    check(questionnaireId, String)
    check(oldIndex, Match.Integer)
    check(newIndex, Match.Integer)

    question = Questions.findOne
      questionnaireId: questionnaireId
      index: oldIndex

    if newIndex > oldIndex
      newIndex -= 1

    Questions.update
      questionnaireId: questionnaireId
      index: { $gt: oldIndex }
    ,
      $inc: { index: -1 }
    ,
      multi: true
    console.log "--------------------"
    Questions.find().forEach (q) ->
      console.log q
    Questions.update
      questionnaireId: questionnaireId
      index: { $gte: newIndex }
    ,
      $inc: { index: 1 }
    ,
      multi: true
    Questions.update
      _id: question._id
    ,
      $set: { index: newIndex}

