import std/strformat, ../[best, build, form, stor, storm]

proc stor(vm: ptr VM): string =
  var fault = if vm.status != FAULT: form().refer else: vm.fault.reform

  return [
    ($vm.status).reform,
    vm.step.reform,
    vm.primitive.reform,
    fault,
    vm.contexts.reform,
    vm.data.reform,
    vm.stream.reform,
  ].reform.print

echo &"formic.id build {buildDescr}"
var v = initVM()
var vm = addr(v)
var line = ""
while true:
  echo vm.stor
  try:
    if not readLine(stdin, line): break
    let (forms, elided) = line.parse.parse
    if elided: echo "We do not transmit elided sources to virtual machines."
    vm.tuck_in(forms)
    vm.advance()
  except Exception as e: echo e.msg
