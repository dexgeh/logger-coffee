#!/usr/bin/env coffee

loglib = require './logger'

log = loglib.getLogger __filename

#no appender specified, this line has no effect
log.debug "hello"

#print world
loglib.addAppender loglib.getConsoleAppender("DEBUG")
log.trace "hello"
log.debug "world"

#the global level wins over the appender level
loglib.setLevel "ERROR"
log.trace "hello"

loglib.addAppender
    log : (caller, level, message) ->
        console.log "#{caller} #{level} #{message}"
    level : 1

#write twice to the console
log.fatal "oh hai"
