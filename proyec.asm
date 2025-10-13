; =====================================================
; JUEGO EGA - MOVIMIENTO DISCRETO ULTRA RESPONSIVO
; Universidad Nacional - Proyecto II Ciclo 2025
; Modo 10h (640x350, 16 colores)
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
VELOCIDAD   EQU 16       ; ¡MOVIMIENTO COMPLETO DE 1 TILE!

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
jugador_px  dw 80
jugador_py  dw 80

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

; === ANTI-REPETICIÓN DE TECLAS ===
ultima_tecla db 0
tecla_procesada db 0

; === MENSAJES ===
msg_titulo  db 'JUEGO EGA - Movimiento Ultra Responsivo',13,10,'$'
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
; BUCLE PRINCIPAL - MÁXIMA RESPONSIVIDAD
; =====================================================
bucle_juego:
    ; Verificar si hay tecla (NO bloqueante)
    mov ah, 1
    int 16h
    jz solo_actualizar
    
    ; HAY TECLA - Leer inmediatamente
    mov ah, 0
    int 16h
    
    ; Verificar ESC
    cmp al, 27
    je fin_juego
    
    ; Procesar tecla y mover INMEDIATAMENTE
    call procesar_tecla_inmediata
    
    ; Actualizar cámara INSTANTÁNEAMENTE después del movimiento
    call centrar_camara_directo
    
    jmp renderizar
    
solo_actualizar:
    ; Si no hay tecla, mantener cámara donde está
    
renderizar:
    ; Renderizar en página oculta
    mov al, pagina_dibujo
    test al, 1
    jz render_p0
    call renderizar_en_pagina_1
    jmp SHORT cambiar_pagina
    
render_p0:
    call renderizar_en_pagina_0
    
cambiar_pagina:
    ; Sincronizar con retrace
    call esperar_retrace
    
    ; Cambiar página visible
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
; PROCESAR TECLA INMEDIATAMENTE
; =====================================================
procesar_tecla_inmediata PROC
    push ax
    push bx
    push cx
    push dx
    
    ; Guardar tecla
    mov bl, al
    mov bh, ah
    
    ; Determinar qué tecla es
    test bl, bl
    jz usar_scan
    mov al, bl
    jmp SHORT verificar_tecla
    
usar_scan:
    mov al, bh
    
verificar_tecla:
    ; ARRIBA
    cmp al, 48h
    je goto_pti_arr
    cmp al, 'w'
    je goto_pti_arr
    cmp al, 'W'
    je goto_pti_arr
    
    ; ABAJO
    cmp al, 50h
    je goto_pti_aba
    cmp al, 's'
    je goto_pti_aba
    cmp al, 'S'
    je goto_pti_aba
    
    ; IZQUIERDA
    cmp al, 4Bh
    je goto_pti_izq
    cmp al, 'a'
    je goto_pti_izq
    cmp al, 'A'
    je goto_pti_izq
    
    ; DERECHA
    cmp al, 4Dh
    je goto_pti_der
    cmp al, 'd'
    je goto_pti_der
    cmp al, 'D'
    je goto_pti_der
    
    jmp SHORT pti_fin

goto_pti_arr:
    jmp pti_arr

goto_pti_aba:
    jmp pti_aba

goto_pti_izq:
    jmp pti_izq

goto_pti_der:
    jmp pti_der

pti_arr:
    ; Calcular nueva posición
    mov ax, jugador_py
    sub ax, VELOCIDAD
    
    ; Verificar límites
    cmp ax, 16
    jb pti_fin
    
    ; Verificar colisión ANTES de mover
    mov cx, jugador_px
    shr cx, 4           ; Convertir a tiles
    mov dx, ax
    shr dx, 4
    call verificar_tile_transitable
    jnc pti_fin         ; Si no es transitable, no mover
    
    ; Mover si es válido
    mov jugador_py, ax
    jmp SHORT pti_fin

pti_aba:
    mov ax, jugador_py
    add ax, VELOCIDAD
    
    cmp ax, 784
    ja pti_fin
    
    mov cx, jugador_px
    shr cx, 4
    mov dx, ax
    shr dx, 4
    call verificar_tile_transitable
    jnc pti_fin
    
    mov jugador_py, ax
    jmp SHORT pti_fin

pti_izq:
    mov ax, jugador_px
    sub ax, VELOCIDAD
    
    cmp ax, 16
    jb pti_fin
    
    mov cx, ax
    shr cx, 4
    mov dx, jugador_py
    shr dx, 4
    call verificar_tile_transitable
    jnc pti_fin
    
    mov jugador_px, ax
    jmp SHORT pti_fin

pti_der:
    mov ax, jugador_px
    add ax, VELOCIDAD
    
    cmp ax, 784
    ja pti_fin
    
    mov cx, ax
    shr cx, 4
    mov dx, jugador_py
    shr dx, 4
    call verificar_tile_transitable
    jnc pti_fin
    
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
    
    ; CX = tile_x, DX = tile_y
    ; Verificar límites del mapa
    cmp cx, 50
    jae vtt_no_transitable
    cmp dx, 50
    jae vtt_no_transitable
    
    ; Calcular offset en mapa
    mov ax, dx
    mov bx, 50
    mul bx
    add ax, cx
    mov bx, ax
    
    ; Obtener tipo de tile
    mov al, [mapa_datos + bx]
    
    ; Verificar si es transitable
    cmp al, TILE_WALL
    je vtt_no_transitable
    cmp al, TILE_WATER
    je vtt_no_transitable
    cmp al, TILE_TREE
    je vtt_no_transitable
    
    ; Es transitable
    pop dx
    pop bx
    pop ax
    stc                 ; Carry = 1 = transitable
    ret

vtt_no_transitable:
    pop dx
    pop bx
    pop ax
    clc                 ; Carry = 0 = no transitable
    ret
verificar_tile_transitable ENDP

; =====================================================
; CENTRAR CÁMARA DIRECTO (INSTANTÁNEO)
; =====================================================
centrar_camara_directo PROC
    push ax
    
    ; Centrar en X
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
    
    ; Centrar en Y
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
    
    ; Calcular tile inicial basado en cámara
    mov ax, camara_px
    shr ax, 4
    mov inicio_tile_x, ax
    
    mov ax, camara_py
    shr ax, 4
    mov inicio_tile_y, ax
    
    ; Calcular offset en píxeles
    mov ax, camara_px
    and ax, 15
    mov offset_px_x, ax
    
    mov ax, camara_py
    and ax, 15
    mov offset_px_y, ax
    
    ; Dibujar tiles visibles (21x13 para cubrir toda la pantalla)
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
    
    ; Calcular coordenadas del tile en el mapa
    mov ax, inicio_tile_y
    add ax, bp
    cmp ax, 50
    jae dmo_next_col
    
    mov bx, inicio_tile_x
    add bx, si
    cmp bx, 50
    jae dmo_next_col
    
    ; Calcular índice en mapa
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
    jne dmo_chk_path
    mov di, OFFSET sprite_wall
    jmp SHORT dmo_draw

dmo_chk_path:
    cmp al, TILE_PATH
    jne dmo_chk_water
    mov di, OFFSET sprite_path
    jmp SHORT dmo_draw

dmo_chk_water:
    cmp al, TILE_WATER
    jne dmo_chk_tree
    mov di, OFFSET sprite_water
    jmp SHORT dmo_draw

dmo_chk_tree:
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
    push cx
    push dx
    push si
    
    ; Calcular posición relativa a la cámara
    mov ax, jugador_px
    sub ax, camara_px
    add ax, viewport_x
    mov cx, ax
    
    mov ax, jugador_py
    sub ax, camara_py
    add ax, viewport_y
    mov dx, ax
    
    mov si, OFFSET sprite_player
    call dibujar_sprite_8x8_en_offset
    
    pop si
    pop dx
    pop cx
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
; DIBUJAR SPRITE 8x8
; =====================================================
dibujar_sprite_8x8_en_offset PROC
    push ax
    push bx
    push cx
    push dx
    push bp
    
    mov bp, 8
    
ds8_fila:
    mov bx, cx
    push bp
    mov bp, 8
    
ds8_pixel:
    lodsb
    test al, al
    jz ds8_skip
    
    call escribir_pixel_en_offset
    
ds8_skip:
    inc cx
    dec bp
    jnz ds8_pixel
    
    mov cx, bx
    pop bp
    inc dx
    dec bp
    jnz ds8_fila
    
    pop bp
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_sprite_8x8_en_offset ENDP

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
    
    ; Calcular offset en memoria de video
    mov ax, dx
    mov di, 80
    mul di
    add ax, temp_offset
    mov di, ax
    
    mov ax, cx
    shr ax, 3
    add di, ax
    
    ; Calcular máscara de bit
    and cx, 7
    mov al, 80h
    shr al, cl
    mov ah, al
    
    ; Escribir píxel usando registros EGA
    mov dx, 3CEh
    
    ; Set/Reset Register
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
    
    ; Abrir archivo
    mov ax, 3D00h
    mov dx, OFFSET archivo_mapa
    int 21h
    jc cm_error
    
    mov bx, ax
    
    ; Saltar primera línea (dimensiones)
    call saltar_linea
    
    ; Leer datos del mapa
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
    
    ; Saltar espacios, tabs, CR, LF
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
    
    ; Convertir y guardar
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
    
    ; Abrir archivo
    mov ax, 3D00h
    int 21h
    jc cs16_error
    
    mov bx, ax
    
    ; Saltar primera línea
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
    
    ; Saltar espacios, tabs, CR, LF
    cmp al, ' '
    je cs16_proc
    cmp al, 13
    je cs16_proc
    cmp al, 10
    je cs16_proc
    cmp al, 9
    je cs16_proc
    
    ; Verificar si es dígito hexadecimal
    cmp al, '0'
    jb cs16_proc
    cmp al, '9'
    jbe cs16_decimal
    
    ; Convertir letra (A-F)
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
; CARGAR SPRITE 8x8
; =====================================================
cargar_sprite_8x8 PROC
    push ax
    push bx
    push cx
    push si
    push bp
    
    ; Abrir archivo
    mov ax, 3D00h
    int 21h
    jc cs8_error
    
    mov bx, ax
    
    ; Saltar primera línea
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
    
    ; Saltar espacios, tabs, CR, LF
    cmp al, ' '
    je cs8_proc
    cmp al, 13
    je cs8_proc
    cmp al, 10
    je cs8_proc
    cmp al, 9
    je cs8_proc
    
    ; Verificar si es dígito
    cmp al, '0'
    jb cs8_proc
    cmp al, '9'
    ja cs8_proc
    
    ; Convertir y guardar
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