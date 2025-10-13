; =====================================================
; JUEGO EGA - SCROLL SUAVE OPTIMIZADO
; Universidad Nacional - Proyecto II Ciclo 2025
; Modo 10h (640x350, 16 colores) FLUIDO Y SIN PARPADEO
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
VELOCIDAD   EQU 2        ; Velocidad de movimiento del jugador

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
msg_titulo  db 'JUEGO EGA - Scroll Suave Optimizado',13,10,'$'
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
    
    ; Inicializar cámara centrada en jugador
    call centrar_camara_inmediato
    
    ; Renderizar ambas páginas iniciales
    call renderizar_en_pagina_0
    call renderizar_en_pagina_1
    
    ; Mostrar página 0 inicialmente
    mov ah, 5
    mov al, 0
    int 10h

; =====================================================
; BUCLE PRINCIPAL DEL JUEGO
; =====================================================
bucle_juego:
    ; Verificar si hay tecla presionada
    mov ah, 1
    int 16h
    jz no_hay_tecla
    
    ; Leer tecla
    mov ah, 0
    int 16h
    
    ; Verificar ESC
    cmp al, 27
    je fin_juego
    
    ; Guardar tecla
    mov tecla_presionada, al
    cmp ah, 0
    je procesar_movimiento
    mov tecla_presionada, ah
    jmp procesar_movimiento

no_hay_tecla:
    mov tecla_presionada, 0

procesar_movimiento:
    ; Mover jugador si hay tecla presionada
    call mover_jugador_suave
    
    ; Actualizar posición de cámara suavemente
    call actualizar_camara_suave
    
    ; Renderizar en la página que NO se está mostrando
    mov al, pagina_dibujo
    test al, 1
    jz render_p0
    call renderizar_en_pagina_1
    jmp mostrar
    
render_p0:
    call renderizar_en_pagina_0
    
mostrar:
    ; Esperar retrace vertical para evitar tearing
    call esperar_retrace
    
    ; Cambiar a la página recién dibujada
    mov ah, 5
    mov al, pagina_dibujo
    int 10h
    
    ; Alternar páginas
    xor pagina_dibujo, 1
    xor pagina_visible, 1
    
    ; Delay muy pequeño para controlar velocidad del juego
    ; AJUSTADO: Valor muy bajo para máxima fluidez
    mov cx, 1
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
    ; Volver a modo texto
    mov ax, 3
    int 10h
    ; Salir al DOS
    mov ax, 4C00h
    int 21h

; =====================================================
; CENTRAR CÁMARA INMEDIATAMENTE EN EL JUGADOR
; =====================================================
centrar_camara_inmediato PROC
    push ax
    push bx
    
    ; Centrar en X
    mov ax, jugador_px
    sub ax, 160        ; viewport_w * 16 / 2 = 160
    jge cci_x_pos
    xor ax, ax
cci_x_pos:
    cmp ax, 480        ; 800 - 320 = 480 (max scroll)
    jle cci_x_ok
    mov ax, 480
cci_x_ok:
    mov camara_px, ax
    
    ; Centrar en Y
    mov ax, jugador_py
    sub ax, 96         ; viewport_h * 16 / 2 = 96
    jge cci_y_pos
    xor ax, ax
cci_y_pos:
    cmp ax, 608        ; 800 - 192 = 608 (max scroll)
    jle cci_y_ok
    mov ax, 608
cci_y_ok:
    mov camara_py, ax
    
    pop bx
    pop ax
    ret
centrar_camara_inmediato ENDP

; =====================================================
; MOVER JUGADOR SUAVE
; =====================================================
mover_jugador_suave PROC
    push ax
    push bx
    
    mov al, tecla_presionada
    test al, al
    jnz mjs_procesar
    jmp mjs_fin

mjs_procesar:

    ; Tecla ARRIBA (↑ o W)
    cmp al, 48h
    je mjs_arr
    cmp al, 'w'
    je mjs_arr
    cmp al, 'W'
    je mjs_arr
    
    ; Tecla ABAJO (↓ o S)
    cmp al, 50h
    je mjs_aba
    cmp al, 's'
    je mjs_aba
    cmp al, 'S'
    je mjs_aba
    
    ; Tecla IZQUIERDA (← o A)
    cmp al, 4Bh
    je mjs_izq
    cmp al, 'a'
    je mjs_izq
    cmp al, 'A'
    je mjs_izq
    
    ; Tecla DERECHA (→ o D)
    cmp al, 4Dh
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
    call verificar_colision_px
    jnc mjs_fin
    add jugador_py, VELOCIDAD
    jmp mjs_fin

mjs_aba:
    mov ax, jugador_py
    add ax, VELOCIDAD
    cmp ax, 784        ; 50*16 - 16 = 784
    ja mjs_fin
    mov jugador_py, ax
    call verificar_colision_px
    jnc mjs_fin
    sub jugador_py, VELOCIDAD
    jmp mjs_fin

mjs_izq:
    mov ax, jugador_px
    sub ax, VELOCIDAD
    cmp ax, 16
    jb mjs_fin
    mov jugador_px, ax
    call verificar_colision_px
    jnc mjs_fin
    add jugador_px, VELOCIDAD
    jmp mjs_fin

mjs_der:
    mov ax, jugador_px
    add ax, VELOCIDAD
    cmp ax, 784        ; 50*16 - 16 = 784
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
    
    ; Convertir posición en píxeles a tiles
    mov ax, jugador_px
    shr ax, 4
    mov cx, ax
    
    mov ax, jugador_py
    shr ax, 4
    mov dx, ax
    
    ; Verificar límites del mapa
    cmp cx, 50
    jae vcp_col
    cmp dx, 50
    jae vcp_col
    
    ; Calcular índice en mapa_datos
    mov ax, dx
    mov bx, 50
    mul bx
    add ax, cx
    
    cmp ax, 2500
    jae vcp_col
    
    ; Leer tipo de tile
    mov si, OFFSET mapa_datos
    add si, ax
    mov al, [si]
    
    ; Verificar si es transitable
    cmp al, TILE_GRASS
    je vcp_ok
    cmp al, TILE_PATH
    je vcp_ok
    
vcp_col:
    stc              ; Carry = 1 indica colisión
    jmp vcp_fin
    
vcp_ok:
    clc              ; Carry = 0 indica sin colisión
    
vcp_fin:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
verificar_colision_px ENDP

; =====================================================
; ACTUALIZAR CÁMARA SUAVE (Interpolación)
; =====================================================
actualizar_camara_suave PROC
    push ax
    push bx
    push dx
    
    ; Calcular posición objetivo en X
    mov ax, jugador_px
    sub ax, 160        ; Centrar en viewport
    jge acs_x_pos
    xor ax, ax
acs_x_pos:
    cmp ax, 480
    jle acs_x_ok
    mov ax, 480
acs_x_ok:
    mov bx, ax         ; BX = objetivo_x
    
    ; Interpolar cámara en X (más rápido que antes)
    sub bx, camara_px  ; Diferencia
    sar bx, 1          ; Dividir por 2 (más rápido que /4)
    add camara_px, bx
    
    ; Calcular posición objetivo en Y
    mov ax, jugador_py
    sub ax, 96         ; Centrar en viewport
    jge acs_y_pos
    xor ax, ax
acs_y_pos:
    cmp ax, 608
    jle acs_y_ok
    mov ax, 608
acs_y_ok:
    mov dx, ax         ; DX = objetivo_y
    
    ; Interpolar cámara en Y
    sub dx, camara_py  ; Diferencia
    sar dx, 1          ; Dividir por 2
    add camara_py, dx
    
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
    
    mov ax, 0          ; Offset página 0
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
    
    mov ax, 8000h      ; Offset página 1
    call limpiar_viewport_en_offset
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
    
    mov dx, 3DAh       ; Puerto de estado CRT
    
er_wait_end:
    in al, dx
    test al, 8         ; Bit 3 = retrace vertical
    jnz er_wait_end    ; Esperar fin de retrace
    
er_wait_start:
    in al, dx
    test al, 8
    jz er_wait_start   ; Esperar inicio de retrace
    
    pop dx
    pop ax
    ret
esperar_retrace ENDP

; =====================================================
; LIMPIAR VIEWPORT EN OFFSET
; =====================================================
limpiar_viewport_en_offset PROC
    push ax
    push bx
    push cx
    push dx
    push di
    push bp
    
    mov bp, ax         ; Guardar offset de página
    
    ; Habilitar escritura en todos los planos
    mov dx, 3C4h       ; Sequencer
    mov ax, 0F02h      ; Map Mask = todos los planos
    out dx, ax
    
    mov bx, viewport_y
    mov cx, VIEWPORT_H * 16  ; Altura del viewport en píxeles
    
lvo_loop:
    ; Calcular offset de línea
    mov ax, bx
    mov di, 80         ; Bytes por línea
    mul di
    add ax, bp         ; Añadir offset de página
    mov di, ax
    
    ; Añadir offset X
    mov ax, viewport_x
    shr ax, 3          ; Dividir por 8 (bytes)
    add di, ax
    
    ; Limpiar 40 bytes (320 píxeles)
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
    
    ; Calcular tile inicial
    mov ax, camara_px
    shr ax, 4
    mov inicio_tile_x, ax
    
    mov ax, camara_py
    shr ax, 4
    mov inicio_tile_y, ax
    
    ; Calcular offset de píxel dentro del tile
    mov ax, camara_px
    and ax, 15
    mov offset_px_x, ax
    
    mov ax, camara_py
    and ax, 15
    mov offset_px_y, ax
    
    ; Dibujar tiles visibles (con uno extra para scroll suave)
    xor bp, bp         ; Fila actual
    
dmo_fila:
    cmp bp, 13         ; VIEWPORT_H + 1
    jb dmo_fila_body
    jmp dmo_fin

dmo_fila_body:
    xor si, si         ; Columna actual
    
dmo_col:
    cmp si, 21         ; VIEWPORT_W + 1
    jae dmo_next_fila
    
    ; Verificar límites del mapa
    mov ax, inicio_tile_y
    add ax, bp
    cmp ax, 50
    jae dmo_next_col
    
    mov bx, inicio_tile_x
    add bx, si
    cmp bx, 50
    jae dmo_next_col
    
    ; Calcular índice del tile
    push dx
    mov dx, 50
    mul dx
    add ax, bx
    pop dx
    
    mov bx, ax
    mov al, [mapa_datos + bx]
    
    ; Seleccionar sprite según tipo de tile
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
    
    ; Calcular posición en pantalla
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
    
    ; Calcular posición del jugador en pantalla
    mov ax, jugador_px
    sub ax, camara_px
    add ax, viewport_x
    mov cx, ax
    
    mov ax, jugador_py
    sub ax, camara_py
    add ax, viewport_y
    mov dx, ax
    
    ; Verificar si está dentro del viewport
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
    
    ; Dibujar sprite del jugador
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
; DIBUJAR SPRITE 16x16 EN OFFSET
; =====================================================
dibujar_sprite_16x16_en_offset PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push bp
    
    mov si, di         ; SI = puntero al sprite
    mov bp, 16         ; 16 filas
    
ds16o_fila:
    mov bx, cx         ; Guardar X inicial
    push bp
    mov bp, 16         ; 16 píxeles por fila
    
ds16o_pixel:
    lodsb              ; Cargar píxel del sprite
    test al, al        ; Si es 0, es transparente
    jz ds16o_skip
    
    call escribir_pixel_en_offset
    
ds16o_skip:
    inc cx             ; Siguiente X
    dec bp
    jnz ds16o_pixel
    
    mov cx, bx         ; Restaurar X
    pop bp
    inc dx             ; Siguiente Y
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
; =====================================================
dibujar_sprite_8x8_en_offset PROC
    push ax
    push bx
    push cx
    push dx
    push bp
    
    mov bp, 8          ; 8 filas
    
ds8o_fila:
    mov bx, cx         ; Guardar X inicial
    push bp
    mov bp, 8          ; 8 píxeles por fila
    
ds8o_pixel:
    lodsb              ; Cargar píxel
    test al, al        ; Si es 0, es transparente
    jz ds8o_skip
    
    call escribir_pixel_en_offset
    
ds8o_skip:
    inc cx             ; Siguiente X
    dec bp
    jnz ds8o_pixel
    
    mov cx, bx         ; Restaurar X
    pop bp
    inc dx             ; Siguiente Y
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
; ESCRIBIR PÍXEL EN OFFSET (Modo EGA)
; =====================================================
escribir_pixel_en_offset PROC
    push ax
    push bx
    push cx
    push dx
    push di
    
    mov bl, al         ; Guardar color
    
    ; Calcular offset en memoria de video
    mov ax, dx         ; Y
    mov di, 80         ; Bytes por línea
    mul di
    add ax, temp_offset
    mov di, ax
    
    mov ax, cx         ; X
    shr ax, 3          ; Dividir por 8
    add di, ax
    
    ; Calcular máscara de bit
    and cx, 7
    mov al, 80h
    shr al, cl
    mov ah, al
    
    ; Programar Graphics Controller
    mov dx, 3CEh       ; GC Address
    
    ; Set/Reset Register
    mov al, 0
    out dx, al
    inc dx
    mov al, bl         ; Color
    out dx, al
    dec dx
    
    ; Enable Set/Reset
    mov al, 1
    out dx, al
    inc dx
    mov al, 0Fh        ; Todos los planos
    out dx, al
    dec dx
    
    ; Bit Mask
    mov al, 8
    out dx, al
    inc dx
    mov al, ah         ; Máscara
    out dx, al
    
    ; Escribir píxel (latching)
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
    
    ; Abrir archivo
    mov ax, 3D00h
    mov dx, OFFSET archivo_mapa
    int 21h
    jc cm_error
    
    mov bx, ax         ; Handle
    call saltar_linea  ; Saltar línea de dimensiones
    
    mov di, OFFSET mapa_datos
    xor bp, bp         ; Contador de tiles
    
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
    
    ; Ignorar espacios y saltos de línea
    cmp al, ' '
    je cm_proc
    cmp al, 13
    je cm_proc
    cmp al, 10
    je cm_proc
    cmp al, 9
    je cm_proc
    
    ; Verificar si es dígito
    cmp al, '0'
    jb cm_proc
    cmp al, '9'
    ja cm_proc
    
    ; Convertir a número
    sub al, '0'
    mov [di], al
    inc di
    inc bp

    cmp bp, 2500       ; 50x50
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
    
    ; Convertir dígito hexadecimal
    cmp al, '0'
    jb cs16_proc
    cmp al, '9'
    jbe cs16_decimal
    
    ; Es A-F
    and al, 0DFh       ; Convertir a mayúscula
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
; SALTAR LÍNEA EN ARCHIVO
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