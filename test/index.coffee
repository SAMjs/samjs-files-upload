chai = require "chai"
should = chai.should()
requireAny = require "try-require-multiple"
Samjs = requireAny "samjs/src", "samjs"
SamjsClient = requireAny "samjs/client-src", "samjs/client"
plugin = require "../src"
pluginClient = require "../client-src"

port = 3080
url = "http://localhost:"+port+"/"
testConfigFile = "test/testConfig.json"

describe "samjs", =>
  describe "plugin", =>
    samjs = samjsClient = null
    after =>
      samjs.shutdown()
      samjsClient.close()
    it "should startup", =>
      samjs = new Samjs
        plugins: plugin
        options: config: testConfigFile
        models:
          name: "testFile"
          db: "files"
          files: "testFile"
      samjs.finished.then (io) => io.listen(port)
    it "should connect", =>
      samjsClient = new SamjsClient
        plugins: [pluginClient]
        url: url
        io: reconnection:false
      samjsClient.finished