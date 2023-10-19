from parseutils import parseHex
from strformat import `&`
from algorithm import reversed

type CppString {.header: "<string>", importcpp: "std::string".} = object
proc cStr(self: CppString): cstring {.importcpp: "const_cast<char*>(#.c_str())".}

proc evalJS(msg: cstring) {.importc.}
proc wasmSTOR(ccode: CppString) {.exportcpp.}

{.emit: """
#include "cheerp/client.h"
#include "cheerp/clientlib.h"

using namespace client;

[[cheerp::genericjs]] std::string clientToCpp(const client::String* str) {
    std::string res;

    const size_t len = str->get_length();
    for (size_t i = 0; i < len; ++i) {
        int u = str->charCodeAt(i);
        if (u >= 0xD800 && u <= 0xDFFF) {
            int u1 = str->charCodeAt(++i);
            u = 0x10000 + ((u & 0x3FF) << 10) | (u1 & 0x3FF);
        }
        if (u < 0 || u > 0xFFFF) {
            u = 0xFFFD; // Was invalid character, use replacement characer U+FFFD
        }
        if (u <= 0x7F) {
            res.push_back(u);
        } else if (u < 0x7FF) {
            res.push_back(0xC0 | (u >> 6));
            res.push_back(0x80 | (u & 63));
        } else {
            res.push_back(0xE0 | (u >> 12));
            res.push_back(0x80 | ((u >> 6) & 63));
            res.push_back(0x80 | (u & 63));
        }
    }
    return res;
}

[[cheerp::genericjs]] void evalJS(const char* str)
{
  client::window.eval(client::String::fromUtf8(str));
}

[[cheerp::jsexport]] [[cheerp::genericjs]] void sendSTOR(const client::String* str)
{
  wasmSTOR(clientToCpp(str));
}
""".}

func jsString*(s: string): string =
  result = newStringOfCap(s.len + s.len shr 2)
  add(result, "\"")
  for c in items(s):
    case c
    of '\\': add(result, "\\\\")
    of '\'': add(result, "\\'")
    of '\"': add(result, "\\\\\"")
    else: add(result, c)
  add(result, "\"")

proc wasmSTOR(ccode: CppString) {.exportcpp.} =
  let code = $(ccode.cStr())
  var v = ""
  for i in countdown(code.len - 1, 0):
    if code[i] in  {'0'..'9', 'a'..'f'}:
      v.add(code[i])
    else:
      break
  var round: int = 0
  if v.len > 0: discard parseHex(v.reversed, round)
  let newCode = code[0 ..< (code.len - v.len)] & &" {round + 1:x}"
  let prefix = &"Can't evaluate <tt>{code.jsString}</tt> (or anything yet).<br/><i>— Nim code running in wasm in a WebWorker after 0x"
  evalJS(cstring(&"self.postMessage('$target.innerHTML = {prefix.jsString}.concat(\\'{round:x}\\').concat(\" window roundtrips.</i>\");$worker.postMessage({newCode.jsString})')"))
