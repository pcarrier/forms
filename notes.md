Dabbling at a formulaic format forming formidable formalisms.

Form follows function, function transforms.

## essence

Take your time. `: breath ( in -- out ).`

Computation. `apply` `compose` `drop` `dup` `quote` `swap`

Context. `assoc` `dissoc` `enter` `leave`

Concurrency. `spawn` `die`

I/O. `read` `write` / `receive` `send`

## data

- Use CBOR for storage (refs are serialized as ) and optionally in the protocol.
- Use STOR when text is warranted.

## code

use nim, inspect min & factor.

## verbiage

journal.
receive and build knowledge.
persist inputs.
internalize.
be lazy.

## primitives

read
write
remember
forget
discard
recall
spawn
die

## CLI UX

```
$ form
Usage: form [opts] [source …]
opts:
  -h            show copyright and licensing information
  -i            interactive console
  -n [::1]:1337 network instance
$ form -i hello.f > world.f
0. [ the
     stack ]
1. { being
       b'built'
     through
       b'the' }
42> { [ very interactive ]
        prompt }
@ most recently defined b'locals'
< … most recently accessed symbols 'under pagination' …
> … +most +recently *altered -symbols                 …
```

## net

https://form.pcarrier.com: frontend
wss://form.pcarrier.com: VM journal + state + I/O
