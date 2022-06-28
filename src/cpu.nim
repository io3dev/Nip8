import strutils
import debug_op
import streams


const
    MEMORYSIZE = 4096
    REGS = 16
    STACKSIZE = 16

    # The address where programs are loaded

    PROGRAM_START = 0x200

    S_WIDTH = 64
    S_HEIGHT = 64

    FONTS = [
        byte(0xF0), 0x90, 0x90, 0x90, 0xF0, # 0
        0x20, 0x60, 0x20, 0x20, 0x70,       # 1
        0xF0, 0x10, 0xF0, 0x80, 0xF0,       # 2
        0xF0, 0x10, 0xF0, 0x10, 0xF0,       # 3
        0x90, 0x90, 0xF0, 0x10, 0x10,       # 4
        0xF0, 0x80, 0xF0, 0x10, 0xF0,       # 5
        0xF0, 0x80, 0xF0, 0x90, 0xF0,       # 6
        0xF0, 0x10, 0x20, 0x40, 0x40,       # 7
        0xF0, 0x90, 0xF0, 0x90, 0xF0,       # 8
        0xF0, 0x90, 0xF0, 0x10, 0xF0,       # 9
        0xF0, 0x90, 0xF0, 0x90, 0x90,       # A
        0xE0, 0x90, 0xE0, 0x90, 0xE0,       # B
        0xF0, 0x80, 0x80, 0x80, 0xF0,       # C
        0xE0, 0x90, 0x90, 0x90, 0xE0,       # D
        0xF0, 0x80, 0xF0, 0x80, 0xF0,       # E
        0xF0, 0x80, 0xF0, 0x80, 0x80        # F  
    ]

var
    v: array[REGS, byte]
    I: uint16

    pc: uint16
    sp: uint8

    stack: array[16, uint16]

    delayt: uint8
    soundt: uint8

    memory: array[MEMORYSIZE, uint16]
    graphics: array[S_WIDTH * S_HEIGHT, byte]

    drawflag: bool

type
    Quirks = enum
        Invaders, None


proc init*() =
    pc = 0x200
    sp = 0

# Loads font array to memory address 0..80
proc load_fonts*() =
    for j in 0..79:
        memory[j] = FONTS[j]

    #cho memory[0].toHex()

# Loads rom file to starting address 0x200 and up
proc load_rom*(path: string) =
    var maxprogramsize = MEMORYSIZE - PROGRAM_START
    var f = open(path)
    var ar = newSeq[uint8](maxprogramsize)
    var size = f.readBytes(ar, 0, maxprogramsize)
    for i, b in ar[0..size]:
        memory[0x200 + i] = uint8(b)
    close(f)

proc execute() =
    #echo soundt
    let msb = memory[pc]
    let lsb = memory[pc + 1]

    var instruction = (uint16(msb) shl 8) or lsb

    let n = instruction and 0x000F
    let nn = instruction and 0x00FF
    let nnn = instruction and 0x0FFF
    let x = (instruction and 0x0F00) shr 8
    let y = (instruction and 0x00F0) shr 4

    case instruction and 0xF000
    of 0x0000:
        case instruction and 0x000F
        of 0x0000:
            # 00E0, clear screen
            # Clears the graphics array

            for j in 0..S_WIDTH * S_HEIGHT - 1:
                graphics[j] = 0

            drawflag = true
            okOp(instruction)
            pc += 2
        of 0x000E:
            #sp -= 1

            #pc = stack[sp]
            #pc += 2;

            pc = stack[sp] + 2
            sp -= 1

            okOp(instruction)
        else:
            noOp(instruction)

    of 0xA000:
        I = instruction and 0x0FFF
        okOp(instruction)
        echo I
        pc += 2;

    of 0x1000:
        pc = instruction and 0x0FFF
        okOp(instruction)

    of 0x2000:
        sp += 1
        stack[sp] = pc
        pc = instruction and 0x0FFF

        okOp(instruction)

    of 0x3000:
        # 3xNN
        # Skips insttruction if vx = nn

        if v[x] == nn:
            pc += 4
        else:
            pc += 2

    of 0x4000:
        if v[x] != nn:
            pc += 4
        else:
            pc += 2

    of 0x5000:
        # Skips if vx = vy
        if v[x] == v[y]:
            pc += 4
        else:
            pc += 2

    of 0x6000:
        # 6xnn
        # Sets vx to nn

        v[x] = uint8(instruction and 0x00FF)

        okOp(instruction)
        pc += 2;

    of 0x7000:
        # 7XNN
        # Adds value with vx

        v[x] += uint8(instruction and 0x00FF)
        #self.registers[self.vx] &= 0xff
        #v[x] = v[x] and 0xff
        pc += 2

    of 0x8000:
        case instruction and 0x000F
        of 0x0:
            v[x] = v[y]
            okOp(instruction)
            pc += 2
        of 0x1:
            v[x] = v[x] or v[y]
            okOp(instruction)
            pc += 2
        of 0x2:
            v[x] = v[x] and v[y]
            okOp(instruction)
            pc += 2
        of 0x3:
            v[x] = v[x] xor v[y]
            okOp(instruction)
            pc += 2
        of 0x4:
            # Add vx and vy, if overflowing vf set to 1
            let result = v[x] + v[y]
            # If the result of vx and vy is overflowing 8 bits
            # set the VF register to 1 (carry flag)
            if result > 255:
                v[0xF] = 1
            v[x] = result

            okOp(instruction)
            pc += 2
        of 0x5:
            # Set vx to vx minus vy
        
            # If there is a borrow, set VF to 1
            if v[x] > v[y]:
                v[0xF] = 1

            v[x] -= v[y]


            okOp(instruction)
            pc += 2

        of 0x6:
            okOp(instruction)
            #echo v[x] shr 1

            v[0xF] = v[x] and 0x1
            v[x] = (v[x] shr 1)

            pc += 2

        of 0x7:
            # sets vx to vy minus vx

            if v[x] > v[y]:
                v[0xF] = 1
            else:
                v[0xF] = 0

            v[x] = v[y] - v[x]

        of 0xE:
            okOp(instruction)

            v[0xF] = (v[x] shr 7)
            v[x] = (v[x] shl 1)

            pc += 2

        else:
            noOp(instruction)


    of 0x9000:
        # skips if vx != vy

        if v[x] != v[y]:
            pc += 4
        else:
            pc += 2

    of 0xD000:
        
        # Dxyn
        # Draws pixel to the screen

        let height = instruction and 0x000F

        let xpos = v[x] and 63
        let ypos = v[y] and 31

        v[0xF] = 0
        for rows in 0..<uint(height):
            let sprite = memory[I + rows]

            for w in 0..<8:
                if (sprite and (uint8(0x80) shr w)) != 0:

                    let a = v[x] + uint16(w)
                    let b = v[y] + uint16(rows)
                    graphics[a + (b * 64)] = graphics[a + (b * 64)] xor 1 

        okOp(instruction)
        drawflag = true
        pc += 2;

    of 0xF000:
        case instruction and 0x00FF
        of 0x07:
            v[x] = delayt
            okOp(instruction)
            pc += 2
        of 0x0A:
            pc += 2
            # TODO WAIT FOR KEYPRESS
            #discard
        of 0x15:
            delayt = v[x]
            okOp(instruction)
            pc += 2
        of 0x18:
            soundt = v[x]
            okOp(instruction)
            pc += 2
        of 0x1E:
            I += v[x]
            okOp(instruction)
            pc += 2
        of 0x29:
            I = v[x] * 5
            okOp(instruction)
            pc += 2
        of 0x33:
            
            let a = v[x] mod 1000
            #memory[I] = (int(a) / 100).uint16

            memory[I] = (v[x].float / 100).uint8
            #memory[I + 1] = #((v[x].float / 10).int16 mod 10).uint16
            memory[I + 1] = ((v[x] mod 100).float / 10).uint8
            memory[I + 2] = (v[x] mod 10).uint8

            #    M[I] = V[x] / 100;
            # #   M[I + 1] = (V[x] / 10) % 10;
            #    M[I + 2] = V[x] % 10;

            pc += 2
        of 0x65:
            #TODO Not working
            pc += 2

        of 0x55:
            #TODO Not working
            

            for i in uint(0)..<x:
                v[i] = memory[I + i].byte()

            pc += 2
        else:
            noOp(instruction)

    else:
        noOp(instruction)
        pc += 2;


proc timers() =
    if soundt != 0:
        soundt -= 1

    if delayt != 0:
        delayt -= 1

proc cycle*() =
    #draw_flag = false

    timers()

    execute();

    #draw_flag = false

proc get_graphics_buffer*(): array[MEMORYSIZE, byte] =
    return graphics

proc get_draw_flag*(): bool =
    return drawflag

proc get_timers*(): (uint8, uint8) =
    return (soundt, delayt)

proc set_draw_flag*(on_off: bool) =
    draw_flag = on_off