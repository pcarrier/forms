const examples = {
  numerals: `[ #u8 42 #f64 3.14159265358979323846
  swap >f64 * >u16 #u16 3 /% ] eval`,
  factorial: `{ u64-factorial ( #u64 1
                  [ over #u64 1 > ]
                  [ over * swap #u64 1 - swap ] while
                  swap drop ) }
enter
  #u64 20 u64-factorial
leave`,
  fibonacci: `def u64-fib ( dup #u64 1 >
              [ dup dup
                #u64 1 - u64-fib
                swap
                #u64 2 - u64-fib
                + swap drop ] when )
#u64 25 u64-fib`,
  prng: `locally ( def xorshift64* ( dup #u64 0 = [ drop #u64 1 ] when
                            dup #u8 12 << |
                            dup #u8 25 >> |
                            dup #u8 27 << |
                            #u64 2685821657736338717 * )
          #u64 0 #u8 0 [ dup #u8 10 < ] [ over xorshift64* swap #u8 1 + ] while ) drop`,
  dynamic: `[ { hello 'world } swap #u get-or dup undef? ! [ halt ] when ] >immediate enter hello leave`,
  aspiration1: `'/devenv fetch 'body get stor> eval`,
  aspiration2: `{ 'url 'https://pcarrier.com 'headers { 'accept 'application/cbor+form } } fetch 'body get cbor> eval`,
};

export default examples;
