LuaRemoteEditorView = require './lua-remote-editor-view'
{CompositeDisposable} = require 'atom'

module.exports = LuaRemoteEditor =
  luaRemoteEditorView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @luaRemoteEditorView = new LuaRemoteEditorView(state.luaRemoteEditorViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @luaRemoteEditorView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'lua-remote-editor:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @luaRemoteEditorView.destroy()

  serialize: ->
    luaRemoteEditorViewState: @luaRemoteEditorView.serialize()

  toggle: ->
    console.log 'LuaRemoteEditor was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
