@ExportTable = new Meteor.Collection "export_table"

Meteor.methods
  'createExportTable': (selection) ->
    checkIfAdmin()
    check selection, Object

    #ExportTable.remove()

    tableName = "export_#{moment().toISOString()}"
    ExportTables.insert
      name: tableName

    headers = Export.columnHeaders(selection)
    Export.rows(selection).forEach (row) ->
      cols = Export.columns(selection, row)
      tableRow =
        tableName: tableName
      i = 0
      while i < headers.length
        header = headers[i].title.replace(/\./g, "_")
        tableRow[header] = cols[i] 
        i++
      ExportTable.insert tableRow
    return

  'removeExportTable': (tableName) ->
    checkIfAdmin()
    check tableName, String
    ExportTable.remove
      tableName: tableName
    ExportTables.remove
      name: tableName
