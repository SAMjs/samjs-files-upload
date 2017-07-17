
devServer = require "ceri-dev-server"
testConfigFile = "test/testConfig.json"
koa = devServer(koa:true)
module.exports = (server) =>
  server.on("request", koa.callback())
  requireAny = require "try-require-multiple"
  Samjs = requireAny "samjs/src", "samjs"
  samjsFiles = requireAny "samjs-files/src", "samjs-files"
  samjsFilesUpload = require "./src"
  samjs = new Samjs
    plugins: [samjsFiles,samjsFilesUpload]
    options: config: testConfigFile
    models:
      name: "tmp"
      db: "files"
      folders: "tmp"
      plugins: ["upload"]
    startup: server
  samjs.finished.then => samjs.listen(port:8080)
  return => samjs.reset()