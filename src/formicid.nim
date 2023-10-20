from parseutils import parseHex
from strformat import `&`
from algorithm import reversed

proc eval_js(code: cstring) {.header: "<emscripten.h>", importc: "emscripten_run_script".}
proc stackCurrent: cuint {.header: "<emscripten/stack.h>", importc: "emscripten_stack_get_current".}
proc stackBase: cuint {.header: "<emscripten/stack.h>", importc: "emscripten_stack_get_base".}
proc stackEnd: cuint {.header: "<emscripten/stack.h>", importc: "emscripten_stack_get_end".}

func js_string(s: string): string =
  let len = s.len
  result = newStringOfCap(len + len shr 2)
  add(result, "\"")
  for c in items(s):
    case c
    of '\\': add(result, "\\\\")
    of '\'': add(result, "\\'")
    of '\"': add(result, "\\\\\"")
    else: add(result, c)
  add(result, "\"")

proc sendMsg(slot:int, code: cstring) {.exportc,
    codegenDecl: "EMSCRIPTEN_KEEPALIVE $# $#$#".} =
  echo "start: ", stackBase(), "-", stackCurrent(), "-", stackEnd()
  let codeStr = $code
  var v = ""
  for i in countdown(codeStr.len - 1, 0):
    if codeStr[i] in  {'0'..'9', 'a'..'f'}:
      v.add(codeStr[i])
    else:
      break
  var round = 0
  if v.len > 0: discard parseHex(v.reversed, round)
  let newCode = codeStr[0 ..< (codeStr.len - v.len)] & &" {round + 1:x}"
  let prefix = &"Can't evaluate <tt>{codeStr.js_string}</tt> (or anything yet).<br/><i>— Nim code running in wasm in a WebWorker after "
  eval_js(cstring(&"self.postMessage('$target.innerHTML = {prefix.js_string}.concat(\\'{round}\\').concat(\" window roundtrips.</i>\");$worker.postMessage([0, {newCode.js_string}])')"))
  echo "end: ", stackBase(), "-", stackCurrent(), "-", stackEnd()

eval_js(cstring("self.postMessage(undefined)"))
