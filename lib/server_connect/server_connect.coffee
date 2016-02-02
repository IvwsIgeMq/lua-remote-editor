
Logger = require '../Logger'

FS = require 'fs'
{Socket} = require "net"
path = require "path"
Host = require '../model/host'



luafuncregex =/^((\s*function)|(\s*local\s*function))\s*\w*\s*\(.*\)\s*(\s*|\w*|.)*end/
luaFunclineRegexp = /function\s*\w*\s*\(.*\)/g
luaFuncNameRegexp =/function\b\s+?(\w+)\s*/


module.exports=
class server_connect
  client:null
  constructor: (@subscriptions) ->
      @subscriptions.add atom.commands.add( 'atom-workspace',{
        'lua-remote-editor:command': => @command()
        'lua-remote-editor:connect': => @connect()
        'lua-remote-editor:trace': => @trace()
        'lua-remote-editor:reload': => @serverReload()
      })


  connect: ->
      if  @client?
        @client.end()
        @client = null


      configPath = path.join( atom.project.getPaths()[0],atom.config.get("lua-remote-editor.configFileName"))
      host= new Host(configPath)
      @client = Socket()
      @client.connect(host.serverport,host.hostname)
      @client.on("data", (info)=> @onData(info) )
      @client.on("error",(info) => @onSocketError(info))
      @client.on("connect",(info) => @onConnectSuccess(info))
      @client.on("close", (info) => @onClose(info))
      Logger.getLogger().log("connecting to ip:#{host.hostname} port:#{host.serverport}")



  onSocketError: (error) ->
    Logger.getLogger().error("onSocketError"+error)

  onConnectSuccess:(info) ->
      @injectluacode()
      Logger.getLogger().log("onConnectSuccess:\t")

  onClose:(info) ->
      Logger.getLogger().error("onClose:\t"+info)


  onData: (data)->
    data = data+ '\0'
    Logger.getLogger().info(data)
  command:() ->
    editor=atom.workspace.getActiveTextEditor()
    str= editor.getSelectedText()
    str= str + ';'
    @client.write(str)

  serverReload:->
    code = 'G_reload_all_module();'
    @client.write(code)

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
  injectluacode: ->
    FS.readFile( __dirname+'/../luacode/trace.lua', 'utf8',(err, contents) =>
                if err
                  Logger.getLogger().log(err)
                else
                  str = contents.toString()
                  str= str + ';'
                  puleCode = str.replace(/--.*/g,"")
                  @client.write(puleCode)
              )

  clear: ->
    @client.end()
