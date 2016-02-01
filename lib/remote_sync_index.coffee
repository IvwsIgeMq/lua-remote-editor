
fs = require('fs-plus')
CompositeDisposable = null
path = null
$ = null

getEventPath = (e)->
  $ ?= require('atom-space-pen-views').$

  target = $(e.target).closest('.file, .directory, .tab')[0]
  target ?= atom.workspace.getActiveTextEditor()

  fullPath = target?.getPath?()
  return [] unless fullPath

  [projectPath, relativePath] = atom.project.relativizePath(fullPath)
  return [projectPath, fullPath]

projectDict = null
disposables = null
RemoteSync = null
logger = null
initProject = (projectPaths)->
  console.log 'initProject'
  disposes = []
  for projectPath of projectDict
    disposes.push projectPath if projectPaths.indexOf(projectPath) == -1

  for projectPath in disposes
    projectDict[projectPath].dispose()
    delete projectDict[projectPath]

  for projectPath in projectPaths
    try
        projectPath = fs.realpathSync(projectPath)
    catch err
        continue
    continue if projectDict[projectPath]
    RemoteSync ?= require "./RemoteSync"
    console.log "projectPath"+projectPath
    obj = RemoteSync.create(projectPath)
    projectDict[projectPath] = obj if obj
    console.log projectDict

handleEvent = (e, cmd)->
  [projectPath, fullPath] = getEventPath(e)
  return unless projectPath

  projectObj = projectDict[fs.realpathSync(projectPath)]
  projectObj[cmd]?(fs.realpathSync(fullPath))


reload = (projectPath)->
  projectDict[projectPath]?.dispose()
  projectDict[projectPath] = RemoteSync.create(projectPath)

configure = (e)->
  [projectPath] = getEventPath(e)
  return unless projectPath

  projectPath = fs.realpathSync(projectPath)
  RemoteSync ?= require "./RemoteSync"
  RemoteSync.configure projectPath, -> reload(projectPath)

class RemoteSyncIndex

  constructor: (subscriptions) ->
    projectDict = {}
    initProject(atom.project.getPaths())
    disposables = subscriptions

    disposables.add atom.commands.add('atom-workspace', {
      'lua-remote-editor:upload-folder': (e)-> handleEvent(e, "uploadFolder")
      'lua-remote-editor:upload-file': (e)-> handleEvent(e, "uploadFile")
      'lua-remote-editor:delete-file': (e)-> handleEvent(e, "deleteFile")
      'lua-remote-editor:delete-folder': (e)-> handleEvent(e, "deleteFile")
      'lua-remote-editor:download-file': (e)-> handleEvent(e, "downloadFile")
      'lua-remote-editor:download-folder': (e)-> handleEvent(e, "downloadFolder")
      'lua-remote-editor:diff-file': (e)-> handleEvent(e, "diffFile")
      'lua-remote-editor:diff-folder': (e)-> handleEvent(e, "diffFolder")
      'lua-remote-editor:upload-git-change': (e)-> handleEvent(e, "uploadGitChange")
      'lua-remote-editor:configure': configure
    })

    disposables.add atom.project.onDidChangePaths (projectPaths)->
      initProject(projectPaths)

    disposables.add atom.workspace.observeTextEditors (editor) ->
      onDidSave = editor.onDidSave (e) ->
        fullPath = e.path
        [projectPath, relativePath] = atom.project.relativizePath(fullPath)
        return unless projectPath

        projectPath = fs.realpathSync(projectPath)
        projectObj = projectDict[projectPath]
        return unless projectObj

        if fs.realpathSync(fullPath) == fs.realpathSync(projectObj.configPath)
          projectObj = reload(projectPath)

        return unless projectObj.host.uploadOnSave
        projectObj.uploadFile(fs.realpathSync(fullPath))


      onDidDestroy = editor.onDidDestroy ->
        disposables.remove onDidSave
        disposables.remove onDidDestroy
        onDidDestroy.dispose()
        onDidSave.dispose()

      disposables.add onDidSave
      disposables.add onDidDestroy

  clean: ->
    disposables.dispose()
    disposables = null
    for projectPath, obj of projectDict
      obj.dispose()
    projectDict = null
module.exports = RemoteSyncIndex
