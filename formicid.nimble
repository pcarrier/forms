version       = "0.1.0"
author        = "Pierre Carrier"
description   = "A novel form factor"
license       = "0BSD"
srcDir        = "src"
bin           = @["formicid"]

requires "nim >= 2.0.0"
# requires "hashlib >= 1.0.1"

task test, "Run test suite":
  exec "testament --megatest:off all"
