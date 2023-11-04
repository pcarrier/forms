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

export function SapView({ value }: { value: Sap }) {
  switch (value[0]) {
    case Type.Tag:
      if (value[1] == "6") {
        if (value[2][0] == Type.U8) {
          return <div className="primitive">%{value[2][1]}</div>;
        }
        if (value[2][0] == Type.Vec) {
          return (
            <div className="immediate">
              <SapView value={value[2]} />
            </div>
          );
        }
      }
      return (
        <>
          <div className="tag">#{value[1]}</div>{" "}
          <div className="tagged">
            <SapView value={value[2]} />
          </div>
        </>
      );
    case Type.Undef:
      return <div className="undef">#u</div>;
    case Type.Null:
      return <div className="null">#n</div>;
    case Type.Bool:
      return (
        <div className={`bool bool-${value[1]}`}>{value[1] ? "#t" : "#f"}</div>
      );
    case Type.Sym:
      return <div className="sym">{value[1]}</div>;
    case Type.Str:
      return <div className="str">{value[1]}</div>;
    case Type.Bin:
      return <div className="bin">{value[1]}</div>;
    case Type.Vec:
      return (
        <table>
          <tbody>
            {(value.slice(1) as Sap[]).map((e, i) => (
              <tr key={i}>
                <td>
                  <SapView value={e} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      );
    case Type.Map:
      let pairs = [];
      for (let i = 1; i < value.length; i += 2) {
        pairs.push(
          <tr key={i}>
            <td>
              <SapView value={value[i] as Sap} />
            </td>
            <td>
              <SapView value={value[i + 1] as Sap} />
            </td>
          </tr>
        );
      }
      return <table><tbody>{pairs}</tbody></table>;
    case Type.U64:
      return <div className="num u64">{value[1]}</div>;
    case Type.U32:
      return <div className="num u32">{value[1]}</div>;
    case Type.U16:
      return <div className="num u16">{value[1]}</div>;
    case Type.U8:
      return <div className="num u8">{value[1]}</div>;
    case Type.I64:
      return <div className="num i64">{value[1]}</div>;
    case Type.I32:
      return <div className="num i32">{value[1]}</div>;
    case Type.I16:
      return <div className="num i16">{value[1]}</div>;
    case Type.I8:
      return <div className="num i8">{value[1]}</div>;
    case Type.F64:
      return <div className="num f64">{value[1]}</div>;
    case Type.F32:
      return <div className="num f32">{value[1]}</div>;
    case Type.F16:
      return <div className="num f16">{value[1]}</div>;
  }
}
