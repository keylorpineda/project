; =====================================================
; JUEGO DE EXPLORACIÓN - EGA FUNCIONAL
; Universidad Nacional - Proyecto II Ciclo 2025
; Modo 10h (640x350, 16 colores) - Doble Buffer con Páginas
; Versión simplificada y robusta
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
VIEWPORT_W  EQU 10
VIEWPORT_H  EQU 8

VIDEO_SEG   EQU 0A000h

; Puertos EGA
SC_INDEX    EQU 3C4h
SC_DATA     EQU 3C5h
GC_INDEX    EQU 3CEh
GC_DATA     EQU 3CFh
CRTC_INDEX  EQU 3D4h

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
jugador_x_ant dw 25
jugador_y_ant dw 25

; === CÁMARA ===
camara_x    dw 0
camara_y    dw 0

; === PÁGINAS ===
pagina_actual   db 0
offset_pagina0  dw 0
offset_pagina1  dw 16000

; === MENSAJES ===
msg_titulo  db 'JUEGO EGA 640x350 - Doble Buffer',13,10,'$'
msg_cargando db 'Cargando...',13,10,'$'
msg_mapa    db 'Mapa: $'
msg_grass   db 'Grass: $'
msg_wall    db 'Wall: $'
msg_path    db 'Path: $'
msg_water   db 'Water: $'
msg_tree    db 'Tree: $'
msg_player  db 'Player: $'
msg_ok      db 'OK',13,10,'$'
msg_error   db 'ERROR',13,10,'$'
msg_controles db 13,10,'WASD o Flechas=Mover, ESC=Salir',13,10
              db 'Presiona tecla...$'

.CODE
inicio:
    mov ax, @data
    mov ds, ax
    mov es, ax

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
    mov dx, OFFSET msg_grass
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_grass
    mov di, OFFSET sprite_grass
    call cargar_sprite_16x16
    jnc cg_ok
    jmp error_carga
cg_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    mov dx, OFFSET msg_wall
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_wall
    mov di, OFFSET sprite_wall
    call cargar_sprite_16x16
    jnc cw_ok
    jmp error_carga
cw_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    mov dx, OFFSET msg_path
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_path
    mov di, OFFSET sprite_path
    call cargar_sprite_16x16
    jnc cp_ok
    jmp error_carga
cp_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    mov dx, OFFSET msg_water
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_water
    mov di, OFFSET sprite_water
    call cargar_sprite_16x16
    jnc cwt_ok
    jmp error_carga
cwt_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    mov dx, OFFSET msg_tree
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_tree
    mov di, OFFSET sprite_tree
    call cargar_sprite_16x16
    jnc ct_ok
    jmp error_carga
ct_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    mov dx, OFFSET msg_player
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_player
    mov di, OFFSET sprite_player
    call cargar_sprite_8x8
    jnc cpl_ok
    jmp error_carga
cpl_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    mov dx, OFFSET msg_controles
    mov ah, 9
    int 21h
    mov ah, 0
    int 16h

    ; MODO EGA 640x350
    mov ax, 10h
    int 10h
    
    call configurar_ega
    
    mov pagina_actual, 0
    call actualizar_camara
    call renderizar_todo
    call cambiar_pagina

; BUCLE PRINCIPAL
bucle_juego:
    mov ah, 1
    int 16h
    jz bucle_juego
    
    mov ah, 0
    int 16h
    
    cmp al, 27
    je fin_juego
    
    ; Guardar posición anterior
    mov ax, jugador_x
    mov jugador_x_ant, ax
    mov ax, jugador_y
    mov jugador_y_ant, ax
    
    ; Procesar tecla
    cmp ah, 48h         ; Arriba
    je mover_arriba
    cmp al, 'w'
    je mover_arriba
    cmp al, 'W'
    je mover_arriba
    
    cmp ah, 50h         ; Abajo
    je mover_abajo
    cmp al, 's'
    je mover_abajo
    cmp al, 'S'
    je mover_abajo
    
    cmp ah, 4Bh         ; Izquierda
    je mover_izquierda
    cmp al, 'a'
    je mover_izquierda
    cmp al, 'A'
    je mover_izquierda
    
    cmp ah, 4Dh         ; Derecha
    je mover_derecha
    cmp al, 'd'
    je mover_derecha
    cmp al, 'D'
    je mover_derecha
    
    jmp bucle_juego

mover_arriba:
    cmp jugador_y, 1
    jbe no_mover
    dec jugador_y
    jmp verificar_movimiento

mover_abajo:
    cmp jugador_y, 48
    jae no_mover
    inc jugador_y
    jmp verificar_movimiento

mover_izquierda:
    cmp jugador_x, 1
    jbe no_mover
    dec jugador_x
    jmp verificar_movimiento

mover_derecha:
    cmp jugador_x, 48
    jae no_mover
    inc jugador_x

verificar_movimiento:
    call verificar_colision
    jnc movimiento_valido
    
    ; Colisión - restaurar
    mov ax, jugador_x_ant
    mov jugador_x, ax
    mov ax, jugador_y_ant
    mov jugador_y, ax
    jmp no_mover

movimiento_valido:
    ; Redibujar
    call actualizar_camara
    call renderizar_todo
    call cambiar_pagina

no_mover:
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
; CONFIGURAR EGA
; =====================================================
configurar_ega PROC
    push ax
    push dx
    
    ; Habilitar todos los planos
    mov dx, SC_INDEX
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    
    ; Write Mode 0
    mov dx, GC_INDEX
    mov al, 5
    out dx, al
    inc dx
    mov al, 0
    out dx, al
    
    ; Bit Mask = FF
    mov dx, GC_INDEX
    mov al, 8
    out dx, al
    inc dx
    mov al, 0FFh
    out dx, al
    
    pop dx
    pop ax
    ret
configurar_ega ENDP

; =====================================================
; CAMBIAR PÁGINA
; =====================================================
cambiar_pagina PROC
    push ax
    push dx
    
    xor pagina_actual, 1
    
    cmp pagina_actual, 0
    je cp_pag0
    mov ax, offset_pagina1
    jmp cp_escribir
    
cp_pag0:
    mov ax, offset_pagina0
    
cp_escribir:
    ; Start Address High
    mov dx, CRTC_INDEX
    push ax
    mov al, 0Ch
    out dx, al
    inc dx
    pop ax
    push ax
    mov al, ah
    out dx, al
    
    ; Start Address Low
    mov dx, CRTC_INDEX
    mov al, 0Dh
    out dx, al
    inc dx
    pop ax
    out dx, al
    
    pop dx
    pop ax
    ret
cambiar_pagina ENDP

; =====================================================
; RENDERIZAR TODO
; =====================================================
renderizar_todo PROC
    push ax
    push es
    
    mov ax, VIDEO_SEG
    mov es, ax
    
    call limpiar_pagina
    call dibujar_mapa
    call dibujar_jugador
    
    pop es
    pop ax
    ret
renderizar_todo ENDP

; =====================================================
; LIMPIAR PÁGINA
; =====================================================
limpiar_pagina PROC
    push ax
    push cx
    push di
    push es
    
    mov ax, VIDEO_SEG
    mov es, ax
    
    cmp pagina_actual, 0
    je lp_pag1
    mov di, offset_pagina0
    jmp lp_limpiar
    
lp_pag1:
    mov di, offset_pagina1
    
lp_limpiar:
    mov cx, 4000
    xor ax, ax
    
    ; Habilitar todos los planos
    push dx
    mov dx, SC_INDEX
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    pop dx
    
    rep stosw
    
    pop es
    pop di
    pop cx
    pop ax
    ret
limpiar_pagina ENDP

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
    
    xor bp, bp
    
dm_fila:
    cmp bp, VIEWPORT_H
    jb dm_f_ok
    jmp dm_fin
dm_f_ok:
    
    xor si, si
    
dm_columna:
    cmp si, VIEWPORT_W
    jb dm_c_ok
    jmp dm_next_f
dm_c_ok:
    
    ; Pos en mapa
    mov ax, camara_y
    add ax, bp
    cmp ax, 50
    jb dm_y_ok
    jmp dm_next_c
dm_y_ok:
    
    mov bx, camara_x
    add bx, si
    cmp bx, 50
    jb dm_xy_ok
    jmp dm_next_c
dm_xy_ok:
    
    ; Índice
    push dx
    mov dx, 50
    mul dx
    add ax, bx
    pop dx
    
    cmp ax, 2500
    jb dm_idx_ok
    jmp dm_next_c
dm_idx_ok:
    
    ; Obtener tile
    push si
    push di
    push bx
    mov bx, OFFSET mapa_datos
    add bx, ax
    mov al, [bx]
    pop bx
    pop di
    pop si
    
    ; Seleccionar sprite
    push si
    push bp
    
    cmp al, TILE_WALL
    jne dm_t2
    mov di, OFFSET sprite_wall
    jmp dm_draw
dm_t2:
    cmp al, TILE_PATH
    jne dm_t3
    mov di, OFFSET sprite_path
    jmp dm_draw
dm_t3:
    cmp al, TILE_WATER
    jne dm_t4
    mov di, OFFSET sprite_water
    jmp dm_draw
dm_t4:
    cmp al, TILE_TREE
    jne dm_t5
    mov di, OFFSET sprite_tree
    jmp dm_draw
dm_t5:
    mov di, OFFSET sprite_grass
    
dm_draw:
    pop bp
    pop si
    
    ; Pos pantalla
    mov ax, si
    mov cx, 16
    mul cx
    add ax, 240
    mov cx, ax
    
    mov ax, bp
    mov bx, 16
    mul bx
    add ax, 111
    mov dx, ax
    
    call dibujar_sprite_16x16
    
dm_next_c:
    inc si
    jmp dm_columna
    
dm_next_f:
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
    
    mov cx, 16
    mul cx
    add ax, 244
    mov cx, ax
    
    mov ax, bx
    mov dx, 16
    mul dx
    add ax, 115
    mov dx, ax
    
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
; DIBUJAR SPRITE 16x16 (BLOQUES 8x1)
; =====================================================
dibujar_sprite_16x16 PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    cmp cx, 624
    ja ds16_fin
    cmp dx, 334
    ja ds16_fin
    
    mov si, di
    xor bp, bp
    
ds16_fila:
    cmp bp, 16
    jae ds16_fin
    
    ; Calcular offset video
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
    je ds16_p1
    add di, offset_pagina0
    jmp ds16_linea
ds16_p1:
    add di, offset_pagina1
    
ds16_linea:
    ; Dibujar 16 píxeles = 2 bytes (8 píxeles/byte)
    push cx
    push dx
    
    mov cx, 2           ; 2 bytes
ds16_byte:
    mov bx, 8           ; 8 píxeles por byte
    xor ah, ah
    
ds16_pixel:
    lodsb
    cmp al, 0
    je ds16_skip
    
    ; Acumular píxel
    or ah, al
    
ds16_skip:
    dec bx
    jnz ds16_pixel
    
    ; Escribir byte completo
    mov es:[di], ah
    inc di
    
    loop ds16_byte
    
    pop dx
    pop cx
    
    inc bp
    jmp ds16_fila
    
ds16_fin:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_sprite_16x16 ENDP

; =====================================================
; DIBUJAR SPRITE 8x8
; =====================================================
dibujar_sprite_8x8 PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    mov si, di
    xor bp, bp
    
ds8_fila:
    cmp bp, 8
    jae ds8_fin
    
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
    
    cmp pagina_actual, 0
    je ds8_p1
    add di, offset_pagina0
    jmp ds8_linea
ds8_p1:
    add di, offset_pagina1
    
ds8_linea:
    push cx
    
    mov cx, 8
    xor ah, ah
    
ds8_pixel:
    lodsb
    cmp al, 0
    je ds8_skip
    or ah, al
    
ds8_skip:
    loop ds8_pixel
    
    mov es:[di], ah
    
    pop cx
    
    inc bp
    jmp ds8_fila
    
ds8_fin:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_sprite_8x8 ENDP

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
    sub ax, 5
    jge ac_x_ok
    xor ax, ax
ac_x_ok:
    mov bx, 40
    cmp ax, bx
    jle ac_x_fin
    mov ax, bx
ac_x_fin:
    mov camara_x, ax
    
    mov ax, jugador_y
    sub ax, 4
    jge ac_y_ok
    xor ax, ax
ac_y_ok:
    mov bx, 42
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
    jc cmap_error
    
    mov bx, ax
    mov ah, 3Fh
    mov cx, 20
    mov dx, OFFSET buffer_temp
    int 21h
    
    mov di, OFFSET mapa_datos
    xor bp, bp
    
cmap_leer:
    mov ah, 3Fh
    mov cx, 200
    mov dx, OFFSET buffer_temp
    int 21h
    
    cmp ax, 0
    je cmap_cerrar
    
    mov cx, ax
    xor si, si

cmap_proc:
    cmp si, cx
    jae cmap_leer

    mov al, [buffer_temp + si]
    inc si
    
    cmp al, ' '
    je cmap_proc
    cmp al, 13
    je cmap_proc
    cmp al, 10
    je cmap_proc
    cmp al, '0'
    jb cmap_proc
    cmp al, '9'
    ja cmap_proc
    
    sub al, '0'
    mov [di], al
    inc di
    inc bp

    cmp bp, 2500
    jb cmap_proc
    
cmap_cerrar:
    mov ah, 3Eh
    int 21h
    clc
    jmp cmap_fin
    
cmap_error:
    stc
    
cmap_fin:
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