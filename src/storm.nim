import std/[algorithm, bitops, deques, parseutils, sequtils, strformat, tables], form, stor

type
  Invalid* = object of CatchableError
  Status* = enum
    RUNNING, FAULT, HALT
  PCode = enum
    HALT = 0, NOOP = 1, EVAL = 2, KIND = 3, SIZE = 4, UNTAG = 5, TAG = 6, R7 = 7, ENTER = 8, LEAVE = 9, CLEAR_STREAM = 10, CLEAR_DATA = 11, R12 = 12, R13 = 13, R14 = 14, R15 = 15,
    RECV = 16, SEND = 17, R18 = 18, R19 = 19, READ = 20, DISCARD_STREAM = 21, R22 = 22, R23 = 23,
    PUSH = 24, POP = 25, R26 = 26, R27 = 27, R28 = 28, R29 = 29, SET = 30, GET = 31, R32 = 32,
    PUSH_DATA = 33, PUSH_STREAM = 34, PUSH_CONTEXTS = 35, R36 = 36, R37 = 37, R38 = 38, R39 = 39, R40 = 40, R41 = 41, R42 = 42, R43 = 43, R44 = 44, R45 = 45, R46 = 46, R47 = 47,
    DROP = 48, PICK = 49, R50, SWAP = 51, R52 = 52, R53 = 53, R54 = 54, R55 = 55, R56 = 56, R57 = 57, R58 = 58, R59 = 59, R60 = 60, R61 = 61, R62 = 62, R63 = 63,
    ADD = 64, SUB = 65, PROD = 66, DIV = 67, R68, MOD = 69, DIVMOD = 70, POW = 71, LT = 72, GT = 73, EQ = 74, LE = 75, GE = 76, AND = 77, OR = 78, NOT = 79, SHL = 80, SHR = 81
    TO_U8 = 82, TO_U16 = 83, TO_U32 = 84, TO_U64 = 85, TO_I8 = 86, TO_I16 = 87, TO_I32 = 88, TO_I64 = 89, TO_F16 = 90, TO_F32 = 91, TO_F64 = 92, TO_STR = 93, TO_SYM = 94
  RefDeq* = Deque[Ref]
  VM* = object
    status*: Status
    step*: BiggestUInt
    data*: RefDeq
    contexts*: RefDeq
    stream*: RefDeq

proc initVM*(): VM =
  result = VM(
    status: RUNNING,
    step: 0,
    data: initDeque[Ref](),
    contexts: initDeque[Ref](),
    stream: initDeque[Ref]()
  )

proc `$`*(vm: VM): string = &"{vm.data} ← {vm.stream} @ {vm.contexts}"

proc lookup(vm: ptr VM, r: Ref): ptr Ref

proc lookup(vm: ptr VM, ctx: Ref, r: Ref): ptr Ref =
  case ctx.kind:
  of Map:
    try: return ctx.map[r].addr except: return nil
  # TODO: vecs?
  else:
    let c = vm.lookup(ctx)
    if c != nil: result = vm.lookup(c[], r)

proc lookup(vm: ptr VM, r: Ref): ptr Ref =
  for ctx in vm.contexts:
    result = vm.lookup(ctx, r)
    if not result.isNil: break

proc eval(vm: ptr VM, r: Ref)

proc add(vm: ptr VM) =
  if vm.data.len < 2: raise newException(Invalid, "deque underflow")
  let b = vm.data.popLast
  let a = vm.data.popLast
  if a.kind != b.kind: raise newException(Invalid, &"kind mismatch")
  case a.kind:
  of U64: vm.data.addLast((a.u64 + b.u64).reform)
  of I64: vm.data.addLast((a.i64 + b.i64).reform)
  of F64: vm.data.addLast((a.f64 + b.f64).formF64.refer)
  of U32: vm.data.addLast((a.u32 + b.u32).reform)
  of I32: vm.data.addLast((a.i32 + b.i32).reform)
  of F32: vm.data.addLast((a.f32 + b.f32).formF32.refer)
  of U16: vm.data.addLast((a.u16 + b.u16).reform)
  of I16: vm.data.addLast((a.i16 + b.i16).reform)
  of F16: vm.data.addLast((a.f16 + b.f16).formF16.refer)
  of U8: vm.data.addLast((a.u8 + b.u8).reform)
  of I8: vm.data.addLast((a.i8 + b.i8).reform)
  of Str: vm.data.addLast((a.str & b.str).reform)
  of Bin: vm.data.addLast((a.bin & b.bin).reform)
  of Vec: vm.data.addLast((a.vec & b.vec).reform)
  of Map:
    var res = a.map
    for k, v in b.map: res[k] = v
    vm.data.addLast(res.reform)
  else: raise newException(Invalid, &"unsupported kind {a.kind}")

proc sub(vm: ptr VM) =
  if vm.data.len < 2: raise newException(Invalid, "deque underflow")
  let b = vm.data.popLast
  let a = vm.data.popLast
  if a.kind != b.kind: raise newException(Invalid, &"kind mismatch")
  case a.kind:
  of U64: vm.data.addLast((a.u64 - b.u64).reform)
  of I64: vm.data.addLast((a.i64 - b.i64).reform)
  of F64: vm.data.addLast((a.f64 - b.f64).formF64.refer)
  of U32: vm.data.addLast((a.u32 - b.u32).reform)
  of I32: vm.data.addLast((a.i32 - b.i32).reform)
  of F32: vm.data.addLast((a.f32 - b.f32).formF32.refer)
  of U16: vm.data.addLast((a.u16 - b.u16).reform)
  of I16: vm.data.addLast((a.i16 - b.i16).reform)
  of F16: vm.data.addLast((a.f16 - b.f16).formF16.refer)
  of U8: vm.data.addLast((a.u8 - b.u8).reform)
  of I8: vm.data.addLast((a.i8 - b.i8).reform)
  else: raise newException(Invalid, &"unsupported kind {a.kind}")

proc size(vm: ptr VM) =
  if vm.data.len < 1: raise newException(Invalid, "deque underflow")
  let v = vm.data.popLast
  case v.kind:
  of Map: vm.data.addLast(v.map.len.reform)
  of Vec: vm.data.addLast(v.vec.len.reform)
  of Bin: vm.data.addLast(v.bin.len.reform)
  of Str: vm.data.addLast(v.str.len.reform)
  of Sym: vm.data.addLast(v.sym.len.reform)
  of U64, I64, F64: vm.data.addLast(8'u8.reform)
  of U32, I32, F32: vm.data.addLast(4'u8.reform)
  of U16, I16, F16: vm.data.addLast(2'u8.reform)
  of U8, I8: vm.data.addLast(1'u8.reform)
  else: raise newException(Invalid, &"no size for {v}")

proc prod(vm: ptr VM) =
  if vm.data.len < 2: raise newException(Invalid, "deque underflow")
  let a = vm.data.popLast
  let b = vm.data.popLast
  if a.kind != b.kind: raise newException(Invalid, &"kind mismatch")
  case a.kind:
  of U64: vm.data.addLast((a.u64 * b.u64).reform)
  of I64: vm.data.addLast((a.i64 * b.i64).reform)
  of F64: vm.data.addLast((a.f64 * b.f64).formF64.refer)
  of U32: vm.data.addLast((a.u32 * b.u32).reform)
  of I32: vm.data.addLast((a.i32 * b.i32).reform)
  of F32: vm.data.addLast((a.f32 * b.f32).formF32.refer)
  of U16: vm.data.addLast((a.u16 * b.u16).reform)
  of I16: vm.data.addLast((a.i16 * b.i16).reform)
  of F16: vm.data.addLast((a.f16 * b.f16).formF16.refer)
  of U8: vm.data.addLast((a.u8 * b.u8).reform)
  of I8: vm.data.addLast((a.i8 * b.i8).reform)
  else: raise newException(Invalid, &"unsupported kind {a.kind}")

proc lt(vm: ptr VM) =
  if vm.data.len < 2: raise newException(Invalid, "deque underflow")
  let b = vm.data.popLast
  let a = vm.data.popLast
  if a.kind != b.kind: raise newException(Invalid, &"kind mismatch")
  case a.kind:
  of U64: vm.data.addLast((a.u64 < b.u64).reform)
  of I64: vm.data.addLast((a.i64 < b.i64).reform)
  of F64: vm.data.addLast((a.f64 < b.f64).reform)
  of U32: vm.data.addLast((a.u32 < b.u32).reform)
  of I32: vm.data.addLast((a.i32 < b.i32).reform)
  of F32: vm.data.addLast((a.f32 < b.f32).reform)
  of U16: vm.data.addLast((a.u16 < b.u16).reform)
  of I16: vm.data.addLast((a.i16 < b.i16).reform)
  of F16: vm.data.addLast((a.f16 < b.f16).reform)
  of U8: vm.data.addLast((a.u8 < b.u8).reform)
  of I8: vm.data.addLast((a.i8 < b.i8).reform)
  else: raise newException(Invalid, &"unsupported kind {a.kind}")

proc gt(vm: ptr VM) =
  if vm.data.len < 2: raise newException(Invalid, "deque underflow")
  let b = vm.data.popLast
  let a = vm.data.popLast
  if a.kind != b.kind: raise newException(Invalid, &"kind mismatch")
  case a.kind:
  of U64: vm.data.addLast((a.u64 > b.u64).reform)
  of I64: vm.data.addLast((a.i64 > b.i64).reform)
  of F64: vm.data.addLast((a.f64 > b.f64).reform)
  of U32: vm.data.addLast((a.u32 > b.u32).reform)
  of I32: vm.data.addLast((a.i32 > b.i32).reform)
  of F32: vm.data.addLast((a.f32 > b.f32).reform)
  of U16: vm.data.addLast((a.u16 > b.u16).reform)
  of I16: vm.data.addLast((a.i16 > b.i16).reform)
  of F16: vm.data.addLast((a.f16 > b.f16).reform)
  of U8: vm.data.addLast((a.u8 > b.u8).reform)
  of I8: vm.data.addLast((a.i8 > b.i8).reform)
  else: raise newException(Invalid, &"unsupported kind {a.kind}")

proc eq(vm: ptr VM) =
  if vm.data.len < 2: raise newException(Invalid, "deque underflow")
  vm.data.addLast((vm.data.popLast == vm.data.popLast).reform)

proc le(vm: ptr VM) =
  if vm.data.len < 2: raise newException(Invalid, "deque underflow")
  let b = vm.data.popLast
  let a = vm.data.popLast
  if a.kind != b.kind: raise newException(Invalid, &"kind mismatch")
  case a.kind:
  of U64: vm.data.addLast((a.u64 >= b.u64).reform)
  of I64: vm.data.addLast((a.i64 >= b.i64).reform)
  of F64: vm.data.addLast((a.f64 >= b.f64).reform)
  of U32: vm.data.addLast((a.u32 >= b.u32).reform)
  of I32: vm.data.addLast((a.i32 >= b.i32).reform)
  of F32: vm.data.addLast((a.f32 >= b.f32).reform)
  of U16: vm.data.addLast((a.u16 >= b.u16).reform)
  of I16: vm.data.addLast((a.i16 >= b.i16).reform)
  of F16: vm.data.addLast((a.f16 >= b.f16).reform)
  of U8: vm.data.addLast((a.u8 >= b.u8).reform)
  of I8: vm.data.addLast((a.i8 >= b.i8).reform)
  else: raise newException(Invalid, &"unsupported kind {a.kind}")

proc ge(vm: ptr VM) =
  if vm.data.len < 2: raise newException(Invalid, "deque underflow")
  let b = vm.data.popLast
  let a = vm.data.popLast
  if a.kind != b.kind: raise newException(Invalid, &"kind mismatch")
  case a.kind:
  of U64: vm.data.addLast((a.u64 <= b.u64).reform)
  of I64: vm.data.addLast((a.i64 <= b.i64).reform)
  of F64: vm.data.addLast((a.f64 <= b.f64).reform)
  of U32: vm.data.addLast((a.u32 <= b.u32).reform)
  of I32: vm.data.addLast((a.i32 <= b.i32).reform)
  of F32: vm.data.addLast((a.f32 <= b.f32).reform)
  of U16: vm.data.addLast((a.u16 <= b.u16).reform)
  of I16: vm.data.addLast((a.i16 <= b.i16).reform)
  of F16: vm.data.addLast((a.f16 <= b.f16).reform)
  of U8: vm.data.addLast((a.u8 <= b.u8).reform)
  of I8: vm.data.addLast((a.i8 <= b.i8).reform)
  else: raise newException(Invalid, &"unsupported kind {a.kind}")


proc andOp(vm: ptr VM) =
  if vm.data.len < 2: raise newException(Invalid, "deque underflow")
  let a = vm.data.popLast
  let b = vm.data.popLast
  if a.kind != b.kind: raise newException(Invalid, &"kind mismatch")
  case a.kind:
  of U64: vm.data.addLast(bitand(a.u64, b.u64).reform)
  of U32: vm.data.addLast(bitand(a.u32, b.u32).reform)
  of U16: vm.data.addLast(bitand(a.u16, b.u16).reform)
  of U8: vm.data.addLast(bitand(a.u8, b.u8).reform)
  of I64: vm.data.addLast(bitand(a.i64, b.i64).reform)
  of I32: vm.data.addLast(bitand(a.i32, b.i32).reform)
  of I16: vm.data.addLast(bitand(a.i16, b.i16).reform)
  of I8: vm.data.addLast(bitand(a.i8, b.i8).reform)
  of Bool: vm.data.addLast((a.b and b.b).reform)
  else: raise newException(Invalid, &"unsupported kind {a.kind}")

proc orOp(vm: ptr VM) =
  if vm.data.len < 2: raise newException(Invalid, "deque underflow")
  let a = vm.data.popLast
  let b = vm.data.popLast
  if a.kind != b.kind: raise newException(Invalid, &"kind mismatch")
  case a.kind:
  of U64: vm.data.addLast(bitor(a.u64, b.u64).reform)
  of U32: vm.data.addLast(bitor(a.u32, b.u32).reform)
  of U16: vm.data.addLast(bitor(a.u16, b.u16).reform)
  of U8: vm.data.addLast(bitor(a.u8, b.u8).reform)
  of I64: vm.data.addLast(bitor(a.i64, b.i64).reform)
  of I32: vm.data.addLast(bitor(a.i32, b.i32).reform)
  of I16: vm.data.addLast(bitor(a.i16, b.i16).reform)
  of I8: vm.data.addLast(bitor(a.i8, b.i8).reform)
  of Bool: vm.data.addLast((a.b or b.b).reform)
  else: raise newException(Invalid, &"unsupported kind {a.kind}")

proc notOp(vm: ptr VM) =
  if vm.data.len < 1: raise newException(Invalid, "deque underflow")
  let x = vm.data.popLast
  case x.kind:
  of U64: vm.data.addLast(x.u64.bitnot.reform)
  of U32: vm.data.addLast(x.u32.bitnot.reform)
  of U16: vm.data.addLast(x.u16.bitnot.reform)
  of U8: vm.data.addLast(x.u8.bitnot.reform)
  of I64: vm.data.addLast(x.i64.bitnot.reform)
  of I32: vm.data.addLast(x.i32.bitnot.reform)
  of I16: vm.data.addLast(x.i16.bitnot.reform)
  of I8: vm.data.addLast(x.i8.bitnot.reform)
  of Bool: vm.data.addLast(x.b.not.reform)
  else: raise newException(Invalid, &"unsupported kind {x.kind}")

proc shlOp(vm: ptr VM) =
  if vm.data.len < 2: raise newException(Invalid, "deque underflow")
  let x = vm.data.popLast
  let y = vm.data.popLast
  let n = try: y[].toInt except: raise newException(Invalid, &"invalid shift {y}")
  case x.kind:
  of U64: vm.data.addLast((x.u64 shl n).reform)
  of U32: vm.data.addLast((x.u32 shl n).reform)
  of U16: vm.data.addLast((x.u16 shl n).reform)
  of U8: vm.data.addLast((x.u8 shl n).reform)
  of I64: vm.data.addLast((x.i64 shl n).reform)
  of I32: vm.data.addLast((x.i32 shl n).reform)
  of I16: vm.data.addLast((x.i16 shl n).reform)
  of I8: vm.data.addLast((x.i8 shl n).reform)
  else: raise newException(Invalid, &"unsupported kind {x.kind}")

proc shrOp(vm: ptr VM) =
  if vm.data.len < 2: raise newException(Invalid, "deque underflow")
  let x = vm.data.popLast
  let y = vm.data.popLast
  let n = try: y[].toInt except: raise newException(Invalid, &"invalid shift {y}")
  case x.kind:
  of U64: vm.data.addLast((x.u64 shr n).reform)
  of U32: vm.data.addLast((x.u32 shr n).reform)
  of U16: vm.data.addLast((x.u16 shr n).reform)
  of U8: vm.data.addLast((x.u8 shr n).reform)
  of I64: vm.data.addLast((x.i64 shr n).reform)
  of I32: vm.data.addLast((x.i32 shr n).reform)
  of I16: vm.data.addLast((x.i16 shr n).reform)
  of I8: vm.data.addLast((x.i8 shr n).reform)
  else: raise newException(Invalid, &"unsupported kind {x.kind}")

proc toU8(vm: ptr VM) =
  if vm.data.len < 1: raise newException(Invalid, "deque underflow")
  let v = vm.data.popLast
  case v.kind
  of U64: vm.data.addLast(uint8(v.u64).reform)
  of U32: vm.data.addLast(uint8(v.u32).reform)
  of U16: vm.data.addLast(uint8(v.u16).reform)
  of U8: vm.data.addLast(v)
  of I64: vm.data.addLast(uint8(v.i64).reform)
  of I32: vm.data.addLast(uint8(v.i32).reform)
  of I16: vm.data.addLast(uint8(v.i16).reform)
  of I8: vm.data.addLast(uint8(v.i8).reform)
  of F64: vm.data.addLast(uint8(v.f64).reform)
  of F32: vm.data.addLast(uint8(v.f32).reform)
  of F16: vm.data.addLast(uint8(v.f16).reform)
  of Bool: vm.data.addLast(uint8(if v.b: 1 else: 0).reform)
  of Str:
    var n: int
    if parseInt(v.str, n) != v.str.len - 1: raise newException(Invalid, &"invalid u8 {v}")
    vm.data.addLast(uint8(n).reform)
  else: raise newException(Invalid, &"unsupported kind {v.kind}")

proc toU16(vm: ptr VM) =
  if vm.data.len < 1: raise newException(Invalid, "deque underflow")
  let v = vm.data.popLast
  case v.kind
  of U64: vm.data.addLast(uint16(v.u64).reform)
  of U32: vm.data.addLast(uint16(v.u32).reform)
  of U16: vm.data.addLast(v)
  of U8: vm.data.addLast(uint16(v.u8).reform)
  of I64: vm.data.addLast(uint16(v.i64).reform)
  of I32: vm.data.addLast(uint16(v.i32).reform)
  of I16: vm.data.addLast(uint16(v.i16).reform)
  of I8: vm.data.addLast(uint16(v.i8).reform)
  of F64: vm.data.addLast(uint16(v.f64).reform)
  of F32: vm.data.addLast(uint16(v.f32).reform)
  of F16: vm.data.addLast(uint16(v.f16).reform)
  of Bool: vm.data.addLast(uint16(if v.b: 1 else: 0).reform)
  of Str:
    var n: int
    if parseInt(v.str, n) != v.str.len - 1: raise newException(Invalid, &"invalid u16 {v}")
    vm.data.addLast(uint16(n).reform)
  else: raise newException(Invalid, &"unsupported kind {v.kind}")

proc toU32(vm: ptr VM) =
  if vm.data.len < 1: raise newException(Invalid, "deque underflow")
  let v = vm.data.popLast
  case v.kind
  of U64: vm.data.addLast(uint32(v.u64).reform)
  of U32: vm.data.addLast(v)
  of U16: vm.data.addLast(uint32(v.u16).reform)
  of U8: vm.data.addLast(uint32(v.u8).reform)
  of I64: vm.data.addLast(uint32(v.i64).reform)
  of I32: vm.data.addLast(uint32(v.i32).reform)
  of I16: vm.data.addLast(uint32(v.i16).reform)
  of I8: vm.data.addLast(uint32(v.i8).reform)
  of F64: vm.data.addLast(uint32(v.f64).reform)
  of F32: vm.data.addLast(uint32(v.f32).reform)
  of F16: vm.data.addLast(uint32(v.f16).reform)
  of Bool: vm.data.addLast(uint32(if v.b: 1 else: 0).reform)
  of Str:
    var n: int
    if parseInt(v.str, n) != v.str.len - 1: raise newException(Invalid, &"invalid u32 {v}")
    vm.data.addLast(uint32(n).reform)
  else: raise newException(Invalid, &"unsupported kind {v.kind}")

proc toU64(vm: ptr VM) =
  if vm.data.len < 1: raise newException(Invalid, "deque underflow")
  let v = vm.data.popLast
  case v.kind
  of U64: vm.data.addLast(v)
  of U32: vm.data.addLast(uint64(v.u32).reform)
  of U16: vm.data.addLast(uint64(v.u16).reform)
  of U8: vm.data.addLast(uint64(v.u8).reform)
  of I64: vm.data.addLast(uint64(v.i64).reform)
  of I32: vm.data.addLast(uint64(v.i32).reform)
  of I16: vm.data.addLast(uint64(v.i16).reform)
  of I8: vm.data.addLast(uint64(v.i8).reform)
  of F64: vm.data.addLast(uint64(v.f64).reform)
  of F32: vm.data.addLast(uint64(v.f32).reform)
  of F16: vm.data.addLast(uint64(v.f16).reform)
  of Bool: vm.data.addLast(uint64(if v.b: 1 else: 0).reform)
  of Str:
    var n: BiggestUInt
    if parseBiggestUInt(v.str, n) != v.str.len - 1: raise newException(Invalid, &"invalid u64 {v}")
    vm.data.addLast(uint64(n).reform)
  else: raise newException(Invalid, &"unsupported kind {v.kind}")

proc toI8(vm: ptr VM) =
  if vm.data.len < 1: raise newException(Invalid, "deque underflow")
  let v = vm.data.popLast
  case v.kind
  of U64: vm.data.addLast(int8(v.u64).reform)
  of U32: vm.data.addLast(int8(v.u32).reform)
  of U16: vm.data.addLast(int8(v.u16).reform)
  of U8: vm.data.addLast(int8(v.u8).reform)
  of I64: vm.data.addLast(int8(v.i64).reform)
  of I32: vm.data.addLast(int8(v.i32).reform)
  of I16: vm.data.addLast(int8(v.i16).reform)
  of I8: vm.data.addLast(v)
  of F64: vm.data.addLast(int8(v.f64).reform)
  of F32: vm.data.addLast(int8(v.f32).reform)
  of F16: vm.data.addLast(int8(v.f16).reform)
  of Bool: vm.data.addLast(int8(if v.b: 1 else: 0).reform)
  of Str:
    var n: int
    if parseInt(v.str, n) != v.str.len - 1: raise newException(Invalid, &"invalid i8 {v}")
    vm.data.addLast(int8(n).reform)
  else: raise newException(Invalid, &"unsupported kind {v.kind}")

proc toI16(vm: ptr VM) =
  if vm.data.len < 1: raise newException(Invalid, "deque underflow")
  let v = vm.data.popLast
  case v.kind
  of U64: vm.data.addLast(int16(v.u64).reform)
  of U32: vm.data.addLast(int16(v.u32).reform)
  of U16: vm.data.addLast(int16(v.u16).reform)
  of U8: vm.data.addLast(int16(v.u8).reform)
  of I64: vm.data.addLast(int16(v.i64).reform)
  of I32: vm.data.addLast(int16(v.i32).reform)
  of I16: vm.data.addLast(v)
  of I8: vm.data.addLast(int16(v.i8).reform)
  of F64: vm.data.addLast(int16(v.f64).reform)
  of F32: vm.data.addLast(int16(v.f32).reform)
  of F16: vm.data.addLast(int16(v.f16).reform)
  of Bool: vm.data.addLast(int16(if v.b: 1 else: 0).reform)
  of Str:
    var n: int
    if parseInt(v.str, n) != v.str.len - 1: raise newException(Invalid, &"invalid i16 {v}")
    vm.data.addLast(int16(n).reform)
  else: raise newException(Invalid, &"unsupported kind {v.kind}")

proc toI32(vm: ptr VM) =
  if vm.data.len < 1: raise newException(Invalid, "deque underflow")
  let v = vm.data.popLast
  case v.kind
  of U64: vm.data.addLast(int32(v.u64).reform)
  of U32: vm.data.addLast(int32(v.u32).reform)
  of U16: vm.data.addLast(int32(v.u16).reform)
  of U8: vm.data.addLast(int32(v.u8).reform)
  of I64: vm.data.addLast(int32(v.i64).reform)
  of I32: vm.data.addLast(v)
  of I16: vm.data.addLast(int32(v.i16).reform)
  of I8: vm.data.addLast(int32(v.i8).reform)
  of F64: vm.data.addLast(int32(v.f64).reform)
  of F32: vm.data.addLast(int32(v.f32).reform)
  of F16: vm.data.addLast(int32(v.f16).reform)
  of Bool: vm.data.addLast(int32(if v.b: 1 else: 0).reform)
  of Str:
    var n: int
    if parseInt(v.str, n) != v.str.len - 1: raise newException(Invalid, &"invalid i32 {v}")
    vm.data.addLast(int8(n).reform)
  else: raise newException(Invalid, &"unsupported kind {v.kind}")

proc toI64(vm: ptr VM) =
  if vm.data.len < 1: raise newException(Invalid, "deque underflow")
  let v = vm.data.popLast
  case v.kind
  of U64: vm.data.addLast(int64(v.u64).reform)
  of U32: vm.data.addLast(int64(v.u32).reform)
  of U16: vm.data.addLast(int64(v.u16).reform)
  of U8: vm.data.addLast(int64(v.u8).reform)
  of I64: vm.data.addLast(v)
  of I32: vm.data.addLast(int64(v.i32).reform)
  of I16: vm.data.addLast(int64(v.i16).reform)
  of I8: vm.data.addLast(int64(v.i8).reform)
  of F64: vm.data.addLast(int64(v.f64).reform)
  of F32: vm.data.addLast(int64(v.f32).reform)
  of F16: vm.data.addLast(int64(v.f16).reform)
  of Bool: vm.data.addLast(int64(if v.b: 1 else: 0).reform)
  of Str:
    var n: BiggestInt
    if parseBiggestInt(v.str, n) != v.str.len - 1: raise newException(Invalid, &"invalid i64 {v}")
    vm.data.addLast(int64(n).reform)
  else: raise newException(Invalid, &"unsupported kind {v.kind}")

proc toF16(vm: ptr VM) =
  if vm.data.len < 1: raise newException(Invalid, "deque underflow")
  let v = vm.data.popLast
  case v.kind
  of U64: vm.data.addLast(float32(v.u64).formF16.refer)
  of U32: vm.data.addLast(float32(v.u32).formF16.refer)
  of U16: vm.data.addLast(float32(v.u16).formF16.refer)
  of U8: vm.data.addLast(float32(v.u8).formF16.refer)
  of I64: vm.data.addLast(float32(v.i64).formF16.refer)
  of I32: vm.data.addLast(float32(v.i32).formF16.refer)
  of I16: vm.data.addLast(float32(v.i16).formF16.refer)
  of I8: vm.data.addLast(float32(v.i8).formF16.refer)
  of F64: vm.data.addLast(float32(v.f64).formF16.refer)
  of F32: vm.data.addLast(float32(v.f32).formF16.refer)
  of F16: vm.data.addLast(v)
  of Bool: vm.data.addLast(float32(if v.b: 1 else: 0).formF16.refer)
  of Str:
    var n: float
    if parseFloat(v.str, n) != v.str.len - 1: raise newException(Invalid, &"invalid f16 {v}")
    vm.data.addLast(float32(n).formF16.refer)
  else: raise newException(Invalid, &"unsupported kind {v.kind}")

proc toF32(vm: ptr VM) =
  if vm.data.len < 1: raise newException(Invalid, "deque underflow")
  let v = vm.data.popLast
  case v.kind
  of U64: vm.data.addLast(float32(v.u64).formF32.refer)
  of U32: vm.data.addLast(float32(v.u32).formF32.refer)
  of U16: vm.data.addLast(float32(v.u16).formF32.refer)
  of U8: vm.data.addLast(float32(v.u8).formF32.refer)
  of I64: vm.data.addLast(float32(v.i64).formF32.refer)
  of I32: vm.data.addLast(float32(v.i32).formF32.refer)
  of I16: vm.data.addLast(float32(v.i16).formF32.refer)
  of I8: vm.data.addLast(float32(v.i8).formF32.refer)
  of F64: vm.data.addLast(float32(v.f64).formF32.refer)
  of F32: vm.data.addLast(v)
  of F16: vm.data.addLast(float32(v.f16).formF32.refer)
  of Bool: vm.data.addLast(float32(if v.b: 1 else: 0).formF32.refer)
  of Str:
    var n: float
    if parseFloat(v.str, n) != v.str.len - 1:
      raise newException(Invalid, &"invalid f32 {v}")
    vm.data.addLast(float32(n).formF32.refer)
  else: raise newException(Invalid, &"unsupported kind {v.kind}")

proc toF64(vm: ptr VM) =
  if vm.data.len < 1: raise newException(Invalid, "deque underflow")
  let v = vm.data.popLast
  case v.kind
  of U64: vm.data.addLast(float64(v.u64).formF64.refer)
  of U32: vm.data.addLast(float64(v.u32).formF64.refer)
  of U16: vm.data.addLast(float64(v.u16).formF64.refer)
  of U8: vm.data.addLast(float64(v.u8).formF64.refer)
  of I64: vm.data.addLast(float64(v.i64).formF64.refer)
  of I32: vm.data.addLast(float64(v.i32).formF64.refer)
  of I16: vm.data.addLast(float64(v.i16).formF64.refer)
  of I8: vm.data.addLast(float64(v.i8).formF64.refer)
  of F64: vm.data.addLast(v)
  of F32: vm.data.addLast(float64(v.f32).formF64.refer)
  of F16: vm.data.addLast(float64(v.f16).formF64.refer)
  of Bool: vm.data.addLast(float64(if v.b: 1 else: 0).formF64.refer)
  of Str:
    var n: BiggestFloat
    if parseBiggestFloat(v.str, n) != v.str.len - 1: raise newException(Invalid, &"invalid f64 {v}")
    vm.data.addLast(float64(n).formF64.refer)
  else: raise newException(Invalid, &"unsupported kind {v.kind}")

proc toStr(vm: ptr VM) =
  if vm.data.len < 1: raise newException(Invalid, "deque underflow")
  let v = vm.data.popLast
  case v.kind:
  of U64: vm.data.addLast(($v.u64).reform)
  of U32: vm.data.addLast(($v.u32).reform)
  of U16: vm.data.addLast(($v.u16).reform)
  of U8: vm.data.addLast(($v.u8).reform)
  of I64: vm.data.addLast(($v.i64).reform)
  of I32: vm.data.addLast(($v.i32).reform)
  of I16: vm.data.addLast(($v.i16).reform)
  of I8: vm.data.addLast(($v.i8).reform)
  of F64: vm.data.addLast(($v.f64).reform)
  of F32: vm.data.addLast(($v.f32).reform)
  of F16: vm.data.addLast(($v.f16).reform)
  of Bool: vm.data.addLast((if v.b: "#t" else: "#f").reform)
  of Undef: vm.data.addLast("#u".reform)
  of Null: vm.data.addLast("#n".reform)
  of Str: vm.data.addLast(v.str.form.refer)
  of Bin: vm.data.addLast(v.bin.form.refer)
  of Sym: vm.data.addLast(v.sym.form.refer)
  else: raise newException(Invalid, &"unsupported kind {v.kind}")

proc toSym(vm: ptr VM) =
  if vm.data.len < 1:
    raise newException(Invalid, "deque underflow")
  let v = vm.data.popLast
  case v.kind:
  of U64: vm.data.addLast(($v.u64).formSym.refer)
  of U32: vm.data.addLast(($v.u32).formSym.refer)
  of U16: vm.data.addLast(($v.u16).formSym.refer)
  of U8: vm.data.addLast(($v.u8).formSym.refer)
  of I64: vm.data.addLast(($v.i64).formSym.refer)
  of I32: vm.data.addLast(($v.i32).formSym.refer)
  of I16: vm.data.addLast(($v.i16).formSym.refer)
  of I8: vm.data.addLast(($v.i8).formSym.refer)
  of F64: vm.data.addLast(($v.f64).formSym.refer)
  of F32: vm.data.addLast(($v.f32).formSym.refer)
  of F16: vm.data.addLast(($v.f16).formSym.refer)
  of Bool: vm.data.addLast((if v.b: "#t" else: "#f").formSym.refer)
  of Undef: vm.data.addLast("#u".formSym.refer)
  of Null: vm.data.addLast("#n".formSym.refer)
  of Str: vm.data.addLast(v.str.formSym.refer)
  of Bin: vm.data.addLast(v.bin.formSym.refer)
  of Sym: vm.data.addLast(v)
  else: raise newException(Invalid, &"unsupported kind {v.kind}")

proc eval(vm: ptr VM, c: uint8) =
  case PCode(c):
  of HALT: vm.status = HALT
  of NOOP: discard
  of EVAL:
    if vm.data.len < 1: raise newException(Invalid, "deque underflow")
    var evaled = vm.data.popLast
    if evaled.kind == Vec: evaled = tag(evaled, CODE_TAG).refer
    vm.eval(evaled)
  of KIND: vm.data.addLast(uint8(vm.data.popLast.kind).reform)
  of SIZE: vm.size
  of UNTAG:
    if vm.data.len < 1: raise newException(Invalid, "deque underflow")
    let v = vm.data.popLast
    if v.kind != Tag:
      raise newException(Invalid, &"kind mismatch: expected tag, found {v.kind}")
    vm.data.addLast(v.tagged)
  of TAG:
    if vm.data.len < 2: raise newException(Invalid, "deque underflow")
    let t = vm.data.popLast
    if t.kind != U64: raise newException(Invalid, &"kind mismatch: expected u64, found {t.kind}")
    let v = vm.data.popLast
    vm.data.addLast(tag(v, t.u64).refer)
  of ENTER:
    if vm.data.len < 1: raise newException(Invalid, "deque underflow")
    vm.contexts.addFirst(vm.data.popLast)
  of LEAVE:
    if vm.contexts.len < 1: raise newException(Invalid, "deque underflow")
    vm.contexts.popFirst
  of CLEAR_STREAM:
    vm.stream.clear
  of CLEAR_DATA:
    vm.data.clear
  of RECV, SEND: raise newException(Invalid, &"we don't know how to send yet") # FIXME
  of READ:
    if vm.data.len < 1: raise newException(Invalid, "deque underflow")
    let f = vm.data.popLast
    let n = try: f[].toInt except: raise newException(Invalid, &"invalid read size {f}")
    if n < 0 or n >= vm.stream.len: raise newException(Invalid, &"index out of bounds {n}")
    vm.data.addLast(vm.stream[n])
  of DISCARD_STREAM:
    if vm.stream.len < 1: raise newException(Invalid, "deque underflow")
    let f = vm.data.popLast
    let n = try: f[].toInt except: raise newException(Invalid, &"invalid discard size {f}")
    if n < 0 or n > vm.stream.len: raise newException(Invalid, &"index out of bounds {n}")
    for i in 1 .. n: vm.stream.popFirst
  of PUSH:
    if vm.data.len < 2: raise newException(Invalid, "deque underflow")
    let x = vm.data.popLast
    let xs = vm.data.popLast
    if xs.kind != Vec: raise newException(Invalid, &"kind mismatch: expected vector, found {xs.kind}")
    var res = xs[]
    res.vec.add(x)
    vm.data.addLast(res.refer)
  of POP:
    if vm.data.len < 1: raise newException(Invalid, "deque underflow")
    let xs = vm.data.popLast
    if xs.kind != Vec: raise newException(Invalid, &"kind mismatch: expected vector, found {xs.kind}")
    if xs.vec.len < 1: raise newException(Invalid, "vec underflow")
    vm.data.addLast(xs.vec[^1])
  of SET:
    if vm.data.len < 3: raise newException(Invalid, "deque underflow")
    let v = vm.data.popLast
    let k = vm.data.popLast
    let c = vm.data.popLast
    case c.kind:
    of Map:
      var res = c[]
      res.map[k] = v
      vm.data.addLast(res.refer)
    of Vec:
      let offset = try: k[].toInt except: raise newException(Invalid, &"invalid vec index {k}")
      if offset < 0 or offset >= c.vec.len: raise newException(Invalid, &"index out of bounds {offset} in {c}")
      var res = c[]
      res.vec[offset] = v
      vm.data.addLast(res.refer)
    else:
      raise newException(Invalid, &"kind mismatch: expected map or vec, found {c.kind}")
  of GET:
    if vm.data.len < 2: raise newException(Invalid, "deque underflow")
    let k = vm.data.popLast
    let c = vm.data.popLast
    case c.kind:
    of Map:
      try: vm.data.addLast(c.map[k]) except: raise newException(Invalid, &"key not found {k} in {c}")
    of Vec:
      let offset = try: k[].toInt except: raise newException(Invalid, &"invalid vec index {k}")
      if offset < 0 or offset >= c.vec.len: raise newException(Invalid, &"index out of bounds {offset} in {c}")
      vm.data.addLast(c.vec[offset])
    of Str:
      let offset = try: k[].toInt except: raise newException(Invalid, &"invalid str index {k}")
      if offset < 0 or offset >= c.str.len: raise newException(Invalid, &"index out of bounds {offset} in {c}")
      vm.data.addLast(c.str[offset].reform)
    of Bin:
      let offset = try: k[].toInt except: raise newException(Invalid, &"invalid bin index {k}")
      if offset < 0 or offset >= c.bin.len: raise newException(Invalid, &"index out of bounds {offset} in {c}")
      vm.data.addLast(c.bin[offset].reform)
    else: raise newException(Invalid, &"kind mismatch: expected map or vec, found {c.kind}")
  of PUSH_DATA:
    vm.data.addLast(toSeq(vm.data.items).reform)
  of PUSH_STREAM:
    vm.data.addLast(toSeq(vm.stream.items).reform)
  of PUSH_CONTEXTS:
    vm.data.addLast(toSeq(vm.contexts.items).reform)
  of DROP:
    if vm.data.len < 1: raise newException(Invalid, "deque underflow")
    discard vm.data.popLast
  of PICK:
    if vm.data.len < 1: raise newException(Invalid, "deque underflow")
    let f = vm.data.popLast
    let n = try: f[].toInt except: raise newException(Invalid, &"invalid index {f}")
    if n >= vm.data.len: raise newException(Invalid, &"index out of bounds {f}")
    vm.data.addLast(vm.data[^(n + 1)])
  of SWAP:
    if vm.data.len < 2: raise newException(Invalid, "deque underflow")
    let a = vm.data.popLast
    let b = vm.data.popLast
    vm.data.addLast(a)
    vm.data.addLast(b)
  of ADD: vm.add
  of SUB: vm.sub
  of PROD: vm.prod
  of DIV, MOD, DIVMOD, POW:
    raise newException(Invalid, &"unsupported operation {c}")
  of LT: vm.lt
  of GT: vm.gt
  of EQ: vm.eq
  of LE: vm.le
  of GE: vm.ge
  of AND: vm.andOp
  of OR: vm.orOp
  of NOT: vm.notOp
  of SHL: vm.shlOp
  of SHR: vm.shrOp
  of TO_U8: vm.toU8
  of TO_U16: vm.toU16
  of TO_U32: vm.toU32
  of TO_U64: vm.toU64
  of TO_I8: vm.toI8
  of TO_I16: vm.toI16
  of TO_I32: vm.toI32
  of TO_I64: vm.toI64
  of TO_F16: vm.toF16
  of TO_F32: vm.toF32
  of TO_F64: vm.toF64
  of TO_STR: vm.toStr
  of TO_SYM: vm.toSym
  of R7, R12, R13, R14, R15, R18, R19, R22, R23, R26, R27,
    R28, R29, R32, R36, R37, R38, R39, R40, R41, R42, R43, R44, R45, R46, R47, R50, R52, R53, R54,
    R55, R56, R57, R58, R59, R60, R61, R62, R63, R68:
    raise newException(Invalid, &"illegal primitive {c}")

proc eval(vm: ptr VM, r: Ref) =
  vm.step += 1
  case r.kind:
  of Sym:
    let res = vm.lookup(r)
    if res.isNil: raise newException(Invalid, &"undefined symbol {r}")
    else:
      vm.eval(res[])
  of Tag:
    if r.tag == CODE_TAG:
      case r.tagged.kind
      of U8:
        vm.eval(r.tagged.u8)
      of Vec:
        let vec = r.tagged.vec
        for i in countdown(vec.high, vec.low): vm.stream.addFirst(vec[i])
      else:
        vm.data.addLast(r)
    else:
      vm.data.addLast(r)
  else:
    vm.data.addLast(r)

proc advance*(vm: ptr VM, steps: int, receiver: proc (vm: ptr VM): void) =
  var save: VM
  vm.status = RUNNING
  var remaining = steps
  try:
    while remaining > 0 and vm.stream.len > 0 and vm.status == RUNNING:
      save = vm[]
      let i = vm.stream.popFirst
      vm.eval(i)
      receiver(vm)
      remaining -= 1
  except:
    vm[] = save
    vm.status = FAULT
    raise getCurrentException()

proc advance*(vm: ptr VM, receiver: proc (vm: ptr VM): void) =
  var save: VM
  vm.status = RUNNING
  try:
    while vm.stream.len > 0 and vm.status == RUNNING:
      save = vm[]
      let i = vm.stream.popFirst
      vm.eval(i)
      receiver(vm)
  except:
    vm[] = save
    vm.status = FAULT
    raise getCurrentException()

proc stream_in*(vm: ptr VM, msgs: openArray[Form]) =
  for msg in msgs: vm.stream.addLast(msg.refer)

proc tuck_in*(vm: ptr VM, msgs: openArray[Form]) =
  for msg in msgs.reversed: vm.stream.addFirst(msg.refer)
