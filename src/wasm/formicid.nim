import std/[strformat, tables], ../[build, form, sap, sss, stor, storm], js

type
  InputError* = object of CatchableError

var VMs = { 0: initVM() }.toTable()

proc sap(vm: ptr VM): string =
  var fault = if vm.fault.isNil: vm.fault[].reform else: formNull().refer

  return [
    ($vm.status).reform,
    fault.reform,
    vm.contexts.reform,
    vm.data.reform,
    vm.stream.reform,
  ].reform.sap

{.emit: """
#include <emscripten.h>
""".}

proc recv(slot: int, msgType: int, msg: cstring) {.exportc, codegenDecl: "EMSCRIPTEN_KEEPALIVE $# $#$#".} =
  var vm =
    try: VMs[slot].addr
    except KeyError:
      jsEval(&"console.log('No such VM', {slot})")
      return
  case msgType:
  of 0, 1:
    try:
      let (forms, elided) = ($msg).parse.parse
      if elided: raise newException(InputError, "We do not transmit elided sources to virtual machines.")
      case msgType:
      of 1: vm.tuck_in(forms)
      else: vm.stream_in(forms)
    except:
      faulty(vm, getCurrentExceptionMsg())
  else:
    faulty(vm, "Unknown message type.")

proc advance(slot: int, steps: int) {.exportc, codegenDecl: "EMSCRIPTEN_KEEPALIVE $# $#$#".} =
  var vm =
    try: VMs[slot].addr
    except KeyError:
      jsEval(&"console.log('No such VM', {slot})")
      return
  if steps < 0: vm.advance()
  else: vm.advance(steps)

proc displayVM(slot: int) {.exportc, codegenDecl: "EMSCRIPTEN_KEEPALIVE $# $#$#".} =
  var vm =
    try: VMs[slot].addr
    except KeyError:
      return
  jsEval(&"self.postMessage('window.$ui({vm.sap.jsString(1, false, false)})')")

proc deFault(slot: int) {.exportc, codegenDecl: "EMSCRIPTEN_KEEPALIVE $# $#$#".} =
  var vm =
    try: VMs[slot].addr
    except KeyError:
      return
  vm.status = RUNNING

echo &"formic.id build {buildDescr}"
jsEval("self.postMessage(undefined)")
