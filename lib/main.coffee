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

    @subscriptions.add atom.workspace.onDidChangeActivePaneItem (item) =>
      if atom.workspace.isTextEditor(item)
        @refresh(item)

  initiEditor: (editor) ->
    console.log editor.getPath()
    # default line-number gutter priority is 0
    # So setting priority=1 place relative-line-numbers2 gutter on just
    # right of line-number guthter.
    editor.addGutter(name: 'relative-line-numbers2', priority: 1)
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
    for editor in atom.workspace.getTextEditors()
      editor.gutterWithName('relative-line-numbers2')?.destroy()
    @markersByEditor.forEach (markers) ->
      for marker in markers
        marker.destroy()
    @markersByEditor.clear()
    @subscriptions.dispose()
