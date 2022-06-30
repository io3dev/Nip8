import strutils

# When an opcode instruction goes right
proc okOp*(op: uint16) =
    #echo "[OK] ", op.toHex()
    discard

# Reports missing instruction and hangs
proc noOp*(op: uint16) =
    echo "[NF] ", op.toHex()
    #discard
