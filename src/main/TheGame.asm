INCLUDE "src/main/utils/hardware.inc"
INCLUDE "src/main/utils/constants.inc"

; DEF VAR_NAME EQU $value

DEF MIDDLE_SCREEN_X EQU SCRN_X / 2 + 8
DEF MIDDLE_SCREEN_Y EQU SCRN_Y / 2 + 16

SECTION "Counter", WRAM0
    wFrameCounter: db

SECTION "Input Variables", WRAM0
    wCurKeys:: db
    wNewKeys:: db

SECTION "Data", WRAM0
    wCurLevelDoorAddr:: dw
    wCurLevelKeyAddr:: dw

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

    ; Copy the level tilemap
    ld de, level2_Tilemap
    ld hl, _SCRN0
    ld bc, level_LEN
    call Memcopy

    ; Copy the backgorund tileset
    ld de, TileSet
    ld hl, _VRAM9000
    ld bc, TileSetEnd - TileSet
    call Memcopy


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                    ;
;       OAM DATA                     ;
;                                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ld a, 0
    ld b, 160
    ld hl, _OAMRAM
ClearOam:
    ld [hli], a
    dec b
    jp nz, ClearOam

    ld b, LVL1_SPAWN_Y
    ld c, LVL1_SPAWN_X
    call SetPlayerPosition

    /* ; PROJECTILE SPRITE IN OAM

    ; Sprite 0
    ld a, SCRN_Y - 32    ;
    ld [hli], a
    ld a, SCRN_X - 16
    ld [hli], a ; 
    ld a, 4     ; Tile index = 0
    ld [hli], a
    xor a
    ld [hli], a ; Attributes = %0000_0000 */

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

    ld a, HIGH(LVL2_DOOR_POSITION)
    ld [wCurLevelDoorAddr], a
    ld a, LOW(LVL2_DOOR_POSITION)
    ld [wCurLevelDoorAddr+1], a

    ld a, HIGH(LVL2_KEY_POSITION)
    ld [wCurLevelKeyAddr], a
    ld a, LOW(LVL2_KEY_POSITION)
    ld [wCurLevelKeyAddr+1], a

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


    ;call UpdateProjectile


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
    call TryMoveLeft

    ; Then check the right button
CheckRight:
    ld a, [wCurKeys]
    and a, PADF_RIGHT
    jp z, CheckUp 
Right:

    ld hl, _OAMRAM
    call TryMoveRight

CheckUp:
    ld a, [wCurKeys]
    and a, PADF_UP
    jp z, CheckDown
Up:

    ld hl, _OAMRAM
    call TryMoveUp

    ; Then check the button
CheckDown:
    ld a, [wCurKeys]
    and a, PADF_DOWN
    jp z, CheckAButton 
Down:

    ld hl, _OAMRAM
    call TryMoveDown
    

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

/* UpdateProjectile: 
    
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
    ret */









;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                    ;
;       UTILS                        ;
;                                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Try move left Player
; @param hl: OAM address
TryMoveLeft:
    ; Put Y position into C reg
    ld a, [hli]
    sub a, 16   ; Don't forget the natural offset
    ld c, a 
    ; Put X position into B reg
    ld a, [hl]
    sub a, 8    ; Don't forget the natural offset
    add a, -1   ; Get X-1
    ld b, a

    call GetTileByPixel
    ld a, [hl]
    call IsKeyTile
    call IsWallTile
    ret z

    ld a, c
    add a, $07
    ld c, a
    call GetTileByPixel
    ld a, [hl]
    call IsKeyTile
    call IsWallTile
    ret z

    ld a, c
    add a, $07
    ld c, a
    call GetTileByPixel
    ld a, [hl]
    call IsKeyTile
    call IsWallTile
    ret z

    ; Do move left
    ld b, 0
    ld c, -1
    jp MovePlayer


; Try move right Player
; @param hl: OAM address
TryMoveRight:
    ; Put Y position into C reg
    ld a, [hli]
    sub a, 16   ; Don't forget the natural offset
    ld c, a 
    ; Put X position into B reg
    ld a, [hl]
    add a, $10  ; Add 16 pixels to get right side
    sub a, 8    ; Don't forget the natural offset
    ;add a, 1    ; Get X+1
    ld b, a

    call GetTileByPixel
    ld a, [hl]
    call IsKeyTile
    call IsWallTile
    ret z

    ld a, c
    add a, $07
    ld c, a
    call GetTileByPixel
    ld a, [hl]
    call IsKeyTile
    call IsWallTile
    ret z

    ld a, c
    add a, $07
    ld c, a
    call GetTileByPixel
    ld a, [hl]
    call IsKeyTile
    call IsWallTile
    ret z

    ; Do move right
    ld b, 0
    ld c, 1
    jp MovePlayer


; Try move up Player
; @param hl: OAM address
TryMoveUp:
    ; Put Y position into C reg
    ld a, [hli]
    sub a, 16   ; Don't forget the natural offset
    add a, -1   ; Get Y-1
    ld c, a 
    ; Put X position into B reg
    ld a, [hl]
    sub a, 8    ; Don't forget the natural offset
    ld b, a

    call GetTileByPixel
    ld a, [hl]
    call IsKeyTile
    call IsWallTile
    ret z

    ld a, b
    add a, $07
    ld b, a
    call GetTileByPixel
    ld a, [hl]
    call IsKeyTile
    call IsWallTile
    ret z    
    
    ld a, b
    add a, $07
    ld b, a
    call GetTileByPixel
    ld a, [hl]
    call IsKeyTile
    call IsWallTile
    ret z

    ; Do move up
    ld b, -1
    ld c, 0
    jp MovePlayer


; Try move down Player
; @param hl: OAM address
TryMoveDown:
    ; Put Y position into C reg
    ld a, [hli]
    add 16      ; Add 16 pixels to get down side
    sub a, 16   ; Don't forget the natural offset
    ;add a, 1   ; Get Y+1
    ld c, a 
    ; Put X position into B reg
    ld a, [hl]
    sub a, 8    ; Don't forget the natural offset
    ld b, a

    call GetTileByPixel
    ld a, [hl]
    call IsKeyTile
    call IsWallTile
    ret z

    ld a, b
    add a, $07
    ld b, a
    call GetTileByPixel
    ld a, [hl]
    call IsKeyTile
    call IsWallTile
    ret z

    ld a, b
    add a, $07
    ld b, a
    call GetTileByPixel
    ld a, [hl]
    call IsKeyTile
    call IsWallTile
    ret z

    ; Do move down
    ld b, 1
    ld c, 0
    jp MovePlayer






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
    ld de, $9800
    add hl, de
    ret

; Check if the tile is a wall
; @param a: tile ID
; @return z: set if a is a wall.
IsWallTile:
    cp a, TILE_WALL_HORIZONTAL
    ret z
    cp a, TILE_WALL_VERTICAL
    ret z
    cp a, TILE_WALL_TOP_LEFT_CORNER
    ret z
    cp a, TILE_WALL_BOT_LEFT_CORNER
    ret z
    cp a, TILE_WALL_BOT_RIGHT_CORNER
    ret z
    cp a, TILE_WALL_TOP_RIGHT_CORNER
    ret z
    cp a, TILE_WALL_CROSS_JUNCTION
    ret z
    cp a, TILE_WALL_B_L_R_JUNCTION
    ret z
    cp a, TILE_WALL_T_L_R_JUNCTION
    ret z
    cp a, TILE_WALL_T_B_R_JUNCTION
    ret z
    cp a, TILE_WALL_T_B_L_JUNCTION
    ret z
    cp a, TILE_WALL_LEFT_END
    ret z
    cp a, TILE_WALL_BOTTOM_END
    ret z
    cp a, TILE_WALL_RIGHT_END
    ret z
    cp a, TILE_WALL_TOP_END
    ret

; Check if the tile is a key
; @param a: tile ID
; @return z: set if a is a key.
IsKeyTile:
    cp a, TILE_KEY
    ret nz
UnlockDoor:
    ld a, [wCurLevelDoorAddr]
    ld h, a
    ld a, [wCurLevelDoorAddr+1]
    ld l, a
    ld [hl], TILE_DOOR_OPEN
    
    ld a, [wCurLevelKeyAddr]
    ld h, a
    ld a, [wCurLevelKeyAddr+1]
    ld l, a
    ld [hl], TILE_GROUND
    call PlayBounceSound

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


PlayerTiles: INCBIN "src/generated/sprites/Player.2bpp"
PlayerTilesEnd:

Projectile: INCBIN "src/generated/sprites/projectile.2bpp"
ProjectileEnd:

TileSet: INCBIN "src/generated/backgrounds/TinySpriteSheet.2bpp"
TileSetEnd:

