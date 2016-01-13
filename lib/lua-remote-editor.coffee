
{CompositeDisposable} = require 'atom'
{MessagePanelView} = require 'atom-message-panel'
SpacePen = require "space-pen"
{Socket} = require "net"
linkPaths = require './link-paths'

luafuncregex =/^((\s*function)|(\s*local\s*function))\s*\w*\s*\(.*\)\s*(\s*|\w*|.)*end/
luaFunclineRegexp = /function\s*\w*\s*\((\s*|\w*)\)/
luaFuncNameRegexp =/function\b\s+?(\w+)\s*/

module.exports = LuaRemoteEditor =
  config:
    hostPort:
      type: 'integer'
      default: 8011
      description: 'hostPort'
    hostIP:
      type: 'string'
      default: "127.0.0.1"
      description: 'hostIP'


  subscriptions: null
  client:null
  messages:null


  activate: ->
          @subscriptions = new CompositeDisposable
          @subscriptions.add atom.commands.add 'atom-workspace', 'lua-remote-editor:command': => @command()
          @subscriptions.add atom.commands.add 'atom-workspace', 'lua-remote-editor:connect': => @connect()
          @subscriptions.add atom.commands.add 'atom-workspace', 'lua-remote-editor:updateFunc': => @updatefunc()
          if not @messages?
            @messages = new MessagePanelView
                  title: atom.config.get("lua-remote-editor.hostIP")
            @messages.attach()
            console.log "new message"
          linkPaths.listen(@messages)


  connect: ->
      console.log "connect"
      if  @client?
        @client.end()
        @client = null

      @client = Socket()
      @client.connect(atom.config.get("lua-remote-editor.hostPort"),atom.config.get("lua-remote-editor.hostIP"))
      @client.on("data", (info)=> @onData(info) )
      @client.on("error",(info) => @onSocketError(info))
      @client.on("connect",(info) => @onConnectSuccess(info))
      @client.on("close", (info) => @onClose(info))
      console.log "init socket" + @client

  onSocketError: (error) ->
    console.log this
    @show("onSocketError"+error)

  onConnectSuccess:(info) ->
      @show("onConnectSuccess:\t")

  onClose:(info) ->
      @show("onClose:\t"+info)


  onData: (data)->
    console.log this
    @show(data)
  deactivate: ->
    @subscriptions.dispose()


  serialize: ->


  show: (data)->
    data = data+ '\0'
    console.log data
    data = linkPaths(data)
    console.log data
    @messages.add SpacePen.$$ ->
      @pre class: "line",=>
        @raw  data
    @messages.attach()
    # 做个判定是不是在最后一行，是就自动向下移，
    @messages.updateScroll()

  command: ->
    editor=atom.workspace.getActiveTextEditor()
    str= editor.getSelectedText()
    str= str + ';'
    @client.write(str)
    console.log str


  updatefunc: ->
    # console.log "updateFunc"
    # editor=atom.workspace.getActiveTextEditor()
    # str= editor.getSelectedText()
    # regExpFunction = new RegExp(/function\b\s+?(\w+)\s*/)
    #
    # console.log regExpFunction.exec(str)
    editor=atom.workspace.getActiveTextEditor()
    str= editor.getSelectedText()
    title = editor.getTitle()
    regExpObject = new RegExp(luafuncregex)
    isFunc = regExpObject.test(str)
    if isFunc
      console.log "string is a function"
      funcNameLine = str.match(luaFuncNameRegexp)[0]
      funcName = funcNameLine.match(luaFuncNameRegexp)[1]
      modeName = title.match(/\w*/)[0]
      code = str.replace(funcName,"")
      puleCode = code.replace(/--.*/g,"")

      console.log funcName,modeName
      luaCode = modeName+"=require "+'("'+modeName+'")'+" "+modeName+"."+funcName+"="+puleCode+" print('updateFunc success');"
      console.log luaCode
      @client.write(luaCode)
    else
      console.log "string is not a function"

  #  editor=atom.workspace.getActiveTextEditor()
  #  str= editor.getSelectedText()
  #  title = editor.getTitle()



#  取出模块名，/^.*\s*function\s*(\w+):(\w+).*$/\2/f/"
#  取出函数名
