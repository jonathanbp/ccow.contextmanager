_ = require('underscore')

# basic utilities
clone = (obj) ->
  if not obj? or typeof obj isnt 'object'
    return obj

  if obj instanceof Date
    return new Date(obj.getTime()) 

  if obj instanceof RegExp
    flags = ''
    flags += 'g' if obj.global?
    flags += 'i' if obj.ignoreCase?
    flags += 'm' if obj.multiline?
    flags += 'y' if obj.sticky?
    return new RegExp(obj.source, flags) 

  newInstance = new obj.constructor()

  for key of obj
    newInstance[key] = clone obj[key]

  return newInstance

# super class for all datatypes
class Format

  parseHAP: (hap) -> hap.split("^")
  generateHAP: (hap) -> hap.join("^")
  parseList: (list) -> list.split("|")
  generateList: (list) -> list.join("|")
  parseObject: (obj) -> 
    # if it is a basic type simply return
    if obj.indexOf("^") + obj.indexOf("|") + obj.indexOf("&") < 0 then return obj
    # if compoun object, i.e. key1=value1&key2=value2 ...
    if obj.indexOf("&") > 0
      kvs = obj.split("&")
      _.reduce(
        kvs, 
        ((memo, kv) =>
          [key, value] = kv.split("=")
          memo[key] = @parseObject(value)
          memo
        ),
        {}
      )
    # if piped list, e.g. a|b|c
    else if obj.indexOf("|") > 0
      @parseList(obj)
    # if hatted, e.g. a^b^b
    else 
      @parseHAP(obj)

  generateObject: (obj) ->
    # primitive type then to string
    if typeof obj isnt "object" then return obj?.toString()
    if obj instanceof Array
      @generateList(obj)
    else
      _.reduce(
        obj, 
        ((memo, value, key) =>
          memo.push("#{key}=#{@generateObject(value)}") 
          memo
        ),
        []
      ).join("&")

  serialize: () ->


# CX
class CX extends Format

  constructor: (hap) ->
    [
      @id,
      @checkdigit,
      @checkdigitscheme,
      @assigningauthority,
      @identifiertypecode,
      @assigningfacility,
      @effectivedate,
      @expirationdate
    ] = @parseHAP(hap)

  serialize: () -> 
    @generateHAP([
      @id,
      @checkdigit,
      @checkdigitscheme,
      @assigningauthority,
      @identifiertypecode,
      @assigningfacility,
      @effectivedate,
      @expirationdate
    ])

reply = (formatter) -> 
  (req, res, data) ->
    if data?.status? then res.status(data.status)
    if req.accepts("json")?
      res.json(data)
    else
      res.send(formatter.generateObject(data))

formatter = new Format()

module.exports = 
  formatter: formatter
  reply: reply(formatter)
  clone: clone
