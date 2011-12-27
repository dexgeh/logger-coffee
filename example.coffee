#!/usr/bin/env coffee

loglib = require './logger'

log = loglib.getLogger __filename

#no appender specified, this line has no effect
log.debug "hello"

#print world - with colors!
loglib.addAppender loglib.getConsoleAppender("DEBUG")
log.trace "hello"
log.debug "world"

#the global level wins over the appender level
loglib.setLevel "ERROR"
log.trace "hello"

#define a custom appender
loglib.addAppender
    log : (instant, caller, level, message) ->
        console.log "#{instant} #{caller} #{level} #{message}"
    level : 1

#write twice to the console
log.fatal "oh hai"

#log to a file, limit the file size to 2M, keep two backups
loglib.addAppender loglib.getRollingFileAppender("output.log", "2M", "2", "ALL")

#write to file
log.fatal "last"
