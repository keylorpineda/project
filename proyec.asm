; JUEGO EGA - ULTRA OPTIMIZADO (Escritura por BYTES, no píxeles)
; Universidad Nacional - Proyecto II Ciclo 2025
; Modo 10h (640x350, 16 colores)
; Optimizado para fluidez tipo Zelda NES
; =====================================================

.MODEL SMALL
.STACK 2048

TILE_GRASS1   EQU 0
TILE_GRASS2   EQU 1
TILE_FLOWER   EQU 2
TILE_PATH     EQU 3
TILE_WATER    EQU 4
TILE_TREE     EQU 5
TILE_SAND     EQU 6
TILE_ROCK     EQU 7
TILE_SNOW     EQU 8
TILE_ICE      EQU 9
TILE_MOUNTAIN EQU 10
TILE_HILL     EQU 11
TILE_BUSH     EQU 12
TILE_DIRT     EQU 13
TILE_LAVA     EQU 14
TILE_BRIDGE   EQU 15

TILE_SIZE      EQU 16
VIEWPORT_W     EQU 20
VIEWPORT_H     EQU 12
VIDEO_SEG      EQU 0A000h
VELOCIDAD      EQU 4          ; 4 píxeles = más rápido

DIR_ABAJO      EQU 0
DIR_ARRIBA     EQU 1
DIR_IZQUIERDA  EQU 2
DIR_DERECHA    EQU 3

.DATA
archivo_mapa   db 'MAPA.TXT',0
archivo_grass1 db 'SPRITES\GRASS_1.TXT',0
archivo_grass2 db 'SPRITES\GRASS_2.TXT',0
archivo_flower db 'SPRITES\FLOWER_1.TXT',0
archivo_path   db 'SPRITES\PATH_2.TXT',0
archivo_water  db 'SPRITES\WATER_2.TXT',0
archivo_tree   db 'SPRITES\TREE_1.TXT',0
archivo_sand   db 'SPRITES\SAND_1.TXT',0
archivo_rock   db 'SPRITES\ROCK_1.TXT',0
archivo_snow   db 'SPRITES\SNOW_1.TXT',0
archivo_ice    db 'SPRITES\ICE_1.TXT',0
archivo_mountain db 'SPRITES\MOUNTA_1.TXT',0
archivo_hill   db 'SPRITES\HILL_1.TXT',0
arquivo_bush   db 'SPRITES\BUSH_1.TXT',0
arquivo_dirt   db 'SPRITES\DIRT_1.TXT',0
arquivo_lava   db 'SPRITES\LAVA_1.TXT',0
arquivo_bridge db 'SPRITES\BRIDGE_1.TXT',0

archivo_player_up_a    db 'SPRITES\PLAYER\UP1.TXT',0
archivo_player_up_b    db 'SPRITES\PLAYER\UP2.TXT',0
archivo_player_down_a  db 'SPRITES\PLAYER\DOWN1.TXT',0
archivo_player_down_b  db 'SPRITES\PLAYER\DOWN2.TXT',0
archivo_player_izq_a   db 'SPRITES\PLAYER\LEFT1.TXT',0
archivo_player_izq_b   db 'SPRITES\PLAYER\LEFT2.TXT',0
archivo_player_der_a   db 'SPRITES\PLAYER\RIGHT1.TXT',0
archivo_player_der_b   db 'SPRITES\PLAYER\RIGHT2.TXT',0

; === MAPA 50x50 ===
mapa_datos  db 2500 dup(0)

; === SPRITES EN FORMATO NORMAL (temporal para carga) ===
sprite_grass1_temp   db 256 dup(0)
sprite_grass2_temp   db 256 dup(0)
sprite_flower_temp   db 256 dup(0)
sprite_path_temp     db 256 dup(0)
sprite_water_temp    db 256 dup(0)
sprite_tree_temp     db 256 dup(0)
sprite_sand_temp     db 256 dup(0)
sprite_rock_temp     db 256 dup(0)
sprite_snow_temp     db 256 dup(0)
sprite_ice_temp      db 256 dup(0)
sprite_mountain_temp db 256 dup(0)
sprite_hill_temp     db 256 dup(0)
sprite_bush_temp     db 256 dup(0)
sprite_dirt_temp     db 256 dup(0)
sprite_lava_temp     db 256 dup(0)
sprite_bridge_temp   db 256 dup(0)

; === SPRITES EN FORMATO PLANAR (4 planos x 32 bytes = 128 bytes cada uno) ===
sprite_grass1   db 128 dup(0)
sprite_grass2   db 128 dup(0)
sprite_flower   db 128 dup(0)
sprite_path     db 128 dup(0)
sprite_water    db 128 dup(0)
sprite_tree     db 128 dup(0)
sprite_sand     db 128 dup(0)
sprite_rock     db 128 dup(0)
sprite_snow     db 128 dup(0)
sprite_ice      db 128 dup(0)
sprite_mountain db 128 dup(0)
sprite_hill     db 128 dup(0)
sprite_bush     db 128 dup(0)
sprite_dirt     db 128 dup(0)
sprite_lava     db 128 dup(0)
sprite_bridge   db 128 dup(0)

; === SPRITES DEL JUGADOR (temporal) ===
jugador_up_a_temp    db 256 dup(0)
jugador_up_b_temp    db 256 dup(0)
jugador_down_a_temp  db 256 dup(0)
jugador_down_b_temp  db 256 dup(0)
jugador_izq_a_temp   db 256 dup(0)
jugador_izq_b_temp   db 256 dup(0)
jugador_der_a_temp   db 256 dup(0)
jugador_der_b_temp   db 256 dup(0)

; === SPRITES DEL JUGADOR (planar) ===
jugador_up_a    db 128 dup(0)
jugador_up_b    db 128 dup(0)
jugador_down_a  db 128 dup(0)
jugador_down_b  db 128 dup(0)
jugador_izq_a   db 128 dup(0)
jugador_izq_b   db 128 dup(0)
jugador_der_a   db 128 dup(0)
jugador_der_b   db 128 dup(0)

buffer_temp db 300 dup(0)

; === JUGADOR ===
jugador_px  dw 400
jugador_py  dw 400
jugador_dir db DIR_ABAJO
jugador_frame db 0

; === ESTADO DE MOVIMIENTO ===
moviendo db 0
pasos_dados db 0

; === CÁMARA ===
camara_px   dw 240
camara_py   dw 304

; === DOBLE BUFFER ===
pagina_visible db 0
pagina_dibujo  db 1

; === VIEWPORT ===
viewport_x  dw 160
viewport_y  dw 79

; === VARIABLES AUXILIARES ===
temp_offset     dw 0
inicio_tile_x   dw 0
inicio_tile_y   dw 0
offset_px_x     dw 0
offset_px_y     dw 0

; === MENSAJES ===
msg_titulo  db 'JUEGO EGA - Optimizado por Bytes',13,10,'$'
msg_cargando db 'Cargando archivos...',13,10,'$'
msg_mapa    db 'Mapa: $'
msg_sprites db 'Sprites terreno: $'
msg_anim    db 'Sprites jugador: $'
msg_convert db 'Convirtiendo a formato planar...$'
msg_ok      db 'OK',13,10,'$'
msg_error   db 'ERROR',13,10,'$'
msg_controles db 13,10,'WASD/Flechas = Mover, ESC = Salir',13,10
              db 'Presiona tecla...$'

.CODE
inicio:
    mov ax, @data
    mov ds, ax
    
    mov dx, OFFSET msg_titulo
    mov ah, 9
    int 21h
    
    mov dx, OFFSET msg_cargando
    mov ah, 9
    int 21h
    
    ; CARGAR MAPA
    mov dx, OFFSET msg_mapa
    mov ah, 9
    int 21h
    call cargar_mapa
    jnc cm_ok
    jmp error_carga
cm_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    ; CARGAR SPRITES
    mov dx, OFFSET msg_sprites
    mov ah, 9
    int 21h
    call cargar_sprites_terreno
    jnc st_ok
    jmp error_carga
st_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    mov dx, OFFSET msg_anim
    mov ah, 9
    int 21h
    call cargar_animaciones_jugador
    jnc anim_ok
    jmp error_carga
anim_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    ; CONVERTIR SPRITES A FORMATO PLANAR
    mov dx, OFFSET msg_convert
    mov ah, 9
    int 21h
    call convertir_todos_sprites_planar
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    mov dx, OFFSET msg_controles
    mov ah, 9
    int 21h
    mov ah, 0
    int 16h
    
    ; Cambiar a modo EGA
    mov ax, 10h
    int 10h
    
    ; Centrar cámara inicial
    call centrar_camara
    
    ; Renderizar ambas páginas
    call renderizar_en_pagina_0
    call renderizar_en_pagina_1
    
    ; Mostrar página 0
    mov ah, 5
    mov al, 0
    int 10h

; =====================================================
; BUCLE PRINCIPAL
; =====================================================
bucle_juego:
    call esperar_retrace
    call procesar_movimiento_continuo
    call actualizar_animacion
    call centrar_camara
    
    mov al, pagina_dibujo
    test al, 1
    jz render_p0
    
    call renderizar_en_pagina_1
    jmp cambiar_pagina
    
render_p0:
    call renderizar_en_pagina_0
    
cambiar_pagina:
    mov ah, 5
    mov al, pagina_dibujo
    int 10h
    
    xor pagina_dibujo, 1
    xor pagina_visible, 1
    
    jmp bucle_juego

error_carga:
    mov dx, OFFSET msg_error
    mov ah, 9
    int 21h
    mov ah, 0
    int 16h

fin_juego:
    mov ax, 3
    int 10h
    mov ax, 4C00h
    int 21h

; =====================================================
; PROCESAR MOVIMIENTO CONTINUO
; =====================================================
procesar_movimiento_continuo PROC
    push ax
    push bx
    push cx
    push dx
    
    mov ah, 1
    int 16h
    jz pmc_no_tecla_stub
    
    mov ah, 0
    int 16h
    
    cmp al, 27
    je fin_juego
    
    mov bl, al
    mov bh, ah
    
    test bl, bl
    jz pmc_usar_scan
    mov al, bl
    jmp pmc_verificar
    
pmc_usar_scan:
    mov al, bh
    
pmc_verificar:
    cmp al, 48h
    je pmc_arriba_stub
    cmp al, 'w'
    je pmc_arriba_stub
    cmp al, 'W'
    je pmc_arriba_stub
    
    cmp al, 50h
    je pmc_abajo_stub
    cmp al, 's'
    je pmc_abajo_stub
    cmp al, 'S'
    je pmc_abajo_stub
    
    cmp al, 4Bh
    je pmc_izquierda_stub
    cmp al, 'a'
    je pmc_izquierda_stub
    cmp al, 'A'
    je pmc_izquierda_stub
    
    cmp al, 4Dh
    je pmc_derecha_stub
    cmp al, 'd'
    je pmc_derecha_stub
    cmp al, 'D'
    je pmc_derecha_stub

    jmp NEAR PTR pmc_no_movimiento

pmc_no_tecla_stub:
    jmp NEAR PTR pmc_no_tecla

pmc_arriba_stub:
    jmp NEAR PTR pmc_arriba

pmc_abajo_stub:
    jmp NEAR PTR pmc_abajo

pmc_izquierda_stub:
    jmp NEAR PTR pmc_izquierda

pmc_derecha_stub:
    jmp NEAR PTR pmc_derecha

pmc_arriba:
    mov jugador_dir, DIR_ARRIBA
    mov ax, jugador_py
    sub ax, VELOCIDAD
    cmp ax, 16
    jae pmc_arriba_check_tile
    jmp NEAR PTR pmc_no_movimiento

pmc_arriba_check_tile:

    mov cx, jugador_px
    shr cx, 4
    mov dx, ax
    shr dx, 4
    call verificar_tile_transitable
    jc pmc_arriba_mover
    jmp NEAR PTR pmc_no_movimiento

pmc_arriba_mover:

    mov jugador_py, ax
    mov moviendo, 1
    jmp pmc_fin

pmc_abajo:
    mov jugador_dir, DIR_ABAJO
    mov ax, jugador_py
    add ax, VELOCIDAD
    cmp ax, 784
    jbe pmc_abajo_check_tile
    jmp NEAR PTR pmc_no_movimiento

pmc_abajo_check_tile:

    mov cx, jugador_px
    shr cx, 4
    mov dx, ax
    shr dx, 4
    call verificar_tile_transitable
    jc pmc_abajo_mover
    jmp NEAR PTR pmc_no_movimiento

pmc_abajo_mover:

    mov jugador_py, ax
    mov moviendo, 1
    jmp pmc_fin

pmc_izquierda:
    mov jugador_dir, DIR_IZQUIERDA
    mov ax, jugador_px
    sub ax, VELOCIDAD
    cmp ax, 16
    jae pmc_izquierda_check_tile
    jmp NEAR PTR pmc_no_movimiento

pmc_izquierda_check_tile:

    mov cx, ax
    shr cx, 4
    mov dx, jugador_py
    shr dx, 4
    call verificar_tile_transitable
    jc pmc_izquierda_mover
    jmp NEAR PTR pmc_no_movimiento

pmc_izquierda_mover:

    mov jugador_px, ax
    mov moviendo, 1
    jmp pmc_fin

pmc_derecha:
    mov jugador_dir, DIR_DERECHA
    mov ax, jugador_px
    add ax, VELOCIDAD
    cmp ax, 784
    jbe pmc_derecha_check_tile
    jmp NEAR PTR pmc_no_movimiento

pmc_derecha_check_tile:

    mov cx, ax
    shr cx, 4
    mov dx, jugador_py
    shr dx, 4
    call verificar_tile_transitable
    jc pmc_derecha_mover
    jmp NEAR PTR pmc_no_movimiento

pmc_derecha_mover:

    mov jugador_px, ax
    mov moviendo, 1
    jmp pmc_fin

pmc_no_movimiento:
    mov moviendo, 0
    jmp pmc_fin

pmc_no_tecla:
    mov moviendo, 0

pmc_fin:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
procesar_movimiento_continuo ENDP

; =====================================================
; ACTUALIZAR ANIMACIÓN
; =====================================================
actualizar_animacion PROC
    push ax
    
    cmp moviendo, 0
    je aa_fin
    
    inc pasos_dados
    mov al, pasos_dados
    
    cmp al, 4
    jb aa_fin
    
    mov pasos_dados, 0
    xor jugador_frame, 1
    
aa_fin:
    pop ax
    ret
actualizar_animacion ENDP

; =====================================================
; CENTRAR CÁMARA
; =====================================================
centrar_camara PROC
    push ax
    push bx
    
    mov ax, jugador_px
    sub ax, 160
    jge cc_x_pos
    xor ax, ax
cc_x_pos:
    cmp ax, 480
    jle cc_x_ok
    mov ax, 480
cc_x_ok:
    mov bx, ax
    
    mov ax, camara_px
    cmp ax, bx
    je cc_y_check
    
    jl cc_x_mover_der
    
    sub ax, VELOCIDAD
    cmp ax, bx
    jge cc_x_set
    mov ax, bx
    jmp cc_x_set
    
cc_x_mover_der:
    add ax, VELOCIDAD
    cmp ax, bx
    jle cc_x_set
    mov ax, bx
    
cc_x_set:
    mov camara_px, ax
    
cc_y_check:
    mov ax, jugador_py
    sub ax, 96
    jge cc_y_pos
    xor ax, ax
cc_y_pos:
    cmp ax, 608
    jle cc_y_ok
    mov ax, 608
cc_y_ok:
    mov bx, ax
    
    mov ax, camara_py
    cmp ax, bx
    je cc_fin
    
    jl cc_y_mover_abajo
    
    sub ax, VELOCIDAD
    cmp ax, bx
    jge cc_y_set
    mov ax, bx
    jmp cc_y_set
    
cc_y_mover_abajo:
    add ax, VELOCIDAD
    cmp ax, bx
    jle cc_y_set
    mov ax, bx
    
cc_y_set:
    mov camara_py, ax
    
cc_fin:
    pop bx
    pop ax
    ret
centrar_camara ENDP

; =====================================================
; VERIFICAR TILE TRANSITABLE
; =====================================================
verificar_tile_transitable PROC
    push ax
    push bx
    push dx
    
    cmp cx, 50
    jae vtt_no_transitable
    cmp dx, 50
    jae vtt_no_transitable
    
    mov ax, dx
    mov bx, 50
    mul bx
    add ax, cx
    mov bx, ax
    
    mov al, [mapa_datos + bx]
    
    cmp al, TILE_WATER
    je vtt_no_transitable
    cmp al, TILE_TREE
    je vtt_no_transitable
    cmp al, TILE_ROCK
    je vtt_no_transitable
    cmp al, TILE_MOUNTAIN
    je vtt_no_transitable
    cmp al, TILE_BUSH
    je vtt_no_transitable
    cmp al, TILE_LAVA
    je vtt_no_transitable

    pop dx
    pop bx
    pop ax
    stc
    ret

vtt_no_transitable:
    pop dx
    pop bx
    pop ax
    clc
    ret
verificar_tile_transitable ENDP

; =====================================================
; CONVERTIR TODOS LOS SPRITES A FORMATO PLANAR
; =====================================================
convertir_todos_sprites_planar PROC
    push si
    push di
    
    ; Terrenos
    mov si, OFFSET sprite_grass1_temp
    mov di, OFFSET sprite_grass1
    call convertir_sprite_a_planar
    
    mov si, OFFSET sprite_grass2_temp
    mov di, OFFSET sprite_grass2
    call convertir_sprite_a_planar
    
    mov si, OFFSET sprite_flower_temp
    mov di, OFFSET sprite_flower
    call convertir_sprite_a_planar
    
    mov si, OFFSET sprite_path_temp
    mov di, OFFSET sprite_path
    call convertir_sprite_a_planar
    
    mov si, OFFSET sprite_water_temp
    mov di, OFFSET sprite_water
    call convertir_sprite_a_planar
    
    mov si, OFFSET sprite_tree_temp
    mov di, OFFSET sprite_tree
    call convertir_sprite_a_planar
    
    mov si, OFFSET sprite_sand_temp
    mov di, OFFSET sprite_sand
    call convertir_sprite_a_planar
    
    mov si, OFFSET sprite_rock_temp
    mov di, OFFSET sprite_rock
    call convertir_sprite_a_planar
    
    mov si, OFFSET sprite_snow_temp
    mov di, OFFSET sprite_snow
    call convertir_sprite_a_planar
    
    mov si, OFFSET sprite_ice_temp
    mov di, OFFSET sprite_ice
    call convertir_sprite_a_planar
    
    mov si, OFFSET sprite_mountain_temp
    mov di, OFFSET sprite_mountain
    call convertir_sprite_a_planar
    
    mov si, OFFSET sprite_hill_temp
    mov di, OFFSET sprite_hill
    call convertir_sprite_a_planar
    
    mov si, OFFSET sprite_bush_temp
    mov di, OFFSET sprite_bush
    call convertir_sprite_a_planar
    
    mov si, OFFSET sprite_dirt_temp
    mov di, OFFSET sprite_dirt
    call convertir_sprite_a_planar
    
    mov si, OFFSET sprite_lava_temp
    mov di, OFFSET sprite_lava
    call convertir_sprite_a_planar
    
    mov si, OFFSET sprite_bridge_temp
    mov di, OFFSET sprite_bridge
    call convertir_sprite_a_planar
    
    ; Jugador
    mov si, OFFSET jugador_up_a_temp
    mov di, OFFSET jugador_up_a
    call convertir_sprite_a_planar
    
    mov si, OFFSET jugador_up_b_temp
    mov di, OFFSET jugador_up_b
    call convertir_sprite_a_planar
    
    mov si, OFFSET jugador_down_a_temp
    mov di, OFFSET jugador_down_a
    call convertir_sprite_a_planar
    
    mov si, OFFSET jugador_down_b_temp
    mov di, OFFSET jugador_down_b
    call convertir_sprite_a_planar
    
    mov si, OFFSET jugador_izq_a_temp
    mov di, OFFSET jugador_izq_a
    call convertir_sprite_a_planar
    
    mov si, OFFSET jugador_izq_b_temp
    mov di, OFFSET jugador_izq_b
    call convertir_sprite_a_planar
    
    mov si, OFFSET jugador_der_a_temp
    mov di, OFFSET jugador_der_a
    call convertir_sprite_a_planar
    
    mov si, OFFSET jugador_der_b_temp
    mov di, OFFSET jugador_der_b
    call convertir_sprite_a_planar
    
    pop di
    pop si
    ret
convertir_todos_sprites_planar ENDP

; =====================================================
; CONVERTIR SPRITE A FORMATO PLANAR
; SI = sprite origen (256 bytes), DI = sprite destino (128 bytes)
; =====================================================
convertir_sprite_a_planar PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    mov bp, 16          ; 16 filas
    
csp_fila:
    ; === BYTE IZQUIERDO (primeros 8 píxeles) ===
    xor bx, bx          ; BL=plano0, BH=plano1
    xor dx, dx          ; DL=plano2, DH=plano3
    mov cx, 8           ; 8 píxeles
    
csp_byte_izq:
    lodsb               ; Leer píxel en AL
    
    ; Extraer bit 0 → plano 0
    test al, 1
    pushf
    shl bl, 1
    popf
    jz csp_izq_bit1
    or bl, 1
    
csp_izq_bit1:
    ; Extraer bit 1 → plano 1
    test al, 2
    pushf
    shl bh, 1
    popf
    jz csp_izq_bit2
    or bh, 1
    
csp_izq_bit2:
    ; Extraer bit 2 → plano 2
    test al, 4
    pushf
    shl dl, 1
    popf
    jz csp_izq_bit3
    or dl, 1
    
csp_izq_bit3:
    ; Extraer bit 3 → plano 3
    test al, 8
    pushf
    shl dh, 1
    popf
    jz csp_izq_next
    or dh, 1
    
csp_izq_next:
    loop csp_byte_izq
    
    ; Guardar byte izquierdo
    mov [di], bl
    mov [di+32], bh
    mov [di+64], dl
    mov [di+96], dh
    inc di
    
    ; === BYTE DERECHO (siguientes 8 píxeles) ===
    xor bx, bx
    xor dx, dx
    mov cx, 8
    
csp_byte_der:
    lodsb
    
    ; Extraer bit 0 → plano 0
    test al, 1
    pushf
    shl bl, 1
    popf
    jz csp_der_bit1
    or bl, 1
    
csp_der_bit1:
    ; Extraer bit 1 → plano 1
    test al, 2
    pushf
    shl bh, 1
    popf
    jz csp_der_bit2
    or bh, 1
    
csp_der_bit2:
    ; Extraer bit 2 → plano 2
    test al, 4
    pushf
    shl dl, 1
    popf
    jz csp_der_bit3
    or dl, 1
    
csp_der_bit3:
    ; Extraer bit 3 → plano 3
    test al, 8
    pushf
    shl dh, 1
    popf
    jz csp_der_next
    or dh, 1
    
csp_der_next:
    loop csp_byte_der
    
    ; Guardar byte derecho
    mov [di], bl
    mov [di+32], bh
    mov [di+64], dl
    mov [di+96], dh
    inc di
    
    dec bp
    jnz csp_fila
    
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
convertir_sprite_a_planar ENDP

; =====================================================
; CARGAR SPRITES DE TERRENO
; =====================================================
cargar_sprites_terreno PROC
    push dx
    push di
    
    mov dx, OFFSET archivo_grass1
    mov di, OFFSET sprite_grass1_temp
    call cargar_sprite_16x16
    jnc cst_grass1_ok
    jmp NEAR PTR cst_error

cst_grass1_ok:
    mov dx, OFFSET archivo_grass2
    mov di, OFFSET sprite_grass2_temp
    call cargar_sprite_16x16
    jnc cst_grass2_ok
    jmp NEAR PTR cst_error

cst_grass2_ok:
    mov dx, OFFSET archivo_flower
    mov di, OFFSET sprite_flower_temp
    call cargar_sprite_16x16
    jnc cst_flower_ok
    jmp NEAR PTR cst_error

cst_flower_ok:
    mov dx, OFFSET archivo_path
    mov di, OFFSET sprite_path_temp
    call cargar_sprite_16x16
    jnc cst_path_ok
    jmp NEAR PTR cst_error

cst_path_ok:
    mov dx, OFFSET archivo_water
    mov di, OFFSET sprite_water_temp
    call cargar_sprite_16x16
    jnc cst_water_ok
    jmp NEAR PTR cst_error

cst_water_ok:
    mov dx, OFFSET archivo_tree
    mov di, OFFSET sprite_tree_temp
    call cargar_sprite_16x16
    jnc cst_tree_ok
    jmp NEAR PTR cst_error

cst_tree_ok:
    mov dx, OFFSET archivo_sand
    mov di, OFFSET sprite_sand_temp
    call cargar_sprite_16x16
    jnc cst_sand_ok
    jmp NEAR PTR cst_error

cst_sand_ok:
    mov dx, OFFSET archivo_rock
    mov di, OFFSET sprite_rock_temp
    call cargar_sprite_16x16
    jnc cst_rock_ok
    jmp NEAR PTR cst_error

cst_rock_ok:
    mov dx, OFFSET archivo_snow
    mov di, OFFSET sprite_snow_temp
    call cargar_sprite_16x16
    jnc cst_snow_ok
    jmp NEAR PTR cst_error

cst_snow_ok:
    mov dx, OFFSET archivo_ice
    mov di, OFFSET sprite_ice_temp
    call cargar_sprite_16x16
    jnc cst_ice_ok
    jmp NEAR PTR cst_error

cst_ice_ok:
    mov dx, OFFSET archivo_mountain
    mov di, OFFSET sprite_mountain_temp
    call cargar_sprite_16x16
    jnc cst_mountain_ok
    jmp NEAR PTR cst_error

cst_mountain_ok:
    mov dx, OFFSET archivo_hill
    mov di, OFFSET sprite_hill_temp
    call cargar_sprite_16x16
    jnc cst_hill_ok
    jmp NEAR PTR cst_error

cst_hill_ok:
    mov dx, OFFSET arquivo_bush
    mov di, OFFSET sprite_bush_temp
    call cargar_sprite_16x16
    jnc cst_bush_ok
    jmp NEAR PTR cst_error

cst_bush_ok:
    mov dx, OFFSET arquivo_dirt
    mov di, OFFSET sprite_dirt_temp
    call cargar_sprite_16x16
    jnc cst_dirt_ok
    jmp NEAR PTR cst_error

cst_dirt_ok:
    mov dx, OFFSET arquivo_lava
    mov di, OFFSET sprite_lava_temp
    call cargar_sprite_16x16
    jnc cst_lava_ok
    jmp NEAR PTR cst_error

cst_lava_ok:
    mov dx, OFFSET arquivo_bridge
    mov di, OFFSET sprite_bridge_temp
    call cargar_sprite_16x16
    jnc cst_bridge_ok
    jmp NEAR PTR cst_error

cst_bridge_ok:
    clc
    jmp cst_fin

cst_error:
    stc

cst_fin:
    pop di
    pop dx
    ret
cargar_sprites_terreno ENDP

; =====================================================
; CARGAR ANIMACIONES JUGADOR
; =====================================================
cargar_animaciones_jugador PROC
    push dx
    push di
    
    mov dx, OFFSET archivo_player_up_a
    mov di, OFFSET jugador_up_a_temp
    call cargar_sprite_16x16
    jc caj_error
    
    mov dx, OFFSET archivo_player_up_b
    mov di, OFFSET jugador_up_b_temp
    call cargar_sprite_16x16
    jc caj_error
    
    mov dx, OFFSET archivo_player_down_a
    mov di, OFFSET jugador_down_a_temp
    call cargar_sprite_16x16
    jc caj_error
    
    mov dx, OFFSET archivo_player_down_b
    mov di, OFFSET jugador_down_b_temp
    call cargar_sprite_16x16
    jc caj_error
    
    mov dx, OFFSET archivo_player_izq_a
    mov di, OFFSET jugador_izq_a_temp
    call cargar_sprite_16x16
    jc caj_error
    
    mov dx, OFFSET archivo_player_izq_b
    mov di, OFFSET jugador_izq_b_temp
    call cargar_sprite_16x16
    jc caj_error
    
    mov dx, OFFSET archivo_player_der_a
    mov di, OFFSET jugador_der_a_temp
    call cargar_sprite_16x16
    jc caj_error
    
    mov dx, OFFSET archivo_player_der_b
    mov di, OFFSET jugador_der_b_temp
    call cargar_sprite_16x16
    jc caj_error
    
    clc
    jmp caj_fin
    
caj_error:
    stc
    
caj_fin:
    pop di
    pop dx
    ret
cargar_animaciones_jugador ENDP

; =====================================================
; OBTENER SPRITE DEL JUGADOR
; =====================================================
obtener_sprite_jugador PROC
    push ax
    push bx
    
    mov al, jugador_dir
    mov bl, jugador_frame
    
    cmp al, DIR_ABAJO
    jne osj_arr
    test bl, bl
    jz osj_down_a
    mov si, OFFSET jugador_down_b
    jmp osj_fin
osj_down_a:
    mov si, OFFSET jugador_down_a
    jmp osj_fin
    
osj_arr:
    cmp al, DIR_ARRIBA
    jne osj_izq
    test bl, bl
    jz osj_up_a
    mov si, OFFSET jugador_up_b
    jmp osj_fin
osj_up_a:
    mov si, OFFSET jugador_up_a
    jmp osj_fin
    
osj_izq:
    cmp al, DIR_IZQUIERDA
    jne osj_der
    test bl, bl
    jz osj_izq_a
    mov si, OFFSET jugador_izq_b
    jmp osj_fin
osj_izq_a:
    mov si, OFFSET jugador_izq_a
    jmp osj_fin
    
osj_der:
    test bl, bl
    jz osj_der_a
    mov si, OFFSET jugador_der_b
    jmp osj_fin
osj_der_a:
    mov si, OFFSET jugador_der_a
    
osj_fin:
    pop bx
    pop ax
    ret
obtener_sprite_jugador ENDP

; =====================================================
; RENDERIZAR EN PÁGINA 0
; =====================================================
renderizar_en_pagina_0 PROC
    push ax
    push es
    
    mov ax, VIDEO_SEG
    mov es, ax
    mov ax, 0
    call dibujar_todo_en_offset
    
    pop es
    pop ax
    ret
renderizar_en_pagina_0 ENDP

; =====================================================
; RENDERIZAR EN PÁGINA 1
; =====================================================
renderizar_en_pagina_1 PROC
    push ax
    push es
    
    mov ax, VIDEO_SEG
    mov es, ax
    mov ax, 8000h
    call dibujar_todo_en_offset
    
    pop es
    pop ax
    ret
renderizar_en_pagina_1 ENDP

; =====================================================
; DIBUJAR TODO EN OFFSET
; =====================================================
dibujar_todo_en_offset PROC
    push ax
    
    mov temp_offset, ax
    call dibujar_mapa_en_offset
    call dibujar_jugador_en_offset
    
    pop ax
    ret
dibujar_todo_en_offset ENDP

; =====================================================
; DIBUJAR MAPA EN OFFSET
; =====================================================
dibujar_mapa_en_offset PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    mov ax, camara_px
    shr ax, 4
    mov inicio_tile_x, ax
    
    mov ax, camara_py
    shr ax, 4
    mov inicio_tile_y, ax
    
    mov ax, camara_px
    and ax, 15
    mov offset_px_x, ax
    
    mov ax, camara_py
    and ax, 15
    mov offset_px_y, ax
    
    xor bp, bp

dmo_fila:
    cmp bp, 13
    jae dmo_fin_stub
    
    xor si, si

dmo_col:
    cmp si, 21
    jae dmo_next_fila
    
    mov ax, inicio_tile_y
    add ax, bp
    cmp ax, 50
    jae dmo_next_col
    
    mov bx, inicio_tile_x
    add bx, si
    cmp bx, 50
    jae dmo_next_col
    
    push dx
    mov dx, 50
    mul dx
    add ax, bx
    pop dx
    mov bx, ax
    
    mov al, [mapa_datos + bx]
    call obtener_sprite_tile
    
    push si
    push bp
    
    mov ax, si
    shl ax, 4
    sub ax, offset_px_x
    add ax, viewport_x
    mov cx, ax
    
    mov ax, bp
    shl ax, 4
    sub ax, offset_px_y
    add ax, viewport_y
    mov dx, ax
    
    call dibujar_sprite_planar_16x16
    
    pop bp
    pop si
    
dmo_next_col:
    inc si
    jmp dmo_col
    
dmo_next_fila:
    inc bp
    jmp dmo_fila

dmo_fin_stub:
    jmp dmo_fin
    
dmo_fin:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_mapa_en_offset ENDP

; =====================================================
; OBTENER SPRITE DE TILE
; =====================================================
obtener_sprite_tile PROC
    push ax
    push bx
    
    mov bl, al
    mov di, OFFSET sprite_grass1
    
    cmp bl, TILE_GRASS2
    jne ost_2
    mov di, OFFSET sprite_grass2
    jmp ost_fin
ost_2:
    cmp bl, TILE_FLOWER
    jne ost_3
    mov di, OFFSET sprite_flower
    jmp ost_fin
ost_3:
    cmp bl, TILE_PATH
    jne ost_4
    mov di, OFFSET sprite_path
    jmp ost_fin
ost_4:
    cmp bl, TILE_WATER
    jne ost_5
    mov di, OFFSET sprite_water
    jmp ost_fin
ost_5:
    cmp bl, TILE_TREE
    jne ost_6
    mov di, OFFSET sprite_tree
    jmp ost_fin
ost_6:
    cmp bl, TILE_SAND
    jne ost_7
    mov di, OFFSET sprite_sand
    jmp ost_fin
ost_7:
    cmp bl, TILE_ROCK
    jne ost_8
    mov di, OFFSET sprite_rock
    jmp ost_fin
ost_8:
    cmp bl, TILE_SNOW
    jne ost_9
    mov di, OFFSET sprite_snow
    jmp ost_fin
ost_9:
    cmp bl, TILE_ICE
    jne ost_10
    mov di, OFFSET sprite_ice
    jmp ost_fin
ost_10:
    cmp bl, TILE_MOUNTAIN
    jne ost_11
    mov di, OFFSET sprite_mountain
    jmp ost_fin
ost_11:
    cmp bl, TILE_HILL
    jne ost_12
    mov di, OFFSET sprite_hill
    jmp ost_fin
ost_12:
    cmp bl, TILE_BUSH
    jne ost_13
    mov di, OFFSET sprite_bush
    jmp ost_fin
ost_13:
    cmp bl, TILE_DIRT
    jne ost_14
    mov di, OFFSET sprite_dirt
    jmp ost_fin
ost_14:
    cmp bl, TILE_LAVA
    jne ost_15
    mov di, OFFSET sprite_lava
    jmp ost_fin
ost_15:
    cmp bl, TILE_BRIDGE
    jne ost_fin
    mov di, OFFSET sprite_bridge

ost_fin:
    pop bx
    pop ax
    ret
obtener_sprite_tile ENDP

; =====================================================
; DIBUJAR JUGADOR EN OFFSET
; =====================================================
dibujar_jugador_en_offset PROC
    push ax
    push cx
    push dx
    push si
    
    mov ax, jugador_px
    sub ax, camara_px
    add ax, viewport_x
    mov cx, ax
    
    mov ax, jugador_py
    sub ax, camara_py
    add ax, viewport_y
    mov dx, ax
    
    call obtener_sprite_jugador
    mov di, si
    
    call dibujar_sprite_planar_16x16
    
    pop si
    pop dx
    pop cx
    pop ax
    ret
dibujar_jugador_en_offset ENDP

; =====================================================
; DIBUJAR SPRITE PLANAR 16x16
; DI = sprite planar, CX = X, DX = Y
; =====================================================
dibujar_sprite_planar_16x16 PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    ; Calcular offset base en memoria de video
    mov ax, dx
    mov bx, 80
    mul bx
    add ax, temp_offset
    mov bp, ax
    
    mov ax, cx
    shr ax, 3
    add bp, ax
    
    ; Calcular shift necesario
    and cx, 7
    
    ; Dibujar 16 filas
    mov bx, 16
    
dsp_fila:
    push bx
    push di
    push bp
    
    ; Plano 0
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    
    mov si, di
    mov di, bp
    lodsb
    stosb
    lodsb
    stosb
    
    ; Plano 1
    dec dx
    mov al, 2
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    
    mov si, OFFSET [si - 2 + 32]
    mov di, bp
    lodsb
    stosb
    lodsb
    stosb
    
    ; Plano 2
    dec dx
    mov al, 2
    out dx, al
    inc dx
    mov al, 4
    out dx, al
    
    mov si, OFFSET [si - 2 + 32]
    mov di, bp
    lodsb
    stosb
    lodsb
    stosb
    
    ; Plano 3
    dec dx
    mov al, 2
    out dx, al
    inc dx
    mov al, 8
    out dx, al
    
    mov si, OFFSET [si - 2 + 32]
    mov di, bp
    lodsb
    stosb
    lodsb
    stosb
    
    pop bp
    add bp, 80
    pop di
    add di, 2
    pop bx
    dec bx
    jnz dsp_fila
    
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_sprite_planar_16x16 ENDP

; =====================================================
; ESPERAR RETRACE VERTICAL
; =====================================================
esperar_retrace PROC
    push ax
    push dx
    
    mov dx, 3DAh
    
er_wait_end:
    in al, dx
    test al, 8
    jnz er_wait_end
    
er_wait_start:
    in al, dx
    test al, 8
    jz er_wait_start
    
    pop dx
    pop ax
    ret
esperar_retrace ENDP

; =====================================================
; CARGAR MAPA
; =====================================================
cargar_mapa PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    mov ax, 3D00h
    mov dx, OFFSET archivo_mapa
    int 21h
    jc cm_error
    
    mov bx, ax
    call saltar_linea
    
    mov di, OFFSET mapa_datos
    xor bp, bp
    
cm_leer:
    mov ah, 3Fh
    mov cx, 200
    mov dx, OFFSET buffer_temp
    int 21h
    
    cmp ax, 0
    je cm_cerrar
    
    mov cx, ax
    xor si, si

cm_proc:
    cmp si, cx
    jae cm_leer

    mov al, [buffer_temp + si]
    inc si
    
    cmp al, ' '
    je cm_proc
    cmp al, 13
    je cm_proc
    cmp al, 10
    je cm_proc
    cmp al, 9
    je cm_proc
    
    cmp al, '0'
    jb cm_chk_upper
    cmp al, '9'
    ja cm_chk_upper
    sub al, '0'
    jmp cm_store

cm_chk_upper:
    cmp al, 'A'
    jb cm_chk_lower
    cmp al, 'F'
    ja cm_chk_lower
    sub al, 'A'
    add al, 10
    jmp cm_store

cm_chk_lower:
    cmp al, 'a'
    jb cm_proc
    cmp al, 'f'
    ja cm_proc
    sub al, 'a'
    add al, 10

cm_store:
    mov [di], al
    inc di
    inc bp
    cmp bp, 2500
    jb cm_proc
    
cm_cerrar:
    mov ah, 3Eh
    int 21h
    clc
    jmp cm_fin
    
cm_error:
    stc
    
cm_fin:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
cargar_mapa ENDP

; =====================================================
; CARGAR SPRITE 16x16
; =====================================================
cargar_sprite_16x16 PROC
    push ax
    push bx
    push cx
    push si
    push bp
    
    mov ax, 3D00h
    int 21h
    jc cs16_error
    
    mov bx, ax
    call saltar_linea
    
    xor bp, bp
    
cs16_leer:
    mov ah, 3Fh
    mov cx, 200
    push dx
    mov dx, OFFSET buffer_temp
    int 21h
    pop dx
    
    cmp ax, 0
    je cs16_cerrar
    
    mov cx, ax
    xor si, si

cs16_proc:
    cmp si, cx
    jae cs16_leer

    mov al, [buffer_temp + si]
    inc si
    
    cmp al, ' '
    je cs16_proc
    cmp al, 13
    je cs16_proc
    cmp al, 10
    je cs16_proc
    cmp al, 9
    je cs16_proc
    
    cmp al, '0'
    jb cs16_proc
    cmp al, '9'
    jbe cs16_dec
    
    and al, 0DFh
    cmp al, 'A'
    jb cs16_proc
    cmp al, 'F'
    ja cs16_proc
    sub al, 'A' - 10
    jmp cs16_guardar

cs16_dec:
    sub al, '0'

cs16_guardar:
    mov [di], al
    inc di
    inc bp
    cmp bp, 256
    jb cs16_proc
    
cs16_cerrar:
    mov ah, 3Eh
    int 21h
    clc
    jmp cs16_fin
    
cs16_error:
    stc
    
cs16_fin:
    pop bp
    pop si
    pop cx
    pop bx
    pop ax
    ret
cargar_sprite_16x16 ENDP

; =====================================================
; SALTAR LÍNEA
; =====================================================
saltar_linea PROC
    push ax
    push cx
    push dx
    
sl_loop:
    mov ah, 3Fh
    mov cx, 1
    mov dx, OFFSET buffer_temp
    int 21h
    
    cmp ax, 0
    je sl_fin
    
    mov al, [buffer_temp]
    cmp al, 10
    je sl_fin
    cmp al, 13
    jne sl_loop
    
sl_fin:
    pop dx
    pop cx
    pop ax
    ret
saltar_linea ENDP

END inicio