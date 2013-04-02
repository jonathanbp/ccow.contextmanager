should = require('should')
clone = require("../Utilities.js").clone

ContextData = require('../ContextData.js').ContextData
ContextManager = require('../ContextManager.js').ContextManager

describe 'ContextManager', ->
  it 'should workd', (done) -> 

    context = new ContextData("TestContext")
    cm = new ContextManager(context)
    
    cm.should.exist
    
    
    
    participantCoupon = cm.JoinCommonContext("test")
    # verify that participant is properly added to context
    should.exist(participantCoupon)
    context.participants.should.have.length(1)
    context.participants[0].should.have.property("coupon",participantCoupon)
    contextCoupon = cm.StartContextChanges(participantCoupon)
    should.exist(contextCoupon)
    context.SetItemValues(participantCoupon, ["a","b"], [1, 2], contextCoupon)
    
    cm.EndContextChanges(contextCoupon)
    .then(
      (result) ->
        result.responses.should.be.empty
        done()
    )
    
    cm.PublishChangesDecision(contextCoupon, "accept")
    context.GetItemValues(participantCoupon, ["a","b"]).should.eql([1,2])
    cm.LeaveCommonContext(participantCoupon)
    context.participants.should.have.length(0)

