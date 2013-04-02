should = require('should')
clone = require("../Utilities.js").clone
winston = require 'winston'

ContextData = require('../ContextData.js').ContextData

context = new ContextData("TestContext")
try
  # Initialization
  should.exist(context)
  context.items.should.exist
  context.participants.should.be.empty
  context.sessions.should.exist
  context.GetItemNames().should.be.empty
  
  context.GetItemValues("", ["nonexistingname", "anothermadeupname"]).should.have.eql [undefined,undefined]
  try 
    context.SetItemValues("idontexist", ["a"], [1])
    should.fail
  catch err
    winston.error err?.msg || err
    should.not.fail
  
  # add participant
  context.participants.push({coupon:"p1"})
  context.SetItemValues("p1", ["a"], [1]).should.have.property("a",1)
  context.GetItemValues("p1", ["a","madeupname"]).should.eql([1,undefined])
  items = context.SetItemValues("p1", ["b","c"], [2,3])
  items.should.have.property("b",2)
  items.should.have.property("c",3)
  context.GetItemValues("p1", ["a","b","c"]).should.eql([1,2,3])
  
  # now with a context coupon
  context.sessions["c1"] = { items: clone(items) }
  context.SetItemValues("p1", ["a"], [1], "c1").should.have.property("a",1)
  context.GetItemValues("p1", ["a"], "c1").should.eql([1])
  items = context.SetItemValues("p1", ["b","c"], [20,30], "c1")
  items.should.have.property("b",20)
  items.should.have.property("c",30)
  context.GetItemValues("p1", ["a","b","c"], "c1").should.eql([1,20,30])
  context.GetItemValues("p1", ["a","b","c"]).should.eql([1,2,3])


catch err
  console.log err
