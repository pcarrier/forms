type
    Kind* = enum
        fUndefined, fNull, fBool
    Form* = object
        case kind*: Kind
            of fUndefined: discard
            of fNull: discard
            of fBool: boolVal*: bool
