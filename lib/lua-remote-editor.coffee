
{CompositeDisposable} = require 'atom'
{MessagePanelView} = require 'atom-message-panel'
SpacePen = require "space-pen"
{Socket} = require "net"
linkPaths = require './link-paths'
FS = require 'fs'

luafuncregex =/^((\s*function)|(\s*local\s*function))\s*\w*\s*\(.*\)\s*(\s*|\w*|.)*end/
luaFunclineRegexp = /function\s*\w*\s*\(.*\)/g
luaFuncNameRegexp =/function\b\s+?(\w+)\s*/



class LuaRemoteEditor
  subscriptions: null
  client:null
  messages:null

  constructor: ->
          @subscriptions = new CompositeDisposable
          @subscriptions.add atom.commands.add 'atom-workspace', 'lua-remote-editor:command': => @command()
          @subscriptions.add atom.commands.add 'atom-workspace', 'lua-remote-editor:connect': => @connect()
          @subscriptions.add atom.commands.add 'atom-workspace', 'lua-remote-editor:updateFunc': => @updatefunc()
          @subscriptions.add atom.commands.add 'atom-workspace', 'lua-remote-editor:clearlog': => @clearlog()
          @subscriptions.add atom.commands.add 'atom-workspace', 'lua-remote-editor:trace': => @trace()


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
      @injectluacode()
      @show("onConnectSuccess:\t")

  onClose:(info) ->
      @show("onClose:\t"+info)


  onData: (data)->
    console.log this
    @show(data)
  deactivate: ->
    @subscriptions.dispose()


  serialize: ->




  injectluacode: ->
    FS.readFile( __dirname+'/../luacode/trace.lua', 'utf8',(err, contents) =>
                if err
                  @show(err)
                else
                  str = contents.toString()
                  str= str + ';'
                  puleCode = str.replace(/--.*/g,"")
                  @client.write(puleCode)
              )

# print(trace)


  clearlog: ->
    @messages.clear()

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

  command:() ->
    editor=atom.workspace.getActiveTextEditor()
    str= editor.getSelectedText()
    str= str + ';'
    @client.write(str)
    console.log str



  trace: ->
      editor=atom.workspace.getActiveTextEditor()
      str= editor.getSelectedText()
      title = editor.getTitle()
      regExpObject = new RegExp(luafuncregex)
      isFunc = regExpObject.test(str)
      if isFunc
        funcNameLine = str.match(luaFunclineRegexp)[0]
        str = str.replace(funcNameLine,funcNameLine+'\n\t trace.trace("n s",5)')
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
      funcNameLine = str.match(luaFunclineRegexp)[0]
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
module.exports =
    config:
      hostPort:
        type: 'integer'
        default: 8011
        description: 'hostPort'
      hostIP:
        type: 'string'
        default: "127.0.0.1"
        description: 'hostIP'
exports = new LuaRemoteEditor
