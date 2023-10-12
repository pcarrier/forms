import std/[deques, sequtils], form, sss, stor
const src = readFile("src/i.stor")

let I* = src.parse.parse[0].map(refer).toDeque
