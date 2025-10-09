; =====================================================
; JUEGO EGA - VRAM con DOBLE BUFFER OPTIMIZADO
; Universidad Nacional - Proyecto II Ciclo 2025
; Modo 10h (640x350, 16 colores) SIN PARPADEO
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

; === JUGADOR ===
jugador_x   dw 25
jugador_y   dw 25

; === CÁMARA ===
camara_x    dw 0
camara_y    dw 0

; === DOBLE BUFFER ===
pagina_visible db 0
pagina_dibujo  db 1

; === VIEWPORT ===
viewport_x  dw 160
viewport_y  dw 79

; === MENSAJES ===
msg_titulo  db 'JUEGO EGA - VRAM + Doble Buffer',13,10,'$'
msg_cargando db 'Cargando archivos...',13,10,'$'
msg_mapa    db 'Mapa: $'
msg_grass   db 'Grass: $'
msg_wall    db 'Wall: $'
msg_path    db 'Path: $'
msg_water   db 'Water: $'
msg_tree    db 'Tree: $'
msg_player  db 'Player: $'
msg_ok      db 'OK',13,10,'$'
msg_error   db 'ERROR - Archivo no encontrado',13,10,'$'
msg_controles db 13,10,'WASD o Flechas = Mover, ESC = Salir',13,10
              db 'Presiona tecla...$'

.CODE
inicio:
    mov ax, @data
    mov ds, ax
    
    ; Título
    mov dx, OFFSET msg_titulo
    mov ah, 9
    int 21h
    
    ; Cargar archivos
    mov dx, OFFSET msg_cargando
    mov ah, 9
    int 21h
    
    ; MAPA
    mov dx, OFFSET msg_mapa
    mov ah, 9
    int 21h
    call cargar_mapa
    jnc mapa_ok
    jmp error_carga
mapa_ok:
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
    jnc grass_ok
    jmp error_carga
grass_ok:
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
    jnc wall_ok
    jmp error_carga
wall_ok:
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
    jnc path_ok
    jmp error_carga
path_ok:
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
    jnc water_ok
    jmp error_carga
water_ok:
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
    jnc tree_ok
    jmp error_carga
tree_ok:
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
    jnc player_ok
    jmp error_carga
player_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    ; Esperar
    mov dx, OFFSET msg_controles
    mov ah, 9
    int 21h
    mov ah, 0
    int 16h
    
    ; Activar modo EGA
    mov ax, 10h
    int 10h
    
    ; Inicializar páginas
    mov pagina_visible, 0
    mov pagina_dibujo, 1
    
    ; Primera renderización
    call actualizar_camara
    call renderizar_en_pagina_0
    call renderizar_en_pagina_1
    
    ; Mostrar página 0
    mov ah, 5
    mov al, 0
    int 10h

; =====================================================
; BUCLE PRINCIPAL - OPTIMIZADO SIN PARPADEO
; =====================================================
bucle_juego:
    ; Verificar tecla SIN BLOQUEAR
    mov ah, 1
    int 16h
    jz sin_movimiento
    
    ; Leer tecla
    mov ah, 0
    int 16h
    
    ; ESC
    cmp al, 27
    je fin_juego
    
    ; Procesar movimiento
    call mover_jugador
    call actualizar_camara
    
    ; RENDERIZAR EN PÁGINA OCULTA
    mov al, pagina_dibujo
    test al, 1
    jz render_pagina_0_bg
    call renderizar_en_pagina_1
    jmp swap_pages
    
render_pagina_0_bg:
    call renderizar_en_pagina_0
    
swap_pages:
    ; ESPERAR RETRACE VERTICAL (elimina parpadeo)
    call esperar_retrace
    
    ; Cambiar página visible
    mov ah, 5
    mov al, pagina_dibujo
    int 10h
    
    ; Intercambiar páginas
    xor pagina_dibujo, 1
    xor pagina_visible, 1
    
sin_movimiento:
    ; Pequeño delay para ~60 FPS
    mov cx, 100
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
; ESPERAR RETRACE VERTICAL (Elimina parpadeo)
; =====================================================
esperar_retrace PROC
    push ax
    push dx
    
    mov dx, 3DAh    ; Puerto de estado CRT
    
er_wait_end:
    in al, dx
    test al, 8      ; Bit 3 = vertical retrace
    jnz er_wait_end ; Esperar a que termine el retrace actual
    
er_wait_start:
    in al, dx
    test al, 8
    jz er_wait_start ; Esperar a que comience el siguiente retrace
    
    pop dx
    pop ax
    ret
esperar_retrace ENDP

; =====================================================
; RENDERIZAR EN PÁGINA 0
; =====================================================
renderizar_en_pagina_0 PROC
    push ax
    push es
    
    mov ax, VIDEO_SEG
    mov es, ax
    
    mov ax, 0               ; Offset página 0
    call limpiar_viewport_en_offset
    call dibujar_mapa_en_offset
    
    mov ax, 0
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
    
    mov ax, 8000h           ; Offset página 1
    call limpiar_viewport_en_offset
    call dibujar_mapa_en_offset
    
    mov ax, 8000h
    call dibujar_jugador_en_offset
    
    pop es
    pop ax
    ret
renderizar_en_pagina_1 ENDP

; =====================================================
; LIMPIAR VIEWPORT EN OFFSET ESPECÍFICO
; AX = offset base
; =====================================================
limpiar_viewport_en_offset PROC
    push ax
    push bx
    push cx
    push dx
    push di
    push bp
    
    mov bp, ax              ; BP = offset base
    
    ; Configurar planos EGA
    mov dx, 3C4h
    mov ax, 0F02h
    out dx, ax
    
    mov bx, viewport_y
    mov cx, VIEWPORT_H * 16
    
lvo_loop:
    ; Calcular offset
    mov ax, bx
    mov di, 80
    mul di
    add ax, bp              ; Añadir offset de página
    mov di, ax
    
    mov ax, viewport_x
    shr ax, 3
    add di, ax
    
    ; Limpiar 40 bytes
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
; DIBUJAR MAPA EN OFFSET ESPECÍFICO
; AX = offset base
; =====================================================
dibujar_mapa_en_offset PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    mov [temp_offset], ax   ; Guardar offset base
    xor bp, bp
    
dmo_fila:
    cmp bp, VIEWPORT_H
    jae dmo_fin

    xor si, si

dmo_col:
    cmp si, VIEWPORT_W
    jae dmo_next_fila
    
    ; Posición en mapa
    mov ax, camara_y
    add ax, bp
    cmp ax, 50
    jae dmo_next_col
    
    mov bx, camara_x
    add bx, si
    cmp bx, 50
    jae dmo_next_col
    
    ; Índice
    push dx
    mov dx, 50
    mul dx
    add ax, bx
    pop dx
    
    ; Obtener tile
    mov bx, ax
    mov al, [mapa_datos + bx]
    
    ; Seleccionar sprite
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
    add ax, viewport_x
    mov cx, ax
    
    mov ax, bp
    shl ax, 4
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

temp_offset dw 0

dibujar_mapa_en_offset ENDP

; =====================================================
; DIBUJAR JUGADOR EN OFFSET ESPECÍFICO
; AX = offset base
; =====================================================
dibujar_jugador_en_offset PROC
    push ax
    push bx
    push cx
    push dx
    
    mov [temp_offset], ax
    
    mov ax, jugador_x
    sub ax, camara_x
    cmp ax, VIEWPORT_W
    jae djo_fin
    
    mov bx, jugador_y
    sub bx, camara_y
    cmp bx, VIEWPORT_H
    jae djo_fin
    
    shl ax, 4
    add ax, viewport_x
    add ax, 4
    mov cx, ax
    
    mov ax, bx
    shl ax, 4
    add ax, viewport_y
    add ax, 4
    mov dx, ax
    
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
; DIBUJAR SPRITE 16x16 EN OFFSET
; CX=X, DX=Y, DI=sprite
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
; DIBUJAR SPRITE 8x8 EN OFFSET
; CX=X, DX=Y, SI=sprite
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
; ESCRIBIR PÍXEL EN OFFSET ESPECÍFICO
; CX=X, DX=Y, AL=color
; Usa temp_offset como base
; =====================================================
escribir_pixel_en_offset PROC
    push ax
    push bx
    push cx
    push dx
    push di
    
    mov bl, al
    
    ; Calcular offset
    mov ax, dx
    mov di, 80
    mul di
    add ax, [temp_offset]   ; Añadir offset de página
    mov di, ax
    
    mov ax, cx
    shr ax, 3
    add di, ax
    
    ; Máscara de bit
    and cx, 7
    mov al, 80h
    shr al, cl
    mov ah, al
    
    ; Configurar EGA
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
    
    ; Escribir
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
; MOVER JUGADOR
; =====================================================
mover_jugador PROC
    push ax
    
    cmp ah, 48h
    je mj_arr
    cmp al, 'w'
    je mj_arr
    cmp al, 'W'
    je mj_arr
    
    cmp ah, 50h
    je mj_aba
    cmp al, 's'
    je mj_aba
    cmp al, 'S'
    je mj_aba
    
    cmp ah, 4Bh
    je mj_izq
    cmp al, 'a'
    je mj_izq
    cmp al, 'A'
    je mj_izq
    
    cmp ah, 4Dh
    je mj_der
    cmp al, 'd'
    je mj_der
    cmp al, 'D'
    je mj_der
    
    jmp mj_fin

mj_arr:
    cmp jugador_y, 1
    jbe mj_fin
    dec jugador_y
    call verificar_colision
    jnc mj_fin
    inc jugador_y
    jmp mj_fin

mj_aba:
    cmp jugador_y, 48
    jae mj_fin
    inc jugador_y
    call verificar_colision
    jnc mj_fin
    dec jugador_y
    jmp mj_fin

mj_izq:
    cmp jugador_x, 1
    jbe mj_fin
    dec jugador_x
    call verificar_colision
    jnc mj_fin
    inc jugador_x
    jmp mj_fin

mj_der:
    cmp jugador_x, 48
    jae mj_fin
    inc jugador_x
    call verificar_colision
    jnc mj_fin
    dec jugador_x

mj_fin:
    pop ax
    ret
mover_jugador ENDP

; =====================================================
; VERIFICAR COLISIÓN
; =====================================================
verificar_colision PROC
    push ax
    push bx
    push si
    
    mov ax, jugador_y
    mov bx, 50
    mul bx
    add ax, jugador_x
    
    cmp ax, 2500
    jae vc_col
    
    mov si, OFFSET mapa_datos
    add si, ax
    mov al, [si]
    
    cmp al, TILE_GRASS
    je vc_ok
    cmp al, TILE_PATH
    je vc_ok
    
vc_col:
    stc
    jmp vc_fin
    
vc_ok:
    clc
    
vc_fin:
    pop si
    pop bx
    pop ax
    ret
verificar_colision ENDP

; =====================================================
; ACTUALIZAR CÁMARA
; =====================================================
actualizar_camara PROC
    push ax
    push bx
    
    mov ax, jugador_x
    sub ax, 10
    jge ac_x_ok
    xor ax, ax
ac_x_ok:
    mov bx, 30
    cmp ax, bx
    jle ac_x_fin
    mov ax, bx
ac_x_fin:
    mov camara_x, ax
    
    mov ax, jugador_y
    sub ax, 6
    jge ac_y_ok
    xor ax, ax
ac_y_ok:
    mov bx, 38
    cmp ax, bx
    jle ac_y_fin
    mov ax, bx
ac_y_fin:
    mov camara_y, ax
    
    pop bx
    pop ax
    ret
actualizar_camara ENDP

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