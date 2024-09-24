INCLUDE "src/main/utils/hardware.inc"
INCLUDE "src/main/utils/constants.inc"

SECTION "Player Variables", WRAM0
    wPlayer_HP:: db
    wPlayer_ATK:: db

SECTION "Player", ROM0

; PLAYER SPRITE IN OAM

; Set player to position on screen
; X Y top left corner
; @param b: Y position
; @param c: X position
SetPlayerPosition::
    ld hl, PLAYER_OAM_ADDR
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



; Move player
; @param b: Y offset
; @param c: X offset
MovePlayer::
    ld hl, OAM_PLAYER_ADDR
    ld d, OAM_PLAYER_SIZE
MovePlayerLoop:
    xor a       ; a = 0
    cp a, d     ; a <= d
    ret z       
    dec d       ; --d

    ld a, [hl]
    add a, b
    ld [hli], a
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