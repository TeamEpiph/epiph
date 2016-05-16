Template.activities.helpers
  activities: ->
    Activities.find()

  activitiesRTS: ->
    useFontAwesome: true,
    rowsPerPage: 100,
    showFilter: true,
    fields: [
      { key: 'description', label: "description"},
      { key: 'reason', label: "reason"},
      { key: 'level', label: "level" },
      { key: 'userId', label: "user", fn: (v,o) -> getUserDescription(Meteor.users.findOne(v)) },
      { key: "createdAt", label: 'created', sortByValue: true, sortOrder: 0, sortDirection: 'descending', fn: (v,o)->fullDate(v)},
    ]

