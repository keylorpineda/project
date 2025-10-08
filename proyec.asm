; JUEGO DE EXPLORACIÓN - CORREGIDO
; Universidad Nacional - Proyecto II Ciclo 2025
; TASM 8086 - Modo EGA 640x350 - VRAM directa

.MODEL SMALL
.STACK 2048

; === CONSTANTES ===
TILE_GRASS  EQU 0
TILE_WALL   EQU 1
TILE_PATH   EQU 2
TILE_WATER  EQU 3
TILE_TREE   EQU 4

TILE_SIZE   EQU 32
VIDEO_SEG   EQU 0A000h

.DATA
; === ARCHIVOS ===
archivo_mapa    db 'mapa.txt',0
archivo_grass   db 'grass.spr',0
archivo_wall    db 'wall.spr',0
archivo_path    db 'path.spr',0
archivo_water   db 'water.spr',0
archivo_tree    db 'tree.spr',0
archivo_player  db 'player.spr',0

; === MAPA ===
mapa_ancho  dw 0
mapa_alto   dw 0
mapa_datos  db 240 dup(0)

; === JUGADOR ===
jugador_x   dw 1
jugador_y   dw 1

; === CÁMARA ===
camara_x    dw 0
camara_y   dw 0

; === SPRITES ===
spr_grass   dw 0, 0
            db 256 dup(0)
spr_wall    dw 0, 0
            db 256 dup(0)
spr_path    dw 0, 0
            db 256 dup(0)
spr_water   dw 0, 0
            db 256 dup(0)
spr_tree    dw 0, 0
            db 256 dup(0)
spr_player  dw 0, 0
            db 64 dup(0)

; === BUFFER ===
buffer_temp db 1024 dup(0)
handle_arch dw 0

; === VARIABLES TEMP ===
temp_x      dw 0
temp_y      dw 0
temp_color  db 0

; === MENSAJES ===
msg_inicio  db 'Cargando archivos...',13,10,'$'
msg_listo   db 'Listo! ESC=Salir WASD/Flechas=Mover',13,10,'$'
msg_error   db 'Error cargando archivos',13,10,'$'

.CODE
inicio:
    mov ax, @data
    mov ds, ax
    
    mov dx, OFFSET msg_inicio
    mov ah, 9
    int 21h
    
    call cargar_mapa
    jc error_carga
    
    call cargar_sprites
    jc error_carga
    
    mov dx, OFFSET msg_listo
    mov ah, 9
    int 21h
    
    mov ah, 0
    int 16h
    
    ; Modo EGA 640x350
    mov ax, 10h
    int 10h
    
    call actualizar_camara
    call limpiar_pantalla
    call renderizar_todo
    
bucle_principal:
    mov ah, 1
    int 16h
    jz bucle_principal
    
    mov ah, 0
    int 16h
    
    cmp al, 27
    je salir_juego
    
    mov ax, jugador_x
    push ax
    mov ax, jugador_y
    push ax
    
    call mover_jugador
    call verificar_colision
    jc restaurar_posicion
    
    add sp, 4
    call actualizar_camara
    call limpiar_pantalla
    call renderizar_todo
    jmp bucle_principal
    
restaurar_posicion:
    pop ax
    mov jugador_y, ax
    pop ax
    mov jugador_x, ax
    jmp bucle_principal

error_carga:
    mov dx, OFFSET msg_error
    mov ah, 9
    int 21h
    mov ah, 0
    int 16h
    
salir_juego:
    mov ax, 3
    int 10h
    mov ax, 4C00h
    int 21h

; ========================================
; LIMPIAR PANTALLA
; ========================================
limpiar_pantalla PROC
    push ax
    push cx
    push di
    push es
    
    mov ax, VIDEO_SEG
    mov es, ax
    xor di, di
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    
    mov cx, 32000
    xor ax, ax
    rep stosb
    
    pop es
    pop di
    pop cx
    pop ax
    ret
limpiar_pantalla ENDP

; ========================================
; DIBUJAR PIXEL EGA
; CX = X, DX = Y, AL = color
; ========================================
dibujar_pixel PROC
    push ax
    push bx
    push cx
    push dx
    push di
    push es
    
    ; Offset = Y * 80 + X / 8
    mov di, dx
    mov bx, 80
    mov ax, di
    mul bx
    mov di, ax
    
    mov ax, cx
    mov bx, cx
    shr ax, 1
    shr ax, 1
    shr ax, 1
    add di, ax
    
    ; Máscara bit
    and bl, 7
    mov cl, bl
    mov ah, 80h
    shr ah, cl
    
    mov bx, VIDEO_SEG
    mov es, bx
    
    ; Bit mask
    mov dx, 3CEh
    mov al, 8
    out dx, al
    inc dx
    mov al, ah
    out dx, al
    
    ; Leer para latches
    mov al, es:[di]
    
    ; Set/Reset con color
    mov dx, 3CEh
    mov al, 0
    out dx, al
    inc dx
    pop es
    push es
    pop bx
    push bx
    mov al, bl
    and al, 0Fh
    out dx, al
    
    ; Enable Set/Reset
    mov dx, 3CEh
    mov al, 1
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    
    ; Escribir
    pop es
    push es
    mov byte ptr es:[di], 0FFh
    
    ; Restaurar
    mov dx, 3CEh
    mov al, 1
    out dx, al
    inc dx
    mov al, 0
    out dx, al
    
    mov dx, 3CEh
    mov al, 8
    out dx, al
    inc dx
    mov al, 0FFh
    out dx, al
    
    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_pixel ENDP

; ========================================
; CARGAR MAPA
; ========================================
cargar_mapa PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov dx, OFFSET archivo_mapa
    mov ax, 3D00h
    int 21h
    jc cm_error
    mov handle_arch, ax
    
    mov bx, ax
    mov dx, OFFSET buffer_temp
    mov cx, 1024
    mov ah, 3Fh
    int 21h
    jc cm_error_cerrar
    
    mov bx, handle_arch
    mov ah, 3Eh
    int 21h
    
    mov si, OFFSET buffer_temp
    mov di, OFFSET mapa_datos
    
    call leer_numero
    mov mapa_ancho, ax
    
    call leer_numero
    mov mapa_alto, ax
    
    xor cx, cx
cm_leer_tiles:
    cmp cx, 240
    jge cm_fin
    
    call leer_numero
    mov byte ptr [di], al
    inc di
    inc cx
    jmp cm_leer_tiles
    
cm_fin:
    clc
    jmp cm_salir
    
cm_error_cerrar:
    mov bx, handle_arch
    mov ah, 3Eh
    int 21h
    
cm_error:
    stc
    
cm_salir:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
cargar_mapa ENDP

; ========================================
; LEER NÚMERO
; ========================================
leer_numero PROC
    push bx
    push cx
    push dx
    
    xor ax, ax
    xor bx, bx
    
ln_loop:
    lodsb
    cmp al, ' '
    je ln_loop
    cmp al, 9
    je ln_loop
    cmp al, 13
    je ln_loop
    cmp al, 10
    je ln_loop
    cmp al, '0'
    jl ln_fin
    cmp al, '9'
    jg ln_fin
    
    sub al, '0'
    mov cl, al
    mov ax, bx
    mov dx, 10
    mul dx
    add al, cl
    adc ah, 0
    mov bx, ax
    jmp ln_loop
    
ln_fin:
    mov ax, bx
    pop dx
    pop cx
    pop bx
    ret
leer_numero ENDP

; ========================================
; CARGAR SPRITES
; ========================================
cargar_sprites PROC
    push ax
    
    mov dx, OFFSET archivo_grass
    mov di, OFFSET spr_grass
    call cargar_sprite
    jc cs_error
    
    mov dx, OFFSET archivo_wall
    mov di, OFFSET spr_wall
    call cargar_sprite
    jc cs_error
    
    mov dx, OFFSET archivo_path
    mov di, OFFSET spr_path
    call cargar_sprite
    jc cs_error
    
    mov dx, OFFSET archivo_water
    mov di, OFFSET spr_water
    call cargar_sprite
    jc cs_error
    
    mov dx, OFFSET archivo_tree
    mov di, OFFSET spr_tree
    call cargar_sprite
    jc cs_error
    
    mov dx, OFFSET archivo_player
    mov di, OFFSET spr_player
    call cargar_sprite
    jc cs_error
    
    clc
    jmp cs_fin
    
cs_error:
    stc
    
cs_fin:
    pop ax
    ret
cargar_sprites ENDP

; ========================================
; CARGAR UN SPRITE
; ========================================
cargar_sprite PROC
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov ax, 3D00h
    int 21h
    jc csp_error
    mov handle_arch, ax
    
    mov bx, ax
    mov dx, OFFSET buffer_temp
    mov cx, 1024
    mov ah, 3Fh
    int 21h
    jc csp_error_cerrar
    
    mov bx, handle_arch
    mov ah, 3Eh
    int 21h
    
    mov si, OFFSET buffer_temp
    
    call leer_numero
    mov word ptr [di], ax
    add di, 2
    
    call leer_numero
    mov word ptr [di], ax
    add di, 2
    
csp_leer_pixeles:
    lodsb
    cmp al, 0
    je csp_fin
    cmp al, ' '
    je csp_leer_pixeles
    cmp al, 9
    je csp_leer_pixeles
    cmp al, 13
    je csp_leer_pixeles
    cmp al, 10
    je csp_leer_pixeles
    
    call hex_a_numero
    mov byte ptr [di], al
    inc di
    jmp csp_leer_pixeles
    
csp_fin:
    clc
    jmp csp_salir
    
csp_error_cerrar:
    mov bx, handle_arch
    mov ah, 3Eh
    int 21h
    
csp_error:
    stc
    
csp_salir:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
cargar_sprite ENDP

; ========================================
; HEX A NÚMERO
; ========================================
hex_a_numero PROC
    cmp al, '0'
    jl han_letra
    cmp al, '9'
    jg han_letra
    sub al, '0'
    ret
    
han_letra:
    cmp al, 'A'
    jl han_minuscula
    cmp al, 'F'
    jg han_minuscula
    sub al, 'A'
    add al, 10
    ret
    
han_minuscula:
    sub al, 'a'
    add al, 10
    ret
hex_a_numero ENDP

; ========================================
; MOVER JUGADOR
; ========================================
mover_jugador PROC
    cmp ah, 48h
    je mj_arriba
    cmp ah, 50h
    je mj_abajo
    cmp ah, 4Bh
    je mj_izquierda
    cmp ah, 4Dh
    je mj_derecha
    
    cmp al, 'w'
    je mj_arriba
    cmp al, 'W'
    je mj_arriba
    cmp al, 's'
    je mj_abajo
    cmp al, 'S'
    je mj_abajo
    cmp al, 'a'
    je mj_izquierda
    cmp al, 'A'
    je mj_izquierda
    cmp al, 'd'
    je mj_derecha
    cmp al, 'D'
    je mj_derecha
    ret
    
mj_arriba:
    dec word ptr jugador_y
    ret
mj_abajo:
    inc word ptr jugador_y
    ret
mj_izquierda:
    dec word ptr jugador_x
    ret
mj_derecha:
    inc word ptr jugador_x
    ret
mover_jugador ENDP

; ========================================
; VERIFICAR COLISIÓN
; ========================================
verificar_colision PROC
    push ax
    push bx
    push si
    
    cmp word ptr jugador_x, 0
    jl vc_colision
    cmp word ptr jugador_y, 0
    jl vc_colision
    
    mov ax, jugador_x
    cmp ax, mapa_ancho
    jge vc_colision
    
    mov ax, jugador_y
    cmp ax, mapa_alto
    jge vc_colision
    
    mov ax, jugador_y
    mov bx, mapa_ancho
    mul bx
    add ax, jugador_x
    mov si, ax
    add si, OFFSET mapa_datos
    mov al, byte ptr [si]
    
    cmp al, TILE_GRASS
    je vc_libre
    cmp al, TILE_PATH
    je vc_libre
    
vc_colision:
    stc
    jmp vc_fin
    
vc_libre:
    clc
    
vc_fin:
    pop si
    pop bx
    pop ax
    ret
verificar_colision ENDP

; ========================================
; ACTUALIZAR CÁMARA
; ========================================
actualizar_camara PROC
    push ax
    push bx
    
    mov ax, jugador_x
    sub ax, 10
    cmp ax, 0
    jge ac_x_ok1
    xor ax, ax
ac_x_ok1:
    mov bx, mapa_ancho
    sub bx, 20
    cmp bx, 0
    jge ac_x_check
    xor bx, bx
ac_x_check:
    cmp ax, bx
    jle ac_x_ok2
    mov ax, bx
ac_x_ok2:
    mov camara_x, ax
    
    mov ax, jugador_y
    sub ax, 5
    cmp ax, 0
    jge ac_y_ok1
    xor ax, ax
ac_y_ok1:
    mov bx, mapa_alto
    sub bx, 10
    cmp bx, 0
    jge ac_y_check
    xor bx, bx
ac_y_check:
    cmp ax, bx
    jle ac_y_ok2
    mov ax, bx
ac_y_ok2:
    mov camara_y, ax
    
    pop bx
    pop ax
    ret
actualizar_camara ENDP

; ========================================
; RENDERIZAR TODO
; ========================================
renderizar_todo PROC
    push ax
    push bx
    push cx
    push dx
    
    mov dx, 0
rt_fila:
    cmp dx, 10
    jge rt_fin_tiles
    
    mov cx, 0
rt_columna:
    cmp cx, 20
    jge rt_fin_columna
    
    push cx
    push dx
    
    mov ax, camara_y
    add ax, dx
    mov bx, mapa_ancho
    mul bx
    add ax, camara_x
    add ax, cx
    
    cmp ax, 240
    jge rt_skip
    
    mov si, ax
    add si, OFFSET mapa_datos
    mov al, byte ptr [si]
    
    pop dx
    pop cx
    
    push cx
    push dx
    call dibujar_tile
    pop dx
    pop cx
    jmp rt_siguiente
    
rt_skip:
    pop dx
    pop cx
    
rt_siguiente:
    inc cx
    jmp rt_columna
    
rt_fin_columna:
    inc dx
    jmp rt_fila
    
rt_fin_tiles:
    call dibujar_jugador
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
renderizar_todo ENDP

; ========================================
; DIBUJAR TILE
; AL = tipo, CX = col, DX = fila
; ========================================
dibujar_tile PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Seleccionar sprite
    mov si, OFFSET spr_grass
    cmp al, TILE_WALL
    jne dt_1
    mov si, OFFSET spr_wall
    jmp dt_draw
dt_1:
    cmp al, TILE_PATH
    jne dt_2
    mov si, OFFSET spr_path
    jmp dt_draw
dt_2:
    cmp al, TILE_WATER
    jne dt_3
    mov si, OFFSET spr_water
    jmp dt_draw
dt_3:
    cmp al, TILE_TREE
    jne dt_draw
    mov si, OFFSET spr_tree
    
dt_draw:
    ; Calcular posición pantalla
    mov ax, cx
    mov bx, TILE_SIZE
    mul bx
    mov temp_x, ax
    
    mov ax, dx
    mov bx, TILE_SIZE
    mul bx
    mov temp_y, ax
    
    add si, 4
    
    ; ✅ DIBUJAR RECTÁNGULO SÓLIDO SIMPLE (más rápido y sin errores)
    mov bl, 2                   ; Color por defecto (verde)
    mov al, byte ptr [si]       ; Primer pixel del sprite
    cmp al, 0
    je dt_fin                   ; Si transparente, no dibujar
    mov bl, al                  ; Usar color del sprite
    
    ; Dibujar rectángulo 32x32
    mov di, 0                   ; Contador Y
dt_y_loop:
    cmp di, 32
    jae dt_fin                  ; ✅ CAMBIAR JGE por JAE
    
    push di
    push cx
    push dx
    
    mov ax, 0                   ; Contador X
dt_x_loop:
    cmp ax, 32
    jae dt_x_next               ; ✅ CAMBIAR JGE por JAE
    
    push ax
    
    ; Calcular posición pixel
    add cx, ax                  ; X final
    add dx, di                  ; Y final
    mov al, bl                  ; Color
    call dibujar_pixel
    
    pop ax
    sub cx, ax                  ; Restaurar X base
    sub dx, di                  ; Restaurar Y base
    
    inc ax
    jmp dt_x_loop
    
dt_x_next:
    pop dx
    pop cx
    pop di
    inc di
    jmp dt_y_loop
    
dt_fin:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_tile ENDP

; ========================================
; DIBUJAR JUGADOR
; ========================================
dibujar_jugador PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    mov ax, jugador_x
    sub ax, camara_x
    cmp ax, 0
    jl djr_salir_inmediato
    cmp ax, 20
    jge djr_salir_inmediato

    mov bx, TILE_SIZE
    mul bx
    mov temp_x, ax

    mov ax, jugador_y
    sub ax, camara_y
    cmp ax, 0
    jl djr_salir_inmediato
    cmp ax, 10
    jge djr_salir_inmediato

    mov bx, TILE_SIZE
    mul bx
    mov temp_y, ax

    jmp short djr_continuar

djr_salir_inmediato:
    jmp djr_fin

djr_continuar:
    mov si, OFFSET spr_player
    add si, 4
    
    mov bp, 0
djr_y:
    cmp bp, 8
    jge djr_done
    
    mov di, 0
djr_x:
    cmp di, 8
    jge djr_next_y
    
    push si
    mov ax, bp
    mov bx, 8
    mul bx
    add ax, di
    add si, ax
    mov bl, byte ptr [si]
    pop si
    
    cmp bl, 0
    je djr_skip
    
    mov temp_color, bl
    
    ; Pixel (0,0)
    mov ax, di
    shl ax, 1
    add ax, temp_x
    mov cx, ax
    mov ax, bp
    shl ax, 1
    add ax, temp_y
    mov dx, ax
    mov al, temp_color
    call dibujar_pixel
    
    ; Pixel (1,0)
    inc cx
    mov al, temp_color
    call dibujar_pixel
    
    ; Pixel (0,1)
    dec cx
    inc dx
    mov al, temp_color
    call dibujar_pixel
    
    ; Pixel (1,1)
    inc cx
    mov al, temp_color
    call dibujar_pixel
    
djr_skip:
    inc di
    jmp djr_x
    
djr_next_y:
    inc bp
    jmp djr_y
    
djr_done:
djr_fin:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_jugador ENDP

; ========================================
; DIBUJAR JUGADOR RÁPIDO - ULTRA COMPACTO
; ========================================
dibujar_jugador_rapido PROC
    push ax
    push bx
    push cx
    push dx
    
    ; Verificar si está en viewport
    mov ax, jugador_x
    sub ax, camara_x
    cmp ax, 10
    jae djr_salir
    
    mov bx, jugador_y
    sub bx, camara_y
    cmp bx, 6
    jae djr_salir
    
    ; Calcular posición base
    mov cx, ax
    shl cx, 4               ; X * 16
    add cx, 4
    
    mov dx, bx
    shl dx, 4               ; Y * 16  
    add dx, 4
    
    ; ✅ DIBUJAR 4 PIXELS EN LUGAR DE 64 (más rápido)
    mov al, 14              ; Amarillo
    mov ah, 0Ch
    mov bh, 0
    
    ; Pixel 1
    int 10h
    inc cx
    ; Pixel 2  
    int 10h
    inc dx
    ; Pixel 3
    int 10h
    dec cx
    ; Pixel 4
    int 10h
    
djr_salir:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_jugador_rapido ENDP

END inicio
