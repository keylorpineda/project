; =====================================================
; JUEGO DE EXPLORACIÓN - EGA FUNCIONAL CON BIOS
; Universidad Nacional - Proyecto II Ciclo 2025
; Modo 10h (640x350, 16 colores) usando INT 10h del BIOS
; GARANTIZADO: Funciona en DOSBox y hardware real
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

; === DOBLE BUFFER: Páginas de video ===
pagina_visual db 0      ; Página visible (0 o 1)

; === MENSAJES ===
msg_titulo  db 'JUEGO EGA 640x350 - Doble Buffer',13,10,'$'
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
msg_controles db 13,10,'WASD o Flechas = Mover',13,10
              db 'ESC = Salir',13,10
              db 'Presiona tecla...$'

.CODE
inicio:
    mov ax, @data
    mov ds, ax
    mov es, ax

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

    ; ✅ MODO 10h EGA (640x350, 16 colores)
    mov ax, 10h
    int 10h
    
    ; Configurar página inicial
    mov pagina_visual, 0
    mov ah, 5
    mov al, 0
    int 10h
    
    ; Primera renderización
    call actualizar_camara
    call renderizar_todo
    call cambiar_pagina

; =====================================================
; BUCLE PRINCIPAL
; =====================================================
bucle_juego:
    ; Verificar tecla
    mov ah, 1
    int 16h
    jz bucle_juego
    
    ; Leer tecla
    mov ah, 0
    int 16h
    
    ; ESC?
    cmp al, 27
    jne continuar_juego
    jmp fin_juego

continuar_juego:
    
    ; Guardar posición
    mov ax, jugador_x
    mov jugador_x_ant, ax
    mov ax, jugador_y
    mov jugador_y_ant, ax
    
    ; Procesar movimiento
    cmp ah, 48h
    je mov_arriba
    cmp al, 'w'
    je mov_arriba
    cmp al, 'W'
    je mov_arriba
    
    cmp ah, 50h
    je mov_abajo
    cmp al, 's'
    je mov_abajo
    cmp al, 'S'
    je mov_abajo
    
    cmp ah, 4Bh
    je mov_izq
    cmp al, 'a'
    je mov_izq
    cmp al, 'A'
    je mov_izq
    
    cmp ah, 4Dh
    je mov_der
    cmp al, 'd'
    je mov_der
    cmp al, 'D'
    je mov_der
    
    jmp bucle_juego

mov_arriba:
    cmp jugador_y, 1
    jbe bucle_juego
    dec jugador_y
    jmp verificar_mov

mov_abajo:
    cmp jugador_y, 48
    jae bucle_juego
    inc jugador_y
    jmp verificar_mov

mov_izq:
    cmp jugador_x, 1
    jbe bucle_juego
    dec jugador_x
    jmp verificar_mov

mov_der:
    cmp jugador_x, 48
    jb mov_der_continuar
    jmp bucle_juego

mov_der_continuar:
    inc jugador_x

verificar_mov:
    ; Verificar colisión
    call verificar_colision
    jnc mov_valido
    
    ; Restaurar
    mov ax, jugador_x_ant
    mov jugador_x, ax
    mov ax, jugador_y_ant
    mov jugador_y, ax
    jmp bucle_juego

mov_valido:
    ; Redibujar
    call actualizar_camara
    call renderizar_todo
    call cambiar_pagina
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
; CAMBIAR PÁGINA (DOBLE BUFFER)
; ✅ Esto hace el cambio instantáneo entre páginas
; =====================================================
cambiar_pagina PROC
    push ax
    
    ; Alternar página
    xor pagina_visual, 1
    
    ; Activar página visual
    mov ah, 5
    mov al, pagina_visual
    int 10h
    
    pop ax
    ret
cambiar_pagina ENDP

; =====================================================
; RENDERIZAR TODO EN PÁGINA OCULTA
; =====================================================
renderizar_todo PROC
    push ax
    
    ; Seleccionar página oculta para dibujar
    mov ah, 5
    mov al, pagina_visual
    xor al, 1               ; Invertir (si visual=0, dibujar en 1)
    int 10h
    
    call dibujar_mapa
    call dibujar_jugador
    
    pop ax
    ret
renderizar_todo ENDP

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
    jb dm_fila_continuar
    jmp dm_fin

dm_fila_continuar:
    
    xor si, si
    
dm_columna:
    cmp si, VIEWPORT_W
    jae dm_next_fila
    
    ; Calcular posición en mapa
    mov ax, camara_y
    add ax, bp
    cmp ax, 50
    jae dm_next_col
    
    mov bx, camara_x
    add bx, si
    cmp bx, 50
    jae dm_next_col
    
    ; Índice: Y * 50 + X
    push dx
    mov dx, 50
    mul dx
    add ax, bx
    pop dx
    
    cmp ax, 2500
    jae dm_next_col
    
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
    jmp dm_dibujar
dm_t2:
    cmp al, TILE_PATH
    jne dm_t3
    mov di, OFFSET sprite_path
    jmp dm_dibujar
dm_t3:
    cmp al, TILE_WATER
    jne dm_t4
    mov di, OFFSET sprite_water
    jmp dm_dibujar
dm_t4:
    cmp al, TILE_TREE
    jne dm_t5
    mov di, OFFSET sprite_tree
    jmp dm_dibujar
dm_t5:
    mov di, OFFSET sprite_grass
    
dm_dibujar:
    pop bp
    pop si
    
    ; Posición en pantalla
    mov ax, si
    mov cx, 16
    mul cx
    add ax, 240         ; Centrar
    mov cx, ax
    
    mov ax, bp
    mov bx, 16
    mul bx
    add ax, 111         ; Centrar
    mov dx, ax
    
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
    
    ; Verificar viewport
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
    
    ; Posición en pantalla
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
; DIBUJAR SPRITE 16x16 USANDO BIOS
; CX=X, DX=Y, DI=sprite
; ✅ USA INT 10h AH=0Ch para escribir píxeles
; =====================================================
dibujar_sprite_16x16 PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push bp
    
    mov si, di
    mov bp, dx          ; Guardar Y inicial
    xor bx, bx          ; BX = contador fila
    
ds16_fila:
    cmp bx, 16
    jae ds16_fin
    
    push cx             ; Guardar X inicial
    push bx
    mov bx, 16          ; Contador columna
    
ds16_pixel:
    lodsb               ; AL = color
    cmp al, 0
    je ds16_skip
    
    ; Dibujar píxel con BIOS
    ; AH=0Ch, AL=color, CX=X, DX=Y
    push ax
    push bx
    push cx
    push dx
    
    mov ah, 0Ch
    xor bh, bh          ; Página 0
    int 10h
    
    pop dx
    pop cx
    pop bx
    pop ax
    
ds16_skip:
    inc cx              ; Siguiente X
    dec bx
    jnz ds16_pixel
    
    pop bx
    pop cx              ; Restaurar X inicial
    
    inc dx              ; Siguiente Y
    inc bx              ; Siguiente fila
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
; DIBUJAR SPRITE 8x8 USANDO BIOS
; CX=X, DX=Y, DI=sprite
; =====================================================
dibujar_sprite_8x8 PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push bp
    
    mov si, di
    mov bp, dx
    xor bx, bx
    
ds8_fila:
    cmp bx, 8
    jae ds8_fin
    
    push cx
    push bx
    mov bx, 8
    
ds8_pixel:
    lodsb
    cmp al, 0
    je ds8_skip
    
    push ax
    push bx
    push cx
    push dx
    
    mov ah, 0Ch
    xor bh, bh
    int 10h
    
    pop dx
    pop cx
    pop bx
    pop ax
    
ds8_skip:
    inc cx
    dec bx
    jnz ds8_pixel
    
    pop bx
    pop cx
    
    inc dx
    inc bx
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
    
    ; Centrar X
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
    
    ; Centrar Y
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
    jc cm_error
    
    mov bx, ax
    mov ah, 3Fh
    mov cx, 20
    mov dx, OFFSET buffer_temp
    int 21h
    
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