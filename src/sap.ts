enum Type {
  Tag = 0,
  Undef = 1,
  Null = 2,
  Bool = 3,
  Sym = 8,
  Str = 9,
  Bin = 10,
  Vec = 11,
  Map = 12,
  U64 = 16,
  U32 = 17,
  U16 = 18,
  U8 = 19,
  I64 = 32,
  I32 = 33,
  I16 = 34,
  I8 = 35,
  F64 = 48,
  F32 = 49,
  F16 = 50,
}

type Tag = [Type.Tag, Sap];
type Undef = [Type.Undef];
type Null = [Type.Null];
type Bool = [Type.Bool, boolean];
type Sym = [Type.Sym, string];
type Str = [Type.Str, string];
type Bin = [Type.Bin, string];
type Vec = [Type.Vec, ...Sap[]];
type SMap = [Type.Map, ...Sap[]];
type U64 = [Type.U64, string];
type U32 = [Type.U32, string];
type U16 = [Type.U16, string];
type U8 = [Type.U8, string];
type I64 = [Type.I64, string];
type I32 = [Type.I32, string];
type I16 = [Type.I16, string];
type I8 = [Type.I8, string];
type F64 = [Type.F64, string];
type F32 = [Type.F32, string];
type F16 = [Type.F16, string];


type Sap =
| Tag
| Undef | Null
| Bool
| Sym | Str | Bin
| Vec | SMap
| U64 | U32 | U16 | U8
| I64 | I32 | I16 | I8
| F64 | F32 | F16;
