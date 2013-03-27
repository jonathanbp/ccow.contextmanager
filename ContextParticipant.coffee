url = require('url')
Q = require('q')
formatter = require('./Utilities.js').formatter
winston = require 'winston'

class ContextParticipant

  constructor: (@coupon,@applicationName) ->

  ContextChangesPending: (contextCoupon) ->
    @log("ContextChangesPending (accept'ed)")
    # return decision => accept|conditionally_accept, reason (empty if accept)
    return { decision: "accept", reason: "" }

  ContextChangesAccepted: (contextCoupon) ->
    @log("ContextChangesAccepted(#{contextCoupon})")

  ContextChangesCancelled: (contextCoupon) ->
    @log("ContextChangesCancelled(#{contextCoupon})")

  CommonContextTerminated: () ->
    @log("CommonContextTerminated")

  Ping: () -> 
    @log("Ping. Pong.")
    "Pong"

  log: (msg) ->
    #winston.info("#{@applicationName} (#{@coupon}) -> #{msg}")

class ContextParticipantProxy extends ContextParticipant

  constructor: (@coupon,@applicationName,@url,@http = require("http")) ->

  ContextChangesAccepted: (contextCoupon) ->
    @get("ContextChangesAccepted", contextCoupon)

  ContextChangesCancelled: (contextCoupon) ->
    @get("ContextChangesCancelled", contextCoupon)

  CommonContextTerminated: (contextCoupon) ->
    @get("CommonContextTerminated", contextCoupon)

  # this returns a promise
  ContextChangesPending: (contextCoupon) ->
    @get("ContextChangesPending", contextCoupon)

  get: (method, contextCoupon) ->
    # send request to callback url and return reply
    @log("ContextChangesPending(#{contextCoupon}) -- proxying to #{@url}")
    deferred = Q.defer()
    @http.get("#{@url}/ContextParticipant/#{method}?contextCoupon=#{contextCoupon}", (res) =>
      chunks = ""
      res.on("data", (chunk) -> chunks += chunk)
      res.on("end", () =>
        response = formatter.parseObject(chunks) 
        @log("received response '#{chunks}' parsed into '#{response}'")
        deferred.resolve(response)
      )
    ).on("error", (e) => 
      @log("received error #{e}")
      deferred.resolve({ decision: "error", reason: "Could not contact '#{@applicationName}' at '#{@url}'."}) 
    )

    # return promise
    deferred.promise

exports.ContextParticipant = ContextParticipant
exports.ContextParticipantProxy = ContextParticipantProxy