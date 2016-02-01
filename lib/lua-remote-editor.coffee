
{CompositeDisposable} = require 'atom'
{MessagePanelView} = require 'atom-message-panel'
SpacePen = require "space-pen"
{Socket} = require "net"
linkPaths = require './link-paths'
FS = require 'fs'
ssh2 = require 'ssh2'
_ = require 'underscore-plus'
Path = require 'path'
remote_sync = require './remote_sync_index'
logger = require './Logger'
path = require "path"
Host = null
luafuncregex =/^((\s*function)|(\s*local\s*function))\s*\w*\s*\(.*\)\s*(\s*|\w*|.)*end/
luaFunclineRegexp = /function\s*\w*\s*\(.*\)/g
luaFuncNameRegexp =/function\b\s+?(\w+)\s*/

module.exports =
  config:
    hostPort:
      type: 'integer'
      default: 8011
      description: 'hostPort'
    hostIP:
      type: 'string'
      default: "192.168.3.119"
      description: 'hostIP'
    userName :
      type:'string'
      default: "my ssh name"
    password:
      type:'string'
      default:"password"
    privateKey:
      type:'string'
      default:"/Users/liangqingfeng/.ssh"
    remoteDirectory:
      type:'string'
      default:"/home"
    configFileName:
      type: 'string'
      default: '.remote-sync.json'



  subscriptions: null
  client:null
  hostIP:null
  hostPort:null

  activate: (state) ->
          # remote_sync.init()
          @subscriptions = new CompositeDisposable
          @subscriptions.add atom.commands.add( 'atom-workspace',{
            'lua-remote-editor:command': => @command()
            'lua-remote-editor:connect': => @connect()
            'lua-remote-editor:clearlog': => @clearlog()
            'lua-remote-editor:clearlog': => @clearlog()
            'lua-remote-editor:clearlog': => @clearlog()
            'lua-remote-editor:trace': => @trace()
          })



          remote = new remote_sync(@subscriptions)


  connect: ->
      console.log "connect"
      if  @client?
        @client.end()
        @client = null
      Host ?= require './model/host'

      configPath = path.join( atom.project.getPaths()[0],atom.config.get("lua-remote-editor.configFileName"))
      host= new Host(configPath)
      @client = Socket()
      @client.connect(host.serverport,host.hostname)
      @client.on("data", (info)=> @onData(info) )
      @client.on("error",(info) => @onSocketError(info))
      @client.on("connect",(info) => @onConnectSuccess(info))
      @client.on("close", (info) => @onClose(info))
      logger.getLogger().log("connecting to ip:#{host.hostname} port:#{host.serverport}")



  onSocketError: (error) ->
    logger.getLogger().error("onSocketError"+error)

  onConnectSuccess:(info) ->
      @injectluacode()
      logger.getLogger().log("onConnectSuccess:\t")

  onClose:(info) ->
      logger.getLogger().error("onClose:\t"+info)


  onData: (data)->
    data = data+ '\0'
    data = linkPaths(data)
    logger.getLogger().log(data)

  deactivate: ->
    @subscriptions.dispose()
    @ssh2Connect.end()
    @editorsSubscription.dispose()



  serialize: ->




  injectluacode: ->
    FS.readFile( __dirname+'/../luacode/trace.lua', 'utf8',(err, contents) =>
                if err
                  logger.getLogger().log(err)
                else
                  str = contents.toString()
                  str= str + ';'
                  puleCode = str.replace(/--.*/g,"")
                  @client.write(puleCode)
              )



  clearlog: ->


  command:() ->
    editor=atom.workspace.getActiveTextEditor()
    str= editor.getSelectedText()
    str= str + ';'
    @client.write(str)

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

  update: ->
    editor=atom.workspace.getActiveTextEditor()
    title = editor.getTitle()
    selected= editor.getSelectedText()
    console.log selected.length
    modeName = title.match(/\w*/)[0]
    filePath= editor.getPath()
    path = filePath.replace(atom.project.getPaths(),".")
    FS.readFile( filePath, 'utf8',(err, contents) =>
                if err
                  @show(err)
                else
                  console.log contents
                  FS.writeFile(filePath, contents)
                  # str = contents.toString()
                  # str = str+'\r'
                  # console.log(str.length)
                  # puleCode =  "file = io.open('"+path+"','w')\n"+
                  #             "local str ='"+str+"'"+
                  #            "print(file:write(str))"+
                  #             "file:close()"+
                  #             "print('update lua file success',str)"
                  #             # '_G["update_'+modeName+'"] = require("'+modeName+'")'+ 'G_unload_module("'+modeName+'");'
                  # puleCode = puleCode+';'
                  # @show(puleCode)
                  # console.log(puleCode.length)
                  puleCode = 'print("'+contents+'");'
                  @client.write(puleCode)

                  # console.log puleCode


              )
