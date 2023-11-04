import std/[deques, strutils, tables], form, jsony

export form

template error(msg: string, i: int) =
  ## Shortcut to raise an exception.
  raise newException(JsonError, msg & " At offset: " & $i)

proc parseHook*(s: string, i: var int, v: var Form) =
  eatSpace(s, i)
  if i < s.len and s[i] == '{':
    v = Form(kind: Map)
    eatChar(s, i, '{')
    while i < s.len:
      eatSpace(s, i)
      if i < s.len and s[i] == '}':
        break
      var k: string
      parseHook(s, i, k)
      eatChar(s, i, ':')
      var e: Form
      parseHook(s, i, e)
      v.map[k.reform] = e.refer
      eatSpace(s, i)
      if i < s.len and s[i] == ',':
        inc i
    eatChar(s, i, '}')
  elif i < s.len and s[i] == '[':
    v = Form(kind: Vec)
    eatChar(s, i, '[')
    while i < s.len:
      eatSpace(s, i)
      if i < s.len and s[i] == ']':
        break
      var e: Form
      parseHook(s, i, e)
      v.vec.addLast(e.refer)
      eatSpace(s, i)
      if i < s.len and s[i] == ',':
        inc i
    eatChar(s, i, ']')
  elif i < s.len and s[i] == '"':
    var str: string
    parseHook(s, i, str)
    v = Form(kind: Str, str: str)
  else:
    var data = parseSymbol(s, i)
    if data == "null":
      v = Form(kind: Null)
    elif data == "true":
      v = Form(kind: Bool, b: true)
    elif data == "false":
      v = Form(kind: Bool, b: false)
    elif data.len > 0 and data[0] in {'0'..'9', '-', '+'}:
      try:
        v = Form(kind: I64, i64: parseBiggestInt(data).int64)
      except ValueError:
        try:
          v = Form(kind: F64, f64: parseFloat(data))
        except ValueError:
          error("Invalid number.", i)
    else:
      error("Unexpected.", i)

proc jsonForm*(str: string): Form =
  str.fromJson(Form)
