libtag = require '../lib/libtag'

return console.log 'Usage: coffee readTag.coffee audio-file' unless process.argv.length >= 3

count = 2
callback = (err, tag) ->
    if err
        console.log err.stack
        console.log 'ERR', process.argv[count]
    else
        console.log tag.get('artist'), tag.get('title')
    if ++count < process.argv.length
        libtag.readTag process.argv[count], callback

libtag.readTag process.argv[count], callback

