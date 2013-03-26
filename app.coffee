#!/usr/bin/env coffee

app = require('express')()
server = require('http').createServer(app)
io = require('socket.io').listen(server)
_ = require('underscore')
# Q is awesome beyond belief
Q = require('q')
Util = require('./Utilities.js')
logger = require('winston')

ContextData = require('./ContextData.js').ContextData
ContextManager = require('./ContextManager.js').ContextManager


defaultcontext = new ContextData("default")
defaultcontext.on("updated",()->logger.debug("UPDATED!"))
defaultcontextmanager = new ContextManager(defaultcontext, (msg) -> io.sockets.emit("message", msg))

interfaces =
  contextdata: defaultcontext
  contextmanager: defaultcontextmanager


# Handler for /<interface>/<method> request
app.get('/:interface/:method', (req, res) ->
  ifc = interfaces[req.param('interface').toLowerCase()]

  logger.info "Invoking '#{req.param('method')}' on '#{req.param('interface')}'"

  Q.all(ifc.InvokeAndMapArguments(req.param('method'), req.query))
  .then((result) -> 
      Util.reply(req, res, result)
  ).fail((err) -> 
      logger.error err
      Util.reply(req, res, err)
  )
)

# Handler for /<interface>?method=<method> requests
app.get('/:interface', (req, res) -> 
  ifc = interfaces[req.param('interface').toLowerCase()]

  if not ifc? 
    logger.log "No such interface #{req.param('interface')}."
    res.status(500).send("No such interface #{req.param('interface')}.")
    return


  if not req.query.method? 
    logger.log "Missing 'method' query param"
    res.status(500).send("Missing 'method' query param")
    return

  logger.info "Invoking '#{req.query.method} on #{req.param('interface')}'"

  Q.all(ifc.InvokeAndMapArgubbments(req.query.method, req.query))
  .then((result) -> 
      Util.reply(req, res, result)
  ).fail((err) -> 
      console.error err
      Util.reply(req, res, err)
  )
)

# Handler for /?interface=<interface>&method=<method> requests
app.get('/', (req, res) -> 
  if not (req.query.method? or req.query.interface?)
    logger.warn "Missing 'method' or 'interface' query param"
    res.status(500).send("Missing 'method' or 'interface' query param")
    return

  logger.info "Invoking '#{req.query.method} on #{req.query.interface}'"

  ifc = interfaces[req.query.interface.toLowerCase()]

  Q.all(ifc.InvokeAndMapArguments(req.query.method, req.query))
  .then((result) -> 
      Util.reply(req, res, result)
  ).fail((err) -> 
      logger.error err
      Util.reply(req, res, err)
  )
)


# Start application
server.listen(3000)
console.log('Listening on port 3000')