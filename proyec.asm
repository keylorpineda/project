; =====================================================
; JUEGO EGA - SCROLL SUAVE ULTRA OPTIMIZADO
; Universidad Nacional - Proyecto II Ciclo 2025
; Modo 10h (640x350, 16 colores) - MÁXIMA FLUIDEZ
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
VELOCIDAD   EQU 4        ; AUMENTADO a 4 píxeles por tecla

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
; Posición inicial: cerca de esquina superior izquierda (tile 5,5)
jugador_px  dw 80      ; 5 tiles * 16 píxeles (más seguro)
jugador_py  dw 80      ; 5 tiles * 16 píxeles

; === CÁMARA (en píxeles) ===
camara_px   dw 0
camara_py   dw 0

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
msg_titulo  db 'JUEGO EGA - Ultra Optimizado',13,10,'$'
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
    
    ; CARGAR TODOS LOS ARCHIVOS
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
    
    mov dx, OFFSET msg_grass
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_grass
    mov di, OFFSET sprite_grass
    call cargar_sprite_16x16
    jnc grass_ok
    jmp error_carga
grass_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    mov dx, OFFSET msg_wall
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_wall
    mov di, OFFSET sprite_wall
    call cargar_sprite_16x16
    jnc wall_ok
    jmp error_carga
wall_ok:
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
    
    mov dx, OFFSET msg_player
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_player
    mov di, OFFSET sprite_player
    call cargar_sprite_8x8
    jnc player_ok
    jmp error_carga
player_ok:
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
    
    ; Inicializar cámara centrada (SIN INTERPOLACIÓN)
    call centrar_camara_directo
    
    ; Renderizar ambas páginas iniciales
    call renderizar_en_pagina_0
    call renderizar_en_pagina_1
    
    ; Mostrar página 0 inicialmente
    mov ah, 5
    mov al, 0
    int 10h

; =====================================================
; BUCLE PRINCIPAL - RESPUESTA INMEDIATA
; =====================================================
bucle_juego:
    ; Verificar tecla SIN ESPERAR
    mov ah, 1
    int 16h
    jz no_hay_tecla
    
    ; Leer y consumir tecla inmediatamente
    mov ah, 0
    int 16h
    
    cmp al, 27
    je fin_juego
    
    ; Guardar tecla correctamente
    test al, al
    jz usar_scan_code
    mov tecla_presionada, al
    jmp procesar_movimiento

usar_scan_code:
    mov tecla_presionada, ah
    jmp procesar_movimiento

no_hay_tecla:
    mov tecla_presionada, 0

procesar_movimiento:
    ; Mover jugador INMEDIATAMENTE
    call mover_jugador_suave
    
    ; Actualizar cámara
    call centrar_camara_directo
    
    ; Renderizar en la página oculta
    mov al, pagina_dibujo
    test al, 1
    jz render_p0
    call renderizar_en_pagina_1
    jmp mostrar
    
render_p0:
    call renderizar_en_pagina_0
    
mostrar:
    ; AHORA SÍ esperar retrace (después de renderizar)
    call esperar_retrace
    
    ; Cambiar página
    mov ah, 5
    mov al, pagina_dibujo
    int 10h
    
    ; Alternar páginas
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
; CENTRAR CÁMARA DIRECTO (SIN INTERPOLACIÓN)
; =====================================================
centrar_camara_directo PROC
    push ax
    
    ; Centrar en X inmediatamente
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
    
    ; Centrar en Y inmediatamente
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
; MOVER JUGADOR - VERSION SIMPLIFICADA SIN COLISIONES
; =====================================================
mover_jugador_suave PROC
    push ax
    push bx
    
    mov al, tecla_presionada
    test al, al
    jz mjs_fin

    ; Teclas ARRIBA
    cmp al, 48h        ; Flecha arriba
    je mjs_arr
    cmp al, 'w'
    je mjs_arr
    cmp al, 'W'
    je mjs_arr
    
    ; Teclas ABAJO
    cmp al, 50h        ; Flecha abajo
    je mjs_aba
    cmp al, 's'
    je mjs_aba
    cmp al, 'S'
    je mjs_aba
    
    ; Teclas IZQUIERDA
    cmp al, 4Bh        ; Flecha izquierda
    je mjs_izq
    cmp al, 'a'
    je mjs_izq
    cmp al, 'A'
    je mjs_izq
    
    ; Teclas DERECHA
    cmp al, 4Dh        ; Flecha derecha
    je mjs_der
    cmp al, 'd'
    je mjs_der
    cmp al, 'D'
    je mjs_der
    
    jmp mjs_fin

mjs_arr:
    mov ax, jugador_py
    sub ax, VELOCIDAD
    cmp ax, 16
    jb mjs_fin
    mov jugador_py, ax
    jmp mjs_fin

mjs_aba:
    mov ax, jugador_py
    add ax, VELOCIDAD
    cmp ax, 784
    ja mjs_fin
    mov jugador_py, ax
    jmp mjs_fin

mjs_izq:
    mov ax, jugador_px
    sub ax, VELOCIDAD
    cmp ax, 16
    jb mjs_fin
    mov jugador_px, ax
    jmp mjs_fin

mjs_der:
    mov ax, jugador_px
    add ax, VELOCIDAD
    cmp ax, 784
    ja mjs_fin
    mov jugador_px, ax

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
    jmp vcp_fin
    
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
; ESPERAR RETRACE - MEJORADO
; =====================================================
esperar_retrace PROC
    push ax
    push dx
    
    mov dx, 3DAh
    
    ; Esperar que termine el retrace actual
er_wait_end:
    in al, dx
    test al, 8
    jnz er_wait_end
    
    ; Esperar inicio del siguiente retrace
er_wait_start:
    in al, dx
    test al, 8
    jz er_wait_start
    
    pop dx
    pop ax
    ret
esperar_retrace ENDP

; =====================================================
; DIBUJAR MAPA EN OFFSET (SIN LIMPIAR PREVIO)
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
    
    ; Calcular tile inicial
    mov ax, camara_px
    shr ax, 4
    mov inicio_tile_x, ax
    
    mov ax, camara_py
    shr ax, 4
    mov inicio_tile_y, ax
    
    ; Calcular offset de píxel
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
    jmp dmo_draw

dmo_check_path:
    cmp al, TILE_PATH
    jne dmo_check_water
    mov di, OFFSET sprite_path
    jmp dmo_draw

dmo_check_water:
    cmp al, TILE_WATER
    jne dmo_check_tree
    mov di, OFFSET sprite_water
    jmp dmo_draw

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
    push si
    
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
    
ds16o_fila:
    mov bx, cx
    push bp
    mov bp, 16
    
ds16o_pixel:
    lodsb
    ; IMPORTANTE: Dibujar TODOS los píxeles (incluso 0=negro)
    call escribir_pixel_en_offset
    
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
; ESCRIBIR PÍXEL - OPTIMIZADO
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
    jbe cs16_decimal
    
    and al, 0DFh
    cmp al, 'A'
    jb cs16_proc
    cmp al, 'F'
    ja cs16_proc
    sub al, 'A' - 10
    jmp cs16_guardar

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
    jmp cs8_fin
    
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