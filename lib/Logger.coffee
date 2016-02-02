PlainMessageView = null

LoggerInstance = null

linkPaths = require './link-paths'

class Logger
  constructor: (@title) ->

  showInPanel: (message, className) ->
    if not @panel
      {MessagePanelView, PlainMessageView} = require "atom-message-panel"
      @panel = new MessagePanelView
        title: @title
      linkPaths.listen(@panel)

    @panel.attach()if @panel.parents('html').length == 0

    msg = new PlainMessageView
      message: message
      className: className

    @panel.add msg

    @panel.setSummary
      summary: message
      className: className

    @panel.body.scrollTop(1e10)
    msg

  log: (message) ->
    date = new Date
    startTime = date.getTime()
    message = "[#{date.toLocaleTimeString()}] #{message}"
    if atom.config.get("lua-remote-editor.logToConsole")
      console.log message
      ()->
        console.log "#{message} Complete (#{Date.now() - startTime}ms)"
    else
      msg = @showInPanel message, "text-info"
      ()=>
          endMsg = " Complete (#{Date.now() - startTime}ms)"
          msg.append endMsg
          @panel.setSummary
            summary: "#{message} #{endMsg}"
            className: "text-info"


  info: (message)->
      if not @panel
        {MessagePanelView, PlainMessageView} = require "atom-message-panel"
        @panel = new MessagePanelView
          title: @title
        linkPaths.listen(@panel)
      message = linkPaths(message)
      @panel.attach()# if @panel.parents('html').length == 0
      SpacePen = require 'space-pen'
      msg = new SpacePen.$$ ->
         @pre class: "text-info",=>
          @raw  message

      # msg = new PlainMessageView
      #   message: message
      #   className: className

      @panel.add msg
  error: (message) ->
    @showInPanel "#{message}","text-error"


  clearlog: ->
    if @panel?
      @panel.clear()



module.exports =
  getLogger: ->
      if not LoggerInstance
        LoggerInstance = new Logger "Remote Sync"
      return LoggerInstance

  create:(title) ->
    return new Logger(title)
