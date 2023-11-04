from unicode import add, Rune

type
  ParseError* = object of CatchableError
  PrintError* = object of CatchableError
  Kind* = enum
    String, Symbol
  Quoting* = enum
    None, Single, Double
  Token* = object
    kind*: Kind
    quoting*: Quoting
    value*: string

func parseHex*(c: char): int =
  case c:
  of '0'..'9':
    result = int(c) - int('0')
  of 'A'..'F':
    result = int(c) - int('A') + 10
  else:
    raise newException(ParseError, "invalid hex digit")

const hexDigits = "0123456789ABCDEF"

func toHex*(c: char): (char, char) =
  let n = uint8(c)
  let leftNibble = n shr 4
  let rightNibble = n and 0xF
  return (hexDigits[leftNibble], hexDigits[rightNibble])

func parseEscape(src: string, i: var int, dst: var string) =
  if i == len(src): raise newException(ParseError, "unterminated escape sequence")
  let c = src[i]
  inc i
  case c:
  of '\'', '"', '\\', ' ':
    add(dst, c)
  of 'n':
    add(dst, '\n')
  of 'r':
    add(dst, '\r')
  of 't':
    add(dst, '\t')
  of 'f':
    add(dst, '\f')
  of 'v':
    add(dst, '\v')
  of 'b':
    add(dst, '\b')
  of '0'..'9', 'A'..'F':
    var n = parseHex(c)
    if i == len(src): raise newException(ParseError, "unterminated escape sequence")
    let c2 = src[i]
    inc i
    case c2:
    of '0'..'9', 'A'..'F':
      add(dst, chr(n shl 4 or parseHex(c2)))
    else:
      raise newException(ParseError, "invalid escape sequence")
  of 'u':
    if i + 4 >= len(src): raise newException(ParseError, "unterminated escape sequence")
    var n = 0
    for j in 0..3:
      n = n shl 4 or parseHex(src[i])
      inc i
    add(dst, Rune(n))
  else:
    raise newException(ParseError, "invalid escape sequence")

func parseDoubleQuotes(src: string, i: var int, dst: var string) =
  while i < len(src):
    var c = src[i]
    inc i
    case c:
    of '"':
      return
    of '\\':
      parseEscape(src, i, dst)
    else:
      add(dst, c)
  raise newException(ParseError, "unterminated string")

func parseUntilSpace(src: string, i: var int, dst: var string) =
  while i < len(src):
    var c = src[i]
    inc i
    case c:
    of ' ', '\n', '\r', '\t', '\f', '\v':
      break
    of '\\':
      if i == len(src): raise newException(ParseError, "unterminated escape sequence")
      parseEscape(src, i, dst)
    else:
      add(dst, c)

func parse*(src: string): seq[Token] =
  result = @[]
  var i = 0
  while i < len(src):
    let c = src[i]
    inc i
    case c:
    of ' ', '\n', '\r', '\t', '\f', '\v':
      discard
    of '"':
      var value = ""
      parseDoubleQuotes(src, i, value)
      add(result, Token(kind: String, quoting: Double, value: value))
    of '\'':
      var value = ""
      parseUntilSpace(src, i, value)
      add(result, Token(kind: String, quoting: Single, value: value))
    of '\\':
      if i == len(src): raise newException(ParseError, "unterminated escape sequence")
      let c2 = src[i]
      var value = ""
      case c2:
        of '"':
          inc i
          parseDoubleQuotes(src, i, value)
          add(result, Token(kind: Symbol, quoting: Double, value: value))
        else:
          parseEscape(src, i, value)
          parseUntilSpace(src, i, value)
          add(result, Token(kind: Symbol, quoting: None, value: value))
    else:
      var value = ""
      add(value, c)
      parseUntilSpace(src, i, value)
      add(result, Token(kind: Symbol, quoting: None, value: value))

func printValue(dst: var string, value: string, inDoubleQuotes: bool) =
  for c in value:
    case c:
    of ' ':
      if inDoubleQuotes: add(dst, ' ') else: add(dst, "\\ ")
    of '\n':
      add(dst, "\\n")
    of '\r':
      add(dst, "\\r")
    of '\t':
      add(dst, "\\t")
    of '\f':
      add(dst, "\\f")
    of '\v':
      add(dst, "\\v")
    of '\b':
      add(dst, "\\b")
    of '\0':
      add(dst, "\\00")
    of '\\':
      add(dst, "\\\\")
    of '"':
      if inDoubleQuotes: add(dst, '\\')
      add(dst, '"')
    of '\x80'..'\xFF':
      add(dst, '\\')
      let (left, right) = toHex(c)
      add(dst, left)
      add(dst, right)
    else:
      add(dst, c)

func printToken(dst: var string, token: Token) =
  case token.kind
  of Kind.String:
    case token.quoting
    of None:
      raise newException(PrintError, "cannot produce unquoted strings")
    of Single:
      add(dst, '\'')
      printValue(dst, token.value, false)
    of Double:
      add(dst, '"')
      printValue(dst, token.value, true)
      add(dst, '"')
  of Kind.Symbol:
    case token.quoting
    of None:
      printValue(dst, token.value, false)
    of Single:
      add(dst, "\\\'")
      printValue(dst, token.value, false)
    of Double:
      add(dst, "\\\"")
      printValue(dst, token.value, true)
      add(dst, '"')

func print*(src: openArray[Token]): string =
  result = ""
  if len(src) == 0: return
  for i, token in src:
    if i > 0: add(result, ' ')
    printToken(result, token)
