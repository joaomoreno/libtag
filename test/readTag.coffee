libtag = require '../lib/libtag'

return console.log 'Usage: coffee readTag.coffee audio-file' unless process.argv.length == 3

libtag.readTag process.argv[2], (err, tag) ->
    return console.log err if err
    console.log tag
