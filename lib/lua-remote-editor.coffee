
{CompositeDisposable} = require 'atom'
{MessagePanelView} = require 'atom-message-panel'
SpacePen = require "space-pen"
{Socket} = require "net"
linkPaths = require './link-paths'

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
          console.log "fasdfafasdfasdfs"
          @subscriptions = new CompositeDisposable
          @subscriptions.add atom.commands.add 'atom-workspace', 'lua-remote-editor:command': => @command()
          @subscriptions.add atom.commands.add 'atom-workspace', 'lua-remote-editor:connect': => @connect()
          @subscriptions.add atom.commands.add 'atom-workspace', 'lua-remote-editor:goto': => @goto()

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
  #     @messages.add SpacePen.View ->
  #           @div =>
  #             @h1 "Spacecraft"
  #             @ol =>
  #               @li click: 'launchSpacecraft', "Saturn V"
  #
  # launchSpacecraft: (event, element) ->
  #   console.log "Preparing #{element.name} for launch!"


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

# print("fsadf")

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
    # console.log str

 #
 # updateFunc: ->
 #   editor=atom.workspace.getActiveTextEditor()
 #   str= editor.getSelectedText()
 #   title = editor.getTitle()
 #      #  取出模块名，/^.*\s*function\s*(\w+):(\w+).*$/\2/f/"
 #      #  取出函数名





  goto: (path) ->
    console.log "goto"
    # 行数是0开始的所以显示的行数
    editor=atom.workspace.getActiveTextEditor()
    item = atom.workspace.getActivePaneItem()
    str = item.getSelectedText()
    console.log item
    console.log str
    console.log editor
    # new_editor = atom.workspace.open("./lua/tools/protobuf.lua")
    # editor=atom.workspace.getActiveTextEditor()
    # str= editor.getSelectedText()
    # console.log  str
    # editor.setCursorBufferPosition([0,0],{autoscroll:true})
    # editor.scrollToBufferPosition([1, 2], center: true)
