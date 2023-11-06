Dabbling at a formulaic format forming formidable formalisms.

## TODO

- `>cbor`, `cbor>`
- `stor2cbor`, `cbor2stor`
- `>json`?
- `json2stor`, `stor2json`
- bf interpreter
- `send` / `recv`, channels
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

Look ups traverse the context stack from top to bottom until a form is found. If no form is available, the machine halts with an error. Only map contexts are supported today, but one could eg evaluate vectors (see `lookup` comment in [storm.nim](src/storm.nim) and the accompanying example in [examples.ts](src/examples.ts)).
