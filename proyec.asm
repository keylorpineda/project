; JUEGO EGA - MOVIMIENTO INSTANTÁNEO CON ANIMACIÓN FLUIDA
; Universidad Nacional - Proyecto II Ciclo 2025
; Modo 10h (640x350, 16 colores)
; =====================================================

.MODEL SMALL
.STACK 2048

; =====================================================
; CONSTANTES
; =====================================================
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

TILE_SIZE   EQU 16
VIEWPORT_W  EQU 20
VIEWPORT_H  EQU 12

VIDEO_SEG   EQU 0A000h
VELOCIDAD   EQU 16

; Direcciones para animación
DIR_ABAJO   EQU 0
DIR_ARRIBA  EQU 1
DIR_IZQUIERDA EQU 2
DIR_DERECHA EQU 3

; Variantes de frames
FRAME_A     EQU 0
FRAME_B     EQU 1

.DATA
; === ARCHIVOS ===
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
archivo_mountain db 'SPRITES\MOUNTAIN_1.TXT',0
archivo_hill   db 'SPRITES\HILL_1.TXT',0
archivo_bush   db 'SPRITES\BUSH_1.TXT',0
archivo_dirt   db 'SPRITES\DIRT_1.TXT',0
archivo_lava   db 'SPRITES\LAVA_1.TXT',0
archivo_bridge db 'SPRITES\BRIDGE_1.TXT',0

; Archivos de sprites del jugador (16x16)
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

; === SPRITES ===
sprite_grass1   db 256 dup(0)
sprite_grass2   db 256 dup(0)
sprite_flower   db 256 dup(0)
sprite_path     db 256 dup(0)
sprite_water    db 256 dup(0)
sprite_tree     db 256 dup(0)
sprite_sand     db 256 dup(0)
sprite_rock     db 256 dup(0)
sprite_snow     db 256 dup(0)
sprite_ice      db 256 dup(0)
sprite_mountain db 256 dup(0)
sprite_hill     db 256 dup(0)
sprite_bush     db 256 dup(0)
sprite_dirt     db 256 dup(0)
sprite_lava     db 256 dup(0)
sprite_bridge   db 256 dup(0)

; === SPRITES DEL JUGADOR (16x16 = 256 bytes cada uno) ===
jugador_up_a    db 256 dup(0)
jugador_up_b    db 256 dup(0)
jugador_down_a  db 256 dup(0)
jugador_down_b  db 256 dup(0)
jugador_izq_a   db 256 dup(0)
jugador_izq_b   db 256 dup(0)
jugador_der_a   db 256 dup(0)
jugador_der_b   db 256 dup(0)

buffer_temp db 300 dup(0)

; === JUGADOR (en píxeles) ===
jugador_px  dw 80
jugador_py  dw 80

; === ANIMACIÓN DEL JUGADOR ===
jugador_dir db DIR_ABAJO
jugador_frame db 0
frame_counter db 0           ; Contador RÁPIDO para cambiar frames (0-3)
ultima_dir_movimiento db DIR_ABAJO

; === CÁMARA (en píxeles) ===
camara_px   dw 0
camara_py   dw 0

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
sprite_pointer  dw 0

; === MENSAJES ===
msg_titulo  db 'JUEGO EGA - Movimiento Instantaneo con Animacion Fluida',13,10,'$'
msg_cargando db 'Cargando archivos...',13,10,'$'
msg_mapa    db 'Mapa: $'
msg_grass1 db 'Grass 1: $'
msg_grass2 db 'Grass 2: $'
msg_flower db 'Flower: $'
msg_path   db 'Path: $'
msg_water  db 'Water: $'
msg_tree   db 'Tree: $'
msg_sand   db 'Sand: $'
msg_rock   db 'Rock: $'
msg_snow   db 'Snow: $'
msg_ice    db 'Ice: $'
msg_mountain db 'Mountain: $'
msg_hill   db 'Hill: $'
msg_bush   db 'Bush: $'
msg_dirt   db 'Dirt: $'
msg_lava   db 'Lava: $'
msg_bridge db 'Bridge: $'
msg_anim    db 'Animaciones del jugador: $'
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
    
    ; CARGAR ARCHIVOS
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
    
    mov dx, OFFSET msg_grass1
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_grass1
    mov di, OFFSET sprite_grass1
    call cargar_sprite_16x16
    jnc grass1_ok
    jmp error_carga
grass1_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h

    mov dx, OFFSET msg_grass2
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_grass2
    mov di, OFFSET sprite_grass2
    call cargar_sprite_16x16
    jnc grass2_ok
    jmp error_carga
grass2_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h

    mov dx, OFFSET msg_flower
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_flower
    mov di, OFFSET sprite_flower
    call cargar_sprite_16x16
    jnc flower_ok
    jmp error_carga
flower_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h

    mov dx, OFFSET msg_path
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_path
    mov di, OFFSET sprite_path
    call cargar_sprite_16x16
    jnc path_ok
    jmp error_carga
path_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    mov dx, OFFSET msg_water
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_water
    mov di, OFFSET sprite_water
    call cargar_sprite_16x16
    jnc water_ok
    jmp error_carga
water_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    mov dx, OFFSET msg_tree
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_tree
    mov di, OFFSET sprite_tree
    call cargar_sprite_16x16
    jnc tree_ok
    jmp error_carga
tree_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h

    mov dx, OFFSET msg_sand
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_sand
    mov di, OFFSET sprite_sand
    call cargar_sprite_16x16
    jnc sand_ok
    jmp error_carga
sand_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h

    mov dx, OFFSET msg_rock
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_rock
    mov di, OFFSET sprite_rock
    call cargar_sprite_16x16
    jnc rock_ok
    jmp error_carga
rock_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h

    mov dx, OFFSET msg_snow
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_snow
    mov di, OFFSET sprite_snow
    call cargar_sprite_16x16
    jnc snow_ok
    jmp error_carga
snow_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h

    mov dx, OFFSET msg_ice
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_ice
    mov di, OFFSET sprite_ice
    call cargar_sprite_16x16
    jnc ice_ok
    jmp error_carga
ice_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h

    mov dx, OFFSET msg_mountain
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_mountain
    mov di, OFFSET sprite_mountain
    call cargar_sprite_16x16
    jnc mountain_ok
    jmp error_carga
mountain_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h

    mov dx, OFFSET msg_hill
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_hill
    mov di, OFFSET sprite_hill
    call cargar_sprite_16x16
    jnc hill_ok
    jmp error_carga
hill_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h

    mov dx, OFFSET msg_bush
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_bush
    mov di, OFFSET sprite_bush
    call cargar_sprite_16x16
    jnc bush_ok
    jmp error_carga
bush_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h

    mov dx, OFFSET msg_dirt
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_dirt
    mov di, OFFSET sprite_dirt
    call cargar_sprite_16x16
    jnc dirt_ok
    jmp error_carga
dirt_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h

    mov dx, OFFSET msg_lava
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_lava
    mov di, OFFSET sprite_lava
    call cargar_sprite_16x16
    jnc lava_ok
    jmp error_carga
lava_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h

    mov dx, OFFSET msg_bridge
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_bridge
    mov di, OFFSET sprite_bridge
    call cargar_sprite_16x16
    jnc bridge_ok
    jmp error_carga
bridge_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h

    ; CARGAR ANIMACIONES DEL JUGADOR
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
    
    mov dx, OFFSET msg_controles
    mov ah, 9
    int 21h
    mov ah, 0
    int 16h
    
    ; Cambiar a modo EGA
    mov ax, 10h
    int 10h
    
    ; Centrar cámara inicial
    call centrar_camara_directo
    
    ; Renderizar ambas páginas
    call renderizar_en_pagina_0
    call renderizar_en_pagina_1
    
    ; Mostrar página 0
    mov ah, 5
    mov al, 0
    int 10h

; =====================================================
; BUCLE PRINCIPAL - MOVIMIENTO INSTANTÁNEO
; =====================================================
bucle_juego:
    ; 1. ESPERAR RETRACE
    call esperar_retrace
    
    ; 2. VERIFICAR TECLAS (SIN DELAY)
    mov ah, 1
    int 16h
    jz sin_tecla
    
    ; Leer tecla
    mov ah, 0
    int 16h
    
    cmp al, 27
    je fin_juego
    
    call procesar_tecla_inmediata

sin_tecla:
    ; 3. ACTUALIZAR ANIMACIÓN (SIEMPRE, MÁS RÁPIDO)
    call actualizar_animacion_rapida
    
    ; 4. ACTUALIZAR CÁMARA
    call centrar_camara_directo
    
    ; 5. RENDERIZAR
    mov al, pagina_dibujo
    test al, 1
    jz render_p0
    
    call renderizar_en_pagina_1
    jmp SHORT cambiar_pagina
    
render_p0:
    call renderizar_en_pagina_0
    
cambiar_pagina:
    ; 6. CAMBIAR PÁGINA
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
; CARGAR ANIMACIONES DEL JUGADOR
; =====================================================
cargar_animaciones_jugador PROC
    push ax
    push bx
    push dx
    push di
    
    mov dx, OFFSET archivo_player_up_a
    mov di, OFFSET jugador_up_a
    call cargar_sprite_16x16_directo
    jnc caj_up_b
    jmp SHORT caj_error
    
caj_up_b:
    mov dx, OFFSET archivo_player_up_b
    mov di, OFFSET jugador_up_b
    call cargar_sprite_16x16_directo
    jnc caj_down_a
    jmp SHORT caj_error
    
caj_down_a:
    mov dx, OFFSET archivo_player_down_a
    mov di, OFFSET jugador_down_a
    call cargar_sprite_16x16_directo
    jnc caj_down_b
    jmp SHORT caj_error
    
caj_down_b:
    mov dx, OFFSET archivo_player_down_b
    mov di, OFFSET jugador_down_b
    call cargar_sprite_16x16_directo
    jnc caj_izq_a
    jmp SHORT caj_error
    
caj_izq_a:
    mov dx, OFFSET archivo_player_izq_a
    mov di, OFFSET jugador_izq_a
    call cargar_sprite_16x16_directo
    jnc caj_izq_b
    jmp SHORT caj_error
    
caj_izq_b:
    mov dx, OFFSET archivo_player_izq_b
    mov di, OFFSET jugador_izq_b
    call cargar_sprite_16x16_directo
    jnc caj_der_a
    jmp SHORT caj_error
    
caj_der_a:
    mov dx, OFFSET archivo_player_der_a
    mov di, OFFSET jugador_der_a
    call cargar_sprite_16x16_directo
    jnc caj_der_b
    jmp SHORT caj_error
    
caj_der_b:
    mov dx, OFFSET archivo_player_der_b
    mov di, OFFSET jugador_der_b
    call cargar_sprite_16x16_directo
    jnc caj_ok
    jmp SHORT caj_error
    
caj_ok:
    clc
    jmp SHORT caj_fin
    
caj_error:
    stc
    
caj_fin:
    pop di
    pop dx
    pop bx
    pop ax
    ret
cargar_animaciones_jugador ENDP

; =====================================================
; CARGAR SPRITE 16x16 DIRECTO
; =====================================================
cargar_sprite_16x16_directo PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push bp
    
    mov ax, 3D00h
    int 21h
    jc cs16d_error
    
    mov bx, ax
    
    call saltar_linea
    jc cs16d_error_close
    
    xor bp, bp
    
cs16d_leer:
    mov ah, 3Fh
    mov cx, 200
    push dx
    mov dx, OFFSET buffer_temp
    int 21h
    pop dx
    
    cmp ax, 0
    je cs16d_cerrar
    
    mov cx, ax
    xor si, si

cs16d_proc:
    cmp si, cx
    jae cs16d_leer

    mov al, [buffer_temp + si]
    inc si
    
    cmp al, ' '
    je cs16d_proc
    cmp al, 13
    je cs16d_proc
    cmp al, 10
    je cs16d_proc
    cmp al, 9
    je cs16d_proc
    
    cmp al, '0'
    jb cs16d_proc
    cmp al, '9'
    jbe cs16d_dec
    
    and al, 0DFh
    cmp al, 'A'
    jb cs16d_proc
    cmp al, 'F'
    ja cs16d_proc
    sub al, 'A' - 10
    jmp SHORT cs16d_guardar

cs16d_dec:
    sub al, '0'

cs16d_guardar:
    mov [di], al
    inc di
    inc bp

    cmp bp, 256
    jb cs16d_proc
    
cs16d_cerrar:
    mov ah, 3Eh
    int 21h
    clc
    jmp SHORT cs16d_fin

cs16d_error_close:
    mov ah, 3Eh
    int 21h
    
cs16d_error:
    stc
    
cs16d_fin:
    pop bp
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
cargar_sprite_16x16_directo ENDP

; =====================================================
; ACTUALIZAR ANIMACIÓN RÁPIDA
; =====================================================
actualizar_animacion_rapida PROC
    push ax
    
    ; Incrementar contador rápidamente (cada 2-3 frames)
    inc frame_counter
    mov al, frame_counter
    
    ; Cambiar frame cada 2-3 frames en lugar de 6
    cmp al, 3
    jb aar_no_cambiar
    
    ; Reset contador
    mov frame_counter, 0
    
    ; Toggle frame (0->1->0)
    xor jugador_frame, 1
    
aar_no_cambiar:
    pop ax
    ret
actualizar_animacion_rapida ENDP

; =====================================================
; OBTENER SPRITE DEL JUGADOR SEGÚN DIRECCIÓN Y FRAME
; =====================================================
obtener_sprite_jugador PROC
    push ax
    push bx
    push cx
    
    mov cl, al
    mov al, bl
    
    cmp cl, DIR_ABAJO
    jne osj_arr
    cmp al, 0
    je osj_down_a
    mov si, OFFSET jugador_down_b
    jmp SHORT osj_fin_proc
    
osj_down_a:
    mov si, OFFSET jugador_down_a
    jmp SHORT osj_fin_proc
    
osj_arr:
    cmp cl, DIR_ARRIBA
    jne osj_izq
    cmp al, 0
    je osj_up_a
    mov si, OFFSET jugador_up_b
    jmp SHORT osj_fin_proc
    
osj_up_a:
    mov si, OFFSET jugador_up_a
    jmp SHORT osj_fin_proc
    
osj_izq:
    cmp cl, DIR_IZQUIERDA
    jne osj_der
    cmp al, 0
    je osj_izq_a
    mov si, OFFSET jugador_izq_b
    jmp SHORT osj_fin_proc
    
osj_izq_a:
    mov si, OFFSET jugador_izq_a
    jmp SHORT osj_fin_proc
    
osj_der:
    cmp al, 0
    je osj_der_a
    mov si, OFFSET jugador_der_b
    jmp SHORT osj_fin_proc
    
osj_der_a:
    mov si, OFFSET jugador_der_a
    
osj_fin_proc:
    pop cx
    pop bx
    pop ax
    ret
obtener_sprite_jugador ENDP

; =====================================================
; PROCESAR TECLA INMEDIATAMENTE
; =====================================================
procesar_tecla_inmediata PROC
    push ax
    push bx
    push cx
    push dx
    
    mov bl, al
    mov bh, ah
    
    test bl, bl
    jz usar_scan_pti
    mov al, bl
    jmp verificar_tecla_pti
    
usar_scan_pti:
    mov al, bh
    
verificar_tecla_pti:
    ; ARRIBA
    cmp al, 48h
    jne pti_chk_w_min
    jmp pti_arr

pti_chk_w_min:
    cmp al, 'w'
    jne pti_chk_w_may
    jmp pti_arr

pti_chk_w_may:
    cmp al, 'W'
    jne pti_chk_down_scan
    jmp pti_arr

pti_chk_down_scan:
    cmp al, 50h
    jne pti_chk_s_min
    jmp pti_aba

pti_chk_s_min:
    cmp al, 's'
    jne pti_chk_s_may
    jmp pti_aba

pti_chk_s_may:
    cmp al, 'S'
    jne pti_chk_left_scan
    jmp pti_aba

pti_chk_left_scan:
    cmp al, 4Bh
    jne pti_chk_a_min
    jmp pti_izq

pti_chk_a_min:
    cmp al, 'a'
    jne pti_chk_a_may
    jmp pti_izq

pti_chk_a_may:
    cmp al, 'A'
    jne pti_chk_right_scan
    jmp pti_izq

pti_chk_right_scan:
    cmp al, 4Dh
    jne pti_chk_d_min
    jmp pti_der

pti_chk_d_min:
    cmp al, 'd'
    jne pti_chk_d_may
    jmp pti_der

pti_chk_d_may:
    cmp al, 'D'
    jne pti_chk_d_may_not
    jmp pti_der

pti_chk_d_may_not:
    jmp pti_fin

pti_arr:
    mov jugador_dir, DIR_ARRIBA
    mov ultima_dir_movimiento, DIR_ARRIBA

    mov ax, jugador_py
    sub ax, 16
    cmp ax, 16
    jae pti_arr_check_tile
    jmp pti_fin

pti_arr_check_tile:
    mov cx, jugador_px
    shr cx, 4
    mov dx, ax
    shr dx, 4
    call verificar_tile_transitable
    jc pti_arr_move
    jmp pti_fin

pti_arr_move:
    mov jugador_py, ax
    jmp pti_fin

pti_aba:
    mov jugador_dir, DIR_ABAJO
    mov ultima_dir_movimiento, DIR_ABAJO

    mov ax, jugador_py
    add ax, 16
    cmp ax, 784
    jbe pti_aba_check_tile
    jmp pti_fin

pti_aba_check_tile:
    mov cx, jugador_px
    shr cx, 4
    mov dx, ax
    shr dx, 4
    call verificar_tile_transitable
    jc pti_aba_move
    jmp pti_fin

pti_aba_move:
    mov jugador_py, ax
    jmp pti_fin

pti_izq:
    mov jugador_dir, DIR_IZQUIERDA
    mov ultima_dir_movimiento, DIR_IZQUIERDA

    mov ax, jugador_px
    sub ax, 16
    cmp ax, 16
    jae pti_izq_check_tile
    jmp pti_fin

pti_izq_check_tile:
    mov cx, ax
    shr cx, 4
    mov dx, jugador_py
    shr dx, 4
    call verificar_tile_transitable
    jc pti_izq_move
    jmp pti_fin

pti_izq_move:
    mov jugador_px, ax
    jmp pti_fin

pti_der:
    mov jugador_dir, DIR_DERECHA
    mov ultima_dir_movimiento, DIR_DERECHA

    mov ax, jugador_px
    add ax, 16
    cmp ax, 784
    jbe pti_der_check_tile
    jmp pti_fin

pti_der_check_tile:
    mov cx, ax
    shr cx, 4
    mov dx, jugador_py
    shr dx, 4
    call verificar_tile_transitable
    jc pti_der_move
    jmp pti_fin

pti_der_move:
    mov jugador_px, ax

pti_fin:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
procesar_tecla_inmediata ENDP

; =====================================================
; VERIFICAR SI TILE ES TRANSITABLE
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
; CENTRAR CÁMARA DIRECTO
; =====================================================
centrar_camara_directo PROC
    push ax
    
    mov ax, jugador_px
    sub ax, 160
    jge ccd_x_pos
    xor ax, ax
ccd_x_pos:
    cmp ax, 480
    jle ccd_x_ok
    mov ax, 480
ccd_x_ok:
    mov camara_px, ax
    
    mov ax, jugador_py
    sub ax, 96
    jge ccd_y_pos
    xor ax, ax
ccd_y_pos:
    cmp ax, 608
    jle ccd_y_ok
    mov ax, 608
ccd_y_ok:
    mov camara_py, ax
    
    pop ax
    ret
centrar_camara_directo ENDP

; =====================================================
; RENDERIZAR EN PÁGINA 0
; =====================================================
renderizar_en_pagina_0 PROC
    push ax
    push es
    
    mov ax, VIDEO_SEG
    mov es, ax
    
    mov ax, 0
    call dibujar_mapa_en_offset
    call dibujar_jugador_en_offset
    
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
    call dibujar_mapa_en_offset
    call dibujar_jugador_en_offset
    
    pop es
    pop ax
    ret
renderizar_en_pagina_1 ENDP

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
    
    mov temp_offset, ax
    
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
    jb dmo_fila_body
    jmp dmo_fin

dmo_fila_body:
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
    
    mov di, OFFSET sprite_grass1

    cmp al, TILE_GRASS2
    jne dmo_chk_flower
dmo_set_grass2:
    mov di, OFFSET sprite_grass2
    jmp short dmo_draw

dmo_chk_flower:
    cmp al, TILE_FLOWER
    jne dmo_chk_path
dmo_set_flower:
    mov di, OFFSET sprite_flower
    jmp short dmo_draw

dmo_chk_path:
    cmp al, TILE_PATH
    jne dmo_chk_water
dmo_set_path:
    mov di, OFFSET sprite_path
    jmp short dmo_draw

dmo_chk_water:
    cmp al, TILE_WATER
    jne dmo_chk_tree
dmo_set_water:
    mov di, OFFSET sprite_water
    jmp short dmo_draw

dmo_chk_tree:
    cmp al, TILE_TREE
    jne dmo_chk_sand
dmo_set_tree:
    mov di, OFFSET sprite_tree
    jmp short dmo_draw

dmo_chk_sand:
    cmp al, TILE_SAND
    jne dmo_chk_rock
dmo_set_sand:
    mov di, OFFSET sprite_sand
    jmp short dmo_draw

dmo_chk_rock:
    cmp al, TILE_ROCK
    jne dmo_chk_snow
dmo_set_rock:
    mov di, OFFSET sprite_rock
    jmp short dmo_draw

dmo_chk_snow:
    cmp al, TILE_SNOW
    jne dmo_chk_ice
dmo_set_snow:
    mov di, OFFSET sprite_snow
    jmp short dmo_draw

dmo_chk_ice:
    cmp al, TILE_ICE
    jne dmo_chk_mountain
dmo_set_ice:
    mov di, OFFSET sprite_ice
    jmp short dmo_draw

dmo_chk_mountain:
    cmp al, TILE_MOUNTAIN
    jne dmo_chk_hill
dmo_set_mountain:
    mov di, OFFSET sprite_mountain
    jmp short dmo_draw

dmo_chk_hill:
    cmp al, TILE_HILL
    jne dmo_chk_bush
dmo_set_hill:
    mov di, OFFSET sprite_hill
    jmp short dmo_draw

dmo_chk_bush:
    cmp al, TILE_BUSH
    jne dmo_chk_dirt
dmo_set_bush:
    mov di, OFFSET sprite_bush
    jmp short dmo_draw

dmo_chk_dirt:
    cmp al, TILE_DIRT
    jne dmo_chk_lava
dmo_set_dirt:
    mov di, OFFSET sprite_dirt
    jmp short dmo_draw

dmo_chk_lava:
    cmp al, TILE_LAVA
    jne dmo_chk_bridge
dmo_set_lava:
    mov di, OFFSET sprite_lava
    jmp short dmo_draw

dmo_chk_bridge:
    cmp al, TILE_BRIDGE
    jne dmo_draw
    mov di, OFFSET sprite_bridge

dmo_draw:
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
    
    call dibujar_sprite_16x16_en_offset
    
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

; =====================================================
; DIBUJAR JUGADOR EN OFFSET
; =====================================================
dibujar_jugador_en_offset PROC
    push ax
    push bx
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
    
    mov al, jugador_dir
    mov bl, jugador_frame
    call obtener_sprite_jugador
    
    mov di, si
    call dibujar_sprite_16x16_en_offset
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_jugador_en_offset ENDP

; =====================================================
; DIBUJAR SPRITE 16x16
; =====================================================
dibujar_sprite_16x16_en_offset PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push bp
    
    mov si, di
    mov bp, 16
    
ds16_fila:
    mov bx, cx
    push bp
    mov bp, 16
    
ds16_pixel:
    lodsb
    test al, al
    jz ds16_skip
    
    call escribir_pixel_en_offset
    
ds16_skip:
    inc cx
    dec bp
    jnz ds16_pixel
    
    mov cx, bx
    pop bp
    inc dx
    dec bp
    jnz ds16_fila
    
    pop bp
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_sprite_16x16_en_offset ENDP

; =====================================================
; ESCRIBIR PÍXEL EN OFFSET
; =====================================================
escribir_pixel_en_offset PROC
    push ax
    push bx
    push cx
    push dx
    push di
    
    mov bl, al
    
    mov ax, dx
    mov di, 80
    mul di
    add ax, temp_offset
    mov di, ax
    
    mov ax, cx
    shr ax, 3
    add di, ax
    
    and cx, 7
    mov al, 80h
    shr al, cl
    mov ah, al
    
    mov dx, 3CEh
    
    mov al, 0
    out dx, al
    inc dx
    mov al, bl
    out dx, al
    dec dx
    
    ; Enable Set/Reset
    mov al, 1
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    dec dx
    
    ; Bit Mask
    mov al, 8
    out dx, al
    inc dx
    mov al, ah
    out dx, al
    
    ; Leer para activar latch, escribir para aplicar
    mov al, es:[di]
    mov es:[di], al
    
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
escribir_pixel_en_offset ENDP

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
    jbe cm_store_digit
    jmp cm_chk_upper

cm_store_digit:
    sub al, '0'
    jmp cm_store_value

cm_chk_upper:
    cmp al, 'A'
    jb cm_chk_lower
    cmp al, 'F'
    ja cm_chk_lower
    sub al, 'A'
    add al, 10
    jmp cm_store_value

cm_chk_lower:
    cmp al, 'a'
    jb cm_proc
    cmp al, 'f'
    ja cm_proc
    sub al, 'a'
    add al, 10

cm_store_value:
    mov [di], al
    inc di
    inc bp

    cmp bp, 2500
    jb cm_proc
    
cm_cerrar:
    mov ah, 3Eh
    int 21h
    clc
    jmp SHORT cm_fin
    
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
    jbe cs16_decimal
    
    and al, 0DFh
    cmp al, 'A'
    jb cs16_proc
    cmp al, 'F'
    ja cs16_proc
    sub al, 'A' - 10
    jmp SHORT cs16_guardar

cs16_decimal:
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
    jmp SHORT cs16_fin
    
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