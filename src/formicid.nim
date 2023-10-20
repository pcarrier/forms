from parseutils import parseHex
from strformat import `&`
from algorithm import reversed

proc evalJS(code: cstring) {.header: "<emscripten.h>", importc: "emscripten_run_script".}
proc stackCurrent: cuint {.header: "<emscripten/stack.h>", importc: "emscripten_stack_get_current".}
proc stackBase: cuint {.header: "<emscripten/stack.h>", importc: "emscripten_stack_get_base".}
proc stackEnd: cuint {.header: "<emscripten/stack.h>", importc: "emscripten_stack_get_end".}

func jsString(s: string): string =
  let len = s.len
  result = newStringOfCap(len + len shr 2)
  result.add("\"")
  for c in items(s):
    case c
    of '\\': result.add("\\\\")
    of '\'': result.add("\\'")
    of '\"': result.add("\\\\\"")
    else: result.add(c)
  result.add("\"")

proc sendMsg(slot: int, code: cstring) {.exportc, codegenDecl: "EMSCRIPTEN_KEEPALIVE $# $#$#".} =
  evalJS(cstring(&"self.postMessage('$target.innerHTML = {slot};$worker.postMessage([{slot + 1}, undefined]);')"))
  echo "end: ", stackBase(), ":", stackCurrent(), ":", stackEnd()

evalJS(cstring("self.postMessage(undefined)"))
