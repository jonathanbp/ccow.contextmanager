should = require('should')
f = require("../Utilities.js").formatter

Q = require('q')

should.exist(f)

obj = { a: 1, b: "two", c: true, d: [10,20,30]}
sobj = f.generateObject(obj)
obj2 = f.parseObject(sobj)

obj2.should.have.property("a",obj.a.toString())
obj2.should.have.property("b",obj.b.toString())
obj2.should.have.property("c")
obj2.d.should.have.length(3)
for i in [0..2]
  do (i) ->
    obj2.d[i].should.eql(obj.d[i].toString())



delay = (ms) ->
    deferred = Q.defer()
    setTimeout((()->deferred.resolve("done")), ms)
    deferred.promise


Q.all(delay(2000)).then(console.log)