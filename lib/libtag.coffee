fs = require 'fs'
io = require './io'
id3 = require './id3'

# ### Public ###

# Given a file `path`, will read an audio tag from the file
# and return it in the form of `callback(err, tag)`.
exports.readTag = (path, callback) ->
    fs.open path, 'r+', (err, fd) ->
        if err then return callback err
        header = new Buffer 10
        io.readExactly fd, header, 0, 10, 0, (err, bytesRead) ->
            if err then return error fd, callback, err
            if id3.isValidHeader header then return id3.readTag fd, header, (err, tag) ->
                return if err then error fd, callback, err else success fd, callback, tag
            else callback 'Tag not recognized'

# ### Private ###

# The `error` and `success` functions merely call a callback
# (as `callback(err, result)`) after closing a file descriptor.
error =   (fd, callback, err) -> fs.close fd, -> callback err
success = (fd, callback, result) -> fs.close fd, -> callback null, result

