version       = "0.1.0"
author        = "Pierre Carrier"
description   = "A novel form factor"
license       = "0BSD"
srcDir        = "src"
bin           = @["wasm/formicid", "dabble/dabble"]

requires "nim >= 2.0.0"
requires "jsony >= 1.1.5"

task test, "Run test suite":
  exec "testament --megatest:off all"

task serve, "Run an HTTP server":
  exec "python3 -mhttp.server"

task deploy, "Deploy":
  exec "nimble build"
  exec "pnpm build"
  exec "pnpm run deploy"
