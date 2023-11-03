Dabbling at a formulaic format forming formidable formalisms.

## TODO

- `>stor`, `>stor`
- `>cbor`, `cbor>`
- `stor2cbor`, `cbor2stor`
- `>json`, `json>`
- `json2stor`, `stor2json`
- bf interpreter
- `send` / `recv`
- js EVAL channel on -42
- `spawn`
- crypto primitives
- network channels



## FORM Open Representation Model (FORM)

_*Status:* memory ready, STOR printing elides cycles and STOR parsing reports them_

FORM is STOR with cycles. That is to say, whereas STORM streams represent a forest, FORM constitutes a graph.

It can be serialized to STORM and CBOR, handling cycles with tags `#28` and `#29` or `#31 #u`
(all as specified in [IANA](https://www.iana.org/assignments/cbor-tags/cbor-tags.xhtml)).

## STORM Machine (STORM)

_*Status:* thinking_

STORM is a virtual machine with a data stack, a context stack, and a stream, all containing references to FORM values (henceforth forms).

### Modus operandi

The machine consumes from its stream, halting whenever it empties.
Forms are handled according to the following rules:
- Primitives, represented by `#6 #u8 i` (or `%i` for short), are executed immediately;
- Symbols are replaced by look ups, then handling restarts;
- All other values are pushed to the data stack.

Look ups traverse the context stack from top to bottom until a form is found. If no form is available, the machine halts with an error.

Each context is looked up based on its type:
- Maps are looked up by key;
- Vectors are evaluated as a stream in a machine with the same contexts except this one, starting with the looked up value on the data stack; if it halts, its top is the result.
- Everything else is looked up recursively first.

## Eye of the STORM (I)

_*Status:* dreaming of https://pcarrier.com/words_

`I` is the initial context of the STORM machine at [formic.id](https://formic.ic/). It exposes primitives and a few convenience forms .

## Meta

`eval`

`<data` `<stream` `<contexts` `<context`

## Contexts

`enter` `exit`

## I/O

`recv` `send` `fetch`

## Data

### Stack

`swap` `dup` `drop`

### Inspection

`kind`

| code | kind |
|------|------|
| 0    | tag  |
| 1    | #u   |
| 2    | #n   |
| 3    | bool |
| 8    | sym  |
| 9    | str  |
| 10   | bin  |
| 11   | vec  |
| 12   | map  |
| 16   | u64  |
| 17   | u32  |
| 18   | u16  |
| 19   | u8   |
| 32   | i64  |
| 33   | i32  |
| 34   | i16  |
| 35   | i8   |
| 48   | f64  |
| 49   | f32  |
| 50   | f16  |

`size`: number of bytes for `bin`, `str` and numbers, number of elements for `vec` and number of pairs for `map`.

### Tests

`tag?` `undef?` `null?` `bool?` `num?` `sym?` `str?` `bin?` `vec?` `map?`

`f?` `f64?` `f32?` `f16?` `i?` `i64?` `i32?` `i16?` `i8?` `u?` `u64?` `u32?` `u16?` `u8?`

### Conversion

`>sym` `>str` `>bin` `>vec` `>map` `>bool` `>u64` `>u32` `>u16` `>u8` `>i64` `>i32` `>i16` `>i8` `>f` `>f64` `>f32` `>f16`

`json>` `>json` `stor>` `>stor` `cbor>` `>cbor`

### Arithmetic

`+` `-` `*` `/` `/.` `%` `/%` `^` `<` `>` `=` `<=` `>=` `&` `|` `!` `>>` `<<`

### Creation

`map!` `vec!` `str!` `sym!` `bin!`

### Access and mutation

`get` `set` `del` `push`

`has?` `keys` `vals` `pairs`

## Concurrency & control flow

`spawn` `die`
