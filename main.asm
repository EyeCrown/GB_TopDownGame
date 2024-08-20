INCLUDE "hardware.inc"

; DEF VAR_NAME EQU $value
DEF BRICK_LEFT EQU $05
DEF BRICK_RIGHT EQU $06
DEF BLANK_TILE EQU $08

SECTION "Counter", WRAM0
    wFrameCounter: db
    wHealthPoints: db

SECTION "Input Variables", WRAM0
    wCurKeys:: db
    wNewKeys:: db

SECTION "Data", WRAM0
    wBallMomentumX: db
    wBallMomentumY: db

    ;   last bit = alive or not
    wGameData: db 

SECTION "Header", ROM0[$100]

    jp EntryPoint

    ds $150 - @, 0 ; Make room for the header

EntryPoint:
    ;Do not turn the LCD off outside of VBlank
WaitVBlank:
    ld a, [rLY]
    cp 144
    jp c, WaitVBlank

    ; Turn the LCD off
    ld a, 0
    ld [rLCDC], a
    
    ; Copy the tile data
    ld de, Tiles
    ld hl, $9000
    ld bc, TilesEnd - Tiles
    call Memcopy

    ; Copy the tilemap
    ld de, Tilemap
    ld hl, $9800
    ld bc, TilemapEnd - Tilemap
    call Memcopy

    ; Copy the paddle data    
    ld de, Paddle
    ld hl, $8000
    ld bc, PaddleEnd - Paddle
    call Memcopy

    ; Copy the ball tile
    ld de, Ball
    ld hl, $8010
    ld bc, BallEnd - Ball
    call Memcopy

    ; Copy the ball tile
    ld de, BallTileData
    ld hl, $8020
    ld bc, BallTileDataEnd - BallTileData
    call Memcopy

    ; Copy big paddle tile
    ld de, BigPaddle
    ld hl, $8030
    ld bc, BigPaddleEnd - BigPaddle
    call Memcopy

    ld a, 0
    ld b, 160
    ld hl, _OAMRAM
ClearOam:
    ld [hli], a
    dec b
    jp nz, ClearOam

    ; Initialize the paddle sprite in OAM
    ld hl, _OAMRAM
    ld a, 128 + 16
    ld [hli], a
    ld a, 16 + 8
    ld [hli], a
    ld a, 3
    ld [hli], a
    ld [hli], a

    ld a, 128 + 16
    ld [hli], a
    ld a, 24 + 8
    ld [hli], a
    ld a, 4
    ld [hli], a
    ld [hli], a


    ; Now initialize the ball sprite
    ld a, 100 + 16
    ld [hli], a
    ld a, 24 + 8
    ld [hli], a
    ld a, 2
    ld [hli], a
    ld a, 0
    ld [hli], a

    ; The ball start out going up to the right
    ld a, 1
    ld [wBallMomentumX], a
    ld a, -1
    ld [wBallMomentumY], a

    ; Turn the LCD on
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
    ld [rLCDC], a
    
    ; During the first (blank) frame, initialize display registers
    ld a, %11_10_01_00
    ld [rBGP], a
    ld a, %11_10_01_00
    ld [rOBP0], a
    
    ld a, 0
    ld [wFrameCounter], a
    ld a, 3
    ld [wHealthPoints], a
    ld a, %0_0_0_0_0_0_0_1
    ld [wGameData], a


Main:
    ld a, [rLY]
    cp 144
    jp nc, Main
WaitVBlank2:
    ld a, [rLY]
    cp 144
    jp c, WaitVBlank2

	; Add the ball's momentum to its position in OAM
	ld a, [wBallMomentumX]
	ld b, a
	ld a, [_OAMRAM + 9]
	add a, b
	ld [_OAMRAM + 9], a
	
	ld a, [wBallMomentumY]
	ld b, a
	ld a, [_OAMRAM + 8]
	add a, b
	ld [_OAMRAM + 8], a

    ; Check the current keys every frame and move left and right.
    call UpdateKeys

BounceOnTop:
    ; Remember to offset the OAM position!
    ; (8, 16) in OAM coordinates is (0, 0) on the screen.
    ld a, [_OAMRAM + 8]
    sub a, 16 + 1
    ld c, a
    ld a, [_OAMRAM + 9]
    sub a, 8
    ld b, a
    call GetTileByPixel ; Returns tile address in hl
    ld a, [hl]
    call IsWallTile
    jp nz, BounceOnRight
	call CheckAndHandleBrick
    ld a, 1
    ld [wBallMomentumY], a
	;call PlayBounceSound
BounceOnRight:
    ld a, [_OAMRAM + 8]
    sub a, 16
    ld c, a
    ld a, [_OAMRAM + 9]
    sub a, 8 - 1
    ld b, a
    call GetTileByPixel
    ld a, [hl]
    call IsWallTile
    jp nz, BounceOnLeft
	call CheckAndHandleBrick
    ld a, -1
    ld [wBallMomentumX], a
	;call PlayBounceSound
BounceOnLeft:
    ld a, [_OAMRAM + 8]
    sub a, 16
    ld c, a
    ld a, [_OAMRAM + 9]
    sub a, 8 + 1
    ld b, a
    call GetTileByPixel
    ld a, [hl]
    call IsWallTile
    jp nz, BounceOnBottom
	call CheckAndHandleBrick
    ld a, 1
    ld [wBallMomentumX], a
	;call PlayBounceSound
BounceOnBottom:
    ld a, [_OAMRAM + 8]
    sub a, 16 - 1
    ld c, a
    ld a, [_OAMRAM + 9]
    sub a, 8
    ld b, a
    call GetTileByPixel
    ld a, [hl]
    call IsWallTile
    jp nz, BounceDone
    cp a, $09 ; ID bottom
    jp z, TakeDamage

	call CheckAndHandleBrick
    ld a, -1
    ld [wBallMomentumY], a
	;call PlayBounceSound
BounceDone:
    ; First, check if the ball is low enough to bounce off the paddle.
    ld a, [_OAMRAM]
    ld b, a
    ld a, [_OAMRAM + 8]
	add a, 8	; To correspond with the ball sprite
    cp a, b
    jp nz, PaddleBounceDone ; If the ball isn't at the same Y position as the paddle, it can't bounce.
    ; Now let's compare the X positions of the objects to see if they're touching.
    ld a, [_OAMRAM + 9] ; Ball's X position.
    ld b, a
    ld a, [_OAMRAM + 1] ; Paddle's X position.
    sub a, 8
    cp a, b
    jp nc, PaddleBounceDone
    add a, 16 + 8 ; 8 to undo, 16 as the width.
    cp a, b
    jp c, PaddleBounceDone

    ld a, -1
    ld [wBallMomentumY], a
    
    ld a, [rBGP]
    rlca
    rlca
    ld [rBGP], a
PaddleBounceDone:

    ; First, check if the left button is pressed
CheckLeft:
    ld a, [wCurKeys]
    and a, PADF_LEFT
    jp z, CheckRight
Left:
    ; Move the paddle one pixel to the left
    ld a, [_OAMRAM + 1]
    dec a
    ; If we've already hit the edge of the playfield, don't move
    cp a, 15
    jp z, Main
    ld [_OAMRAM + 1], a
    ld a, [_OAMRAM + 5]
    dec a
    ld [_OAMRAM + 5], a
    jp Main

    ; Then check the right button
CheckRight:
    ld a, [wCurKeys]
    and a, PADF_RIGHT
    jp z, CheckAButton 
Right:
    ; Move the paddle one pixel to the right.
    ld a, [_OAMRAM + 1]
    inc a
    ; If we've already hit the edge of the playfield, don't move
    cp a, 97
    jp z, Main
    ld [_OAMRAM + 1], a
    ld a, [_OAMRAM + 5]
    inc a
    ld [_OAMRAM + 5], a
    jp Main

    ;
 CheckAButton:
    ld a, [wCurKeys]
    and a, PADF_A
    jp z, Main
AButton:
    jp Main


 

; Copy bytes from one area to another.
; @param de: Source
; @param hl: Destination
; @param bc: Length
Memcopy:
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or a, c
    jp nz, Memcopy
    ret

UpdateKeys:
  ; Poll half the controller
  ld a, P1F_GET_BTN
  call .onenibble
  ld b, a ; B7-4 = 1; B3-0 = unpressed buttons

  ; Poll the other half
  ld a, P1F_GET_DPAD
  call .onenibble
  swap a ; A3-0 = unpressed directions; A7-4 = 1
  xor a, b ; A = pressed buttons + directions
  ld b, a ; B = pressed buttons + directions

  ; And release the controller
  ld a, P1F_GET_NONE
  ldh [rP1], a

  ; Combine with previous wCurKeys to make wNewKeys
  ld a, [wCurKeys]
  xor a, b ; A = keys that changed state
  and a, b ; A = keys that changed to pressed
  ld [wNewKeys], a
  ld a, b
  ld [wCurKeys], a
  ret

.onenibble
  ldh [rP1], a ; switch the key matrix
  call .knownret ; burn 10 cycles calling a known ret
  ldh a, [rP1] ; ignore value while waiting for the key matrix to settle
  ldh a, [rP1]
  ldh a, [rP1] ; this read counts
  or a, $F0 ; A7-4 = 1; A3-0 = unpressed keys
.knownret
  ret

; Checks if a brick was collided with and breaks it if possible.
; @param hl: address of tile.
CheckAndHandleBrick:
    ld a, [hl]
    cp a, BRICK_LEFT
    jr nz, CheckAndHandleBrickRight
    ; Break a brick from the left side.
	;call PlayBreakSound
    ld [hl], BLANK_TILE
    inc hl
    ld [hl], BLANK_TILE

    call IncScore

CheckAndHandleBrickRight:
    cp a, BRICK_RIGHT
    ret nz
    ; Break a brick from the right side.
	;call PlayBreakSound
    ld [hl], BLANK_TILE
    dec hl
    ld [hl], BLANK_TILE
    
    call IncScore

    ret

; Convert a pixel position to a tilemap address
; hl = $9800 + X + Y * 32
; @param b: X
; @param c: Y
; @return hl: tile address
GetTileByPixel:
    ; First, we need to divide by 8 to convert a pixel position to a tile position.
    ; After this we want to multiply the Y position by 32.
    ; These operations effectively cancel out so we only need to mask the Y value.
    ld a, c
    and a, %11111000
    ld l, a
    ld h, 0
    ; Now we have the position * 8 in hl
    add hl, hl ; position * 16
    add hl, hl ; position * 32
    ; Convert the X position to an offset.
    ld a, b
    srl a ; a / 2
    srl a ; a / 4
    srl a ; a / 8
    ; Add the two offsets together.
    add a, l
    ld l, a
    adc a, h
    sub a, l
    ld h, a
    ; Add the offset to the tilemap's base address, and we are done!
    ld bc, $9800
    add hl, bc
    ret

; @param a: tile ID
; @return z: set if a is a wall.
IsWallTile:
    cp a, $00
    ret z
    cp a, $01
    ret z
    cp a, $02
    ret z
    cp a, $04
    ret z
    cp a, $05
    ret z
    cp a, $06
    ret z
    cp a, $07
    ret

PlayBounceSound:
	ld a, $85
	ld [rNR21], a
	ld a, $70
	ld [rNR22], a
	ld a, $0d
	ld [rNR23], a
	ld a, $c3
	ld [rNR24], a
	ret	

PlayBreakSound:
	ld a, $01
	ld [rNR41], a
	ld a, $f0
	ld [rNR42], a
	ld a, $91
	ld [rNR43], a
	ld a, $c0
	ld [rNR44], a
	ret

IncScore:
    ;ld bc, $9852
    ld hl, $9851
    call IncNumberScore
    ret 

; @param hl: address of number.
; 0: $24
; 9: $2D
IncNumberScore:
    ld a, [hl]
    inc a
    cp a, $2D + 1 
    jr nz, SimpleInc
CarryInc:
    ; > 9
    ld a, $24
    ld [hl], a
    ; call same function for $9851 decalage 
    dec hl
    call IncNumberScore
    ret 
SimpleInc:
    ld [hl], a
    ret

TakeDamage:
    ld a, [wHealthPoints]
    cp a, 0
    ret z
    ld b, a     ; HP in b
    ld h, $98
    ld a, $92
    sub a, b
    ld l, a
    
    ld a, [hl]
    inc a
    ld [hl], a

    ld a, b
    dec a
    ld [wHealthPoints], a

    cp a, 0
    jp z, Die
    
    ; //TODO: make respawn system
    ld a, -1
    ld [wBallMomentumY], a
    jp BounceDone

Die:
    ; //TODO: make death system
    ld a, [wGameData]
    ld a, $01
    ld [wGameData], a
    jp Main

Tiles:
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33322222
	dw `33322222
	dw `33322222
	dw `33322211
	dw `33322211
	dw `33333333
	dw `33333333
	dw `33333333
	dw `22222222
	dw `22222222
	dw `22222222
	dw `11111111
	dw `11111111
	dw `33333333
	dw `33333333
	dw `33333333
	dw `22222333
	dw `22222333
	dw `22222333
	dw `11222333
	dw `11222333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `22222222
	dw `20000000
	dw `20111111
	dw `20111111
	dw `20111111
	dw `20111111
	dw `22222222
	dw `33333333
	dw `22222223
	dw `00000023
	dw `11111123
	dw `11111123
	dw `11111123
	dw `11111123
	dw `22222223
	dw `33333333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `11001100
	dw `11111111
	dw `11111111
	dw `21212121
	dw `22222222
	dw `22322232
	dw `23232323
	dw `33333333
	; Paste your logo here:
    INCBIN "res/img/logo.2bpp"
    INCBIN "res/fonts/text-font.2bpp"
    INCBIN "res/img/heart_fill.2bpp"
    INCBIN "res/img/heart_empty.2bpp"
TilesEnd:

Tilemap:
	db $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $02, $03, $03, $03, $03, $1A, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $07, $46, $36, $42, $45, $38, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $08, $07, $24, $24, $24, $24, $24, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $08, $07, $03, $4E, $4E, $4E, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $0A, $0B, $0C, $0D, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $0E, $0F, $10, $11, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $12, $13, $14, $15, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $16, $17, $18, $19, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
TilemapEnd:

Paddle:
    dw `13333331
    dw `30000003
    dw `13333331
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
PaddleEnd:

BigPaddle: INCBIN "res/img/paddle16x8.2bpp"
BigPaddleEnd:

Ball:
    dw `00033000
    dw `00322300
    dw `03222230
    dw `03222230
    dw `00322300
    dw `00033000
    dw `00000000
    dw `00000000
BallEnd:

BallTileData: INCBIN "res/img/image.2bpp"
BallTileDataEnd: