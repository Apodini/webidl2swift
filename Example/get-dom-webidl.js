const cheerio = require('cheerio')
const fetch = require('node-fetch')
const fs = require('fs')

fetch('https://dom.spec.whatwg.org')
  .then(res => res.text())
  .then(html => cheerio.load(html))
  .then($ => $('.idl.def').text())
  .then(idl => {
    fs.writeFileSync('WebIDL-files/dom.webidl', idl)
    console.log(`Wrote ${idl.split('\n').length.toLocaleString()} lines!`)
  })
  .catch(err => console.error("Failed!", err))
