INCLUDE "src/main/utils/hardware.inc"

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

    ; Copy the projectile tile data
    ld de, Projectile
    ld hl, $8040
    ld bc, ProjectileEnd - Projectile
    call Memcopy

    ; Copy the tile data
    ; ld de, Tiles
    ; ld hl, $9000
    ; ld bc, TilesEnd - Tiles
    ; call Memcopy

    ; Copy the level tilemap
    ld de, level1_Tilemap
    ld hl, _SCRN0
    ld bc, _SCRN1 - _SCRN0
    call Memcopy

    ; Copy the level tilemap
    ld de, TileSet
    ld hl, _VRAM9000
    ld bc, TileSetEnd - TileSet
    call Memcopy

;DrawBG:
;    ld h, HIGH(_SCRN0)
;    ld l,  LOW(_SCRN0)
;    inc hl
;
;    ld c, $20
;DrawBGLoop:
;    ld b, $10
;
;    ld a, $01
;    and c
;    jp z, DrawBGLineEven
;    inc hl  ; impair / odd
;    jp DrawBGLineLoop
;
;DrawBGLineEven:
;    dec hl  ; pair  / even
;
;    
;DrawBGLineLoop:
;    ld a, $01
;    ld [hli], a
;    inc hl
;    dec b
;    jp nz, DrawBGLineLoop
;    dec c
;    jp nz, DrawBGLoop


    ld a, 0
    ld b, 160
    ld hl, _OAMRAM
ClearOam:
    ld [hli], a
    dec b
    jp nz, ClearOam


    ld hl, _OAMRAM

    ; PLAYER SPRITE IN OAM

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
    xor a
    ld [hli], a ; Attributes = %0000_0000
    ; Sprite 2
    ld a, MIDDLE_SCREEN_Y       ; Y = 16
    ld [hli], a
    ld a, MIDDLE_SCREEN_X - 8
    ld [hli], a ; X = 8
    ld a, 2     ; Tile index = 0
    ld [hli], a
    xor a
    ld [hli], a ; Attributes = %0000_0000
    ; Sprite 3
    ld a, MIDDLE_SCREEN_Y       ; Y = 16
    ld [hli], a
    ld a, MIDDLE_SCREEN_X
    ld [hli], a ; X = 8
    ld a, 3     ; Tile index = 0
    ld [hli], a
    ld [hli], a ; Attributes = %0000_0000

    ; PROJECTILE SPRITE IN OAM

    ; Sprite 0
    ld a, SCRN_Y - 32    ;
    ld [hli], a
    ld a, SCRN_X - 16
    ld [hli], a ; 
    ld a, 4     ; Tile index = 0
    ld [hli], a
    xor a
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

    ld a, [wFrameCounter]    ; 256 = 60 * 4
    add a, $04
    ld [wFrameCounter], a


    call UpdateProjectile
    call DoOther


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                    ;
;       INPUTS                       ;
;                                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Check the current keys every frame and move left and right.
    call UpdateKeys

CheckLeft:
    ld a, [wCurKeys]
    and a, PADF_LEFT
    jp z, CheckRight
Left:

    ld hl, _OAMRAM
    ld d, 4
    call MoveLeftObjectXPos

    ; Then check the right button
CheckRight:
    ld a, [wCurKeys]
    and a, PADF_RIGHT
    jp z, CheckUp 
Right:

    ld hl, _OAMRAM
    ld d, 4
    call MoveRightObjectXPos

CheckUp:
    ld a, [wCurKeys]
    and a, PADF_UP
    jp z, CheckDown
Up:

    ld hl, _OAMRAM
    ld d, 4
    call MoveUpObjectYPos

    ; Then check the button
CheckDown:
    ld a, [wCurKeys]
    and a, PADF_DOWN
    jp z, CheckAButton 
Down:

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
;       METHODS                      ;
;                                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateProjectile: 
    
    ld hl, _OAMRAM + (sizeof_OAM_ATTRS * 4)
    ld d, 1
    call MoveLeftObjectXPos
    ld hl, _OAMRAM + (sizeof_OAM_ATTRS * 4)
    ld d, 1
    call MoveLeftObjectXPos

    ld a, [_OAMRAM + (sizeof_OAM_ATTRS * 4) + 1]
    cp a, $09
    ret nc
    ld a, SCRN_X
    ld [_OAMRAM + (sizeof_OAM_ATTRS * 4) + 1], a
    ret









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




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                    ;
;       SPRITES                      ;
;                                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


PlayerTiles: INCBIN "src/generated/sprites/TestPlayer.2bpp"
PlayerTilesEnd:

Projectile: INCBIN "src/generated/sprites/projectile.2bpp"
ProjectileEnd:

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

TileSet: INCBIN "src/generated/backgrounds/TinySpriteSheet.2bpp"
TileSetEnd:

