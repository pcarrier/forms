import std/strutils

func jsString*(s: string, depth: uint8, replaceHTML: bool, externalQuotes: bool): string =
  let repeatsOnQuotesAround = (1 shl depth) - 1
  let repeatsOnBackslashInside = (1 shl (depth + 1))
  let repeatsOnQuotesInside = repeatsOnBackslashInside - 1
  let len = s.len
  result = newStringOfCap(len + len shr 1)
  if externalQuotes:
    result.add(repeat('\\', repeatsOnQuotesAround))
    result.add('\'')
  for c in items(s):
    case c
    of '\\': result.add(repeat('\\', repeatsOnBackslashInside))
    of '\'':
      result.add(repeat('\\', repeatsOnQuotesInside))
      result.add('\'')
    of '<':
      if replaceHTML: result.add("&lt;")
      else: result.add(c)
    of '>':
      if replaceHTML: result.add("&gt;")
      else: result.add(c)
    else: result.add(c)
  if externalQuotes:
    result.add(repeat('\\', repeatsOnQuotesAround))
    result.add('\'')

proc jsEval*(code: cstring) {.header: "<emscripten.h>", importc: "emscripten_run_script".}
