power2To8 = Math.pow(2,8)

Buffer.prototype.toInt = (start, length, bom) ->
    sum = 0
    factor = 1
    indexes = if bom is 'little' then [start..start + length - 1] else [start + length - 1..start]
    for i in indexes
        sum += this[i] * factor
        factor *= power2To8
    sum

getBOM = (buffer) ->
    switch buffer.toInt 0, 2
        when 0xfeff then 'big'
        when 0xfffe then 'little'
        else undefined

_toString = Buffer.prototype.toString
Buffer.prototype.toString = (encoding, start, end) ->
    switch encoding
        when 'utf16'
            words = []
            i = start or 0
            end = end or this.length
            if bom = getBOM this, i then i += 2 else bom = 'big'
            while i < end
                word = this.toInt i, 2, bom
                if 0x0000 <= word <= 0xd7ff or 0xe000 <= word <= 0xffff
                    words.push word
                else if 0x10000 <= word <= 0x10ffff
                    word -= 0x10000
                    words.push 0xd800 + (word >> 10), 0xdc00 + (word & 0x3ff)
                i += 2
            String.fromCharCode.apply null, words
        else _toString.apply this, arguments

