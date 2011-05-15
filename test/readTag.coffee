libtag = require '../lib/libtag'

return console.log 'Usage: coffee readTag.coffee audio-file' unless process.argv.length >= 3

count = 2
callback = (err, tag) ->
    return console.log err if err
    console.log(tag.get(field) for field in ['track', 'album', 'artist', 'title'])
    if ++count < process.argv.length
        libtag.readTag process.argv[count], callback
libtag.readTag process.argv[count], callback

