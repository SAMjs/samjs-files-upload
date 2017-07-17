crypto = require "crypto"
hash = (name) => crypto.createHash("md5").update(name).digest("hex")
lookup = {}
getFileStream = (model, o) =>
    o.file = await model.getFile o.path
    await model.before.write(o)
    if o.file.isNew
      await model.before.insert(o)
    else
      await model.before.update(o)
    o.stream = model.samjs.fs.createWriteStream o.file.fullpath
    o.end = =>
      clearTimeout o.timeoutObj if o.timeoutObj?
      delete lookup[o.hash]
      new model.samjs.Promise (resolve) => o.stream.end(null,null,resolve)
    o.abort = abortUpload.bind(null, model, o)
    o.hash = hash(o.file.fullpath)
    o.resetTimeout = => 
      clearTimeout o.timeoutObj if o.timeoutObj?
      o.timeoutObj = setTimeout o.abort, 10000
    o.resetTimeout()
    lookup[o.hash] = o
    return o

abortUpload = (model, o) =>
  await o.end()
  await model.samjs.fs.remove o.file.fullpath

finishUpload = (model, o) =>
  await o.end()
  if o.file.isNew
    await model.after.insert(o)
  else
    await model.after.update(o)
  o.file.isNew = false
  await model.after.write(o)

listener = (model, socket) =>
  socket.on "upload", (request, cb) =>
    getFileStream model, path: request, socket: socket
    .then ({hash}) => success: true, content: hash
    .catch (err)   =>
      console.log err
      success: false, content: err.message
    .then cb
  socket.on "upload-chunk", (request, cb) =>
    if (o = lookup[request.id])?
      o.resetTimeout()
      if not o.stream.write(new Buffer(request.chunk))
        o.stream.once "drain", =>
          cb(success: true)
      else
        cb(success: true)
    else
      cb(success: false, content: "not found")
  socket.on "upload-abort", (request, cb) =>
    if (o = lookup[request])?
      await o.abort()
      cb(success: true)
    else
      cb(success: false, content: "not found")
  socket.on "upload-end", (request, cb) =>
    if (o = lookup[request])?
      await finishUpload(model, o)
      cb(success: true)
    else
      cb(success: false, content: "not found")

module.exports = (samjs) =>
  samjs.after.models.call
    prio: samjs.prio.POST_PROCESS
    hook: (models) =>
      for name, model of models
        if model.db == "files" and ~model.plugins.indexOf("upload")
          model.after.listen.call
            prio: samjs.prio.HOOK_INTERFACE
            hook: listener.bind null, model