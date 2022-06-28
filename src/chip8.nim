import nimraylib_now
import cpu
import math
import os



if paramCount() == 0:
  echo "Failed to specify a chip8 rom!"
  quit(QuitFailure)

init()
load_fonts()
load_rom(paramStr(1))

const X_OFFSET = 0 #64 # Screen x offset
const Y_OFFSET = 0# - 32

var
  screenWidth: int32 = 800
  screenHeight: int32 = 450

  foregroundColour = WHITE
  backgroundColour = BLACK

initWindow(screenWidth, screenHeight, "Chip8 Emu")
setTargetFPS(400)

while not windowShouldClose():

  beginDrawing()
  #clearBackground(Raywhite)
  let flag = get_draw_flag()
  let gfx = get_graphics_buffer()
  cycle()
  if flag == true:
    clearBackground(Raywhite)
    for y in 0..32:
      for x in 0..64:
        if gfx[x + (y * 64)] == 1:
          let pix_x = x * 8 + X_OFFSET
          let pix_y = y * 8 + Y_OFFSET

          drawRectangle(cint(pix_x), cint(pix_y), 10, 10, foregroundColour)
          #set_draw_flag(false)

        else:
          let pix_x = x * 8 + X_OFFSET
          let pix_y = y * 8 + Y_OFFSET

          drawRectangle(cint(pix_x), cint(pix_y), 10, 10, backgroundColour)
  #clearBackground(Raywhite)
  endDrawing()

closeWindow()
