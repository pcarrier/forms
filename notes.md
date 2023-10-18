Dabbling at a formulaic format forming formidable formalisms.

## essence

Arithmetic. `+ - * / % ^ < > = <= >= & | ! >> <<`

Dict. `get` `set` `lose` `within` `leave`

I/O. `receive` `send` `fetch`

Formats. `stor>` `>stor` `cbor>` `>cbor`

Concurrency. `spawn` `die`

## CBOR

Tags: 6 for symbols, 28-29 for cycles.

## STOR

```
#u #n #f #t
0 +3.14 6.626068e-34 +299_792_458 0xdeadbeef
#+inf #-inf #nan
#fl|#f64|#f32|#f16 …
#il|#i64|#i32|#i16|#i8 …
symbol
  one\ with\ spaces
  #s "{another with brackets and braces}"
'string
  'one\ with\ spaces
#b '\ffbinary\00
"string \u1F600"
[ 1 2 3 … ]
{ a 1
  b 2
  c 3
  … }
\\ \  \n \t \r \b \f \" \' \xx \uxxxx
```
