import nimraylib_now
import cpu
import strutils
import os

type
  AppOptions = enum
    MANUAL_CYCLE, NORMAL

var CurOptions = @[AppOptions.NORMAL]
if paramCount() == 0:
  echo "Failed to specify a chip8 rom!"
  quit(QuitFailure)
elif paramCount() == 2:
  case paramStr(2)
  of "--manual":
    CurOptions.add(AppOptions.MANUAL_CYCLE)

init()
initAudioDevice()
load_fonts()
load_rom(paramStr(1))

let sfx = loadMusicStream("beep.ogg")

const
  X_OFFSET = 0
  Y_OFFSET = 0

  # This is an array because we will cycle through it to find out which key is pressed
  # The number of each item is the chip8 key number
  KEYS = [
    KeyboardKey.X,
    KeyboardKey.One,
    KeyboardKey.Two,
    KeyboardKey.Three,
    KeyboardKey.Q,
    KeyboardKey.W,
    KeyboardKey.E,
    KeyboardKey.A,
    KeyboardKey.S,
    KeyboardKey.D,
    KeyboardKey.Z,
    KeyboardKey.C,
    KeyboardKey.Four,
    KeyboardKey.R,
    KeyboardKey.F,
    KeyboardKey.V
  ]


var
  screenWidth: int32 = 520
  screenHeight: int32 = 300

  foregroundColour = BLACK
  backgroundColour = WHITE

initWindow(screenWidth, screenHeight, "Chip8 Emu")
setTargetFPS(800)

while not windowShouldClose():
  playMusicStream(sfx)
  beginDrawing()
  #clearBackground(Raywhite)
  let flag = get_draw_flag()
  let gfx = get_graphics_buffer()
  let pcs = cstring(get_pc())
  #drawText(cstring(get_pc()), 50, 270, 100, RED)
  if CurOptions[0] == AppOptions.MANUAL_CYCLE:
    drawText("MANUAL CYCLE MODE", 190, 300, 20, RED)
    if isKeyPressed(KeyboardKey.Space):
      cycle()
  else:
    cycle()


  #cycle()
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

  send_key(0, false)
  var curKey = 0
  #echo keyPressed
  for i in 0..Keys.high():
    if isKeyDown(Keys[i]):
      send_key(i, true)

  endDrawing()

closeWindow()
unloadMusicStream(sfx)
closeAudioDevice()