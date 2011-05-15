fs = require 'fs'
io = require './io'
id3 = require './id3'

# ### Public ###

# Given a file `path`, will read an audio tag from the file
# and return it in the form of `callback(err, tag)`.
exports.readTag = (path, callback) ->
    fs.open path, 'r+', (err, fd) ->
        if err then return callback err
        id3.detectTag fd, (err, parser) ->
            if err then return callback err
            if not parser then return callback 'Not ID3 file'
            parser.readTag fd, (err, tag) ->
                return if err then error fd, callback, err else success fd, callback, tag

# ### Private ###

# The `error` and `success` functions merely call a callback
# (as `callback(err, result)`) after closing a file descriptor.
error =   (fd, callback, err) -> fs.close fd, -> callback err
success = (fd, callback, result) -> fs.close fd, -> callback null, result

