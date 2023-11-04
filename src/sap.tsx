export enum Type {
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

type Tag = [Type.Tag, string, Sap];
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

export type Sap =
  | Tag
  | Undef
  | Null
  | Bool
  | Sym
  | Str
  | Bin
  | Vec
  | SMap
  | U64
  | U32
  | U16
  | U8
  | I64
  | I32
  | I16
  | I8
  | F64
  | F32
  | F16;

export function SapView(props: { value: Sap }) {
  switch (props.value[0]) {
    case Type.Tag:
      return (
        <>
          <span class="tag">#{props.value[1]}</span>{" "}
          <span class="tagged">
            <SapView value={props.value[2]} />
          </span>
        </>
      );
    case Type.Undef:
      return <span class="undef">#u</span>;
    case Type.Null:
      return <span class="null">#n</span>;
    case Type.Bool:
      return (
        <span class={`bool bool-${props.value[1]}`}>
          {props.value[1] ? "#t" : "#f"}
        </span>
      );
    case Type.Sym:
      return <span class="sym">{props.value[1]}</span>;
    case Type.Str:
      return <span class="str">{props.value[1]}</span>;
    case Type.Bin:
      return <span class="bin">{props.value[1]}</span>;
    case Type.Vec:
      return (
        <table>
          {(props.value.slice(1) as Sap[]).map((e) => (
            <tr>
              <td>
                <SapView value={e} />
              </td>
            </tr>
          ))}
        </table>
      );
    case Type.Map:
      let pairs = [];
      for (let i = 1; i < props.value.length; i += 2) {
        pairs.push(
          <tr>
            <td>
              <SapView value={props.value[i] as Sap} />
            </td>
            <td>
              <SapView value={props.value[i + 1] as Sap} />
            </td>
          </tr>
        );
      }
      return <table>{pairs}</table>;
    case Type.U64:
      return <span class="num u64">{props.value[1]}</span>;
    case Type.U32:
      return <span class="num u32">{props.value[1]}</span>;
    case Type.U16:
      return <span class="num u16">{props.value[1]}</span>;
    case Type.U8:
      return <span class="num u8">{props.value[1]}</span>;
    case Type.I64:
      return <span class="num i64">{props.value[1]}</span>;
    case Type.I32:
      return <span class="num i32">{props.value[1]}</span>;
    case Type.I16:
      return <span class="num i16">{props.value[1]}</span>;
    case Type.I8:
      return <span class="num i8">{props.value[1]}</span>;
    case Type.F64:
      return <span class="num f64">{props.value[1]}</span>;
    case Type.F32:
      return <span class="num f32">{props.value[1]}</span>;
    case Type.F16:
      return <span class="num f16">{props.value[1]}</span>;
  }
}
