events = require 'events'
fs = require 'fs'
path = require 'path'

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


levelColors =
    'TRACE' : ['\033[1m', '\033[22m'] #bold
    'DEBUG' : ['\033[33m', '\033[39m'] #yellow
    'INFO'  : ['\033[32m','\033[39m'] #green
    'ERROR' : ['\033[31m', '\033[39m'] #red
    'FATAL' : ['\033[35m', '\033[39m'] #magenta

exports.getConsoleColorFormatter = (caller, level, message) ->
    timeColor = "\033[1m"+new Date().toUTCString()+"\033[22m"
    levelColor = levelColors[level][0] + levelPad[level] + levelColors[level][1]
    callerColor = "\033[36m"+(caller.substring process.env.PWD.length+1)+"\033[39m"
    "[#{timeColor} #{levelColor}] #{callerColor} #{message}"

exports.addAppender = (appender) ->
    dispatcher.appenders.push appender

exports.getConsoleAppender = (level) ->
    throw new Error("Unknown level #{level}") if not levels[level]
    lvl = levels[level]
    consoleApp =
        formatter : exports.getConsoleColorFormatter
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
                fs.write id, (@formatter caller, level, message+'\n'), null, 'utf8', () ->
                    fs.close id
        level : lvl
    return fileApp

exports.getRollingFileAppender = (filename, maxSize, backups, level) ->
    throw new Error "Unknown level #{level}" if not levels[level]
    throw new Error "Backups have to be a positive number" if not backups > 0 and typeof backups isnt Number
    throw new Error "max size have to be a positive number (bytes) suffixed by M or K (megabytes or kilobytes)" if not maxSize.match /[0-9]+[MmKk]?/
    maxSizeBytes = parseInt ""+maxSize
    chr = maxSize.substring(maxSize.length-1).toUpperCase()
    maxSizeBytes = maxSizeBytes * 1024 if chr is "K"
    maxSizeBytes = maxSizeBytes * 1024 * 1024 if chr is "M"
    currentBackupIndex = 0
    currentFileSize = 0
    if path.existsSync filename
        currentFileSize = (fs.statSync filename).size
    rollingFileApp =
        formatter : exports.simpleFormatter
        log : (caller, level, message) ->
            @rollFile() if @currentFileSize > maxSizeBytes
            @appendLog caller, level, message
        rollFile : () ->
            @currentBackupIndex = @currentBackupIndex+1
            @currentBackupIndex = 1 if @currentBackupIndex > backups
            fs.renameSync filename, filename+"."+@currentBackupIndex
            @currentFileSize = 0
        appendLog : (caller, level, message) ->
            fs.open filename, 'a', '0666', (err, id) ->
                line = exports.simpleFormatter caller, level, message+'\n'
                fs.write id, line, null, 'utf8', () ->
                    fs.closeSync id
                    rollingFileApp.currentFileSize += line.length
        currentBackupIndex : currentBackupIndex
        currentFileSize : currentFileSize
        level : levels[level]
    return rollingFileApp
