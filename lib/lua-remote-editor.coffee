
{CompositeDisposable} = require 'atom'
remote_sync = require './remote_sync_index'
logger = require './Logger'
ServerConnect =require './server_connect/server_connect'




module.exports =
  config:
    configFileName:
      type: 'string'
      default: '.remote-sync.json'



  subscriptions: null



  activate: (state) ->
          @subscriptions = new CompositeDisposable
          @subscriptions.add atom.commands.add( 'atom-workspace',{
            'lua-remote-editor:clearlog': => @clearlog()
          })
          remote = new remote_sync(@subscriptions)
          @connect = new ServerConnect(@subscriptions)
    

  deactivate: ->
    @subscriptions.dispose()
    @connect.clear()



  serialize: ->




  clearlog: ->
    logger.getLogger().clearlog()



  # update: ->
  #   editor=atom.workspace.getActiveTextEditor()
  #   title = editor.getTitle()
  #   selected= editor.getSelectedText()
  #   console.log selected.length
  #   modeName = title.match(/\w*/)[0]
  #   filePath= editor.getPath()
  #   path = filePath.replace(atom.project.getPaths(),".")
  #   FS.readFile( filePath, 'utf8',(err, contents) =>
  #               if err
  #                 @show(err)
  #               else
  #                 console.log contents
  #                 FS.writeFile(filePath, contents)
  #                 # str = contents.toString()
  #                 # str = str+'\r'
  #                 # console.log(str.length)
  #                 # puleCode =  "file = io.open('"+path+"','w')\n"+
  #                 #             "local str ='"+str+"'"+
  #                 #            "print(file:write(str))"+
  #                 #             "file:close()"+
  #                 #             "print('update lua file success',str)"
  #                 #             # '_G["update_'+modeName+'"] = require("'+modeName+'")'+ 'G_unload_module("'+modeName+'");'
  #                 # puleCode = puleCode+';'
  #                 # @show(puleCode)
  #                 # console.log(puleCode.length)
  #                 puleCode = 'print("'+contents+'");'
  #                 @client.write(puleCode)
  #
  #                 # console.log puleCode
  #
  #
  #             )
