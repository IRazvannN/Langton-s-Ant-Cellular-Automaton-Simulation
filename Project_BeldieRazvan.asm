; ==============================================================================
; Langton's Ant Cellular Automaton Simulation
; Architecture: 16-bit x86 Assembly
; Environment: DOS / EMU8086
; ==============================================================================

include 'emu8086.inc'
ORG 100h

; --- System Initialization ---
MOV AL, 03h         ; Set video mode to 03h (80x25 16-color text)
MOV AH, 00h         ; INT 10h, AH=00h: Set Video Mode
INT 10h

; --- Main Simulation Loop ---
start:
    ; 1. Update Cursor Position
    MOV DH, y       ; DH = Row
    MOV DL, x       ; DL = Column
    MOV BH, 0       ; Video page 0
    MOV AH, 02h     ; INT 10h, AH=02h: Set Cursor Position
    INT 10h

    ; 2. Read Current State
    MOV AH, 08h     ; INT 10h, AH=08h: Read Character and Attribute at Cursor
    MOV BH, 00h
    INT 10h         
    MOV current, AL ; Buffer background state prior to agent rendering

    ; 3. Render Visual Agent
    MOV AH, 09h     ; INT 10h, AH=09h: Write Character and Attribute
    MOV AL, 02h     ; Agent sprite (ASCII 02h)
    MOV BH, 00h
    MOV BL, 0Ch     ; Attribute: Light Red
    MOV CX, 1
    INT 10h

    ; 4. Asynchronous Input Handling
input_check:
    MOV AH, 01h     ; INT 16h, AH=01h: Check Keyboard Buffer
    INT 16h
    JZ  delay_start ; Branch if buffer empty (ZF=1)
    
    MOV AH, 00h     ; INT 16h, AH=00h: Read Keystroke
    INT 16h
    
    CMP AL, 'q'
    JE  stop
    
    CMP AL, 'f'    
    JNE try_slower
    
    ; Decrease delay (Increase speed) with bounds checking
    CMP speed, 500  
    JG  sub_speed
    MOV speed, 1    ; Clamp to maximum operational speed
    JMP delay_start
    
sub_speed:
    SUB speed, 500
    JMP delay_start

try_slower:
    ; Increase delay (Decrease speed)
    CMP AL, 's'
    JNE delay_start
    ADD speed, 500

    ; 5. Execution Delay Loop
delay_start:
    MOV CX, 0
loop_wait:
    INC CX
    CMP CX, speed
    JNE loop_wait

    ; 6. Automaton Ruleset Evaluation
    CMP current, 219 ; 219 = ASCII Solid Block
    JE  do_left
    
    ; Rule A: White Cell (Space) -> Turn Right, Invert to Black
    INC dir
    CMP dir, 4
    JNE write_block
    MOV dir, 0       ; Clamp orientation (0-3)
    
write_block:
    MOV AH, 09h    
    MOV AL, 219     ; Write Block
    MOV BL, 07h     ; Attribute: Light Gray
    MOV CX, 1
    INT 10h
    JMP move_ant

do_left:
    ; Rule B: Black Cell (Block) -> Turn Left, Invert to White
    CMP dir, 0
    JE  fix_neg
    DEC dir
    JMP write_space
fix_neg:
    MOV dir, 3       ; Clamp orientation (0-3)

write_space:
    MOV AH, 09h
    MOV AL, 32       ; Write Space
    MOV BL, 07h      ; Attribute: Light Gray
    MOV CX, 1
    INT 10h

    ; 7. Coordinate Translation
move_ant:
    CMP dir, 0
    JE  go_up
    CMP dir, 1
    JE  go_right
    CMP dir, 2
    JE  go_down
    CMP dir, 3
    JE  go_left

go_up:    
    DEC y
    JMP bounds
go_right: 
    INC x
    JMP bounds
go_down:  
    INC y
    JMP bounds
go_left:  
    DEC x

    ; 8. Toroidal Boundary Wrapping
bounds:
    CMP x, 80       ; Right boundary
    JE  rst_x0
    CMP x, 0FFh     ; Left boundary (-1 overflow)
    JE  rst_x79
    CMP y, 25       ; Bottom boundary
    JE  rst_y0
    CMP y, 0FFh     ; Top boundary (-1 overflow)
    JE  rst_y24
    JMP start

rst_x0:  
    MOV x, 0
    JMP start
rst_x79: 
    MOV x, 79
    JMP start
rst_y0:  
    MOV y, 0
    JMP start
rst_y24: 
    MOV y, 24
    JMP start

stop:
    RET             ; Terminate routine, return to OS

; --- Data Segment ---
x        DB 40      ; Agent X-coordinate
y        DB 12      ; Agent Y-coordinate
dir      DB 0       ; Orientation (0=N, 1=E, 2=S, 3=W)
current  DB 0       ; State buffer for rendering pipeline
speed    DW 10      ; Cycle delay coefficient

END