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

; Tabla de offsets de video (Y x 80)
; Evita multiplicacion en cada calculo de posicion
video_offsets   dw 350 dup(?)

; Tabla de multiplicacion por 100 (Y x 100)
; Para indices de mapa 100x100
mul100_table    dw 100 dup(?)

; Tabla de transitabilidad de tiles
; 1 = transitable, 0 = no transitable
tile_walkable   db 256 dup(1)

; ============================================
; OPTIMIZACION #2: PRE-MASCARAS
; ============================================

; Mascaras pre-calculadas para sprites del jugador (32x32)
; Cada sprite tiene 32 filas x 4 bytes = 128 bytes de mascara
jugador_up_a_mask       db 128 dup(0)
jugador_up_b_mask       db 128 dup(0)
jugador_down_a_mask     db 128 dup(0)
jugador_down_b_mask     db 128 dup(0)
jugador_izq_a_mask      db 128 dup(0)
jugador_izq_b_mask      db 128 dup(0)
jugador_der_a_mask      db 128 dup(0)
jugador_der_b_mask      db 128 dup(0)

; Mascaras pre-calculadas para tiles (16x16)
; Cada tile tiene 16 filas x 2 bytes = 32 bytes de mascara
sprite_grass1_mask      db 32 dup(0)
sprite_path_mask        db 32 dup(0)
sprite_water_mask       db 32 dup(0)
sprite_tree_mask        db 32 dup(0)
sprite_sand_mask        db 32 dup(0)
sprite_rock_mask        db 32 dup(0)    ; ← AGREGAR ESTO
sprite_snow_mask        db 32 dup(0)
sprite_ice_mask         db 32 dup(0)
sprite_wall_mask        db 32 dup(0)
sprite_roof_mask        db 32 dup(0)
sprite_brick_mask       db 32 dup(0)
sprite_dirt_mask        db 32 dup(0)
sprite_lava_mask        db 32 dup(0)
sprite_bridge_mask      db 32 dup(0)

sprite_cristal_mask     db 32 dup(0)
sprite_gema_mask        db 32 dup(0)
sprite_moneda_mask      db 32 dup(0)

sprite_heart_full_mask  db 32 dup(0)
sprite_heart_empty_mask db 32 dup(0)

; ============================================
; ============================================
; OPTIMIZACION #3: DIRTY RECTANGLES
; ============================================

; Mapa de tiles "sucios" que necesitan redibujo
; Un byte por tile, valor = numero de frame en que fue marcado
dirty_tiles     db 10000 dup(0)

; Contador de frames (se incrementa cada frame)
frame_counter   db 0

; ============================================
; FIN DE OPTDATA.INC
; ============================================