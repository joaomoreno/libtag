_ = require 'underscore'
io = require './io'
require './buffer'

# ### Public ###

class ID3Tag
    constructor: (@tag) ->
    get: (field) ->
        return undefined unless id = aliasToId[field]
        @tag.frames[id]?.content

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
        tag.frames = parseFrames tag, buffer
        callback null, new ID3Tag tag

# ### Private ###

# #### Header ####

parseHeaderVersion = (buffer) ->
    major:      buffer[3]
    revision:   buffer[4]
    version:    'ID3v2.' + buffer[3] + '.' + buffer[4]

parseHeaderFlags = (buffer) ->
    unsynchronisation:      !!(0x80 & buffer[5])
    extenderHeader:         !!(0x40 & buffer[5])
    experimentalIndicator:  !!(0x20 & buffer[5])

parseHeaderSize = (buffer) -> buffer.toInt 6, 4, 'big', 7

parseExtendedHeader = (header) -> undefined

parseHeader = (buffer) ->
    header = {}
    header.version =    parseHeaderVersion buffer
    header.flags   =    parseHeaderFlags header, buffer
    header.size    =    parseHeaderSize buffer
    header

# #### Frame ####

parseFrameId = (buffer, start) -> buffer.toString 'utf8', start, start + 4

parseFrameSize = (tag, buffer, start) ->
    if tag.header.version.major is 4
        buffer.toInt start + 4, 4, 'big', 7
    else
        buffer.toInt start + 4, 4

parseFrameFlags = (buffer, start) ->
    tagAlterPreservation:   !!(0x80 & buffer[start + 8])
    fileAlterPreservation:  !!(0x40 & buffer[start + 8])
    readOnly:               !!(0x20 & buffer[start + 8])
    compression:            !!(0x80 & buffer[start + 9])
    encryption:             !!(0x40 & buffer[start + 9])
    groupingIdentity:       !!(0x20 & buffer[start + 9])

parseFrame = (tag, buffer, start) ->
    return unless start < buffer.length
    frame =
        id: parseFrameId buffer, start
        size: parseFrameSize tag, buffer, start
        flags: parseFrameFlags buffer, start
    start += 10
    if frame.id[0] is 'T'
        frame.encoding = if buffer[start] == 0 then 'ISO-8859-1' else 'UTF16'
        frame.content = buffer[start + 1 .. start + frame.size - 1].toString(if frame.encoding == 'UTF16' then 'utf16' else 'utf8')
    frame

parseFrames = (tag, buffer) ->
    frames = {}
    start = 0
    while frame = parseFrame tag, buffer, start
        frames[frame.id] = frame
        start += frame.size + 10
    frames

aliasToId =
    album:              'TALB'
    bpm:                'TBPM'
    composer:           'TCOM'
    contentType:        'TCON'
    copyright:          'TCOP'
    date:               'TDAT'
    playlistDelay:      'TDLY'
    encodedBy:          'TENC'
    lyricist:           'TEXT'
    fileType:           'TFLT'
    time:               'TIME'
    category:           'TIT1'
    title:              'TIT2'
    subtitle:           'TIT3'
    initialKey:         'TKEY'
    language:           'TLAN'
    length:             'TLEN'
    mediaType:          'TMED'
    originalTitle:      'TOAL'
    originalFilename:   'TOFN'
    originalLyricist:   'TOLY'
    originalArtist:     'TOPE'
    originalYear:       'TORY'
    owner:              'TOWN'
    artist:             'TPE1'
    band:               'TPE2'
    conductor:          'TPE3'
    interpreter:        'TPE4'
    setPart:            'TPOS'
    publisher:          'TPUB'
    track:              'TRCK'
    recordingDates:     'TRDA'
    internetRadioName:  'TRSN'
    internetRadioOwner: 'TRSO'
    size:               'TSIZ'
    isrc:               'TSRC'
    encodingSettings:   'TSSE'
    year:               'TYER'
    text:               'TXXX'

idToAlias = {}
for own alias, id of aliasToId
    idToAlias[id] = alias

