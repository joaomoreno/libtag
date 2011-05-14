fs = require 'fs'

exactlyMaximumAttempts = 10

readExactly = (fd, buffer, offset, length, position, callback) ->
    totalLength = length
    totalBytesRead = 0
    attempts = 0
    recursive = (err, bytesRead) ->
        if err then return callback err, totalBytesRead
        totalBytesRead += bytesRead
        if bytesRead == 0 then attempts += 1 else attempts = 0
        if attempts > exactlyMaximumAttempts
            return callback 'Reached maximum read attempts', totalBytesRead
        if totalBytesRead < totalLength
            readExactly fd, buffer, totalBytesRead, totalLength - totalBytesRead, null, recursive
        else
            callback null, totalBytesRead
    fs.read fd, buffer, offset, length, position, recursive

readExactlyToBuffer = (fd, position, length, callback) ->
    buffer = new Buffer length
    readExactly fd, buffer, 0, length, position, (err, bytesRead) ->
        if err then return callback err
        callback null, buffer

exports.readExactly = readExactly
exports.readExactlyToBuffer = readExactlyToBuffer

