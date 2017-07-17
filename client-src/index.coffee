chunksize = 1024*1024
plugin = ->
plugin.model = (model, type) ->
  if type == "files"
    model.upload = ({filename, file, onProgress}) ->
      abort = null
      _id = null
      filename ?= file.name
      finished = new model.samjs.Promise (resolve, reject) ->
        abort = -> model.getter("upload-abort", _id).then(reject).catch(reject)
        model.getter("upload", filename)
        .then (id) ->
            _id = id
            reader = new FileReader
            reader.onabort = abort
            position = 0
            percent = 0
            size = file.size
            getSlice = -> file.slice(position,Math.min(position += chunksize,size));
            isFinished = -> position >= size
            reader.onload = ->
              model.getter("upload-chunk", id:id, chunk: reader.result)
              .then ->
                if (newPercent = position/size*100) - percent > 5
                  onProgress(Math.min(100,Math.round(newPercent)))
                  percent = newPercent
                unless isFinished()
                  reader.readAsArrayBuffer(getSlice()) 
                else
                  model.getter("upload-end", id)
                  .then ->
                    onProgress(100)
                    resolve()
                  .catch(reject)
              
            reader.readAsArrayBuffer(getSlice())
            
      return abort: abort, finished: finished

module.exports = plugin
