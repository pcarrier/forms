import std/[deques, strformat, tables], form, jsony

proc addSap(str: var string, r: Ref) =
  str.add(&"[{r.kind.ord}")
  case r.kind:
  of Tag:
    str.add(&",\"{r.tag}\",")
    str.addSap(r.tagged)
  of Undef, Null: discard
  of Bool:
    if r.b:
      str.add(",true")
    else:
      str.add(",false")
  of Sym:
    str.add(&",{r.sym.toJSON()}")
  of Str:
    str.add(&",{r.str.toJSON()}")
  of Bin:
    str.add(&",{r.bin.toJSON()}")
  of Vec:
    for e in r.vec.items:
      str.add(',')
      str.addSap(e)
  of Map:
    for k, v in r.map.pairs:
      str.add(',')
      str.addSap(k)
      str.add(',')
      str.addSap(v)
  of U64:
    str.add(&",\"{r.u64}\"")
  of I64:
    str.add(&",\"{r.i64}\"")
  of F64:
    str.add(&",\"{r.f64}\"")
  of U32:
    str.add(&",\"{r.u32}\"")
  of I32:
    str.add(&",\"{r.i32}\"")
  of F32:
    str.add(&",\"{r.f32}\"")
  of U16:
    str.add(&",\"{r.u16}\"")
  of I16:
    str.add(&",\"{r.i16}\"")
  of F16:
    str.add(&",\"{r.f16}\"")
  of U8:
    str.add(&",\"{r.u8}\"")
  of I8:
    str.add(&",\"{r.i8}\"")
  str.add("]")


proc sap*(r: Ref): string =
  result.addSap(r)
