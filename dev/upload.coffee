createView = require "ceri-dev-server/lib/createView"
Samjs  = require "samjs"
samjsFiles = require "samjs-files"
samjsFilesUpload = require "../client-src"
samjs = new Samjs
  plugins: [samjsFiles, samjsFilesUpload]
model = samjs.model("tmp")
module.exports = createView
  structure: template 1, """
    <input type="file" @change="onUpload"></input>
  """
  methods:
    onUpload: ({target}) ->
      file = target.files[0]
      model.upload(filename:model.prependFolder(file.name), file:file, onProgress: console.log.bind(console))