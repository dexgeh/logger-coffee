Logging utility for coffee-script.

**Usage**

Create a logger:

    loglib = require './logger'
    log = loglib.getLogger __filename

Output to console:
    
    loglib.addAppender loglib.getConsoleAppender "ALL"

Output to file:

    loglib.addAppender loglib.getFileAppender "filename.log", "ALL"

Use the logger:

    log.trace "hello"
    log.debug "hello"
    log.info  "hello"
    log.warn  "hello"
    log.error "hello"
    log.fatal "hello"

The levels are (from the code):

    exports.levels = levels =
        'ALL'  :  1
        'TRACE' : 2
        'DEBUG' : 3
        'INFO'  : 4
        'WARN'  : 5
        'ERROR' : 6
        'FATAL' : 7
        'OFF'   : 8


The configuration using loglib has global effect.

There is a global log level, default to ALL, that can be changed by:

    loglib.setLevel "DEBUG"

The appenders have to own two attributes.
The function log, take three arguments (caller, level, message) and the level attribute expressed as number.

See example.coffee.
