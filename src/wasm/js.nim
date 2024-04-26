import std/strutils

func jsString*(s: string, depth: uint8, replaceHTML: bool): string =
  let repeatsOnBackslashInside = 1 shl depth
  let repeatsOnQuotesInside = (1 shl depth) - 1
  let len = s.len
  result = newStringOfCap(len + len shr 1)
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

proc emscripten_run_script(code: cstring) {.header: "<emscripten.h>", importc: "emscripten_run_script".}

proc jsEval*(code: string) =
  emscripten_run_script(cstring(code))
