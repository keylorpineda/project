; =====================================================
; JUEGO EGA - SCROLL SUAVE PIXEL POR PIXEL
; Universidad Nacional - Proyecto II Ciclo 2025
; Modo 10h (640x350, 16 colores) FLUIDO
; =====================================================

.MODEL SMALL
.STACK 2048

; =====================================================
; CONSTANTES
; =====================================================
TILE_GRASS  EQU 0
TILE_WALL   EQU 1
TILE_PATH   EQU 2
TILE_WATER  EQU 3
TILE_TREE   EQU 4

TILE_SIZE   EQU 16
VIEWPORT_W  EQU 20
VIEWPORT_H  EQU 12

VIDEO_SEG   EQU 0A000h
VELOCIDAD   EQU 2

.DATA
; === ARCHIVOS ===
archivo_mapa   db 'MAPA.TXT',0
archivo_grass  db 'GRASS.TXT',0
archivo_wall   db 'WALL.TXT',0
archivo_path   db 'PATH.TXT',0
archivo_water  db 'WATER.TXT',0
archivo_tree   db 'TREE.TXT',0
archivo_player db 'PLAYER.TXT',0

; === MAPA 50x50 ===
mapa_datos  db 2500 dup(0)

; === SPRITES ===
sprite_grass  db 256 dup(0)
sprite_wall   db 256 dup(0)
sprite_path   db 256 dup(0)
sprite_water  db 256 dup(0)
sprite_tree   db 256 dup(0)
sprite_player db 64 dup(0)

buffer_temp db 300 dup(0)

; === JUGADOR (en píxeles) ===
jugador_px  dw 400
jugador_py  dw 400

; === CÁMARA (en píxeles) ===
camara_px   dw 0
camara_py   dw 0

; === OBJETIVO DE CÁMARA ===
objetivo_px dw 0
objetivo_py dw 0

; === DOBLE BUFFER ===
pagina_visible db 0
pagina_dibujo  db 1

; === VIEWPORT ===
viewport_x  dw 160
viewport_y  dw 79

; === CONTROL ===
tecla_presionada db 0

; === VARIABLES AUXILIARES ===
temp_offset     dw 0
inicio_tile_x   dw 0
inicio_tile_y   dw 0
offset_px_x     dw 0
offset_px_y     dw 0

; === MENSAJES ===
msg_titulo  db 'JUEGO EGA - Scroll Suave',13,10,'$'
msg_cargando db 'Cargando archivos...',13,10,'$'
msg_mapa    db 'Mapa: $'
msg_grass   db 'Grass: $'
msg_wall    db 'Wall: $'
msg_path    db 'Path: $'
msg_water   db 'Water: $'
msg_tree    db 'Tree: $'
msg_player  db 'Player: $'
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
    
    ; MAPA
    mov dx, OFFSET msg_mapa
    mov ah, 9
    int 21h
    call cargar_mapa
    jc error_carga
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    ; GRASS
    mov dx, OFFSET msg_grass
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_grass
    mov di, OFFSET sprite_grass
    call cargar_sprite_16x16
    jc error_carga
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    ; WALL
    mov dx, OFFSET msg_wall
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_wall
    mov di, OFFSET sprite_wall
    call cargar_sprite_16x16
    jc error_carga
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    ; PATH
    mov dx, OFFSET msg_path
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_path
    mov di, OFFSET sprite_path
    call cargar_sprite_16x16
    jc error_carga
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    ; WATER
    mov dx, OFFSET msg_water
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_water
    mov di, OFFSET sprite_water
    call cargar_sprite_16x16
    jc error_carga
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    ; TREE
    mov dx, OFFSET msg_tree
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_tree
    mov di, OFFSET sprite_tree
    call cargar_sprite_16x16
    jc error_carga
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    ; PLAYER
    mov dx, OFFSET msg_player
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_player
    mov di, OFFSET sprite_player
    call cargar_sprite_8x8
    jc error_carga
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    mov dx, OFFSET msg_controles
    mov ah, 9
    int 21h
    mov ah, 0
    int 16h
    
    ; Modo EGA
    mov ax, 10h
    int 10h
    
    call actualizar_camara_suave
    call renderizar_en_pagina_0
    call renderizar_en_pagina_1
    
    mov ah, 5
    mov al, 0
    int 10h

bucle_juego:
    mov ah, 1
    int 16h
    jz no_hay_tecla
    
    mov ah, 0
    int 16h
    
    cmp al, 27
    je fin_juego
    
    mov tecla_presionada, al
    cmp ah, 0
    je procesar_movimiento
    mov tecla_presionada, ah
    jmp SHORT procesar_movimiento

no_hay_tecla:
    mov tecla_presionada, 0

procesar_movimiento:
    call mover_jugador_suave
    call actualizar_camara_suave
    
    mov al, pagina_dibujo
    test al, 1
    jz render_p0
    call renderizar_en_pagina_1
    jmp SHORT mostrar
    
render_p0:
    call renderizar_en_pagina_0
    
mostrar:
    call esperar_retrace
    
    mov ah, 5
    mov al, pagina_dibujo
    int 10h
    
    xor pagina_dibujo, 1
    xor pagina_visible, 1
    
    mov cx, 50
delay_loop:
    nop
    loop delay_loop
    
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
; MOVER JUGADOR SUAVE
; =====================================================
mover_jugador_suave PROC
    push ax
    push bx
    
    mov al, tecla_presionada
    test al, al
    jz mjs_fin
    
    cmp al, 48h
    je mjs_arr
    cmp al, 'w'
    je mjs_arr
    cmp al, 'W'
    je mjs_arr
    
    cmp al, 50h
    je mjs_aba
    cmp al, 's'
    je mjs_aba
    cmp al, 'S'
    je mjs_aba
    
    cmp al, 4Bh
    je mjs_izq
    cmp al, 'a'
    je mjs_izq
    cmp al, 'A'
    je mjs_izq
    
    cmp al, 4Dh
    je mjs_der
    cmp al, 'd'
    je mjs_der
    cmp al, 'D'
    je mjs_der
    
    jmp SHORT mjs_fin

mjs_arr:
    mov ax, jugador_py
    sub ax, VELOCIDAD
    cmp ax, 16
    jb mjs_fin
    mov jugador_py, ax
    call verificar_colision_px
    jnc mjs_fin
    add jugador_py, VELOCIDAD
    jmp SHORT mjs_fin

mjs_aba:
    mov ax, jugador_py
    add ax, VELOCIDAD
    cmp ax, 768
    ja mjs_fin
    mov jugador_py, ax
    call verificar_colision_px
    jnc mjs_fin
    sub jugador_py, VELOCIDAD
    jmp SHORT mjs_fin

mjs_izq:
    mov ax, jugador_px
    sub ax, VELOCIDAD
    cmp ax, 16
    jb mjs_fin
    mov jugador_px, ax
    call verificar_colision_px
    jnc mjs_fin
    add jugador_px, VELOCIDAD
    jmp SHORT mjs_fin

mjs_der:
    mov ax, jugador_px
    add ax, VELOCIDAD
    cmp ax, 768
    ja mjs_fin
    mov jugador_px, ax
    call verificar_colision_px
    jnc mjs_fin
    sub jugador_px, VELOCIDAD

mjs_fin:
    pop bx
    pop ax
    ret
mover_jugador_suave ENDP

; =====================================================
; VERIFICAR COLISIÓN
; =====================================================
verificar_colision_px PROC
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov ax, jugador_px
    shr ax, 4
    mov cx, ax
    
    mov ax, jugador_py
    shr ax, 4
    mov dx, ax
    
    cmp cx, 50
    jae vcp_col
    cmp dx, 50
    jae vcp_col
    
    mov ax, dx
    mov bx, 50
    mul bx
    add ax, cx
    
    cmp ax, 2500
    jae vcp_col
    
    mov si, OFFSET mapa_datos
    add si, ax
    mov al, [si]
    
    cmp al, TILE_GRASS
    je vcp_ok
    cmp al, TILE_PATH
    je vcp_ok
    
vcp_col:
    stc
    jmp SHORT vcp_fin
    
vcp_ok:
    clc
    
vcp_fin:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
verificar_colision_px ENDP

; =====================================================
; ACTUALIZAR CÁMARA SUAVE
; =====================================================
actualizar_camara_suave PROC
    push ax
    push bx
    push dx
    
    mov ax, jugador_px
    sub ax, 160
    jge acs_x_pos
    xor ax, ax
acs_x_pos:
    cmp ax, 480
    jle acs_x_ok
    mov ax, 480
acs_x_ok:
    mov objetivo_px, ax
    
    mov ax, jugador_py
    sub ax, 96
    jge acs_y_pos
    xor ax, ax
acs_y_pos:
    cmp ax, 608
    jle acs_y_ok
    mov ax, 608
acs_y_ok:
    mov objetivo_py, ax
    
    mov ax, objetivo_px
    sub ax, camara_px
    sar ax, 2
    add camara_px, ax
    
    mov ax, objetivo_py
    sub ax, camara_py
    sar ax, 2
    add camara_py, ax
    
    pop dx
    pop bx
    pop ax
    ret
actualizar_camara_suave ENDP

; =====================================================
; RENDERIZAR EN PÁGINA 0
; =====================================================
renderizar_en_pagina_0 PROC
    push ax
    push es
    
    mov ax, VIDEO_SEG
    mov es, ax
    
    mov ax, 0
    call limpiar_viewport_en_offset
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
    call limpiar_viewport_en_offset
    call dibujar_mapa_en_offset
    call dibujar_jugador_en_offset
    
    pop es
    pop ax
    ret
renderizar_en_pagina_1 ENDP

; =====================================================
; ESPERAR RETRACE
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
; LIMPIAR VIEWPORT
; =====================================================
limpiar_viewport_en_offset PROC
    push ax
    push bx
    push cx
    push dx
    push di
    push bp
    
    mov bp, ax
    
    mov dx, 3C4h
    mov ax, 0F02h
    out dx, ax
    
    mov bx, viewport_y
    mov cx, VIEWPORT_H * 16
    
lvo_loop:
    mov ax, bx
    mov di, 80
    mul di
    add ax, bp
    mov di, ax
    
    mov ax, viewport_x
    shr ax, 3
    add di, ax
    
    push cx
    mov cx, 40
    xor al, al
    rep stosb
    pop cx
    
    inc bx
    loop lvo_loop
    
    pop bp
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
limpiar_viewport_en_offset ENDP

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
    jae dmo_fin
    
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
    
    mov di, OFFSET sprite_grass
    
    cmp al, TILE_WALL
    jne dmo_check_path
    mov di, OFFSET sprite_wall
    jmp SHORT dmo_draw

dmo_check_path:
    cmp al, TILE_PATH
    jne dmo_check_water
    mov di, OFFSET sprite_path
    jmp SHORT dmo_draw

dmo_check_water:
    cmp al, TILE_WATER
    jne dmo_check_tree
    mov di, OFFSET sprite_water
    jmp SHORT dmo_draw

dmo_check_tree:
    cmp al, TILE_TREE
    jne dmo_draw
    mov di, OFFSET sprite_tree

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
    
    mov temp_offset, ax
    
    mov ax, jugador_px
    sub ax, camara_px
    add ax, viewport_x
    mov cx, ax
    
    mov ax, jugador_py
    sub ax, camara_py
    add ax, viewport_y
    mov dx, ax
    
    cmp cx, viewport_x
    jl djo_fin
    cmp dx, viewport_y
    jl djo_fin
    
    mov ax, viewport_x
    add ax, 320
    cmp cx, ax
    jg djo_fin
    
    mov ax, viewport_y
    add ax, 192
    cmp dx, ax
    jg djo_fin
    
    mov si, OFFSET sprite_player
    call dibujar_sprite_8x8_en_offset
    
djo_fin:
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
    
ds16o_fila:
    mov bx, cx
    push bp
    mov bp, 16
    
ds16o_pixel:
    lodsb
    test al, al
    jz ds16o_skip
    
    call escribir_pixel_en_offset
    
ds16o_skip:
    inc cx
    dec bp
    jnz ds16o_pixel
    
    mov cx, bx
    pop bp
    inc dx
    dec bp
    jnz ds16o_fila
    
    pop bp
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_sprite_16x16_en_offset ENDP

; =====================================================
; DIBUJAR SPRITE 8x8
; =====================================================
dibujar_sprite_8x8_en_offset PROC
    push ax
    push bx
    push cx
    push dx
    push bp
    
    mov bp, 8
    
ds8o_fila:
    mov bx, cx
    push bp
    mov bp, 8
    
ds8o_pixel:
    lodsb
    test al, al
    jz ds8o_skip
    
    call escribir_pixel_en_offset
    
ds8o_skip:
    inc cx
    dec bp
    jnz ds8o_pixel
    
    mov cx, bx
    pop bp
    inc dx
    dec bp
    jnz ds8o_fila
    
    pop bp
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_sprite_8x8_en_offset ENDP

; =====================================================
; ESCRIBIR PÍXEL
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
    
    mov al, 1
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    dec dx
    
    mov al, 8
    out dx, al
    inc dx
    mov al, ah
    out dx, al
    
    mov al, es:[di]
    stosb
    
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
    jb cm_proc
    cmp al, '9'
    ja cm_proc
    
    sub al, '0'
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
    ja cs16_proc
    
    sub al, '0'
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
; CARGAR SPRITE 8x8
; =====================================================
cargar_sprite_8x8 PROC
    push ax
    push bx
    push cx
    push si
    push bp
    
    mov ax, 3D00h
    int 21h
    jc cs8_error
    
    mov bx, ax
    call saltar_linea
    
    xor bp, bp
    
cs8_leer:
    mov ah, 3Fh
    mov cx, 100
    push dx
    mov dx, OFFSET buffer_temp
    int 21h
    pop dx
    
    cmp ax, 0
    je cs8_cerrar
    
    mov cx, ax
    xor si, si

cs8_proc:
    cmp si, cx
    jae cs8_leer

    mov al, [buffer_temp + si]
    inc si
    
    cmp al, ' '
    je cs8_proc
    cmp al, 13
    je cs8_proc
    cmp al, 10
    je cs8_proc
    cmp al, 9
    je cs8_proc
    cmp al, '0'
    jb cs8_proc
    cmp al, '9'
    ja cs8_proc
    
    sub al, '0'
    mov [di], al
    inc di
    inc bp

    cmp bp, 64
    jb cs8_proc
    
cs8_cerrar:
    mov ah, 3Eh
    int 21h
    clc
    jmp SHORT cs8_fin
    
cs8_error:
    stc
    
cs8_fin:
    pop bp
    pop si
    pop cx
    pop bx
    pop ax
    ret
cargar_sprite_8x8 ENDP

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