const cheerio = require('cheerio')
const fetch = require('node-fetch')
const fs = require('fs')

fetch(`https://${process.argv[2]}.spec.whatwg.org`)
  .then(res => res.text())
  .then(html => cheerio.load(html))
  .then($ => $('.idl.def, pre code.idl').text())
  .then(idl => {
    fs.writeFileSync(`WebIDL-files/${process.argv[2]}.webidl`, idl)
    console.log(`Wrote ${idl.split('\n').length.toLocaleString()} lines!`)
  })
  .catch(err => console.error("Failed!", err))
