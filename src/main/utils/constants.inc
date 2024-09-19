include "src/main/utils/hardware.inc"

DEF PLAYER_MOVE_SPEED EQU 15

DEF level_LEN EQU 1024

; from https://rgbds.gbdev.io/docs/v0.6.1/rgbasm.5#EXPRESSIONS
; The RS group of commands is a handy way of defining structure offsets:
RSRESET
DEF metasprite_y                RB   1
DEF metasprite_x                RB   1
DEF metasprite_tile             RB   1
DEF metasprite_flag             RB   1
DEF METASPRITE_BYTES_COUNT      RB   0


RSRESET
DEF spriteTilesStart            RB _VRAM
DEF PLAYER_TILES_START          RB 4*16
DEF ENEMY_TILES_START           RB 4*16
DEF BULLET_TILES_START          RB 0


; Standard metasprite for "Pokemon" is a square 56px * 56px
; 56 = 7 sprites of 8px
; MS stands for METASPRITE 
DEF MS_STD_LEN                  EQU $07
DEF MS_STD_SIZE_SQRT            EQU $0707
DEF MS_NEXT_LINE_OFFSET             EQU $20 - MS_STD_LEN

DEF MS_ENEMY_ID_SPRITE          EQU $80
DEF MS_ENEMY_POS                EQU $9C2B

DEF MS_PLAYER_ID_SPRITE         EQU $B1
DEF MS_PLAYER_POS               EQU $9D22

DEF MS_STD_SIZE_IN_VRAM         EQU $310

; Demon data access constants
RSRESET
DEF _ID         RB 1
DEF _TYPE       RB 1
DEF _HP         RB 1
DEF _ATK        RB 1
DEF _DEF        RB 1
DEF _SPRITE     RW 1
DEF _NAME       RB 8

; Player data access constants
; Team:
RSRESET
DEF _1ST          RW 1
DEF _2ND          RW 1
DEF _3RD          RW 1

; Owned:
RSRESET
DEF _CURRENT_HP RB 1
DEF _SPECIES    RW 1

DEF _SIZE_OWNED RB 1


; HUD constants =====================
; Actions
DEF CURSOR_TILE_ID      EQU $01
DEF ACTION_1_POS        EQU $9DAE
DEF ACTION_2_POS        EQU $9DCE
DEF ACTION_3_POS        EQU $9DEE
DEF ACTION_4_POS        EQU $9E0E

; Player demon data
DEF CUR_HP_POS          EQU $9E05
DEF MAX_HP_POS          EQU $9E09



