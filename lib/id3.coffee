fs = require 'fs'
_ = require 'underscore'
io = require './io'
buffer = require './buffer'

isValidHeader = (buffer) ->
    # Check that it really is an ID3v2 tag
    return false if buffer.toString('utf8', 0, 3) != 'ID3'
    # Check that no unknown flags are set
    return false if buffer[5] & 0x1f
    # Check certain size bits are zero-ed
    return false if _.detect(buffer[6..9], (i) -> i < 0x8)
    return true

parseHeaderVersion = (buffer) -> return 'ID3v2.' + buffer[3] + '.' + buffer[4]
parseHeaderFlags = (buffer) ->
    unsynchronisation:      !!(0x80 & buffer[5])
    extenderHeader:         !!(0x40 & buffer[5])
    experimentalIndicator:  !!(0x20 & buffer[5])
parseHeaderSize = (buffer) -> return buffer[9] + buffer[8] * 128 + buffer[7] * 16384 + buffer[6] * 2097152
parseExtendedHeader = (header) -> undefined

readHeader = (fd, position, callback) ->
    header = new Buffer 10
    io.readExactly fd, header, 0, 10, position, (err, bytesRead) ->
        position += bytesRead
        if err then return callback err
        if not isValidHeader header then return callback 'Not valid ID3v2 header'
        callback null, position,
            version:    parseHeaderVersion header
            flags:      parseHeaderFlags header
            size:       parseHeaderSize header

# *** Frame

parseFrameId = (buffer, start) -> buffer.toString 'utf8', start, start + 4
parseFrameSize = (buffer, start) -> buffer.toInt start + 4, 4
parseFrameFlags = (buffer, start) ->
    tagAlterPreservation:   !!(0x80 & buffer[start + 8])
    fileAlterPreservation:  !!(0x40 & buffer[start + 8])
    readOnly:               !!(0x20 & buffer[start + 8])
    compression:            !!(0x80 & buffer[start + 9])
    encryption:             !!(0x40 & buffer[start + 9])
    groupingIdentity:       !!(0x20 & buffer[start + 9])

parseFrame = (buffer, start) ->
    return unless start < buffer.length
    frame =
        id: parseFrameId(buffer, start)
        size: parseFrameSize(buffer, start)
        flags: parseFrameFlags(buffer, start)
    start += 10
    if frame.id[0] is 'T'
        frame.encoding = if buffer[start] == 0 then 'ISO-8859-1' else 'UTF16'
        buffer = buffer[start + 1 .. start + frame.size]
        frame.text = if frame.encoding == 'UTF16' then buffer.toString('utf16') else buffer.toString('utf8')
    frame

parseFrames = (buffer) ->
    frames = []
    start = 0
    while frame = parseFrame buffer, start
        frames.push frame
        start += frame.size + 10
    frames

error = (fd, callback, err) -> fs.close fd, -> callback err
success = (fd, callback, tag) -> fs.close fd, -> callback null, tag

read = (path, callback) ->
    fs.open path, 'r+', (err, fd) ->
        if err then return callback err
        tag = {}
        readHeader fd, 0, (err, position, header) ->
            if err then return error fd, callback, err
            tag.header = header
            io.readExactlyToBuffer fd, position, tag.header.size, (err, buffer) ->
                if err then return error fd, callback, err
                tag.frames = parseFrames buffer
                fs.close fd, () ->
                    success fd, callback, tag

read './test/audiofile1.mp3', (err, tag) ->
    return console.log err if err
    console.log tag

