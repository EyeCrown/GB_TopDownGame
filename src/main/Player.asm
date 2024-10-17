INCLUDE "src/main/utils/hardware.inc"
INCLUDE "src/main/utils/constants.inc"

SECTION "Player Variables", WRAM0
    wPlayer_HP:: db
    wPlayer_ATK:: db

    wPlayer_Y:: db
    wPlayer_X:: db

SECTION "Player", ROM0

; PLAYER SPRITE IN OAM

; Set player to position on screen
; X Y top left corner
; @param b: Y position
; @param c: X position
SetPlayerPositionVariables::
    ld a, LOW(wPlayer_Y)        ; Load wPlayer_Y address in HL
    ld l, a                     ;   |
    ld a, HIGH(wPlayer_Y)       ;   |
    ld h, a                     ;   |
    ld a, b                     ; Write Y position into HL
    ld [hli], a                 ;   |   + inc HL to get wPlayer_X address in HL
    ld a, c                     ; Write X position into HL 
    ld [hl], a                  ;   |
    ret 

; Set player to position on screen
; X Y top left corner
; @param b: Y position
; @param c: X position
SetPlayerPosition::
    ld a, LOW(wShadowOAM)
    ld l, a
    ld a, HIGH(wShadowOAM)
    ld h, a
    ; ld hl, _OAMRAM
    ; Sprite 0
    ld a, b
    add 0 + 16    ; Y = 16
    ld [hli], a
    ld a, c
    add 0 + 8
    ld [hli], a ; X = 8
    ld a, 0     ; Tile index = 0
    ld [hli], a
    ld [hli], a ; Attributes = %0000_0000
    ; Sprite 1
    ld a, b
    add 0 + 16    ; Y = 16
    ld [hli], a
    ld a, c
    add 8 + 8
    ld [hli], a ; X = 8
    ld a, 1    ; Tile index = 1
    ld [hli], a
    xor a
    ld [hli], a ; Attributes = %0000_0000
    ; Sprite 2
    ld a, b
    add 8 + 16    ; Y = 16
    ld [hli], a
    ld a, c
    add 0 + 8
    ld [hli], a ; X = 8
    ld a, 2    ; Tile index = 2
    ld [hli], a
    xor a
    ld [hli], a ; Attributes = %0000_0000
    ; Sprite 3
    ld a, b
    add 8 + 16    ; Y = 16
    ld [hli], a
    ld a, c
    add 8 + 8
    ld [hli], a ; X = 8
    ld a, 3    ; Tile index = 3
    ld [hli], a
    xor a
    ld [hli], a ; Attributes = %0000_0000
    ret


; Update player position X/Y variables
; @param b: Y offset
; @param c: X offset
MovePlayer:: 
    ld a, LOW(wPlayer_Y)
    ld l, a
    ld a, HIGH(wPlayer_Y)
    ld h, a
    ld a, [hl]
    add a, b
    ld [hli], a     ; hl++ -> hl = wPlayer_X 
    ld a, [hl]
    add a, c
    ret 

; Move player
; @param b: Y offset
; @param c: X offset
MovePlayerOld::
    ld a, LOW(wPlayer_Y)
    ld l, a
    ld a, HIGH(wPlayer_Y)
    ld h, a
    ld d, OAM_PLAYER_SIZE
MovePlayerLoop:
    xor a       ; a = 0
    cp a, d     ; a <= d
    ret z       
    dec d       ; --d

    ld a, [hl]
    add a, b
    ld [hli], a     ; hl++ -> hl = wPlayer_X 
    ld a, [hl]
    add a, c
    ld [hli], a
    inc hl
    inc hl

    jp MovePlayerLoop

; Move player but without a loop,
; so no risk of obliterate character
; @param b: Y offset
; @param c: X offset
MovePlayerNoLoop::
    ld hl, OAM_PLAYER_ADDR

    ld a, [hl]
    add a, b
    ld [hli], a
    ld a, [hl]
    add a, c
    ld [hli], a
    inc hl
    inc hl

    ld a, [hl]
    add a, b
    ld [hli], a
    ld a, [hl]
    add a, c
    ld [hli], a
    inc hl
    inc hl

    ld a, [hl]
    add a, b
    ld [hli], a
    ld a, [hl]
    add a, c
    ld [hli], a
    inc hl
    inc hl

    ld a, [hl]
    add a, b
    ld [hli], a
    ld a, [hl]
    add a, c
    ld [hli], a
    inc hl
    inc hl

    ret


DrawPlayerShadowOAM::
    
    
    ld a, LOW(wPlayer_Y)
    ld l, a
    ld a, HIGH(wPlayer_Y)
    ld h, a

    ld a, [hli]
    ld d, a

    ld a, [hl]
    ld e, a

    ; d: Y Position
    ; e: X Position
    
    ld a, LOW(wShadowOAM)
    ld l, a
    ld a, HIGH(wShadowOAM)
    ld h, a
    
    ; Sprite 0
    ld a, d
    ld [hli], a
    ld a, e
    ld [hli], a
    ld a, TILE_PLAYER_00
    ld [hli], a
    ld a, $00
    ld [hli], a
    
    ld a, e
    add $08     ; X + 8
    ld e, a

    ; Sprite 1
    ld a, d
    ld [hli], a
    ld a, e
    ld [hli], a
    ld a, TILE_PLAYER_01
    ld [hli], a
    ld a, $00
    ld [hli], a

    ld a, d
    add $08     ; Y + 8
    ld d, a

    ld a, e
    sub $08     ; X - 8
    ld e, a

    ; Sprite 2
    ld a, d
    ld [hli], a
    ld a, e
    ld [hli], a
    ld a, TILE_PLAYER_02
    ld [hli], a
    ld a, $00
    ld [hli], a

    ld a, e
    add $08     ; X + 8
    ld e, a

    ; Sprite 3
    ld a, d
    ld [hli], a
    ld a, e
    ld [hli], a
    ld a, TILE_PLAYER_03
    ld [hli], a
    ld a, $00
    ld [hli], a

    ret