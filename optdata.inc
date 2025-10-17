; ============================================
; OPTDATA.INC - Datos del motor optimizado
; Universidad Nacional - Proyecto II Ciclo 2025
; ============================================
; Este archivo contiene todas las estructuras
; de datos para las optimizaciones del motor.
; NO compilar directamente, usar INCLUDE.
; ============================================

; ============================================
; OPTIMIZACION #1: LOOKUP TABLES
; ============================================

; Tabla de offsets de video (Y × 80)
; Evita multiplicación en cada cálculo de posición
video_offsets   dw 350 dup(?)

; Tabla de multiplicación por 100 (Y × 100)
; Para índices de mapa 100×100
mul100_table    dw 100 dup(?)

; Tabla de transitabilidad de tiles
; 1 = transitable, 0 = no transitable
tile_walkable   db 256 dup(1)

; ============================================
; OPTIMIZACION #2: PRE-MASCARAS
; ============================================

; Máscaras pre-calculadas para sprites del jugador (32×32)
; Cada sprite tiene 32 filas × 4 bytes = 128 bytes de máscara
jugador_up_a_mask       db 128 dup(0)
jugador_up_b_mask       db 128 dup(0)
jugador_down_a_mask     db 128 dup(0)
jugador_down_b_mask     db 128 dup(0)
jugador_izq_a_mask      db 128 dup(0)
jugador_izq_b_mask      db 128 dup(0)
jugador_der_a_mask      db 128 dup(0)
jugador_der_b_mask      db 128 dup(0)

; Máscaras pre-calculadas para tiles (16×16)
; Cada tile tiene 16 filas × 2 bytes = 32 bytes de máscara
sprite_grass1_mask      db 32 dup(0)
sprite_path_mask        db 32 dup(0)
sprite_water_mask       db 32 dup(0)
sprite_tree_mask        db 32 dup(0)
sprite_sand_mask        db 32 dup(0)
sprite_snow_mask        db 32 dup(0)
sprite_ice_mask         db 32 dup(0)
sprite_wall_mask        db 32 dup(0)
sprite_dirt_mask        db 32 dup(0)
sprite_lava_mask        db 32 dup(0)
sprite_bridge_mask      db 32 dup(0)

; ============================================
; OPTIMIZACION #3: DIRTY RECTANGLES
; ============================================

; Mapa de tiles "sucios" que necesitan redibujo
; Un byte por tile, valor = número de frame en que fue marcado
dirty_tiles     db 10000 dup(0)

; Contador de frames (se incrementa cada frame)
frame_counter   db 0

; ============================================
; FIN DE OPTDATA.INC
; ============================================