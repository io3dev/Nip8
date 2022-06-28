# Package

version       = "0.0.1"
author        = "io3dev"
description   = "A simple chip8 emulator"
license       = "GPL-3.0-only"
srcDir        = "src"
bin           = @["chip8"]


# Dependencies

requires "nim >= 1.6.6"
requires "nimraylib_now"