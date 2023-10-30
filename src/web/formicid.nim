import std/[deques, strformat, strutils, tables], ../[build, sss, form, stor, storm], js

type
  ElidedError* = object of CatchableError

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

proc html(vm: VM): string =
  result.add("<table>")
  result.add("<tr><th>Status</th><th>Contexts</th><th>Data</th><th>Stream</th></tr>")
  result.add(&"<tr><td>{vm.status}<br/>step {vm.step}</td><td>{vm.contexts.html}</td><td>{vm.data.html}</td><td>{vm.stream.html}</td></tr>")
  result.add("</table>")

proc reportError(msg: string, vm: VM) =
  let js = &"self.postMessage('$target.innerHTML = \\'<em>{msg.jsString(2, true, false)}</em>{vm.html.jsString(2, false, false)}\\'')"
  jsEval(cstring(js))

proc display(vm: ptr VM) =
  let state = vm[].html
  let jsCode = &"self.postMessage('$target.innerHTML = {state.jsString(1, false, true)}')"
  jsEval(cstring(jsCode))

proc recv(slot: int, msgType: int, msg: cstring) {.exportc, codegenDecl: "EMSCRIPTEN_KEEPALIVE $# $#$#".} =
  var vm =
    try: VMs[slot].addr
    except KeyError:
      jsEval(cstring(&"self.postMessage('$target.innerHTML = \\'<em>No such VM</em>\\'')"))
      return
  case msgType:
  of 0, 1:
    try:
      let (forms, elided) = ($msg).parse.parse
      if elided: raise newException(ElidedError, "We do not transmit elided sources to virtual machines.")
      case msgType:
      of 1: vm.tuck_in(forms)
      else: vm.stream_in(forms)
      display(vm)
    except PrintError:
      reportError(&"PrintError: {getCurrentExceptionMsg()}", vm[])
    except ParseError:
      reportError(&"ParseError: {getCurrentExceptionMsg()}", vm[])
    except ElidedError:
      reportError(&"ElidedError: {getCurrentExceptionMsg()}", vm[])
    except:
      reportError(&"Unhandled exception: {getCurrentExceptionMsg()}", vm[])
  else:
    reportError(&"Unknown message type: {msgType}", vm[])

proc advance(slot: int, steps: int) {.exportc, codegenDecl: "EMSCRIPTEN_KEEPALIVE $# $#$#".} =
  var vm =
    try: VMs[slot].addr
    except KeyError:
      jsEval(cstring(&"self.postMessage('$target.innerHTML = \\'<em>No such VM</em>\\'')"))
      return
  try:
    if steps < 0: vm.advance(display)
    else: vm.advance(steps, display)
  except Invalid:
    reportError(&"Invalid: {getCurrentExceptionMsg()}", vm[])
  except:
    reportError(&"Unhandled exception: {getCurrentExceptionMsg()}", vm[])

echo &"formic.id build {buildDescr}"
jsEval(cstring("self.postMessage(undefined)"))
