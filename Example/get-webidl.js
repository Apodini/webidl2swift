import { load } from 'cheerio'
import fetch from 'node-fetch'
import { writeFileSync } from 'node:fs'

fetch(`https://${process.argv[2]}.spec.whatwg.org`)
  .then(res => res.text())
  .then(html => load(html))
  .then($ => $('.idl.def, pre code.idl').text())
  .then(idl => {
    writeFileSync(`WebIDL-files/${process.argv[2]}.idl`, idl)
    console.log(`Wrote ${idl.split('\n').length.toLocaleString()} lines!`)
  })
  .catch(err => console.error("Failed!", err))
