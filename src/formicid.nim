from strutils import parseHexInt
from strformat import `&`
# from algorithm import reversed

proc emscripten_run_script(code: cstring) {.header: "<emscripten.h>",
    importc: "emscripten_run_script".}

# func js_string(s: string): string =
#   let len = s.len
#   result = newStringOfCap(len + len shr 2)
#   add(result, "\"")
#   for c in items(s):
#     case c
#     of '\\': add(result, "\\\\")
#     of '\'': add(result, "\\'")
#     of '\"': add(result, "\\\\\"")
#     else: add(result, c)
#   add(result, "\"")

proc eval_js(code: string) = emscripten_run_script(cstring(code))

# proc eval_stor(code: cstring) {.exportc,
#     codegenDecl: "__attribute__((used)) $# $#$#".} =
#   let codeStr = $code
#   var v = ""
#   for i in countdown(codeStr.len - 1, 0):
#     if codeStr[i] in  {'0'..'9', 'a'..'f'}:
#       v.add(codeStr[i])
#     else:
#       break
#   var round = if v.len > 0: parseHexInt(cast[string](v.reversed)) else: 0
#   let newCode = codeStr[0 ..< (codeStr.len - v.len)] & &" {round + 1:x}"
#   let prefix = &"Can't evaluate <tt>{codeStr.js_string}</tt> (or anything yet).<br/><i>— Nim code running in wasm in a WebWorker after 0x"
#   eval_js(&"self.postMessage('$target.innerHTML = {prefix.js_string}.concat(\\'{round:x}\\').concat(\" window roundtrips.</i>\");$worker.postMessage({newCode.js_string})')")

proc loop(n: int) {.exportc,
    codegenDecl: "__attribute__((used)) $# $#$#".} =
  eval_js(&"self.postMessage('$target.innerHTML = {n};$worker.postMessage({n + 1})')")
