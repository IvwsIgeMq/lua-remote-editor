LuaRemoteEditor = require '../lib/lua-remote-editor'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "LuaRemoteEditor", ->
  [workspaceElement, activationPromise] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('lua-remote-editor')

  describe "when the lua-remote-editor:toggle event is triggered", ->
    it "hides and shows the modal panel", ->
      # Before the activation event the view is not on the DOM, and no panel
      # has been created
      expect(workspaceElement.querySelector('.lua-remote-editor')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.commands.dispatch workspaceElement, 'lua-remote-editor:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(workspaceElement.querySelector('.lua-remote-editor')).toExist()

        luaRemoteEditorElement = workspaceElement.querySelector('.lua-remote-editor')
        expect(luaRemoteEditorElement).toExist()

        luaRemoteEditorPanel = atom.workspace.panelForItem(luaRemoteEditorElement)
        expect(luaRemoteEditorPanel.isVisible()).toBe true
        atom.commands.dispatch workspaceElement, 'lua-remote-editor:toggle'
        expect(luaRemoteEditorPanel.isVisible()).toBe false

    it "hides and shows the view", ->
      # This test shows you an integration test testing at the view level.

      # Attaching the workspaceElement to the DOM is required to allow the
      # `toBeVisible()` matchers to work. Anything testing visibility or focus
      # requires that the workspaceElement is on the DOM. Tests that attach the
      # workspaceElement to the DOM are generally slower than those off DOM.
      jasmine.attachToDOM(workspaceElement)

      expect(workspaceElement.querySelector('.lua-remote-editor')).not.toExist()

      # This is an activation event, triggering it causes the package to be
      # activated.
      atom.commands.dispatch workspaceElement, 'lua-remote-editor:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        # Now we can test for view visibility
        luaRemoteEditorElement = workspaceElement.querySelector('.lua-remote-editor')
        expect(luaRemoteEditorElement).toBeVisible()
        atom.commands.dispatch workspaceElement, 'lua-remote-editor:toggle'
        expect(luaRemoteEditorElement).not.toBeVisible()
