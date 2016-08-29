clone = require("./Utilities.js").clone
events = require('events')
Q = require('q')
logger = require('winston')
_ = require('lodash')
uuid = require('node-uuid')

ContextParticipant = require("./ContextParticipant.js").ContextParticipant
ContextParticipantProxy = require("./ContextParticipant.js").ContextParticipantProxy


#
# The ContextManager (CM) is used to control the overall flow of context changes. 
#
class ContextManager extends events.EventEmitter

  # Constructor saves *context* which this CM is responsible for and optionally a *notifier* which is expected to be a function which will be invoked when there are notifications. This is expected to be used in e.g. a websocket notifier.
  constructor: (@context, @notifier) ->


  # A "dispatcher" which can invoke methods and map arguments.
  InvokeAndMapArguments: (method, args) ->
    switch method
      when "JoinCommonContext" then @JoinCommonContext(args.applicationName, args.contextParticipant)
      when "LeaveCommonContext" then @LeaveCommonContext(args.participantCoupon)
      when "StartContextChanges" then @StartContextChanges(args.participantCoupon)
      when "EndContextChanges" then @EndContextChanges(args.contextCoupon)
      when "PublishChangesDecision" then @PublishChangesDecision(args.contextCoupon, args.decision)
      when "GetMostRecentContextCoupon" then @GetMostRecentContextCoupon()
      else throw { msg: "No such method '#{method}' on ContextManager" }

  ###

  ###
  JoinCommonContext: (applicationName, contextParticipant) -> 
    logger.info "app name = #{applicationName}"
    if not applicationName? then throw { type: "MissingArg", msg: "'applicationName' is mandatory for JoinCommonContext"}
    
    logger.info "creating participant"

    # create participant
    participant = 
      if contextParticipant? 
        new ContextParticipantProxy(uuid.v4(), applicationName, contextParticipant)
      else
        new ContextParticipant(uuid.v4(), applicationName)
  
    # if the participant is already present use the saved participant
    participantInContext = _.find(@context.participants, (p) -> p.applicationName is participant.applicationName and p.url is participant.url)
    if not participantInContext? 
      # save participant in context
      @context.participants.push(participant)
    else
      # participant was already present, use existing
      participant = participantInContext
  
    logger.info "returning coupon = #{participant.coupon}"
    # return participant coupon
    participant.coupon


  LeaveCommonContext: (participantCoupon) ->
    if not participantCoupon? then throw { type: "MissingArg", msg: "'participantCoupon' is mandatory for LeaveCommonContext"}
    @context.participants = _.reject(@context.participants, (p) -> p.coupon is participantCoupon)
    logger.info "#{participantCoupon} left context, current participants are now: #{_.pluck(@context.participants, "coupon")}"

  StartContextChanges: (participantCoupon) -> 
    contextCoupon = uuid.v4()
    context = 
      items: clone(@context.items)
      active: true
      coupon: contextCoupon
      owner: participantCoupon

    @context.sessions[contextCoupon] = context 
    return contextCoupon

  EndContextChanges: (contextCoupon) -> 
    if not @context.sessions[contextCoupon]?
      throw new { status: 501, msg: "No such context #{contextCoupon}"}

    @context.sessions[contextCoupon].active = false

    logger.debug @notifier

    # invoke builtin notifier
    @notifier?(
      target:
        interface: "ContextParticipant"
        method: "ContextChangesPending"
      args:
        contextCoupon: contextCoupon
    )

    # call ContextChangesPending on all ContextParticipants
    responses = (participant.ContextChangesPending(contextCoupon) for participant in @context.participants when participant.coupon isnt @context.sessions[contextCoupon]?.owner)

    defer = Q.defer()

    if responses.length > 0
      Q.allResolved(responses)
      .then(
        (promises) ->
          result = 
            noContinue: false
            responses: ((if promise.valueOf? then promise.valueOf() else promise) for promise in promises)
          defer.resolve(result)
      )
    else
      # resolve w no responses
      defer.resolve({ noContinue: false, responses: []})

    return defer.promise

  PublishChangesDecision: (contextCoupon, decision) -> 
    context = @context.sessions[contextCoupon]
    delete @context.sessions[contextCoupon]

    accepted = decision?.toLowerCase() is "accept"

    # commit actions
    # save latest context coupon
    @context.latestContextCoupon = contextCoupon
    # copy items to base context
    @context.items = context.items

    # invoke builtin notifier
    @notifier?(
      target:
        interface: "ContextParticipant"
        method: if accepted then "ContextChangesAccepted" else "ContextChangesCancelled"
      args:
        contextCoupon: contextCoupon || ""
    )
    # call ContextChangesAccepted/Cancelled on all ContextParticipants
    ((if accepted then participant.ContextChangesAccepted(contextCoupon || "") else participant.ContextChangesCancelled(contextCoupon || "")) for participant in @context.participants when participant.coupon isnt context?.owner)
    return

  GetMostRecentContextCoupon: () -> @context.latestContextCoupon

exports.ContextManager = ContextManager
