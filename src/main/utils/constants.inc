include "src/main/utils/hardware.inc"

DEF level_LEN EQU 1024

DEF OAM_PLAYER_ADDR         EQU $00         ; 1st location in OAM
DEF OAM_PLAYER_SIZE         EQU $04         ; Number of sprites of player

; TILESET Constants ID =====================
RSRESET
DEF TILE_GROUND                     RB $01

DEF TILE_WALL_HORIZONTAL            RB $01
DEF TILE_WALL_VERTICAL              RB $01

DEF TILE_WALL_TOP_LEFT_CORNER       RB $01
DEF TILE_WALL_BOT_LEFT_CORNER       RB $01
DEF TILE_WALL_BOT_RIGHT_CORNER      RB $01
DEF TILE_WALL_TOP_RIGHT_CORNER      RB $01

DEF TILE_WALL_CROSS_JUNCTION        RB $01  ; Order: Top | Bottom | Left | Right
DEF TILE_WALL_B_L_R_JUNCTION        RB $01
DEF TILE_WALL_T_L_R_JUNCTION        RB $01
DEF TILE_WALL_T_B_R_JUNCTION        RB $01
DEF TILE_WALL_T_B_L_JUNCTION        RB $01

DEF TILE_WALL_LEFT_END              RB $01
DEF TILE_WALL_BOTTOM_END            RB $01
DEF TILE_WALL_RIGHT_END             RB $01
DEF TILE_WALL_TOP_END               RB $01

DEF TILE_DOOR_CLOSE                 RB $01
DEF TILE_DOOR_OPEN                  RB $01
DEF TILE_KEY                        RB $01


; PLAYER Data  ==============================

DEF PLAYER_OAM_ADDR EQU $FE00   ; ID° 0 in OAM

RSRESET
DEF TILE_PLAYER_00      RB $01
DEF TILE_PLAYER_01      RB $01
DEF TILE_PLAYER_02      RB $01
DEF TILE_PLAYER_03      RB $01

DEF LVL1_SPAWN_X        EQU 16 
DEF LVL1_SPAWN_Y        EQU 16



DEF LVL2_DOOR_POSITION      EQU $99E3
DEF LVL2_KEY_POSITION       EQU $98CA


DEF LVL2_SPAWN_X        EQU SCRN_X / 2 + 8
DEF LVL2_SPAWN_Y        EQU SCRN_Y / 2 + 16
















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



