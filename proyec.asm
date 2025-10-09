; =====================================================
; JUEGO DE EXPLORACIÓN - EGA CON PÁGINAS DE VIDEO
; Universidad Nacional - Proyecto II Ciclo 2025
; Modo 10h (640x350, 16 colores EGA)
; DOBLE BUFFER: Dibuja en página oculta, cambia página
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
VIEWPORT_W  EQU 10          ; 10 tiles = 160 píxeles
VIEWPORT_H  EQU 8           ; 8 tiles = 128 píxeles

VIDEO_SEG   EQU 0A000h
CRTC_ADDR   EQU 3D4h        ; Puerto CRTC

.DATA
; === ARCHIVOS ===
archivo_mapa   db 'MAPA.TXT',0
archivo_grass  db 'GRASS.TXT',0
archivo_wall   db 'WALL.TXT',0
archivo_path   db 'PATH.TXT',0
archivo_water  db 'WATER.TXT',0
archivo_tree   db 'TREE.TXT',0
archivo_player db 'PLAYER.TXT',0
handle_archivo dw 0

; === MAPA 50x50 ===
mapa_datos  db 2500 dup(0)

; === SPRITES 16x16 (256 bytes cada uno) ===
sprite_grass  db 256 dup(0)
sprite_wall   db 256 dup(0)
sprite_path   db 256 dup(0)
sprite_water  db 256 dup(0)
sprite_tree   db 256 dup(0)

; === SPRITE JUGADOR 8x8 (64 bytes) ===
sprite_player db 64 dup(0)

; === BUFFER TEMPORAL ===
buffer_temp db 300 dup(0)

; === JUGADOR ===
jugador_x   dw 25
jugador_y   dw 25
jugador_x_ant dw 25
jugador_y_ant dw 25

; === CÁMARA ===
camara_x    dw 0
camara_y    dw 0

; === PÁGINAS DE VIDEO ===
pagina_actual   db 0        ; 0 o 1
offset_pagina0  dw 0        ; Página 0: offset 0
offset_pagina1  dw 8000     ; Página 1: offset 8000 (32KB después)

; === MENSAJES ===
msg_titulo  db 'JUEGO EXPLORACION EGA - Doble Buffer con Paginas',13,10,'$'
msg_cargando db 'Cargando archivos...',13,10,'$'
msg_mapa    db '- Mapa: $'
msg_grass   db '- Grass: $'
msg_wall    db '- Wall: $'
msg_path    db '- Path: $'
msg_water   db '- Water: $'
msg_tree    db '- Tree: $'
msg_player  db '- Player: $'
msg_ok      db 'OK',13,10,'$'
msg_error   db 'ERROR',13,10,'$'
msg_controles db 13,10,'Controles: Flechas/WASD=Mover, ESC=Salir',13,10
              db 'Presiona tecla...$'

.CODE
inicio:
    mov ax, @data
    mov ds, ax
    mov es, ax

    ; Mostrar título
    mov dx, OFFSET msg_titulo
    mov ah, 9
    int 21h

    ; Cargar archivos
    mov dx, OFFSET msg_cargando
    mov ah, 9
    int 21h
    
    ; === CARGAR MAPA ===
    mov dx, OFFSET msg_mapa
    mov ah, 9
    int 21h
    call cargar_mapa
    jnc cargar_mapa_ok
    jmp error_carga
cargar_mapa_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    ; === CARGAR GRASS ===
    mov dx, OFFSET msg_grass
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_grass
    mov di, OFFSET sprite_grass
    call cargar_sprite_16x16
    jnc cargar_grass_ok
    jmp error_carga
cargar_grass_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    ; === CARGAR WALL ===
    mov dx, OFFSET msg_wall
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_wall
    mov di, OFFSET sprite_wall
    call cargar_sprite_16x16
    jnc cargar_wall_ok
    jmp error_carga
cargar_wall_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    ; === CARGAR PATH ===
    mov dx, OFFSET msg_path
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_path
    mov di, OFFSET sprite_path
    call cargar_sprite_16x16
    jnc cargar_path_ok
    jmp error_carga
cargar_path_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    ; === CARGAR WATER ===
    mov dx, OFFSET msg_water
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_water
    mov di, OFFSET sprite_water
    call cargar_sprite_16x16
    jnc cargar_water_ok
    jmp error_carga
cargar_water_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    ; === CARGAR TREE ===
    mov dx, OFFSET msg_tree
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_tree
    mov di, OFFSET sprite_tree
    call cargar_sprite_16x16
    jnc cargar_tree_ok
    jmp error_carga
cargar_tree_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    ; === CARGAR PLAYER ===
    mov dx, OFFSET msg_player
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_player
    mov di, OFFSET sprite_player
    call cargar_sprite_8x8
    jnc cargar_player_ok
    jmp error_carga
cargar_player_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    ; Esperar tecla
    mov dx, OFFSET msg_controles
    mov ah, 9
    int 21h
    mov ah, 0
    int 16h

    ; ✅ ACTIVAR MODO 10h EGA (640x350, 16 colores)
    mov ax, 10h
    int 10h
    
    ; Inicializar páginas de video
    call inicializar_paginas
    
    ; Primera renderización
    call actualizar_camara
    call renderizar_todo
    
    ; Mostrar página inicial
    call mostrar_pagina

; =====================================================
; BUCLE PRINCIPAL DEL JUEGO
; =====================================================
bucle_juego:
    ; ¿Hay tecla presionada?
    mov ah, 1
    int 16h
    jz bucle_juego          ; No hay tecla, continuar
    
    ; Leer tecla
    mov ah, 0
    int 16h
    
    ; ¿ESC?
    cmp al, 27
    je fin_juego
    
    ; Procesar movimiento
    call mover_jugador
    
    ; ¿Se movió el jugador?
    mov ax, jugador_x
    cmp ax, jugador_x_ant
    jne jugador_movio
    mov ax, jugador_y
    cmp ax, jugador_y_ant
    je bucle_juego          ; No se movió, continuar
    
jugador_movio:
    ; Actualizar cámara y redibujar
    call actualizar_camara
    call renderizar_todo
    call mostrar_pagina
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
; INICIALIZAR PÁGINAS DE VIDEO
; =====================================================
inicializar_paginas PROC
    push ax
    
    mov pagina_actual, 0
    
    pop ax
    ret
inicializar_paginas ENDP

; =====================================================
; MOSTRAR PÁGINA (CAMBIO INSTANTÁNEO)
; ✅ Esta es la magia del doble buffer con páginas
; =====================================================
mostrar_pagina PROC
    push ax
    push dx
    
    ; Alternar página
    xor pagina_actual, 1
    
    ; Cambiar página visible
    mov dx, CRTC_ADDR
    mov al, 0Ch             ; Start Address High
    out dx, al
    inc dx
    
    cmp pagina_actual, 0
    je mp_pagina0
    
    ; Mostrar página 1
    mov ax, offset_pagina1
    shr ax, 8               ; High byte
    out dx, al
    jmp mp_fin
    
mp_pagina0:
    ; Mostrar página 0
    xor al, al
    out dx, al
    
mp_fin:
    pop dx
    pop ax
    ret
mostrar_pagina ENDP

; =====================================================
; RENDERIZAR TODO (en página oculta)
; =====================================================
renderizar_todo PROC
    push ax
    push es
    
    ; Seleccionar página oculta para dibujar
    mov ax, VIDEO_SEG
    mov es, ax
    
    call limpiar_pagina_oculta
    call dibujar_mapa
    call dibujar_jugador
    
    pop es
    pop ax
    ret
renderizar_todo ENDP

; =====================================================
; LIMPIAR PÁGINA OCULTA
; =====================================================
limpiar_pagina_oculta PROC
    push ax
    push cx
    push di
    
    ; Calcular offset de página oculta
    cmp pagina_actual, 0
    je lpo_usar_pag1
    
    ; Página actual es 1, limpiar página 0
    mov di, offset_pagina0
    jmp lpo_limpiar
    
lpo_usar_pag1:
    ; Página actual es 0, limpiar página 1
    mov di, offset_pagina1
    
lpo_limpiar:
    ; Limpiar área del viewport
    ; 160 píxeles × 128 líneas = 20,480 píxeles
    ; En modo planar: 20,480 / 8 = 2,560 bytes por plano
    
    ; Por simplicidad, limpiar un área rectangular
    mov cx, 2000            ; Aproximado
    xor ax, ax
    rep stosw
    
    pop di
    pop cx
    pop ax
    ret
limpiar_pagina_oculta ENDP

; =====================================================
; DIBUJAR MAPA
; =====================================================
dibujar_mapa PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    xor bp, bp              ; Fila viewport (0-7)
    
dm_fila:
    cmp bp, VIEWPORT_H
    jb dm_fila_ok
    jmp dm_fin

dm_fila_ok:
    xor si, si              ; Columna viewport (0-9)
    
dm_columna:
    cmp si, VIEWPORT_W
    jb dm_columna_ok
    jmp dm_next_fila

dm_columna_ok:
    
    ; Calcular posición en mapa
    mov ax, camara_y
    add ax, bp
    cmp ax, 50
    jb dm_y_ok
    jmp dm_next_col

dm_y_ok:
    
    mov bx, camara_x
    add bx, si
    cmp bx, 50
    jb dm_coords_ok
    jmp dm_next_col

dm_coords_ok:
    
    ; Índice en mapa: Y * 50 + X
    push dx
    mov dx, 50
    mul dx
    add ax, bx
    pop dx
    
    cmp ax, 2500
    jb dm_get_tile
    jmp dm_next_col

dm_get_tile:
    
    ; Obtener tile del mapa
    push si
    push di
    mov di, OFFSET mapa_datos
    add di, ax
    mov al, [di]
    pop di
    pop si
    
    ; Seleccionar sprite según tile
    push si
    push bp
    
    cmp al, TILE_GRASS
    jne dm_check_wall
    mov di, OFFSET sprite_grass
    jmp dm_dibujar
    
dm_check_wall:
    cmp al, TILE_WALL
    jne dm_check_path
    mov di, OFFSET sprite_wall
    jmp dm_dibujar
    
dm_check_path:
    cmp al, TILE_PATH
    jne dm_check_water
    mov di, OFFSET sprite_path
    jmp dm_dibujar
    
dm_check_water:
    cmp al, TILE_WATER
    jne dm_check_tree
    mov di, OFFSET sprite_water
    jmp dm_dibujar
    
dm_check_tree:
    cmp al, TILE_TREE
    jne dm_default
    mov di, OFFSET sprite_tree
    jmp dm_dibujar
    
dm_default:
    mov di, OFFSET sprite_grass
    
dm_dibujar:
    pop bp
    pop si
    
    ; Calcular posición en pantalla
    ; X = columna * 16 + offset_viewport_x
    mov ax, si
    mov cx, TILE_SIZE
    mul cx
    add ax, 240             ; Centrar horizontalmente (640-160)/2
    mov cx, ax
    
    ; Y = fila * 16 + offset_viewport_y
    mov ax, bp
    mov bx, TILE_SIZE
    mul bx
    add ax, 111             ; Centrar verticalmente (350-128)/2
    mov dx, ax
    
    ; Dibujar sprite
    call dibujar_sprite_16x16
    
dm_next_col:
    inc si
    jmp dm_columna
    
dm_next_fila:
    inc bp
    jmp dm_fila
    
dm_fin:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_mapa ENDP

; =====================================================
; DIBUJAR JUGADOR
; =====================================================
dibujar_jugador PROC
    push ax
    push bx
    push cx
    push dx
    
    ; Verificar si está en viewport
    mov ax, jugador_x
    sub ax, camara_x
    js dj_fin
    cmp ax, VIEWPORT_W
    jae dj_fin
    
    mov bx, jugador_y
    sub bx, camara_y
    js dj_fin
    cmp bx, VIEWPORT_H
    jae dj_fin
    
    ; Calcular posición en pantalla
    mov cx, TILE_SIZE
    mul cx
    add ax, 244             ; Centrar + 4 píxeles
    mov cx, ax
    
    mov ax, bx
    mov dx, TILE_SIZE
    mul dx
    add ax, 115             ; Centrar + 4 píxeles
    mov dx, ax
    
    ; Dibujar sprite jugador
    mov di, OFFSET sprite_player
    call dibujar_sprite_8x8
    
dj_fin:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_jugador ENDP

; =====================================================
; DIBUJAR SPRITE 16x16
; Entrada: CX=X, DX=Y, DI=sprite, ES=VIDEO_SEG
; =====================================================
dibujar_sprite_16x16 PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push bp
    
    ; Verificar límites
    cmp cx, 624             ; 640-16
    ja ds16_fin_jmp
    cmp dx, 334             ; 350-16
    ja ds16_fin_jmp
    jmp ds16_ok
    
ds16_fin_jmp:
    jmp ds16_fin
    
ds16_ok:
    mov si, di              ; SI = sprite
    xor bp, bp              ; Fila del sprite
    
ds16_fila:
    cmp bp, 16
    jae ds16_fin
    
    ; Calcular offset en video
    mov ax, dx
    add ax, bp
    mov bx, 80              ; 640/8 = 80 bytes por línea
    mul bx
    
    push dx
    mov bx, cx
    shr bx, 3               ; X / 8
    add ax, bx
    mov di, ax              ; DI = offset en video
    pop dx
    
    ; Obtener offset de página oculta
    cmp pagina_actual, 0
    je ds16_pag1
    add di, offset_pagina0
    jmp ds16_dibujar_linea
    
ds16_pag1:
    add di, offset_pagina1
    
ds16_dibujar_linea:
    push cx
    mov cx, 16              ; 16 píxeles
    
ds16_pixel:
    lodsb                   ; AL = color del sprite
    cmp al, 0
    je ds16_skip_pixel
    
    ; Dibujar píxel (simplificado)
    mov es:[di], al
    
ds16_skip_pixel:
    inc di
    loop ds16_pixel
    
    pop cx
    inc bp
    jmp ds16_fila
    
ds16_fin:
    pop bp
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_sprite_16x16 ENDP

; =====================================================
; DIBUJAR SPRITE 8x8
; Entrada: CX=X, DX=Y, DI=sprite, ES=VIDEO_SEG
; =====================================================
dibujar_sprite_8x8 PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push bp
    
    mov si, di
    xor bp, bp
    
ds8_fila:
    cmp bp, 8
    jae ds8_fin
    
    ; Calcular offset
    mov ax, dx
    add ax, bp
    mov bx, 80
    mul bx
    
    push dx
    mov bx, cx
    shr bx, 3
    add ax, bx
    mov di, ax
    pop dx
    
    ; Página oculta
    cmp pagina_actual, 0
    je ds8_pag1
    add di, offset_pagina0
    jmp ds8_linea
    
ds8_pag1:
    add di, offset_pagina1
    
ds8_linea:
    push cx
    mov cx, 8
    
ds8_pixel:
    lodsb
    cmp al, 0
    je ds8_skip
    mov es:[di], al
    
ds8_skip:
    inc di
    loop ds8_pixel
    
    pop cx
    inc bp
    jmp ds8_fila
    
ds8_fin:
    pop bp
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_sprite_8x8 ENDP

; =====================================================
; MOVER JUGADOR
; =====================================================
mover_jugador PROC
    push ax
    push bx
    
    ; Guardar posición anterior
    mov ax, jugador_x
    mov jugador_x_ant, ax
    mov ax, jugador_y
    mov jugador_y_ant, ax
    
    ; Flecha arriba o W
    cmp ah, 48h
    je mj_arriba
    cmp al, 'w'
    je mj_arriba
    cmp al, 'W'
    je mj_arriba
    jmp mj_check_abajo
    
mj_arriba:
    cmp jugador_y, 1
    jbe mj_fin
    dec jugador_y
    jmp mj_verificar
    
mj_check_abajo:
    cmp ah, 50h
    je mj_abajo
    cmp al, 's'
    je mj_abajo
    cmp al, 'S'
    jne mj_check_izq
    
mj_abajo:
    cmp jugador_y, 48
    jae mj_fin
    inc jugador_y
    jmp mj_verificar
    
mj_check_izq:
    cmp ah, 4Bh
    je mj_izquierda
    cmp al, 'a'
    je mj_izquierda
    cmp al, 'A'
    jne mj_check_der
    
mj_izquierda:
    cmp jugador_x, 1
    jbe mj_fin
    dec jugador_x
    jmp mj_verificar
    
mj_check_der:
    cmp ah, 4Dh
    je mj_derecha
    cmp al, 'd'
    je mj_derecha
    cmp al, 'D'
    jne mj_fin
    
mj_derecha:
    cmp jugador_x, 48
    jae mj_fin
    inc jugador_x
    
mj_verificar:
    ; Verificar colisión
    call verificar_colision
    jnc mj_fin
    
    ; Hay colisión, restaurar posición
    mov ax, jugador_x_ant
    mov jugador_x, ax
    mov ax, jugador_y_ant
    mov jugador_y, ax
    
mj_fin:
    pop bx
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
    
    ; Calcular índice: Y * 50 + X
    mov ax, jugador_y
    mov bx, 50
    mul bx
    add ax, jugador_x
    
    cmp ax, 2500
    jae vc_colision
    
    ; Obtener tile
    mov si, OFFSET mapa_datos
    add si, ax
    mov al, [si]
    
    ; Solo grass y path son transitables
    cmp al, TILE_GRASS
    je vc_ok
    cmp al, TILE_PATH
    je vc_ok
    
vc_colision:
    stc                     ; CF=1: colisión
    jmp vc_fin
    
vc_ok:
    clc                     ; CF=0: sin colisión
    
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
    
    ; Centrar cámara en jugador X
    mov ax, jugador_x
    sub ax, VIEWPORT_W / 2
    jge ac_x_ok
    xor ax, ax
    
ac_x_ok:
    mov bx, 50
    sub bx, VIEWPORT_W
    cmp ax, bx
    jle ac_x_fin
    mov ax, bx
    
ac_x_fin:
    mov camara_x, ax
    
    ; Centrar cámara en jugador Y
    mov ax, jugador_y
    sub ax, VIEWPORT_H / 2
    jge ac_y_ok
    xor ax, ax
    
ac_y_ok:
    mov bx, 50
    sub bx, VIEWPORT_H
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
; CARGAR MAPA 50x50
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
    mov ah, 3Fh
    mov cx, 20
    mov dx, OFFSET buffer_temp
    int 21h
    
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

cm_procesar:
    cmp si, cx
    jae cm_leer

    mov al, [buffer_temp + si]
    inc si
    
    ; Filtrar espacios
    cmp al, ' '
    je cm_procesar
    cmp al, 13
    je cm_procesar
    cmp al, 10
    je cm_procesar
    
    ; Convertir ASCII a número
    cmp al, '0'
    jb cm_procesar
    cmp al, '9'
    ja cm_procesar
    
    sub al, '0'
    mov [di], al
    inc di
    inc bp

    cmp bp, 2500
    jb cm_procesar
    
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
; Entrada: DX=nombre archivo, DI=buffer destino
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
    
    ; Saltar dimensiones
    mov ah, 3Fh
    mov cx, 20
    push dx
    mov dx, OFFSET buffer_temp
    int 21h
    pop dx
    
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
; Entrada: DX=nombre archivo, DI=buffer destino
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
    
    ; Saltar dimensiones
    mov ah, 3Fh
    mov cx, 20
    push dx
    mov dx, OFFSET buffer_temp
    int 21h
    pop dx
    
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

END inicio
