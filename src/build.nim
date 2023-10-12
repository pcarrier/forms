import std/strformat

const buildDescr* =
  &"{staticExec(\"git describe --tags --abbrev=0 --dirty --always\")} ({CompileDate}T{CompileTime}Z)"
