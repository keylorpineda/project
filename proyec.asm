; JUEGO EGA - Universidad Nacional - Proyecto II Ciclo 2025
; VERSIÓN CORREGIDA - Manejo correcto de scroll suave
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
TILE_WALL     EQU 10
TILE_HILL     EQU 11
TILE_BUSH     EQU 12
TILE_DIRT     EQU 13
TILE_LAVA     EQU 14
TILE_BRIDGE   EQU 15

TILE_SIZE      EQU 16
VIDEO_SEG      EQU 0A000h
VELOCIDAD      EQU 4

DIR_ABAJO      EQU 0
DIR_ARRIBA     EQU 1
DIR_IZQUIERDA  EQU 2
DIR_DERECHA    EQU 3

.DATA
archivo_mapa   db 'MAPA.TXT',0
archivo_grass1 db 'SPRITES\GRASS_1.TXT',0
archivo_path   db 'SPRITES\PATH_2.TXT',0
archivo_water  db 'SPRITES\WATER_2.TXT',0
archivo_tree   db 'SPRITES\TREE_1.TXT',0
archivo_sand   db 'SPRITES\SAND_1.TXT',0
archivo_snow   db 'SPRITES\SNOW_1.TXT',0
archivo_ice    db 'SPRITES\ICE_1.TXT',0
archivo_wall   db 'SPRITES\WALL_1.TXT',0
arquivo_dirt   db 'SPRITES\DIRT_1.TXT',0
arquivo_lava   db 'SPRITES\LAVA_1.TXT',0
arquivo_bridge db 'SPRITES\BRIDGE_1.TXT',0

archivo_player_up_a    db 'SPRITES\PLAYER\UP1.TXT',0
arquivo_player_up_b    db 'SPRITES\PLAYER\UP2.TXT',0
archivo_player_down_a  db 'SPRITES\PLAYER\DOWN1.TXT',0
archivo_player_down_b  db 'SPRITES\PLAYER\DOWN2.TXT',0
archivo_player_izq_a   db 'SPRITES\PLAYER\LEFT1.TXT',0
arquivo_player_izq_b   db 'SPRITES\PLAYER\LEFT2.TXT',0
archivo_player_der_a   db 'SPRITES\PLAYER\RIGHT1.TXT',0
arquivo_player_der_b   db 'SPRITES\PLAYER\RIGHT2.TXT',0

mapa_datos  db 2500 dup(0)

sprite_grass1_temp   db 256 dup(0)
sprite_path_temp     db 256 dup(0)
sprite_water_temp    db 256 dup(0)
sprite_tree_temp     db 256 dup(0)
sprite_sand_temp     db 256 dup(0)
sprite_snow_temp     db 256 dup(0)
sprite_ice_temp      db 256 dup(0)
sprite_wall_temp     db 256 dup(0)
sprite_dirt_temp     db 256 dup(0)
sprite_lava_temp     db 256 dup(0)
sprite_bridge_temp   db 256 dup(0)

sprite_grass1   db 128 dup(0)
sprite_path     db 128 dup(0)
sprite_water    db 128 dup(0)
sprite_tree     db 128 dup(0)
sprite_sand     db 128 dup(0)
sprite_snow     db 128 dup(0)
sprite_ice      db 128 dup(0)
sprite_wall     db 128 dup(0)
sprite_dirt     db 128 dup(0)
sprite_lava     db 128 dup(0)
sprite_bridge   db 128 dup(0)

jugador_up_a_temp    db 1024 dup(0)
jugador_up_b_temp    db 1024 dup(0)
jugador_down_a_temp  db 1024 dup(0)
jugador_down_b_temp  db 1024 dup(0)
jugador_izq_a_temp   db 1024 dup(0)
jugador_izq_b_temp   db 1024 dup(0)
jugador_der_a_temp   db 1024 dup(0)
jugador_der_b_temp   db 1024 dup(0)

jugador_up_a    db 256 dup(0)
jugador_up_b    db 256 dup(0)
jugador_down_a  db 256 dup(0)
jugador_down_b  db 256 dup(0)
jugador_izq_a   db 256 dup(0)
jugador_izq_b   db 256 dup(0)
jugador_der_a   db 256 dup(0)
jugador_der_b   db 256 dup(0)

buffer_temp db 300 dup(0)

jugador_px  dw 400
jugador_py  dw 400
jugador_dir db DIR_ABAJO
jugador_frame db 0

moviendo db 0
pasos_dados db 0

camara_px   dw 240
camara_py   dw 304

pagina_visible db 0
pagina_dibujo  db 1

viewport_x  dw 160
viewport_y  dw 79

temp_offset     dw 0
inicio_tile_x   dw 0
inicio_tile_y   dw 0

msg_titulo  db 'JUEGO EGA - Universidad Nacional',13,10,'$'
msg_cargando db 'Cargando archivos...',13,10,'$'
msg_mapa    db 'Mapa: $'
msg_sprites db 'Sprites terreno: $'
msg_anim    db 'Sprites jugador: $'
msg_convert db 'Convirtiendo...$'
msg_ok      db 'OK',13,10,'$'
msg_error   db 'ERROR',13,10,'$'
msg_controles db 13,10,'WASD = Mover, ESC = Salir',13,10
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
    
    mov ax, 10h
    int 10h
    
    call centrar_camara
    call renderizar_en_pagina_0
    call renderizar_en_pagina_1
    
    mov ah, 5
    mov al, 0
    int 10h

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
    call esperar_retrace
    call esperar_retrace
    call esperar_retrace
    
    mov ah, 5
    mov al, pagina_dibujo
    int 10h
    
    call esperar_retrace
    call esperar_retrace
    
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

procesar_movimiento_continuo PROC
    push ax
    push bx
    push cx
    push dx
    
    mov ah, 1
    int 16h
    jnz pmc_tiene_tecla
    jmp pmc_no_tecla

pmc_tiene_tecla:
    
    mov ah, 0
    int 16h
    
    ; CRÍTICO: Verificar ESC primero
    cmp ah, 01h
    je pmc_salir
    cmp al, 27
    je pmc_salir
    
    mov bl, al
    mov bh, ah

    test bl, bl
    jz pmc_usar_scan
    mov al, bl
    jmp pmc_normalizar

pmc_usar_scan:
    mov al, bh

pmc_normalizar:
    cmp al, 'a'
    jb pmc_verificar
    cmp al, 'z'
    ja pmc_verificar
    and al, 5Fh

pmc_verificar:
    cmp al, 48h
    je pmc_arriba
    cmp al, 'W'
    je pmc_arriba

    cmp al, 50h
    je pmc_abajo
    cmp al, 'S'
    je pmc_abajo

    cmp al, 4Bh
    jne pmc_verificar_a
    jmp pmc_izquierda

pmc_verificar_a:
    cmp al, 'A'
    jne pmc_verificar_derecha_scan
    jmp pmc_izquierda

pmc_verificar_derecha_scan:
    cmp al, 4Dh
    jne pmc_verificar_derecha_letra
    jmp pmc_derecha

pmc_verificar_derecha_letra:
    cmp al, 'D'
    je pmc_derecha
    jmp pmc_no_movimiento

pmc_no_movimiento_local:
    jmp pmc_no_movimiento

pmc_salir:
    pop dx
    pop cx
    pop bx
    pop ax
    jmp fin_juego

pmc_arriba:
    mov jugador_dir, DIR_ARRIBA
    mov ax, jugador_py
    sub ax, VELOCIDAD
    cmp ax, 16
    jae pmc_arriba_dentro_limite
    jmp pmc_no_movimiento

pmc_arriba_dentro_limite:
    
    mov cx, jugador_px
    shr cx, 4
    mov dx, ax
    sub dx, 8
    shr dx, 4
    call verificar_tile_transitable
    jc pmc_arriba_transitable
    jmp pmc_no_movimiento

pmc_arriba_transitable:
    
    mov jugador_py, ax
    mov moviendo, 1
    jmp pmc_fin

pmc_abajo:
    mov jugador_dir, DIR_ABAJO
    mov ax, jugador_py
    add ax, VELOCIDAD
    cmp ax, 784
    jbe pmc_abajo_dentro_limite
    jmp pmc_no_movimiento

pmc_abajo_dentro_limite:
    
    mov cx, jugador_px
    shr cx, 4
    mov dx, ax
    shr dx, 4
    call verificar_tile_transitable
    jc pmc_abajo_transitable
    jmp pmc_no_movimiento

pmc_abajo_transitable:
    
    mov jugador_py, ax
    mov moviendo, 1
    jmp pmc_fin

pmc_izquierda:
    mov jugador_dir, DIR_IZQUIERDA
    mov ax, jugador_px
    sub ax, VELOCIDAD
    cmp ax, 16
    jae pmc_izquierda_dentro_limite
    jmp pmc_no_movimiento

pmc_izquierda_dentro_limite:
    
    mov cx, ax
    sub cx, 8
    shr cx, 4
    mov dx, jugador_py
    shr dx, 4
    call verificar_tile_transitable
    jc pmc_izquierda_transitable
    jmp pmc_no_movimiento

pmc_izquierda_transitable:
    
    mov jugador_px, ax
    mov moviendo, 1
    jmp pmc_fin

pmc_derecha:
    mov jugador_dir, DIR_DERECHA
    mov ax, jugador_px
    add ax, VELOCIDAD
    cmp ax, 784
    jbe pmc_derecha_dentro_limite
    jmp pmc_no_movimiento

pmc_derecha_dentro_limite:
    
    mov cx, ax
    add cx, 8
    shr cx, 4
    mov dx, jugador_py
    shr dx, 4
    call verificar_tile_transitable
    jc pmc_derecha_transitable
    jmp pmc_no_movimiento

pmc_derecha_transitable:
    
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

actualizar_animacion PROC
    push ax
    
    cmp moviendo, 0
    je aa_fin
    
    inc pasos_dados
    mov al, pasos_dados
    cmp al, 8
    jb aa_fin
    
    mov pasos_dados, 0
    xor jugador_frame, 1
    
aa_fin:
    pop ax
    ret
actualizar_animacion ENDP

centrar_camara PROC
    push ax
    push bx
    
    ; Alinear cámara a múltiplos de 16 para evitar desplazamiento de bits
    mov ax, jugador_px
    sub ax, 160
    jge cc_x_pos
    xor ax, ax
cc_x_pos:
    cmp ax, 480
    jle cc_x_ok
    mov ax, 480
cc_x_ok:
    ; Alinear a 16 píxeles
    and ax, 0FFF0h
    mov camara_px, ax
    
    mov ax, jugador_py
    sub ax, 96
    jge cc_y_pos
    xor ax, ax
cc_y_pos:
    cmp ax, 608
    jle cc_y_ok
    mov ax, 608
cc_y_ok:
    ; Alinear a 16 píxeles
    and ax, 0FFF0h
    mov camara_py, ax
    
    pop bx
    pop ax
    ret
centrar_camara ENDP

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
    cmp al, TILE_WALL
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

convertir_todos_sprites_planar PROC
    push si
    push di
    
    mov si, OFFSET sprite_grass1_temp
    mov di, OFFSET sprite_grass1
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

    mov si, OFFSET sprite_snow_temp
    mov di, OFFSET sprite_snow
    call convertir_sprite_a_planar
    
    mov si, OFFSET sprite_ice_temp
    mov di, OFFSET sprite_ice
    call convertir_sprite_a_planar
    
    mov si, OFFSET sprite_wall_temp
    mov di, OFFSET sprite_wall
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
    
    mov si, OFFSET jugador_up_a_temp
    mov di, OFFSET jugador_up_a
    call convertir_sprite_32x32_a_planar    ; CAMBIO AQUÍ
    
    mov si, OFFSET jugador_up_b_temp
    mov di, OFFSET jugador_up_b
    call convertir_sprite_32x32_a_planar    ; CAMBIO AQUÍ
    
    mov si, OFFSET jugador_down_a_temp
    mov di, OFFSET jugador_down_a
    call convertir_sprite_32x32_a_planar    ; CAMBIO AQUÍ
    
    mov si, OFFSET jugador_down_b_temp
    mov di, OFFSET jugador_down_b
    call convertir_sprite_32x32_a_planar    ; CAMBIO AQUÍ
    
    mov si, OFFSET jugador_izq_a_temp
    mov di, OFFSET jugador_izq_a
    call convertir_sprite_32x32_a_planar    ; CAMBIO AQUÍ
    
    mov si, OFFSET jugador_izq_b_temp
    mov di, OFFSET jugador_izq_b
    call convertir_sprite_32x32_a_planar    ; CAMBIO AQUÍ
    
    mov si, OFFSET jugador_der_a_temp
    mov di, OFFSET jugador_der_a
    call convertir_sprite_32x32_a_planar    ; CAMBIO AQUÍ
    
    mov si, OFFSET jugador_der_b_temp
    mov di, OFFSET jugador_der_b
    call convertir_sprite_32x32_a_planar    ; CAMBIO AQUÍ
    
    pop di
    pop si
    ret
convertir_todos_sprites_planar ENDP

convertir_sprite_a_planar PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    mov bp, 16
    
csp_fila:
    xor bx, bx
    xor dx, dx
    mov cx, 8
    
csp_byte_izq:
    lodsb
    
    shl dl, 1
    shl dh, 1
    shl bl, 1
    shl bh, 1
    
    test al, 01h
    jz csp_izq_b1
    or dl, 1
    
csp_izq_b1:
    test al, 02h
    jz csp_izq_b2
    or dh, 1
    
csp_izq_b2:
    test al, 04h
    jz csp_izq_b3
    or bl, 1
    
csp_izq_b3:
    test al, 08h
    jz csp_izq_next
    or bh, 1
    
csp_izq_next:
    loop csp_byte_izq
    
    mov [di], dl
    mov [di+32], dh
    mov [di+64], bl
    mov [di+96], bh
    inc di
    
    xor bx, bx
    xor dx, dx
    mov cx, 8
    
csp_byte_der:
    lodsb
    
    shl dl, 1
    shl dh, 1
    shl bl, 1
    shl bh, 1
    
    test al, 01h
    jz csp_der_b1
    or dl, 1
    
csp_der_b1:
    test al, 02h
    jz csp_der_b2
    or dh, 1
    
csp_der_b2:
    test al, 04h
    jz csp_der_b3
    or bl, 1
    
csp_der_b3:
    test al, 08h
    jz csp_der_next
    or bh, 1
    
csp_der_next:
    loop csp_byte_der
    
    mov [di], dl
    mov [di+32], dh
    mov [di+64], bl
    mov [di+96], bh
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

; AGREGAR ESTA FUNCIÓN NUEVA después de convertir_sprite_a_planar:

convertir_sprite_32x32_a_planar PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    mov bp, 32          ; 32 filas
    
csp32_fila:
    ; Procesar los primeros 16 píxeles (2 bytes en planar)
    xor bx, bx
    xor dx, dx
    mov cx, 8
    
csp32_byte1:
    lodsb
    
    shl dl, 1
    shl dh, 1
    shl bl, 1
    shl bh, 1
    
    test al, 01h
    jz csp32_1_b1
    or dl, 1
csp32_1_b1:
    test al, 02h
    jz csp32_1_b2
    or dh, 1
csp32_1_b2:
    test al, 04h
    jz csp32_1_b3
    or bl, 1
csp32_1_b3:
    test al, 08h
    jz csp32_1_next
    or bh, 1
csp32_1_next:
    loop csp32_byte1
    
    mov [di], dl
    mov [di+64], dh
    mov [di+128], bl
    mov [di+192], bh
    inc di
    
    ; Segundo byte de los primeros 16 píxeles
    xor bx, bx
    xor dx, dx
    mov cx, 8
    
csp32_byte2:
    lodsb
    
    shl dl, 1
    shl dh, 1
    shl bl, 1
    shl bh, 1
    
    test al, 01h
    jz csp32_2_b1
    or dl, 1
csp32_2_b1:
    test al, 02h
    jz csp32_2_b2
    or dh, 1
csp32_2_b2:
    test al, 04h
    jz csp32_2_b3
    or bl, 1
csp32_2_b3:
    test al, 08h
    jz csp32_2_next
    or bh, 1
csp32_2_next:
    loop csp32_byte2
    
    mov [di], dl
    mov [di+64], dh
    mov [di+128], bl
    mov [di+192], bh
    inc di
    
    ; Procesar los siguientes 16 píxeles (otros 2 bytes)
    xor bx, bx
    xor dx, dx
    mov cx, 8
    
csp32_byte3:
    lodsb
    
    shl dl, 1
    shl dh, 1
    shl bl, 1
    shl bh, 1
    
    test al, 01h
    jz csp32_3_b1
    or dl, 1
csp32_3_b1:
    test al, 02h
    jz csp32_3_b2
    or dh, 1
csp32_3_b2:
    test al, 04h
    jz csp32_3_b3
    or bl, 1
csp32_3_b3:
    test al, 08h
    jz csp32_3_next
    or bh, 1
csp32_3_next:
    loop csp32_byte3
    
    mov [di], dl
    mov [di+64], dh
    mov [di+128], bl
    mov [di+192], bh
    inc di
    
    ; Cuarto byte
    xor bx, bx
    xor dx, dx
    mov cx, 8
    
csp32_byte4:
    lodsb
    
    shl dl, 1
    shl dh, 1
    shl bl, 1
    shl bh, 1
    
    test al, 01h
    jz csp32_4_b1
    or dl, 1
csp32_4_b1:
    test al, 02h
    jz csp32_4_b2
    or dh, 1
csp32_4_b2:
    test al, 04h
    jz csp32_4_b3
    or bl, 1
csp32_4_b3:
    test al, 08h
    jz csp32_4_next
    or bh, 1
csp32_4_next:
    loop csp32_byte4
    
    mov [di], dl
    mov [di+64], dh
    mov [di+128], bl
    mov [di+192], bh
    inc di
    
    dec bp
    jz csp32_fin
    jmp csp32_fila

csp32_fin:
    
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
convertir_sprite_32x32_a_planar ENDP

cargar_sprites_terreno PROC
    push dx
    push di
    
    mov dx, OFFSET archivo_grass1
    mov di, OFFSET sprite_grass1_temp
    call cargar_sprite_16x16
    jnc cst_load_path
    jmp cst_error

cst_load_path:
    mov dx, OFFSET archivo_path
    mov di, OFFSET sprite_path_temp
    call cargar_sprite_16x16
    jnc cst_load_water
    jmp cst_error

cst_load_water:
    mov dx, OFFSET archivo_water
    mov di, OFFSET sprite_water_temp
    call cargar_sprite_16x16
    jnc cst_load_tree
    jmp cst_error

cst_load_tree:
    mov dx, OFFSET archivo_tree
    mov di, OFFSET sprite_tree_temp
    call cargar_sprite_16x16
    jnc cst_load_sand
    jmp cst_error

cst_load_sand:
    mov dx, OFFSET archivo_sand
    mov di, OFFSET sprite_sand_temp
    call cargar_sprite_16x16
    jnc cst_load_snow
    jmp cst_error

cst_load_snow:
    mov dx, OFFSET archivo_snow
    mov di, OFFSET sprite_snow_temp
    call cargar_sprite_16x16
    jnc cst_load_ice
    jmp cst_error

cst_load_ice:
    mov dx, OFFSET archivo_ice
    mov di, OFFSET sprite_ice_temp
    call cargar_sprite_16x16
    jnc cst_load_wall
    jmp cst_error

cst_load_wall:
    mov dx, OFFSET archivo_wall
    mov di, OFFSET sprite_wall_temp
    call cargar_sprite_16x16
    jnc cst_load_dirt
    jmp cst_error

cst_load_dirt:
    mov dx, OFFSET arquivo_dirt
    mov di, OFFSET sprite_dirt_temp
    call cargar_sprite_16x16
    jnc cst_load_lava
    jmp cst_error

cst_load_lava:
    mov dx, OFFSET arquivo_lava
    mov di, OFFSET sprite_lava_temp
    call cargar_sprite_16x16
    jnc cst_load_bridge
    jmp cst_error

cst_load_bridge:
    mov dx, OFFSET arquivo_bridge
    mov di, OFFSET sprite_bridge_temp
    call cargar_sprite_16x16
    jnc cst_success
    jmp cst_error

cst_success:
    clc
    jmp cst_fin

cst_error:
    stc

cst_fin:
    pop di
    pop dx
    ret
cargar_sprites_terreno ENDP

; REEMPLAZAR cargar_animaciones_jugador COMPLETO:

cargar_animaciones_jugador PROC
    push dx
    push di
    
    mov dx, OFFSET archivo_player_up_a
    mov di, OFFSET jugador_up_a_temp
    call cargar_sprite_32x32        ; CAMBIO AQUÍ
    jnc caj_load_up_b
    jmp caj_error

caj_load_up_b:
    mov dx, OFFSET arquivo_player_up_b
    mov di, OFFSET jugador_up_b_temp
    call cargar_sprite_32x32        ; CAMBIO AQUÍ
    jnc caj_load_down_a
    jmp caj_error

caj_load_down_a:
    mov dx, OFFSET archivo_player_down_a
    mov di, OFFSET jugador_down_a_temp
    call cargar_sprite_32x32        ; CAMBIO AQUÍ
    jnc caj_load_down_b
    jmp caj_error

caj_load_down_b:
    mov dx, OFFSET archivo_player_down_b
    mov di, OFFSET jugador_down_b_temp
    call cargar_sprite_32x32        ; CAMBIO AQUÍ
    jnc caj_load_left_a
    jmp caj_error

caj_load_left_a:
    mov dx, OFFSET archivo_player_izq_a
    mov di, OFFSET jugador_izq_a_temp
    call cargar_sprite_32x32        ; CAMBIO AQUÍ
    jnc caj_load_left_b
    jmp caj_error

caj_load_left_b:
    mov dx, OFFSET arquivo_player_izq_b
    mov di, OFFSET jugador_izq_b_temp
    call cargar_sprite_32x32        ; CAMBIO AQUÍ
    jnc caj_load_right_a
    jmp caj_error

caj_load_right_a:
    mov dx, OFFSET archivo_player_der_a
    mov di, OFFSET jugador_der_a_temp
    call cargar_sprite_32x32        ; CAMBIO AQUÍ
    jnc caj_load_right_b
    jmp caj_error

caj_load_right_b:
    mov dx, OFFSET arquivo_player_der_b
    mov di, OFFSET jugador_der_b_temp
    call cargar_sprite_32x32        ; CAMBIO AQUÍ
    jnc caj_success
    jmp caj_error

caj_success:
    clc
    jmp caj_fin
    
caj_error:
    stc
    
caj_fin:
    pop di
    pop dx
    ret
cargar_animaciones_jugador ENDP

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

dibujar_todo_en_offset PROC
    push ax
    
    mov temp_offset, ax
    call dibujar_mapa_en_offset
    call dibujar_jugador_en_offset
    
    pop ax
    ret
dibujar_todo_en_offset ENDP

dibujar_mapa_en_offset PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    ; Calcular tile inicial (ahora alineado a 16)
    mov ax, camara_px
    shr ax, 4
    mov inicio_tile_x, ax
    
    mov ax, camara_py
    shr ax, 4
    mov inicio_tile_y, ax
    
    xor bp, bp

dmo_fila:
    cmp bp, 13
    jb dmo_fila_loop
    jmp dmo_fin

dmo_fila_loop:
    xor si, si

dmo_col:
    cmp si, 21
    jb dmo_col_loop
    jmp dmo_next_fila

dmo_col_loop:
    mov ax, inicio_tile_y
    add ax, bp
    cmp ax, 50
    jb dmo_y_in_range
    jmp dmo_next_col

dmo_y_in_range:
    mov bx, inicio_tile_x
    add bx, si
    cmp bx, 50
    jb dmo_indices_validos
    jmp dmo_next_col

dmo_indices_validos:
    
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
    
    ; Calcular posición alineada
    mov ax, si
    shl ax, 4
    sub ax, camara_px
    add ax, viewport_x
    add ax, camara_px
    mov cx, ax
    
    mov ax, bp
    shl ax, 4
    sub ax, camara_py
    add ax, viewport_y
    add ax, camara_py
    mov dx, ax
    
    cmp cx, viewport_x
    jge dmo_check_x_max
    jmp dmo_skip_tile

dmo_check_x_max:
    cmp cx, 480
    jl dmo_check_y_min
    jmp dmo_skip_tile

dmo_check_y_min:
    cmp dx, viewport_y
    jge dmo_check_y_max
    jmp dmo_skip_tile

dmo_check_y_max:
    cmp dx, 271
    jl dmo_render_tile
    jmp dmo_skip_tile

dmo_render_tile:
    call dibujar_sprite_planar_16x16
    
dmo_skip_tile:
    pop bp
    pop si
    
dmo_next_col:
    inc si
    jmp dmo_col
    
dmo_next_fila:
    inc bp
    jmp dmo_fila
    
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

obtener_sprite_tile PROC
    push ax
    push bx
    
    mov bl, al
    mov di, OFFSET sprite_grass1

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
    cmp bl, TILE_WALL
    jne ost_11
    mov di, OFFSET sprite_wall
    jmp ost_fin
ost_11:
    cmp bl, TILE_DIRT
    jne ost_12
    mov di, OFFSET sprite_dirt
    jmp ost_fin
ost_12:
    cmp bl, TILE_LAVA
    jne ost_13
    mov di, OFFSET sprite_lava
    jmp ost_fin
ost_13:
    cmp bl, TILE_BRIDGE
    jne ost_fin
    mov di, OFFSET sprite_bridge

ost_fin:
    pop bx
    pop ax
    ret
obtener_sprite_tile ENDP

dibujar_jugador_en_offset PROC
    push ax
    push cx
    push dx
    push si
    
    mov ax, jugador_px
    sub ax, 16
    sub ax, camara_px
    add ax, viewport_x
    mov cx, ax
    
    cmp cx, -32
    jl djeo_fin
    cmp cx, 640
    jg djeo_fin
    
    mov ax, jugador_py
    sub ax, 32
    sub ax, camara_py
    add ax, viewport_y
    mov dx, ax
    
    cmp dx, -32
    jl djeo_fin
    cmp dx, 350
    jg djeo_fin
    
    call obtener_sprite_jugador
    mov di, si
    
    call dibujar_sprite_planar_32x32
    
djeo_fin:
    pop si
    pop dx
    pop cx
    pop ax
    ret
dibujar_jugador_en_offset ENDP

dibujar_sprite_planar_16x16 PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    mov ax, dx
    mov bx, 80
    mul bx
    add ax, temp_offset
    mov bp, ax
    
    mov ax, cx
    shr ax, 3
    add bp, ax
    
    mov cx, 16

dsp_loop_fila:
    push cx
    push di
    push bp
    
    mov bx, di
    
    mov al, [bx]
    mov dl, [bx+32]
    not dl
    and al, dl
    and al, [bx+64]
    and al, [bx+96]
    not al
    mov ah, al
    
    mov al, [bx+1]
    mov dl, [bx+33]
    not dl
    and al, dl
    and al, [bx+65]
    and al, [bx+97]
    not al
    
    push ax
    
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 0
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    
    pop ax
    push ax
    
    mov di, bp
    
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx]
    and al, cl
    or al, ch
    mov es:[di], al
    inc di
    
    pop ax
    push ax
    mov cl, al
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, al
    mov al, [bx+1]
    and al, cl
    or al, ch
    mov es:[di], al
    
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    
    pop ax
    push ax
    mov di, bp
    
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+32]
    and al, cl
    or al, ch
    mov es:[di], al
    inc di
    
    pop ax
    push ax
    mov cl, al
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, al
    mov al, [bx+33]
    and al, cl
    or al, ch
    mov es:[di], al
    
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 4
    out dx, al
    
    pop ax
    push ax
    mov di, bp
    
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+64]
    and al, cl
    or al, ch
    mov es:[di], al
    inc di
    
    pop ax
    push ax
    mov cl, al
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, al
    mov al, [bx+65]
    and al, cl
    or al, ch
    mov es:[di], al
    
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 3
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 8
    out dx, al
    
    pop ax
    mov di, bp
    
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+96]
    and al, cl
    or al, ch
    mov es:[di], al
    inc di
    
    mov cl, al
    not cl
    mov ch, es:[di]
    and ch, cl
    mov al, [bx+97]
    and al, cl
    or al, ch
    mov es:[di], al
    
    pop bp
    add bp, 80
    pop di
    add di, 2
    pop cx
    dec cx
    jnz dsp_loop_fila_stub
    jmp dsp_loop_fila_exit

dsp_loop_fila_stub:
    jmp dsp_loop_fila

dsp_loop_fila_exit:
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 0
    out dx, al
    
    mov dx, 3CEh
    mov al, 5
    out dx, al
    inc dx
    mov al, 0
    out dx, al
    
    mov dx, 3CEh
    mov al, 3
    out dx, al
    inc dx
    mov al, 0
    out dx, al
    
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_sprite_planar_16x16 ENDP

dibujar_sprite_planar_32x32 PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    mov ax, dx
    mov bx, 80
    mul bx
    add ax, temp_offset
    mov bp, ax
    
    mov ax, cx
    shr ax, 3
    add bp, ax
    
    mov cx, 32

dsp32_loop_fila:
    push cx
    push di
    push bp
    
    mov bx, di
    
    mov al, [bx]
    mov dl, [bx+64]
    not dl
    and al, dl
    and al, [bx+128]
    and al, [bx+192]
    not al
    push ax
    
    mov al, [bx+1]
    mov dl, [bx+65]
    not dl
    and al, dl
    and al, [bx+129]
    and al, [bx+193]
    not al
    push ax
    
    mov al, [bx+2]
    mov dl, [bx+66]
    not dl
    and al, dl
    and al, [bx+130]
    and al, [bx+194]
    not al
    push ax
    
    mov al, [bx+3]
    mov dl, [bx+67]
    not dl
    and al, dl
    and al, [bx+131]
    and al, [bx+195]
    not al
    push ax
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    
    mov di, bp
    
    pop ax
    push ax
    mov cl, al
    not cl
    mov ch, es:[di+3]
    and ch, cl
    mov cl, al
    mov al, [bx+3]
    and al, cl
    or al, ch
    mov es:[di+3], al
    
    pop ax
    pop ax
    push ax
    push ax
    mov cl, al
    not cl
    mov ch, es:[di+2]
    and ch, cl
    mov cl, al
    mov al, [bx+2]
    and al, cl
    or al, ch
    mov es:[di+2], al
    
    pop ax
    pop ax
    push ax
    push ax
    mov cl, al
    not cl
    mov ch, es:[di+1]
    and ch, cl
    mov cl, al
    mov al, [bx+1]
    and al, cl
    or al, ch
    mov es:[di+1], al
    
    pop ax
    pop ax
    push ax
    push ax
    mov cl, al
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, al
    mov al, [bx]
    and al, cl
    or al, ch
    mov es:[di], al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    
    mov di, bp
    pop ax
    pop ax
    pop ax
    push ax
    push ax
    push ax
    mov cl, al
    not cl
    mov ch, es:[di+3]
    and ch, cl
    mov cl, al
    mov al, [bx+67]
    and al, cl
    or al, ch
    mov es:[di+3], al
    
    pop ax
    pop ax
    push ax
    push ax
    mov cl, al
    not cl
    mov ch, es:[di+2]
    and ch, cl
    mov cl, al
    mov al, [bx+66]
    and al, cl
    or al, ch
    mov es:[di+2], al
    
    pop ax
    pop ax
    push ax
    push ax
    mov cl, al
    not cl
    mov ch, es:[di+1]
    and ch, cl
    mov cl, al
    mov al, [bx+65]
    and al, cl
    or al, ch
    mov es:[di+1], al
    
    pop ax
    push ax
    mov cl, al
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, al
    mov al, [bx+64]
    and al, cl
    or al, ch
    mov es:[di], al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 4
    out dx, al
    
    mov di, bp
    pop ax
    pop ax
    pop ax
    push ax
    push ax
    push ax
    mov cl, al
    not cl
    mov ch, es:[di+3]
    and ch, cl
    mov cl, al
    mov al, [bx+131]
    and al, cl
    or al, ch
    mov es:[di+3], al
    
    pop ax
    pop ax
    push ax
    push ax
    mov cl, al
    not cl
    mov ch, es:[di+2]
    and ch, cl
    mov cl, al
    mov al, [bx+130]
    and al, cl
    or al, ch
    mov es:[di+2], al
    
    pop ax
    pop ax
    push ax
    push ax
    mov cl, al
    not cl
    mov ch, es:[di+1]
    and ch, cl
    mov cl, al
    mov al, [bx+129]
    and al, cl
    or al, ch
    mov es:[di+1], al
    
    pop ax
    push ax
    mov cl, al
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, al
    mov al, [bx+128]
    and al, cl
    or al, ch
    mov es:[di], al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 8
    out dx, al
    
    mov di, bp
    pop ax
    pop ax
    pop ax
    mov cl, al
    not cl
    mov ch, es:[di+3]
    and ch, cl
    mov cl, al
    mov al, [bx+195]
    and al, cl
    or al, ch
    mov es:[di+3], al
    
    pop ax
    pop ax
    mov cl, al
    not cl
    mov ch, es:[di+2]
    and ch, cl
    mov cl, al
    mov al, [bx+194]
    and al, cl
    or al, ch
    mov es:[di+2], al
    
    pop ax
    pop ax
    mov cl, al
    not cl
    mov ch, es:[di+1]
    and ch, cl
    mov cl, al
    mov al, [bx+193]
    and al, cl
    or al, ch
    mov es:[di+1], al
    
    pop ax
    mov cl, al
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, al
    mov al, [bx+192]
    and al, cl
    or al, ch
    mov es:[di], al
    
    pop bp
    add bp, 80
    pop di
    add di, 4
    pop cx
    dec cx
    jz dsp32_fin
    jmp dsp32_loop_fila

dsp32_fin:
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 0
    out dx, al
    
    mov dx, 3CEh
    mov al, 5
    out dx, al
    inc dx
    mov al, 0
    out dx, al
    
    mov dx, 3CEh
    mov al, 3
    out dx, al
    inc dx
    mov al, 0
    out dx, al
    
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_sprite_planar_32x32 ENDP

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

cargar_sprite_32x32 PROC
    push ax
    push bx
    push cx
    push si
    push bp
    
    mov ax, 3D00h
    int 21h
    jc cs32_error
    
    mov bx, ax
    call saltar_linea
    
    xor bp, bp
    
cs32_leer:
    mov ah, 3Fh
    mov cx, 200
    push dx
    mov dx, OFFSET buffer_temp
    int 21h
    pop dx
    
    cmp ax, 0
    je cs32_cerrar
    
    mov cx, ax
    xor si, si

cs32_proc:
    cmp si, cx
    jae cs32_leer

    mov al, [buffer_temp + si]
    inc si
    
    cmp al, ' '
    je cs32_proc
    cmp al, 13
    je cs32_proc
    cmp al, 10
    je cs32_proc
    cmp al, 9
    je cs32_proc
    
    cmp al, '0'
    jb cs32_proc
    cmp al, '9'
    jbe cs32_dec
    
    and al, 0DFh
    cmp al, 'A'
    jb cs32_proc
    cmp al, 'F'
    ja cs32_proc
    sub al, 'A' - 10
    jmp cs32_guardar

cs32_dec:
    sub al, '0'

cs32_guardar:
    mov [di], al
    inc di
    inc bp
    cmp bp, 1024        ; 32x32 = 1024
    jb cs32_proc
    
cs32_cerrar:
    mov ah, 3Eh
    int 21h
    clc
    jmp cs32_fin
    
cs32_error:
    stc
    
cs32_fin:
    pop bp
    pop si
    pop cx
    pop bx
    pop ax
    ret
cargar_sprite_32x32 ENDP

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