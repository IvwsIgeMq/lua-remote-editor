
{CompositeDisposable} = require 'atom'
{MessagePanelView} = require 'atom-message-panel'
SpacePen = require "space-pen"
{Socket} = require "net"
linkPaths = require './link-paths'
FS = require 'fs'
ssh2 = require 'ssh2'
_ = require 'underscore-plus'

luafuncregex =/^((\s*function)|(\s*local\s*function))\s*\w*\s*\(.*\)\s*(\s*|\w*|.)*end/
luaFunclineRegexp = /function\s*\w*\s*\(.*\)/g
luaFuncNameRegexp =/function\b\s+?(\w+)\s*/




class LuaRemoteEditor
  subscriptions: null
  client:null
  messages:null
  ssh2Connect:null
  ssh2SFTP:null


  constructor: ->
          @subscriptions = new CompositeDisposable
          @subscriptions.add atom.commands.add 'atom-workspace', 'lua-remote-editor:command': => @command()
          @subscriptions.add atom.commands.add 'atom-workspace', 'lua-remote-editor:connect': => @connect()
          @subscriptions.add atom.commands.add 'atom-workspace', 'lua-remote-editor:update': => @updateFile()
          @subscriptions.add atom.commands.add 'atom-workspace', 'lua-remote-editor:clearlog': => @clearlog()
          @subscriptions.add atom.commands.add 'atom-workspace', 'lua-remote-editor:trace': => @trace()

          if not @messages?
            @messages = new MessagePanelView
                  title: atom.config.get("lua-remote-editor.hostIP")
            @messages.attach()
            console.log "new message"
            linkPaths.listen(@messages)
          @connect()

  connect: ->
      console.log "connect"
      if  @client?
        @client.end()
        @client = null

      if @ssh2Connect?
        @ssh2Connect.end()
        @ssh2Connect =null
        @ssh2SFTP.end()
        @ssh2SFTP = null

      @ssh2Connect = new ssh2()
      @ssh2Connect.on('ready',() =>
        console.log 'Client ready'
        @ssh2Connect.sftp((err,sftp)=>
          if err?
              throw err
          @ssh2SFTP = sftp
          console.log "sftp connect success "
        )
      )
      @ssh2Connect.connect({
          host: atom.config.get("lua-remote-editor.hostIP"),
          port: 22,
          username: atom.config.get("lua-remote-editor.userName"),
          privateKey: FS.readFileSync(atom.config.get( "lua-remote-editor.privateKey"))
        })

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
    @ssh2Connect.end()


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


  updateFile: ->
    editor=atom.workspace.getActiveTextEditor()
    remotePath = atom.config.get("lua-remote-editor.remoteDirectory")
    localPath = editor.getPath()
    remotePath = remotePath+atom.project.relativizePath(localPath)
    console.log remotePath,localPath,atom.project.getPaths()[0]
    # @ssh2SFTP.fastPut(editor.getPath(),remotePath+)



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
    console.log(str.length)


    atom.d
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


exports = new LuaRemoteEditor
