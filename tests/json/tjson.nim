import std/unittest, form, stor, json

suite "json parsing":
  test "parses null":
    check("null".jsonForm == Form(kind: Null))
  test "parses bools":
    check("true".jsonForm == Form(kind: Bool, b: true))
    check("false".jsonForm == Form(kind: Bool, b: false))
  test "parses strings":
    check("\"hello\"".jsonForm == Form(kind: Str, str: "hello"))
  test "parses numbers":
    check("12.3".jsonForm == Form(kind: F64, f64: 12.3))
  test "parses objects and arrays":
    check($"{\"hello\":[\"world\"]}".jsonForm == "{ 'hello [ 'world ] }")
