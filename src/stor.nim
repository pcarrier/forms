import std/[base64, deques, parseutils, intsets, tables], best, form

func parse(src: openArray[Token]; i: var int,  elided: var bool): Form

func parseVec(src: openArray[Token]; i: var int, elided: var bool, sep: string): Form =
  if i == len(src):
    raise newException(ParseError, "unterminated vector")
  result = Form(kind: Vec)
  while i < len(src) and
      (src[i].kind != Symbol or src[i].quoting != None or src[i].value != sep):
    let elem = new Ref
    elem[] = parse(src, i, elided)
    result.vec.addLast(elem)
  if i == len(src):
    raise newException(ParseError, "unterminated vector")
  inc i

func parseMap(src: openArray[Token]; i: var int, elided: var bool): Form =
  if i == len(src):
    raise newException(ParseError, "unterminated map")
  result = Form(kind: Map)
  while i < len(src) and (src[i].kind != Symbol or src[i].quoting != None or src[i].value != "}"):
    let key = new Ref
    key[] = parse(src, i, elided)
    if src[i - 1].kind == Symbol and src[i - 1].quoting == None and src[i - 1].value == "}":
      break
    if i == len(src):
      raise newException(ParseError, "unterminated map")
    let val = new Ref
    val[] = parse(src, i, elided)
    result.map[key] = val
    if i == len(src):
      raise newException(ParseError, "unterminated map")
  inc i

func parse(src: openArray[Token]; i: var int, elided: var bool): Form =
  if i == len(src):
    raise newException(ParseError, "unexpected end of input")
  let tok = src[i]
  inc i
  case tok.kind:
  of String:
    return form(tok.value)
  of Symbol:
    if tok.quoting == None:
      case tok.value:
      of "[": return parseVec(src, i, elided, "]")
      of "{": return parseMap(src, i, elided)
      of "(": return tag(parseVec(src, i, elided, ")").refer, CODE_TAG)
      elif tok.value[0] == '#':
        case tok.value:
        of "#u": return form()
        of "#n": return formNull()
        of "#f": return form(false)
        of "#t": return form(true)
        of "#e":
          elided = true
          return formSym("#e")
        of "#c":
          discard parse(src, i, elided)
          return parse(src, i, elided)
        of "#b":
          let next = parse(src, i, elided)
          if next.kind != Str:
            raise newException(ParseError, "expected string after #b")
          return formBin(next.str)
        of "#B":
          let next = parse(src, i, elided)
          if next.kind != Str:
            raise newException(ParseError, "expected string after #b")
          try:
            return formBin(decode(next.str))
          except ValueError:
            raise newException(ParseError, "illegal base64 string")
        of "#f64":
          let next = parse(src, i, elided)
          if next.kind != Sym:
            raise newException(ParseError, "expected symbol after #f64")
          var f: float64
          if parseFloat(next.sym, f) != len(next.sym):
            raise newException(ParseError, "expected float after #f64")
          return formF64(f)
        of "#f32":
          let next = parse(src, i, elided)
          if next.kind != Sym:
            raise newException(ParseError, "expected symbol after #f32")
          var f: float
          if parseFloat(next.sym, f) != len(next.sym):
            raise newException(ParseError, "expected float after #f32")
          return formF32(f)
        of "#f16":
          let next = parse(src, i, elided)
          if next.kind != Sym:
            raise newException(ParseError, "expected symbol after #f16")
          var f: float
          if parseFloat(next.sym, f) != len(next.sym):
            raise newException(ParseError, "expected float after #f16")
          return formF16(f)
        of "#i64":
          let next = parse(src, i, elided)
          if next.kind != Sym:
            raise newException(ParseError, "expected symbol after #i64")
          var i: int64
          if parseBiggestInt(next.sym, i) != len(next.sym):
            raise newException(ParseError, "expected int after #i64")
          return form(i)
        of "#i32":
          let next = parse(src, i, elided)
          if next.kind != Sym:
            raise newException(ParseError, "expected symbol after #i32")
          var i: int
          if parseInt(next.sym, i) != len(next.sym):
            raise newException(ParseError, "expected int after #i32")
          return form(int32(i))
        of "#i16":
          let next = parse(src, i, elided)
          if next.kind != Sym:
            raise newException(ParseError, "expected symbol after #i16")
          var i: int
          if parseInt(next.sym, i) != len(next.sym):
            raise newException(ParseError, "expected int after #i16")
          return form(int16(i))
        of "#i8":
          let next = parse(src, i, elided)
          if next.kind != Sym:
            raise newException(ParseError, "expected symbol after #i8")
          var i: int
          if parseInt(next.sym, i) != len(next.sym):
            raise newException(ParseError, "expected int after #i8")
          return form(int8(i))
        of "#u64":
          let next = parse(src, i, elided)
          if next.kind != Sym:
            raise newException(ParseError, "expected symbol after #u64")
          var u: uint64
          if parseBiggestUint(next.sym, u) != len(next.sym):
            raise newException(ParseError, "expected uint after #u64")
          return form(u)
        of "#u32":
          let next = parse(src, i, elided)
          if next.kind != Sym:
            raise newException(ParseError, "expected symbol after #u32")
          var u: uint
          if parseUint(next.sym, u) != len(next.sym):
            raise newException(ParseError, "expected uint after #u32")
          return form(uint32(u))
        of "#u16":
          let next = parse(src, i, elided)
          if next.kind != Sym:
            raise newException(ParseError, "expected symbol after #u16")
          var u: uint
          if parseUint(next.sym, u) != len(next.sym):
            raise newException(ParseError, "expected uint after #u16")
          return form(uint16(u))
        of "#u8":
          let next = parse(src, i, elided)
          if next.kind != Sym:
            raise newException(ParseError, "expected symbol after #u8")
          var u: uint
          if parseUint(next.sym, u) != len(next.sym):
            raise newException(ParseError, "expected uint after #u8")
          return form(uint8(u))
        else:
          var v: uint64
          if parseBiggestUint(tok.value, v, 1) != len(tok.value) - 1:
            raise newException(ParseError, "invalid #form")
          var next = parse(src, i, elided)
          let tagged = new Ref
          tagged[] = next
          return tag(tagged, v)
      elif tok.value[0] == '%':
        if tok.value.len == 1:
          return formSym(tok.value)
        var v: int
        if parseInt(tok.value[1..^1], v) == len(tok.value) - 1:
          return tag(form(uint8(v)).refer, CODE_TAG)
        else: return formSym(tok.value)
    return formSym(tok.value)

func parse*(src: openArray[Token]): (seq[Form], bool) =
  var sequence: seq[Form] = @[]
  var elided = false
  var i = 0
  while i < src.len: sequence.add(parse(src, i, elided))
  return (sequence, elided)

func addEscaped(s: string, dst: var string, escapeNonAscii: bool) =
  for c in s:
    case c:
      of ' ': add(dst, "\\ ")
      of '\\': add(dst, "\\\\")
      of '\n': add(dst, "\\n")
      of '\r': add(dst, "\\r")
      of '\t': add(dst, "\\t")
      of '\f': add(dst, "\\f")
      of '\v': add(dst, "\\v")
      of '\b': add(dst, "\\b")
      of '\x00': add(dst, "\\00")
      of '\x80'..'\xFF':
        if escapeNonAscii:
          let (left, right) = toHex(c)
          add(dst, '\\')
          add(dst, left)
          add(dst, right)
        else: add(dst, c)
      else: add(dst, c)

proc print*(f: Ref, result: var string, seen: IntSet) =
  var currentlySeen = seen
  if currentlySeen.containsOrIncl(cast[int](f.addr)):
    add(result, "#<elided>")
    return
  case f.kind:
  of Tag:
    if f.tag == CODE_TAG and f.tagged.kind == U8:
      add(result, '%')
      add(result, $f.tagged.u8)
    elif f.tag == CODE_TAG and f.tagged.kind == Vec:
      add(result, '(')
      for elem in f.tagged.vec:
        add(result, ' ')
        print(elem, result, seen)
      add(result, " )")
    else:
      add(result, '#')
      add(result, $f.tag)
      add(result, ' ')
      print(f.tagged, result, seen)
  of Undef:
    add(result, "#u")
  of Null:
    add(result, "#n")
  of Bool:
    if f.b:
      add(result, "#t")
    else:
      add(result, "#f")
  of Sym:
    if f.sym.len == 0 or f.sym[0] in {'#', '[', '{', ']', '}', '"', '\''}:
      add(result, "\\'")
    addEscaped(f.sym, result, false)
  of Str:
    add(result, '\'')
    addEscaped(f.str, result, false)
  of Bin:
    # Arbitrary choice of 16 bytes to peek at bytes for short values.
    if f.bin.len < 16:
      add(result, "#b ")
      addEscaped(f.bin, result, true)
    else:
      add(result, "#B \'")
      add(result, encode(f.bin, safe = true))
  of F64:
    add(result, "#f64 ")
    add(result, $f.f64)
  of F32:
    add(result, "#f32 ")
    add(result, $f.f32)
  of F16:
    add(result, "#f16 ")
    add(result, $f.f16)
  of I64:
    add(result, "#i64 ")
    add(result, $f.i64)
  of I32:
    add(result, "#i32 ")
    add(result, $f.i32)
  of I16:
    add(result, "#i16 ")
    add(result, $f.i16)
  of I8:
    add(result, "#i8 ")
    add(result, $f.i8)
  of U64:
    add(result, "#u64 ")
    add(result, $f.u64)
  of U32:
    add(result, "#u32 ")
    add(result, $f.u32)
  of U16:
    add(result, "#u16 ")
    add(result, $f.u16)
  of U8:
    add(result, "#u8 ")
    add(result, $f.u8)
  of Vec:
    add(result, '[')
    for elem in f.vec:
      add(result, ' ')
      print(elem, result, seen)
    add(result, " ]")
  of Map:
    add(result, '{')
    for key, val in f.map:
      add(result, ' ')
      print(key, result, seen)
      add(result, ' ')
      print(val, result, seen)
    add(result, " }")

proc print*(r: Ref): string =
  var seen = initIntSet()
  print(r, result, seen)

proc print*(src: openArray[Ref]): string =
  var seen = initIntSet()
  for i, form in src:
    if i > 0:
      add(result, ' ')
    print(form, result, seen)

proc `$`*(r: Ref): string =
  r.print

proc `$`*(f: Form): string =
  $(f.refer)
