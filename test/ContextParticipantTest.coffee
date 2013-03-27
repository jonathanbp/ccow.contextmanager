should = require('should')
clone = require("../Utilities.js").clone
events = require("events")


ContextParticipant = require('../ContextParticipant.js').ContextParticipant
ContextParticipantProxy = require('../ContextParticipant.js').ContextParticipantProxy


class TestResource extends events.EventEmitter

  data: (s, delay = 500) =>
    setTimeout(
      =>
        @emit("data", s)
        @emit("end")
      delay
    )


class TestHttp extends events.EventEmitter

  constructor: ->
    @urlsInvoked = []

  get: (url, callback) ->

    @urlsInvoked.push url

    res = new TestResource()

    callback(res)
    res.data("decision=accept&reason=all good")

    # return this
    @

cp = new ContextParticipant("coupon#1", "application#1")

describe "ContextParticipant", ->
  describe "ContextChangesPending", ->
    it "should return an object w properties decision and reason", ->
      result = cp.ContextChangesPending("coupon#3")
      result.should.have.property("decision")
      result.should.have.property("reason")
  describe "ContextChangesAccepted", ->
    it "should't do anything interesting", ->
      cp.ContextChangesAccepted("coupon#3")
  describe "ContextChangesCancelled", ->
    it "should't do anything interesting", ->
      cp.ContextChangesCancelled("coupon#3")
  describe "CommonContextTerminated", ->
    it "should't do anything interesting", ->
      cp.CommonContextTerminated()


# PROXY

describe "ContextParticipantProxy", ->
  describe "ContextChangesPending", ->
    it "should GET the correct url", (done) -> 
      http = new TestHttp()
      cpp = new ContextParticipantProxy("coupon#2", "application#1", "http://test", http)
      result = cpp.ContextChangesPending("coupon#3")

      result.then (v) -> 
        should.exist v
        v.should.have.property("decision","accept")
        done()
      
      http.urlsInvoked.should.have.length(1)
      http.urlsInvoked.should.match(/ContextParticipant\/ContextChangesPending/)

  describe "ContextChangesAccepted", ->
    it "should GET the correct url", (done) -> 
      http = new TestHttp()
      cpp = new ContextParticipantProxy("coupon#2", "application#1", "http://test", http)

      result = cpp.ContextChangesAccepted("coupon#3")

      result.then (v) -> 
        should.exist v
        done()
      
      http.urlsInvoked.should.have.length(1)
      http.urlsInvoked.should.match(/ContextParticipant\/ContextChangesAccepted/)


  describe "ContextChangesCancelled", ->
    it "should GET the correct url", (done) -> 
      http = new TestHttp()
      cpp = new ContextParticipantProxy("coupon#2", "application#1", "http://test", http)

      result = cpp.ContextChangesCancelled("coupon#3")

      result.then (v) -> 
        should.exist v
        done()
      
      http.urlsInvoked.should.have.length(1)
      http.urlsInvoked.should.match(/ContextParticipant\/ContextChangesCancelled/)
  describe "CommonContextTerminated", ->
    it "should GET the correct url", (done) -> 
      http = new TestHttp()
      cpp = new ContextParticipantProxy("coupon#2", "application#1", "http://test", http)

      result = cpp.CommonContextTerminated("coupon#3")

      result.then (v) -> 
        should.exist v
        done()
      
      http.urlsInvoked.should.have.length(1)
      http.urlsInvoked.should.match(/ContextParticipant\/CommonContextTerminated/)


