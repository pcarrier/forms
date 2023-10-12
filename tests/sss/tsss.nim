import std/unittest, sss

suite "sss parser":
  test "parses the empty string":
    check(parse("").len == 0)
  test "parses a single token with spaces":
    check(parse(" sym\n") == @[Token(kind: Symbol, quoting: None, value: "sym")])
  test "parses a simple sequence":
    check(parse("sym \\\"sym\" 'str \"str\"") == @[
      Token(kind: Symbol, quoting: None, value: "sym"),
      Token(kind: Symbol, quoting: Double, value: "sym"),
      Token(kind: String, quoting: Single, value: "str"),
      Token(kind: String, quoting: Double, value: "str")])
  test "parses \\00, \\ff and Unicode":
    check(parse("\\u2705 '\\u2705 \"\\u2705\" \"\\ff\" \\00") == @[
      Token(kind: Symbol, quoting: None, value: "✅"),
      Token(kind: String, quoting: Single, value: "✅"),
      Token(kind: String, quoting: Double, value: "✅"),
      Token(kind: String, quoting: Double, value: "\ff"),
      Token(kind: Symbol, quoting: None, value: "\0")])
  test "lets us make fun symbols":
    check(parse("\\'' \\'\" \\\"\\\"\"") == @[
      Token(kind: Symbol, quoting: Single, value: "'"),
      Token(kind: Symbol, quoting: Single, value: "\""),
      Token(kind: Symbol, quoting: Double, value: "\"")])

suite "sss printer":
  test "prints the empty string":
    check(print(@[]) == "")
  test "prints tokens":
    check(print(@[Token(kind: Symbol, quoting: None, value: "sym")]) == "sym")
    check(print(@[Token(kind: Symbol, quoting: Single, value: "sym")]) == "\\'sym")
    check(print(@[Token(kind: Symbol, quoting: Double, value: "sym")]) == "\\\"sym\"")

suite "sss roundtrips":
  let chunks = @["😅", " ", "'", "\"", "\\", "\\00", "\\u0000", "\x00", "\u0000"];

  test "parses and prints and parses and prints the same":
    for i in len(chunks)..10_000:
      block subtest:
        var j = i
        var str = ""
        while j >= len(chunks):
          add(str, chunks[j mod chunks.len])
          j = j div chunks.len
        let parsed =
          try: parse(str)
          except ParseError: break subtest
        let printed = print(parsed)
        let reparsed = parse(printed)
        check(parsed == reparsed)
        let reprinted = print(reparsed)
        check(reprinted == printed)
