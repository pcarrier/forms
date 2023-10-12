import std/[sequtils, tables, unittest], form, sss, stor

func newRef(value: Form): Ref =
  result = new(Ref)
  result[] = value


suite "stor parser":
  test "handles a form with spaces":
    let stream = parse("foo\\ bar")
    let (parsed, _) = parse(stream)
    check(parsed == @[Form(kind: Sym, sym: "foo bar")])
  test "handles a non-trivial form":
    let stream = parse("{ [ foo #f16 +inf ] #b \"hello\" } #u8 0 send")
    let (parsed, _) = parse(stream)
    let expected = @[
      Form(kind: Map, map: toOrderedTable[Ref, Ref]({
        newRef(Form(kind: Vec, vec: @[
          newRef(Form(kind: Sym, sym: "foo")),
          newRef(Form(kind: F16, f16: Inf)),
        ])): newRef(Form(kind: Bin, bin: "hello")),
      })),
      Form(kind: U8, u8: 0),
      Form(kind: Sym, sym: "send"),
    ]
    check(parsed == expected)

suite "stor printer":
  test "outputs spaces and zeros escaped":
    let forms = @[Form(kind: Sym, sym: "foo bar\x00quz").refer, Form(kind: U8, u8: 0).refer]
    let expected = "foo\\ bar\\00quz #u8 0"
    check(print(forms) == expected)

suite "sss roundtrips":
  let chunks = @["😅", " ", "'", "\"", "\\", "\\00", "\\u0000", "\x00", "\u0000", " { ", " } ", "%", "[", "]", "#c"];

  test "parses and prints and parses and prints the same":
    for i in len(chunks)..10_000:
      block subtest:
        var j = i
        var str = ""
        while j >= len(chunks):
          add(str, chunks[j mod chunks.len])
          j = j div chunks.len
        checkpoint(str)
        let (parsed, _) =
          try: str.parse.parse
          except ParseError: break subtest
        let printed = parsed.map(refer).print
        let resss = printed.parse
        let (reparsed, _) = resss.parse
        check(parsed == reparsed)
        let reprinted = print(reparsed.map(refer))
        check(reprinted == printed)
