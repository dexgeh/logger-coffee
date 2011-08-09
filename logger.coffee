events = require 'events'
fs = require 'fs'

exports.levels = levels =
    'ALL'  :  1
    'TRACE' : 2
    'DEBUG' : 3
    'INFO'  : 4
    'WARN'  : 5
    'ERROR' : 6
    'FATAL' : 7
    'OFF'   : 8

dispatcher = new events.EventEmitter()
dispatcher.on  'log', (caller, level, message) ->
    for appender in @appenders
        appender.log caller, level, message if levels[level] >= appender.level

dispatcher.log = (caller, level, message) ->
    @emit 'log', caller, level, message if levels[level] and levels[level] >= @globalLevel

dispatcher.globalLevel = 1
dispatcher.appenders = []

exports.setLevel = (level) ->
    throw new Error("Unknown level #{level}") if not levels[level]
    dispatcher.globalLevel = levels[level]

exports.getLogger = (caller) ->
    log : (message, level) ->
        dispatcher.log caller,  level , message
    trace : (message) ->
        dispatcher.log caller, 'TRACE', message
    debug : (message) ->
        dispatcher.log caller, 'DEBUG', message
    info  : (message) ->
        dispatcher.log caller, 'INFO' , message
    warn  : (message) ->
        dispatcher.log caller, 'WARN' , message
    error : (message) ->
        dispatcher.log caller, 'ERROR', message
    fatal : (message) ->
        dispatcher.log caller, 'FATAL', message

levelPad =
    'TRACE' : 'TRACE'
    'DEBUG' : 'DEBUG'
    'INFO'  : 'INFO '
    'WARN'  : 'WARN '
    'ERROR' : 'ERROR'
    'FATAL' : 'FATAL'

exports.simpleFormatter = (caller, level, message) ->
    "[#{new Date().toUTCString()} #{levelPad[level]}] #{caller.substring(process.env.PWD.length+1)} #{message}"

exports.addAppender = (appender) ->
    dispatcher.appenders.push appender

exports.getConsoleAppender = (level) ->
    throw new Error("Unknown level #{level}") if not levels[level]
    lvl = levels[level]
    consoleApp =
        formatter : exports.simpleFormatter
        log : (caller, level, message) ->
            console.log (@formatter caller, level, message)
        level : lvl
    return consoleApp

exports.getFileAppender = (filename, level) ->
    throw new Error("Unknown level #{level}") if not levels[level]
    lvl = levels[level]
    fileApp =
        formatter : exports.simpleFormatter
        log : (caller, level, message) ->
            fs.open filename, 'a', '0666', (err, id) ->
                fs.write id, (fileApp.formatter caller, level, message+'\n'), null, 'utf8', () ->
                    fs.close id
        level : lvl
