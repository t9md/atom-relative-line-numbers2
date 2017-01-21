{CompositeDisposable} = require 'atom'
settings = require './settings'

itemForRow = (rowText) ->
  # String(row).length
  item = document.createElement('span')
  item.textContent = rowText
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
    # default line-number gutter priority is 0
    # So setting priority=1 place relative-line-numbers2 gutter on just
    # right of line-number guthter.
    editor.addGutter(name: 'relative-line-numbers2', priority: 1)
    # editor.addGutter(name: 'relative-line-numbers2')
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
    # # if softWrapped
    # #   lineNumber = "•"
    # # else
    #   lineNumber = (bufferRow + 1).toString()
    #   padding = _.multiplyString("\u00a0", maxLineNumberDigits - lineNumber.length)


    maxLineNumberWidth = editor.getLineCount().toString().length
    for row in [0..editor.getLastBufferRow()]
      relativeRow = Math.abs(row - currentRow).toString()
      # padding = _.multiplyString("\u00a0", maxLineNumberWidth - relativeRow.length)
      padding = "\u00a0".repeat(maxLineNumberWidth - relativeRow.length)

      marker = editor.markBufferPosition([row, 0])
      markers.push(marker)
      gutter.decorateMarker marker, {
        class: "relative-line-numbers2-row"
        item: itemForRow(padding + relativeRow)
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
