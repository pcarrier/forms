import std/[deques, strformat, strutils, tables], ../[build, sss, form, stor, storm], js

type
  InputError* = object of CatchableError

var VMs = { 0: initVM() }.toTable()

proc html(r: Ref): string =
  case r.kind:
  of U64, U32, U16, U8, I64, I32, I16, I8, F64, F32, F16, Bool, Undef, Null:
    result.add($r)
  of Sym, Str, Bin:
    result.add(($r).multiReplace(@[("&", "&amp;"), ("<", "&lt;"), (">", "&gt;"), ("\"", "&quot;")]))
  of Tag:
    if r.tag == CODE_TAG:
      case r.tagged.kind:
      of U8:
        result.add(&"%{r.tagged.u8}")
      of Vec:
        if r.tagged.vec.len == 0:
          result.add(&"( )")
        else:
          result.add(&"( ){r.tagged.html}")
      else: result.add(&"<span class='tag'>#{r.tag}</span> {r.tagged.html}")
    else:
      result.add(&"<span class='tag'>#{r.tag}</span> {r.tagged.html}")
  of Vec:
    if r.vec.len == 0:
      result.add($r)
    else:
      result.add("<table>")
      for f in r.vec:
        result.add(&"<lr><td>{f.html}</td></tr>")
      result.add("</table>")
  of Map:
    if r.map.len == 0:
      result.add($r)
    else:
      result.add("<table>")
      for k, v in r.map.pairs:
        result.add(&"<tr><td>{k.html}</td><td>{v.html}</td></tr>")
      result.add("</table>")

proc html(rs: RefDeq): string =
  result.add(&"<table>")
  for r in rs.items:
    result.add(&"<tr><td>{r.html}</td></tr>")
  result.add(&"</table>")

proc html(vm: ptr VM): string =
  let status = case vm.status
  of FAULT: &"<span class=\"fault\">{vm.fault}</div>"
  else: $vm.status
  result.add(&"<p>{status} (step {vm.step})</p><table>")
  result.add("<tr><th>Contexts</th><th>Data</th><th>Stream</th></tr>")
  result.add(&"<tr><td>{vm.contexts.html}</td><td>{vm.data.html}</td><td>{vm.stream.html}</td></tr>")
  result.add("</table>")

proc display(vm: ptr VM) =
  let state = vm.html
  jsEval(&"self.postMessage('$target.innerHTML = {state.jsString(1, false, true)}')")

{.emit: """
#include <emscripten.h>
""".}

proc recv(slot: int, msgType: int, msg: cstring) {.exportc, codegenDecl: "EMSCRIPTEN_KEEPALIVE $# $#$#".} =
  var vm =
    try: VMs[slot].addr
    except KeyError:
      jsEval(&"self.postMessage('$target.innerHTML = \\'<em>No such VM</em>\\'')")
      return
  case msgType:
  of 0, 1:
    try:
      let (forms, elided) = ($msg).parse.parse
      if elided: raise newException(InputError, "We do not transmit elided sources to virtual machines.")
      case msgType:
      of 1: vm.tuck_in(forms)
      else: vm.stream_in(forms)
      display(vm)
    except:
      faulty(vm, getCurrentExceptionMsg())
  else:
    faulty(vm, "Unknown message type.")

proc advance(slot: int, steps: int) {.exportc, codegenDecl: "EMSCRIPTEN_KEEPALIVE $# $#$#".} =
  var vm =
    try: VMs[slot].addr
    except KeyError:
      jsEval(&"self.postMessage('$target.innerHTML = \\'<em>No such VM</em>\\'')")
      return
  if steps < 0: vm.advance()
  else: vm.advance(steps)

proc displayVM(slot: int) {.exportc, codegenDecl: "EMSCRIPTEN_KEEPALIVE $# $#$#".} =
  var vm =
    try: VMs[slot].addr
    except KeyError:
      return
  display(vm)

proc deFault(slot: int) {.exportc, codegenDecl: "EMSCRIPTEN_KEEPALIVE $# $#$#".} =
  var vm =
    try: VMs[slot].addr
    except KeyError:
      return
  vm.status = RUNNING

echo &"formic.id build {buildDescr}"
jsEval("self.postMessage(undefined)")
