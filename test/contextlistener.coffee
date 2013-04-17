io = require('socket.io-client')
prompt = require("prompt")


socket = io.connect("http://localhost:3000")

socket.on('connect', () -> console.log("connected"))
socket.on('message', (msg) -> console.log("message: ", msg))
socket.on('disconnect', () -> console.log("disconnect"))


prompt.message = "# "
prompt.delimiter = ""
prompt.start()
prompt.get("Any key to exit?", () -> {})