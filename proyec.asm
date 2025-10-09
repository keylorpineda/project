; =====================================================
; JUEGO EGA RÁPIDO - Acceso Directo a Memoria de Video
; Universidad Nacional - Proyecto II Ciclo 2025
; Modo 10h (640x350, 16 colores) OPTIMIZADO
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
VIEWPORT_W  EQU 20      ; 20 tiles × 16px = 320px
VIEWPORT_H  EQU 12      ; 12 tiles × 16px = 192px

VIDEO_SEG   EQU 0A000h  ; Segmento de video EGA

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

; === OFFSET EN PANTALLA ===
viewport_x  dw 160      ; Centrado (640-320)/2
viewport_y  dw 79       ; Centrado (350-192)/2

; === MENSAJES ===
msg_titulo  db 'JUEGO EGA - Motor Rapido VRAM',13,10,'$'
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
    
    ; Primera renderización
    call actualizar_camara
    call renderizar_todo

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
    
    ; ESC
    cmp al, 27
    je fin_juego
    
    ; Mover
    call mover_jugador
    call actualizar_camara
    call renderizar_todo
    
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
; RENDERIZAR TODO (RÁPIDO!)
; =====================================================
renderizar_todo PROC
    push ax
    push es
    
    ; ES = segmento de video
    mov ax, VIDEO_SEG
    mov es, ax
    
    ; Limpiar viewport rápido
    call limpiar_viewport
    
    ; Dibujar mapa
    call dibujar_mapa_rapido
    
    ; Dibujar jugador
    call dibujar_jugador_rapido
    
    pop es
    pop ax
    ret
renderizar_todo ENDP

; =====================================================
; LIMPIAR VIEWPORT (Negro)
; =====================================================
limpiar_viewport PROC
    push ax
    push cx
    push di
    push es
    
    mov ax, VIDEO_SEG
    mov es, ax
    
    mov cx, VIEWPORT_H
    mov di, 0
    
lv_fila:
    push cx
    push di
    
    ; Calcular offset
    mov ax, viewport_y
    add ax, di
    mov bx, 80          ; 640/8 bytes por línea
    mul bx
    mov di, ax
    
    ; Añadir X
    mov ax, viewport_x
    shr ax, 3           ; /8
    add di, ax
    
    ; Escribir 40 bytes (320 píxeles / 8)
    mov cx, 40
    xor al, al
    rep stosb
    
    pop di
    pop cx
    inc di
    loop lv_fila
    
    pop es
    pop di
    pop cx
    pop ax
    ret
limpiar_viewport ENDP

; =====================================================
; DIBUJAR MAPA RÁPIDO
; =====================================================
dibujar_mapa_rapido PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    xor bp, bp          ; BP = fila viewport
    
dmr_fila:
    cmp bp, VIEWPORT_H
    jae dmr_fin
    
    xor si, si          ; SI = columna viewport
    
dmr_col:
    cmp si, VIEWPORT_W
    jae dmr_next_fila
    
    ; Calcular posición en mapa
    mov ax, camara_y
    add ax, bp
    cmp ax, 50
    jae dmr_next_col
    
    mov bx, camara_x
    add bx, si
    cmp bx, 50
    jae dmr_next_col
    
    ; Índice en mapa
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
    jne dmr_check_path
    mov di, OFFSET sprite_wall
    jmp dmr_draw

dmr_check_path:
    cmp al, TILE_PATH
    jne dmr_check_water
    mov di, OFFSET sprite_path
    jmp dmr_draw

dmr_check_water:
    cmp al, TILE_WATER
    jne dmr_check_tree
    mov di, OFFSET sprite_water
    jmp dmr_draw

dmr_check_tree:
    cmp al, TILE_TREE
    jne dmr_draw
    mov di, OFFSET sprite_tree

dmr_draw:
    ; Calcular posición en pantalla
    push si
    push bp
    
    mov ax, si
    shl ax, 4           ; *16
    add ax, viewport_x
    mov cx, ax          ; CX = X
    
    mov ax, bp
    shl ax, 4           ; *16
    add ax, viewport_y
    mov dx, ax          ; DX = Y
    
    call dibujar_sprite_16x16_vram
    
    pop bp
    pop si
    
dmr_next_col:
    inc si
    jmp dmr_col
    
dmr_next_fila:
    inc bp
    jmp dmr_fila
    
dmr_fin:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_mapa_rapido ENDP

; =====================================================
; DIBUJAR JUGADOR RÁPIDO
; =====================================================
dibujar_jugador_rapido PROC
    push ax
    push bx
    push cx
    push dx
    
    ; Posición relativa
    mov ax, jugador_x
    sub ax, camara_x
    cmp ax, VIEWPORT_W
    jae djr_fin
    
    mov bx, jugador_y
    sub bx, camara_y
    cmp bx, VIEWPORT_H
    jae djr_fin
    
    ; Calcular pantalla
    shl ax, 4
    add ax, viewport_x
    add ax, 4           ; Centrar 8x8 en tile 16x16
    mov cx, ax
    
    mov ax, bx
    shl ax, 4
    add ax, viewport_y
    add ax, 4
    mov dx, ax
    
    mov si, OFFSET sprite_player
    call dibujar_sprite_8x8_vram
    
djr_fin:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_jugador_rapido ENDP

; =====================================================
; DIBUJAR SPRITE 16x16 EN VRAM
; CX=X, DX=Y, DI=sprite, ES=A000h
; =====================================================
dibujar_sprite_16x16_vram PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    mov si, di
    mov bp, 16          ; Filas
    
ds16v_fila:
    push cx
    push bp
    mov bp, 16          ; Columnas
    
ds16v_pixel:
    lodsb
    cmp al, 0
    je ds16v_skip
    
    ; Escribir píxel en VRAM (modo planar)
    call escribir_pixel_ega
    
ds16v_skip:
    inc cx
    dec bp
    jnz ds16v_pixel
    
    pop bp
    pop cx
    inc dx
    dec bp
    jnz ds16v_fila
    
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_sprite_16x16_vram ENDP

; =====================================================
; DIBUJAR SPRITE 8x8 EN VRAM
; CX=X, DX=Y, SI=sprite, ES=A000h
; =====================================================
dibujar_sprite_8x8_vram PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push bp
    
    mov bp, 8
    
ds8v_fila:
    push cx
    push bp
    mov bp, 8
    
ds8v_pixel:
    lodsb
    cmp al, 0
    je ds8v_skip
    
    call escribir_pixel_ega
    
ds8v_skip:
    inc cx
    dec bp
    jnz ds8v_pixel
    
    pop bp
    pop cx
    inc dx
    dec bp
    jnz ds8v_fila
    
    pop bp
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_sprite_8x8_vram ENDP

; =====================================================
; ESCRIBIR PÍXEL EGA (Modo Planar 16 colores)
; CX=X, DX=Y, AL=color, ES=A000h
; =====================================================
escribir_pixel_ega PROC
    push ax
    push bx
    push cx
    push dx
    push di
    
    ; Calcular offset = (Y * 80) + (X / 8)
    mov ax, dx
    mov bx, 80
    mul bx
    mov di, ax
    
    mov ax, cx
    mov bx, ax
    shr ax, 3
    add di, ax
    
    ; Bit dentro del byte
    and bx, 7
    mov cl, bl
    mov bl, 80h
    shr bl, cl          ; Máscara de bit
    
    ; AL = color a escribir
    pop dx
    push dx
    mov al, dl
    
    ; Configurar registros EGA
    mov dx, 3CEh        ; Graphics Controller
    
    ; Set/Reset Register (índice 0)
    mov ah, al
    mov al, 0
    out dx, ax
    
    ; Enable Set/Reset (índice 1) - todos los planos
    mov ax, 0F01h
    out dx, ax
    
    ; Bit Mask (índice 8)
    mov ah, bl
    mov al, 8
    out dx, ax
    
    ; Escribir (lee-modifica-escribe automático)
    mov al, es:[di]
    mov es:[di], al
    
    ; Restaurar Bit Mask
    mov ax, 0FF08h
    out dx, ax
    
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
escribir_pixel_ega ENDP

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
    sub ax, 10          ; VIEWPORT_W / 2
    jge ac_x_ok
    xor ax, ax
ac_x_ok:
    mov bx, 30          ; 50 - 20
    cmp ax, bx
    jle ac_x_fin
    mov ax, bx
ac_x_fin:
    mov camara_x, ax
    
    mov ax, jugador_y
    sub ax, 6           ; VIEWPORT_H / 2
    jge ac_y_ok
    xor ax, ax
ac_y_ok:
    mov bx, 38          ; 50 - 12
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