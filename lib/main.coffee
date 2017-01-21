{CompositeDisposable} = require 'atom'
settings = require './settings'

itemForRow = (row) ->
  item = document.createElement('span')
  item.textContent = row
  item

module.exports =
  config: settings.config

  activate: ->
    @subscriptions = new CompositeDisposable
    @markersByEditor = new Map()

    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      @initiEditor(editor)

  initiEditor: (editor) ->
    editor.addGutter(name: 'relative-line-numbers2')
    @subscriptions.add editor.onDidChangeCursorPosition =>
      @refresh(editor)

  refresh: (editor) ->
    if @markersByEditor.has(editor)
      for marker in @markersByEditor.get(editor)
        marker.destroy()
       @markersByEditor.delete(editor)

    selection = editor.getLastSelection()
    [startRow, endRow] = selection.getBufferRowRange()
    if selection.isReversed()
      currentRow = startRow
    else
      currentRow = endRow

    gutter = editor.gutterWithName('relative-line-numbers2')
    markers = []
    for row in [0..editor.getLastBufferRow()]
      relativeRow = Math.abs(row - currentRow)
      marker = editor.markBufferPosition([row, 0])
      markers.push(marker)
      gutter.decorateMarker marker, {
        class: "relative-line-numbers2-row"
        item: itemForRow(relativeRow)
      }
    @markersByEditor.set(editor, markers)

  deactivate: ->
    @subscriptions.dispose()
