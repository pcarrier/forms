import std/[hashes, tables]

type
  Kind* = enum
    Tag = 0
    Undef = 1
    Null = 2
    Bool = 3
    Sym = 8
    Str = 9
    Bin = 10
    Vec = 11
    Map = 12
    U64 = 16
    U32 = 17
    U16 = 18
    U8 = 19
    I64 = 32
    I32 = 33
    I16 = 34
    I8 = 35
    F64 = 48
    F32 = 49
    F16 = 50
  Ref* = ref Form
  Form* = object
    case kind*: Kind:
    of Tag:
      tag*: uint64
      tagged*: Ref
    of Undef: discard
    of Null: discard
    of Bool: b*: bool
    of Sym: sym*: string
    of Str: str*: string
    of Bin: bin*: string
    of Vec: vec*: seq[Ref]
    of Map: map*: OrderedTable[Ref, Ref]
    of U64: u64*: uint64
    of U32: u32*: uint32
    of U16: u16*: uint16
    of U8: u8*: uint8
    of I64: i64*: int64
    of I32: i32*: int32
    of I16: i16*: int16
    of I8: i8*: int8
    of F64: f64*: float64
    of F32: f32*: float32
    of F16: f16*: float32

const CODE_TAG* = 6

func `==`*(lhs: Ref, rhs: Ref): bool
func hash*(r: Ref): Hash

func `==`*(lhs: Form, rhs: Form): bool =
  if lhs.kind != rhs.kind: return false
  case lhs.kind:
  of Tag: lhs.tag == rhs.tag and lhs.tagged == rhs.tagged
  of Undef: true
  of Null: true
  of Bool: lhs.b == rhs.b
  of Sym: lhs.sym == rhs.sym
  of Str: lhs.str == rhs.str
  of Bin: lhs.bin == rhs.bin
  of Vec: lhs.vec == rhs.vec
  of Map: lhs.map == rhs.map
  of U64: lhs.u64 == rhs.u64
  of U32: lhs.u32 == rhs.u32
  of U16: lhs.u16 == rhs.u16
  of U8: lhs.u8 == rhs.u8
  of I64: lhs.i64 == rhs.i64
  of I32: lhs.i32 == rhs.i32
  of I16: lhs.i16 == rhs.i16
  of I8: lhs.i8 == rhs.i8
  of F64: lhs.f64 == rhs.f64
  of F32: lhs.f32 == rhs.f32
  of F16: lhs.f16 == rhs.f16

func `==`(lhs: Ref, rhs: Ref): bool =
  not lhs.isNil and not rhs.isNil and (lhs[] == rhs[])

# TODO: avoid cycles (seen pattern)
func hash*(f: Form): Hash =
  var h = f.kind.hash
  case f.kind:
  of Tag:
    h = h !& f.tag.hash
    h = h !& f.tagged.hash
  of Undef: discard
  of Null: discard
  of Bool: h = h !& f.b.hash
  of Sym: h = h !& f.sym.hash
  of Str: h = h !& f.str.hash
  of Bin: h = h !& f.bin.hash
  of Vec: h = h !& f.vec.hash
  of Map: h = h !& f.map.hash
  of U64: h = h !& f.u64.hash
  of U32: h = h !& f.u32.hash
  of U16: h = h !& f.u16.hash
  of U8: h = h !& f.u8.hash
  of I64: h = h !& f.i64.hash
  of I32: h = h !& f.i32.hash
  of I16: h = h !& f.i16.hash
  of I8: h = h !& f.i8.hash
  of F64: h = h !& f.f64.hash
  of F32: h = h !& f.f32.hash
  of F16: h = h !& f.f16.hash
  result = !$h

func hash*(r: Ref): Hash =
  if r.isNil: 0 else: r[].hash

func form*: Form = Form(kind: Undef)
func formNull*: Form = Form(kind: Null)
func form*(value: bool): Form = Form(kind: Bool, b: value)
func form*(value: string): Form = Form(kind: Str, str: value)
func formSym*(value: string): Form = Form(kind: Sym, sym: value)
func formBin*(value: string): Form = Form(kind: Bin, bin: value)
func form*(value: seq[Ref]): Form = Form(kind: Vec, vec: value)
func form*(value: OrderedTable[Ref, Ref]): Form = Form(kind: Map, map: value)
func form*(value: uint64): Form = Form(kind: U64, u64: value)
func form*(value: uint32): Form = Form(kind: U32, u32: value)
func form*(value: uint16): Form = Form(kind: U16, u16: value)
func form*(value: uint8): Form = Form(kind: U8, u8: value)
func form*(value: int64): Form = Form(kind: I64, i64: value)
func form*(value: int32): Form = Form(kind: I32, i32: value)
func form*(value: int16): Form = Form(kind: I16, i16: value)
func form*(value: int8): Form = Form(kind: I8, i8: value)
func formF64*(value: float64): Form = Form(kind: F64, f64: value)
func formF32*(value: float32): Form = Form(kind: F32, f32: value)
func formF16*(value: float32): Form = Form(kind: F16, f16: value)
func tag*(r: Ref, tag: uint64): Form = Form(kind: Tag, tag: tag, tagged: r)

func form*(r: Ref): Form = r[]
func refer*(f: Form): Ref =
  result = new Ref
  result[] = f

template reform*[T](v: T): Ref = v.form.refer

func toInt*(f: Form): int =
  case f.kind:
  of U64: result = int(f.u64)
  of U32: result = int(f.u32)
  of U16: result = int(f.u16)
  of U8: result = int(f.u8)
  of I64: result = int(f.i64)
  of I32: result = int(f.i32)
  of I16: result = int(f.i16)
  of I8: result = int(f.i8)
  of F64: result = int(f.f64)
  of F32: result = int(f.f32)
  of F16: result = int(f.f16)
  of Bool: result = int(f.b)
  else: raise newException(CatchableError, "cannot convert to int")
