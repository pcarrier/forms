Dabbling at a formulaic format forming formidable formalisms.

Form follows function, function transforms.

## essence

Take your time. `: breath ( in -- out ).`

Computation. `apply` `compose` `drop` `dup` `quote` `swap`

Context. `assoc` `dissoc` `enter` `leave`

Concurrency. `spawn` `die`

I/O. `read` `write` / `receive` `send`

## data

Use CBOR for storage and optionally in the protocol.

Offer a textual equivalent, Simple Text Object Representation, around:

```
4269%        tag prefix
1023         int
-4.2e-4      float
-5f16        16-bit float
#0…#255     simple value
#n           null
#u           undefined
#t           true
#f           false
[ a b c ]    array
{ a b c d }  map
"\05ab\02"   string
hello14!     string
#b"\05ab\02" byte array
abc          unquoted strings
```

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

## UX

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