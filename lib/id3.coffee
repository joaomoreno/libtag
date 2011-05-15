_ = require 'underscore'
io = require './io'
require './buffer'

# ### Public ###

# Checking for a valid ID3 header means that
exports.isValidHeader = (buffer) ->
    # the first three bytes are 'ID3',
    return false if buffer.toString('utf8', 0, 3) != 'ID3'
    # no weird flags are set, and
    return false if buffer[5] & 0x1f
    # no weird bits are set.
    return false if _.detect(buffer[6..9], (i) -> i < 0x8)
    return true

# Read an ID3 tag from an open file, referenced by `fd`.
# The file's first 10 bytes have already been read and placed in `header`.
# Should call `callback(err, tag)`.
exports.readTag = (fd, header, callback) ->
    tag = { header: parseHeader header }
    io.readExactlyToBuffer fd, header.length, tag.header.size, (err, buffer) ->
        if err then return callback err
        tag.frames = parseFrames buffer
        callback null, tag

# ### Private ###

# #### Header ####
parseHeaderVersion = (buffer) -> return 'ID3v2.' + buffer[3] + '.' + buffer[4]
parseHeaderFlags = (buffer) ->
    unsynchronisation:      !!(0x80 & buffer[5])
    extenderHeader:         !!(0x40 & buffer[5])
    experimentalIndicator:  !!(0x20 & buffer[5])
parseHeaderSize = (buffer) -> return buffer[9] + buffer[8] * 128 + buffer[7] * 16384 + buffer[6] * 2097152
parseExtendedHeader = (header) -> undefined

parseHeader = (header) ->
    version:    parseHeaderVersion header
    flags:      parseHeaderFlags header
    size:       parseHeaderSize header

# #### Frame ####
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

