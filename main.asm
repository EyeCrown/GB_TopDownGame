INCLUDE "hardware.inc"

; DEF VAR_NAME EQU $value

DEF MIDDLE_SCREEN_X EQU SCRN_X / 2 + 8
DEF MIDDLE_SCREEN_Y EQU SCRN_Y / 2 + 16

SECTION "Counter", WRAM0
    wFrameCounter: db

SECTION "Input Variables", WRAM0
    wCurKeys:: db
    wNewKeys:: db

SECTION "Data", WRAM0


SECTION "Header", ROM0[$100]
    jp EntryPoint

    ds $150 - @, 0 ; Make room for the header

EntryPoint:
    ; Do not turn the LCD off outside of VBlank
WaitVBlank:
    ld a, [rLY]
    cp 144
    jp c, WaitVBlank

    ; Turn the LCD off
    ld a, 0
    ld [rLCDC], a
    
    ; Copy the player tile data
    ld de, PlayerTiles
    ld hl, $8000
    ld bc, PlayerTilesEnd - PlayerTiles
    call Memcopy

    ; Copy the tile data
    ld de, Tiles
    ld hl, $9000
    ld bc, TilesEnd - Tiles
    call Memcopy

DrawBG:
    ld h, HIGH(_SCRN0)
    ld l,  LOW(_SCRN0)
    inc hl

    ld c, $20
DrawBGLoop:
    ld b, $10

    ld a, $01
    and c
    jp z, DrawBGLineEven
    inc hl  ; impair / odd
    jp DrawBGLineLoop

DrawBGLineEven:
    dec hl  ; pair  / even

    
DrawBGLineLoop:
    ld a, $01
    ld [hli], a
    inc hl
    dec b
    jp nz, DrawBGLineLoop
    dec c
    jp nz, DrawBGLoop


    ld a, 0
    ld b, 160
    ld hl, _OAMRAM
ClearOam:
    ld [hli], a
    dec b
    jp nz, ClearOam


    ld hl, _OAMRAM
    ; Sprite 0
    ld a, MIDDLE_SCREEN_Y - 8    ; Y = 16
    ld [hli], a
    ld a, MIDDLE_SCREEN_X - 8
    ld [hli], a ; X = 8
    ld a, 0     ; Tile index = 0
    ld [hli], a
    ld [hli], a ; Attributes = %0000_0000
    ; Sprite 1
    ld a, MIDDLE_SCREEN_Y - 8    ; Y = 16
    ld [hli], a
    ld a, MIDDLE_SCREEN_X
    ld [hli], a ; X = 8
    ld a, 1     ; Tile index = 0
    ld [hli], a
    ld [hli], a ; Attributes = %0000_0000
    ; Sprite 2
    ld a, MIDDLE_SCREEN_Y       ; Y = 16
    ld [hli], a
    ld a, MIDDLE_SCREEN_X - 8
    ld [hli], a ; X = 8
    ld a, 2     ; Tile index = 0
    ld [hli], a
    ld [hli], a ; Attributes = %0000_0000
    ; Sprite 3
    ld a, MIDDLE_SCREEN_Y       ; Y = 16
    ld [hli], a
    ld a, MIDDLE_SCREEN_X
    ld [hli], a ; X = 8
    ld a, 3     ; Tile index = 0
    ld [hli], a
    ld [hli], a ; Attributes = %0000_0000

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                    ;
;       MAIN                         ;
;                                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Main:
    ld a, [rLY]
    cp 144
    jp nc, Main
WaitVBlank2:
    ld a, [rLY]
    cp 144
    jp c, WaitVBlank2


    ld a, [wFrameCounter]
    inc a
    cp a, 60    ; 60 FPS
    jp nz, Continue
    ld a, 0

Continue:
    ld [wFrameCounter], a
    ; Check the current keys every frame and move left and right.
    call UpdateKeys



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                    ;
;       INPUTS                       ;
;                                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CheckLeft:
    ld a, [wCurKeys]
    and a, PADF_LEFT
    jp z, CheckRight
Left:
    ; ld h, HIGH(rSCX)
    ; ld l,  LOW(rSCX)
    ; dec [hl]
    /* ld e, 1
    ld hl, _OAMRAM
    ld c, 4
    call MoveNegativeXObjectLoop */
    ld hl, _OAMRAM
    ld d, 4
    call MoveLeftObjectXPos

    ; Then check the right button
CheckRight:
    ld a, [wCurKeys]
    and a, PADF_RIGHT
    jp z, CheckUp 
Right:
    ; ld h, HIGH(rSCX)
    ; ld l,  LOW(rSCX)
    ; inc [hl]
    /* ld e, 1
    ld hl, _OAMRAM
    ld c, 4
    call MovePositiveXObjectLoop */

    ld hl, _OAMRAM
    ld d, 4
    call MoveRightObjectXPos

CheckUp:
    ld a, [wCurKeys]
    and a, PADF_UP
    jp z, CheckDown
Up:
    /* ld d, 1
    ld hl, _OAMRAM
    ld b, 4
    call MoveNegativeYObjectLoop */
    ld hl, _OAMRAM
    ld d, 4
    call MoveUpObjectYPos
    
    ; ld h, HIGH(rSCY)
    ; ld l,  LOW(rSCY)
    ; dec [hl]
    ; Then check the button
CheckDown:
    ld a, [wCurKeys]
    and a, PADF_DOWN
    jp z, CheckAButton 
Down:
    ; ld h, HIGH(rSCY)
    ; ld l,  LOW(rSCY)
    ; inc [hl]

    /* ld d, 1
    ld hl, _OAMRAM
    ld b, 4
    call MovePositiveYObjectLoop */

    ld hl, _OAMRAM
    ld d, 4
    call MoveDownObjectYPos
    

CheckAButton:
    ld a, [wCurKeys]
    and a, PADF_A
    jp z, CheckBButton 
AButton:
    ld a, [wFrameCounter]
    ; cp a, 0
    xor a, %0000_0011
    ; jp nz, EndOfMain
    jp z, EndOfMain
    ld a, [rBGP]
    rlca 
    rlca     
    ld [rBGP], a

CheckBButton:
    ld a, [wCurKeys]
    and a, PADF_B
    jp z, Main 
BButton:
    ld a, [rBGP]
    rrca 
    rrca     
    ld [rBGP], a
    
    ; End of Main loop
EndOfMain:
    jp Main




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                    ;
;       UTILS                        ;
;                                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Move down object in OAM Y Position 
; @param hl: OAM address 
; @param  d: Number of sprites
MoveDownObjectYPos:
    ld a, [hl]
    cp a, $90     ; Maximum = 160 - 16
    ret nc
MoveDownObjectYPosLoop:
    xor a       ; a = 0
    cp a, d     ; a == d
    ret z
    dec d       ; --d
        inc [hl]    ; YPos++
    inc hl
    inc hl
    inc hl
    inc hl
    jp MoveDownObjectYPosLoop

; Move up object in OAM by one pixel
; @param hl: OAM address 
; @param  d: Number of sprites
MoveUpObjectYPos:
    ld a, [hl]
    cp a, $11     ; Minimum = 0 + 16 (+1)
    ret c
MoveUpObjectYPosLoop:
    xor a       ; a = 0
    cp a, d     ; a == d
    ret z
    dec d       ; --d
        dec [hl]    ; YPos--
    inc hl
    inc hl
    inc hl
    inc hl
    jp MoveUpObjectYPosLoop

; Move right object in OAM by one pixel
; @param hl: OAM address
; @param  d: Number of sprites
MoveRightObjectXPos:
    inc hl
    ld a, [hl]
    cp a, $98     ; Maximum = 160 - 8
    ret nc
MoveRightObjectXPosLoop:
    xor a       ; a = 0
    cp a, d     ; a == d
    ret z
    dec d       ; --d
        inc [hl]    ; YPos++
    inc hl
    inc hl
    inc hl
    inc hl
    jp MoveRightObjectXPosLoop

; Move left object in OAM by one pixel
; @param hl: OAM address 
; @param  d: Number of sprites
MoveLeftObjectXPos:
    inc hl
    ld a, [hl]
    cp a, $09     ; Minimum = 0 + 8 (+1)
    ret c
MoveLeftObjectXPosLoop:
    xor a       ; a = 0
    cp a, d     ; a == d
    ret z
    dec d       ; --d
        dec [hl]    ; YPos--
    inc hl
    inc hl
    inc hl
    inc hl
    jp MoveLeftObjectXPosLoop


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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                    ;
;       SPRITES                      ;
;                                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


PlayerTiles: INCBIN "res/img/2bppFiles/TestPlayer.2bpp"
PlayerTilesEnd:


Tiles:
White:      ; White tile
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
WhiteEnd:
Black:      ; Black tile
    dw `33333333
    dw `33333333
    dw `33333333
    dw `33333333
    dw `33333333
    dw `33333333
    dw `33333333
    dw `33333333
BlackEnd:
TilesEnd: