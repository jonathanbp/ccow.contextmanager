events = require('events')
logger = require('winston')

class ContextData extends events.EventEmitter

  constructor: (@name, @participants, @items) ->
    @_ = require('underscore')  
    @participants ||= []
    @items ||= {}
    @sessions = {}

  InvokeAndMapArguments: (method, args) ->
    switch method
      when "GetItemNames" then @GetItemNames(args.contextCoupon)
      when "GetItemValues" then @GetItemValues(args.participantCoupon, args.itemNames.split("|"), args.contextCoupon, (args.onlyChanges?.toLowerCase() is 'true'))
      when "SetItemValues" then @SetItemValues(args.participantCoupon, args.itemNames.split("|"), args.itemValues.split("|"), args.contextCoupon)

      else throw { msg: "No such method '#{method}' on Context" }


  GetItemNames: (contextCoupon) => 
    items = @sessions[contextCoupon]?.items || @items
    @_.keys(items)

  GetItemValues: (participantCoupon, itemNames, contextCoupon, onlyChanges) => 
    if onlyChanges then throw { msg: "'onlyChanges' argument to GetItemValues with value true not currently supported", status: 501 }
    items = @sessions[contextCoupon]?.items || @items
    # do not remove null values
    @_.map(itemNames, (name) -> items[name])

  SetItemValues: (participantCoupon, itemNames, itemValues, contextCoupon) => 
    items = @sessions[contextCoupon]?.items || @items

    # ensure all required parameters are set
    if not (itemNames? and itemValues? and participantCoupon?) 
      throw { msg: "Required arguments for 'SetItemValues' are 'itemNames','itemValues' and 'participantCoupon'" }
    
    # check that participant is present in context
    if not @_.any(@participants,(p)->p.coupon is participantCoupon)
      throw { msg: "No such participant '#{participantCoupon}'"}

    # updated all itemValues referred to in itemNames
    for i in [0..(itemNames.length-1)]
      do (i) =>
        logger.info "updating #{itemNames[i]} with #{itemValues[i]}"
        items[itemNames[i]] = itemValues[i]
    
    # emit updated event
    @emit("updated", this, itemNames, itemValues, participantCoupon)

    # return current items
    items

exports.ContextData = ContextData