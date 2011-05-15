io = require './io'
require './buffer'

# ### ID3 ###

class ID3Tag

    aliasToId: {}

    constructor: (@tag) ->
        @idToAlias = {}
        for own alias, id of @aliasToId
            @idToAlias[id] = alias

    get: (field) ->
        return undefined unless id = @aliasToId[field]
        @tag.frames[id]?.content

class ID3Parser

    frameHeaderSize:    6
    tagClass:           ID3Tag
   
    readTag: (fd, callback) ->
        self = this
        parseHeader = @parseHeader
        parseFrames = @parseFrames
        tagClass = @tagClass
        io.readExactlyToBuffer fd, 0, 10, (err, buffer) ->
            tag = { header: parseHeader.apply(self, [buffer]) }
            io.readExactlyToBuffer fd, tag.header.length, tag.header.size, (err, buffer) ->
                if err then return callback err
                try
                    tag.frames = parseFrames.apply(self, [tag, buffer, 10])
                    callback null, new tagClass tag
                catch err
                    callback err

    parseHeaderVersion: (buffer) ->
        major:      buffer[3]
        revision:   buffer[4]
        version:    'ID3v2.' + buffer[3] + '.' + buffer[4]

    parseHeaderFlags: (buffer) ->
        unsynchronisation:      !!(0x80 & buffer[5])
        extenderHeader:         !!(0x40 & buffer[5])

    parseHeaderSize: (buffer) -> buffer.toInt 6, 4, 'big', 7

    parseExtendedHeader: (header) -> undefined

    parseHeader: (buffer) ->
        version:    @parseHeaderVersion buffer
        flags:      @parseHeaderFlags buffer
        size:       @parseHeaderSize buffer

    parseFrameId: (buffer, start) -> buffer.toString 'utf8', start, start + 3

    parseFrameSize: (buffer, start) -> buffer.toInt start + 3, 3

    parseFrame: (tag, buffer, start) ->
        return unless start < buffer.length and buffer[start]
        frame =
            id:         @parseFrameId buffer, start
            size:       @parseFrameSize buffer, start
        if frame.id[0] is 'T'
            start += @frameHeaderSize
            frame.encoding = if buffer[start] == 0 then 'iso-8859-1' else 'utf16'
            buffer = buffer[start + 1 .. start + frame.size - 1]
            decoding = if frame.encoding is 'utf16' then 'utf16' else 'utf8'
            frame.content = buffer.toString(decoding)
        frame

    parseFrames: (tag, buffer, start) ->
        frames = {}
        start = start || 0
        while frame = @parseFrame tag, buffer, start
            frames[frame.id] = frame
            start += frame.size + @frameHeaderSize
        tag.padding = buffer.length - start
        frames

# ### ID3v2 ###

class ID3v2Tag extends ID3Tag

    aliasToId:
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

class ID3v2Parser extends ID3Parser

    tagClass:           ID3v2Tag

    parseHeaderFlags: (header, buffer) ->
        super header, buffer

# ### ID3v3 ###

class ID3v3Tag extends ID3Tag

    aliasToId:
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

class ID3v3Parser extends ID3v2Parser

    frameHeaderSize:    10
    tagClass:           ID3v3Tag

    parseFrameId: (buffer, start) -> buffer.toString 'utf8', start, start + 4

    parseFrameSize: (buffer, start) -> buffer.toInt start + 4, 4

    parseFrameFlags: (buffer, start) ->
        tagAlterPreservation:   !!(0x80 & buffer[start + 8])
        fileAlterPreservation:  !!(0x40 & buffer[start + 8])
        readOnly:               !!(0x20 & buffer[start + 8])
        compression:            !!(0x80 & buffer[start + 9])
        encryption:             !!(0x40 & buffer[start + 9])
        groupingIdentity:       !!(0x20 & buffer[start + 9])

    parseHeaderFlags: (buffer) ->
        flags = super buffer
        flags.experimentalIndicator = !!(0x20 & buffer[5])
        flags

# ### ID3v4 ###

class ID3v4Parser extends ID3v3Parser

    parseHeaderFlags: (buffer) ->
        flags = super buffer
        flags.footer = !!(0x10 & buffer[5])
        flags

    parseFrameSize: (buffer, start) ->
        buffer.toInt start + 4, 4, 'big', 7

# Checking for a valid ID3 header means that
exports.detectTag = (fd, callback) ->
    io.readExactlyToBuffer fd, 0, 10, (err, buffer) ->
        if err then return callback err
        # the first three bytes are 'ID3',
        return callback null, null if buffer.toString('utf8', 0, 3) != 'ID3'
        # no weird flags are set, and
        return callback null, null if buffer[5] & 0x1f
        # no weird bits are set.
        for word in buffer[6..9]
            return callback null, null if word >= 0x80
        version = ID3Parser.prototype.parseHeaderVersion(buffer)
        parser = switch version.major
            when 2 then new ID3v2Parser
            when 3 then new ID3v3Parser
            when 4 then new ID3v4Parser
            else null
        return callback null, parser

