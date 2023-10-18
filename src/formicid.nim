from strformat import `&`

proc emscripten_run_script(code: cstring) {.header: "<emscripten.h>",
    importc: "emscripten_run_script".}

func js_string(s: string): string =
  result = newStringOfCap(s.len + s.len shr 2)
  add(result, "\"")
  for c in items(s):
    case c
    of '\\': add(result, "\\\\")
    of '\'': add(result, "\\'")
    of '\"': add(result, "\\\\\"")
    else: add(result, c)
  add(result, "\"")

proc eval_js(code: cstring) = emscripten_run_script(code)

proc eval_stor(code: cstring) {.exportc,
    codegenDecl: "__attribute__((used)) $# $#$#".} =
  let msg = &"I don't know how to evaluate <tt>{js_string($code)}</tt> yet. Or anything, for that matter.<br/><i>This message delivered by Nim code running in WebAssembly in a WebWorker.</i>"
  eval_js(cstring(&"self.postMessage('document.body.innerHTML = {msg.js_string}')"))

echo "Booted."
