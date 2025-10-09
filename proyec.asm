; =====================================================
; JUEGO DE EXPLORACIÓN - MODO EGA 0Dh (320x200x16)
; CON DOBLE BUFFER REAL EN RAM
; Universidad Nacional - Proyecto II Ciclo 2025
; =====================================================

.MODEL SMALL
.STACK 4096

; === CONSTANTES ===
TILE_GRASS  EQU 0
TILE_WALL   EQU 1
TILE_PATH   EQU 2
TILE_WATER  EQU 3
TILE_TREE   EQU 4

TILE_SIZE   EQU 16
SCREEN_W    EQU 320
SCREEN_H    EQU 200
VIEWPORT_W  EQU 20
VIEWPORT_H  EQU 12

.DATA
; === ARCHIVOS ===
archivo_mapa db 'MAPA.TXT',0

; === MAPA ===
mapa_ancho  dw 100
mapa_alto   dw 100
mapa_datos  db 10000 dup(0)

; === JUGADOR ===
jugador_x   dw 10
jugador_y   dw 10
jugador_x_ant dw 10
jugador_y_ant dw 10

; === CÁMARA ===
camara_x    dw 0
camara_y    dw 0

; === DOBLE BUFFER DINÁMICO ===
back_buffer_seg dw 0

; === BUFFER ARCHIVO ===
buffer_archivo db 4096 dup(0)
handle_arch dw 0
buffer_pos dw 0

; === MENSAJES ===
msg_titulo  db 'JUEGO DE EXPLORACION - EGA + DOBLE BUFFER',13,10
           db '==========================================',13,10,'$'
msg_cargando db 'Cargando MAPA.TXT...$'
msg_generando db 'Generando mapa...$'
msg_ok     db 'OK',13,10,'$'
msg_dim    db 'Mapa: $'
msg_x      db 'x$'
msg_listo  db 13,10,'Viewport: 20x12 tiles (320x192 px)',13,10
           db 'Controles: Flechas/WASD = Mover, ESC = Salir',13,10
           db 'Presiona tecla...$'
msg_archivo_ok db ' Encontrado!',13,10,'$'
msg_no_archivo db ' No encontrado.',13,10,'$'
msg_mem_ok db 'Buffer asignado: 64KB',13,10,'$'
msg_mem_fail db 'ERROR: Sin memoria.',13,10,'$'

.CODE
inicio:
    mov ax, @data
    mov ds, ax
    mov es, ax

    ; Título
    mov dx, OFFSET msg_titulo
    mov ah, 9
    int 21h

    ; Cargar mapa
    mov dx, OFFSET msg_cargando
    mov ah, 9
    int 21h
    call cargar_mapa_seguro

    ; Asignar buffer
    call init_back_buffer
    jc sin_memoria

    ; Listo
    mov dx, OFFSET msg_listo
    mov ah, 9
    int 21h
    mov ah, 0
    int 16h

    ; Modo gráfico
    mov ax, 0Dh
    int 10h
    
    call init_ega
    call actualizar_camara
    call renderizar

bucle_juego:
    mov ah, 1
    int 16h
    jz bucle_juego

    mov ah, 0
    int 16h
    
    cmp al, 27
    je terminar

    call mover_jugador
    call actualizar_camara
    call renderizar
    
    jmp bucle_juego

sin_memoria:
    mov dx, OFFSET msg_mem_fail
    mov ah, 9
    int 21h

terminar:
    mov ax, 3
    int 10h
    call liberar_back_buffer
    mov ax, 4C00h
    int 21h

; =====================================================
; INICIALIZAR EGA
; =====================================================
init_ega PROC
    push ax
    push dx
    mov dx, 3CEh
    mov al, 5
    out dx, al
    inc dx
    mov al, 0
    out dx, al
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    pop dx
    pop ax
    ret
init_ega ENDP

; =====================================================
; GESTIÓN DE MEMORIA PARA DOBLE BUFFER
; =====================================================
init_back_buffer PROC
    push ax
    push bx
    mov ah, 48h
    mov bx, 4000
    int 21h
    jc ib_error
    mov back_buffer_seg, ax
    push dx
    mov dx, OFFSET msg_mem_ok
    mov ah, 9
    int 21h
    pop dx
    clc
    jmp ib_done
ib_error:
    stc
ib_done:
    pop bx
    pop ax
    ret
init_back_buffer ENDP

liberar_back_buffer PROC
    push ax
    push es
    mov ax, back_buffer_seg
    cmp ax, 0
    je lb_done
    mov es, ax
    mov ah, 49h
    int 21h
    mov back_buffer_seg, 0
lb_done:
    pop es
    pop ax
    ret
liberar_back_buffer ENDP

; =====================================================
; CARGAR MAPA
; =====================================================
cargar_mapa_seguro PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov dx, OFFSET archivo_mapa
    mov ax, 3D00h
    int 21h
    jc cms_no_encontrado
    
    mov handle_arch, ax
    mov dx, OFFSET msg_archivo_ok
    mov ah, 9
    int 21h
    
    mov bx, handle_arch
    mov cx, 4096
    mov dx, OFFSET buffer_archivo
    mov ah, 3Fh
    int 21h
    jc cms_cerrar_generar
    
    cmp ax, 0
    je cms_cerrar_generar
    
    mov si, OFFSET buffer_archivo
    mov buffer_pos, si
    
    call parsear_num_buffer
    cmp ax, 100
    jne cms_cerrar_generar
    mov mapa_ancho, ax
    
    call parsear_num_buffer
    cmp ax, 100
    jne cms_cerrar_generar
    mov mapa_alto, ax
    
    push bx
    mov dx, OFFSET msg_dim
    mov ah, 9
    int 21h
    mov ax, 100
    call imprimir_num
    mov dx, OFFSET msg_x
    mov ah, 9
    int 21h
    mov ax, 100
    call imprimir_num
    mov dl, 13
    mov ah, 2
    int 21h
    mov dl, 10
    int 21h
    pop bx
    
    mov di, OFFSET mapa_datos
    mov cx, 10000
    
cms_leer_loop:
    push cx
    push di
    call parsear_num_buffer
    pop di
    mov [di], al
    inc di
    pop cx
    loop cms_leer_loop
    
    mov bx, handle_arch
    mov ah, 3Eh
    int 21h
    
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    jmp cms_fin
    
cms_cerrar_generar:
    mov bx, handle_arch
    mov ah, 3Eh
    int 21h
    jmp cms_generar
    
cms_no_encontrado:
    mov dx, OFFSET msg_no_archivo
    mov ah, 9
    int 21h
    
cms_generar:
    mov dx, OFFSET msg_generando
    mov ah, 9
    int 21h
    call generar_simple
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
cms_fin:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
cargar_mapa_seguro ENDP

parsear_num_buffer PROC
    push bx
    push cx
    push dx
    xor ax, ax
    xor bx, bx
    mov si, buffer_pos
pnb_skip_ws:
    mov bl, [si]
    cmp bl, 0
    je pnb_done
    cmp bl, ' '
    je pnb_next
    cmp bl, 9
    je pnb_next
    cmp bl, 13
    je pnb_next
    cmp bl, 10
    je pnb_next
    jmp pnb_parse
pnb_next:
    inc si
    jmp pnb_skip_ws
pnb_parse:
    cmp bl, '0'
    jb pnb_done
    cmp bl, '9'
    ja pnb_done
    sub bl, '0'
    mov cx, 10
    mul cx
    add ax, bx
    inc si
    mov bl, [si]
    jmp pnb_parse
pnb_done:
    inc si
    mov buffer_pos, si
    pop dx
    pop cx
    pop bx
    ret
parsear_num_buffer ENDP

imprimir_num PROC
    push ax
    push bx
    push cx
    push dx
    mov cx, 0
    mov bx, 10
    cmp ax, 0
    jne dividir
    push ax
    inc cx
    jmp imprimir
dividir:
    xor dx, dx
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne dividir
imprimir:
    pop dx
    add dl, '0'
    mov ah, 2
    int 21h
    loop imprimir
    pop dx
    pop cx
    pop bx
    pop ax
    ret
imprimir_num ENDP

; =====================================================
; GENERAR MAPA SIMPLE
; =====================================================
generar_simple PROC
    push ax
    push cx
    push di
    
    mov mapa_ancho, 100
    mov mapa_alto, 100
    
    ; Llenar con grass
    mov di, OFFSET mapa_datos
    mov cx, 10000
    mov al, TILE_GRASS
    rep stosb
    
    ; Bordes
    mov di, OFFSET mapa_datos
    mov cx, 100
    mov al, TILE_WALL
gs_borde_sup:
    mov [di], al
    inc di
    loop gs_borde_sup
    
    mov di, OFFSET mapa_datos
    add di, 9900
    mov cx, 100
    mov al, TILE_WALL
gs_borde_inf:
    mov [di], al
    inc di
    loop gs_borde_inf
    
    mov bx, 1
gs_laterales:
    cmp bx, 99
    jae gs_done
    mov ax, bx
    mov cx, 100
    mul cx
    mov di, ax
    add di, OFFSET mapa_datos
    mov al, TILE_WALL
    mov [di], al
    add di, 99
    mov [di], al
    inc bx
    jmp gs_laterales
    
gs_done:
    pop di
    pop cx
    pop ax
    ret
generar_simple ENDP

; =====================================================
; MOVER JUGADOR
; =====================================================
mover_jugador PROC
    push ax
    push bx
    
    mov ax, jugador_x
    mov jugador_x_ant, ax
    mov ax, jugador_y
    mov jugador_y_ant, ax
    
    cmp ah, 48h
    je mv_arriba
    cmp al, 'w'
    je mv_arriba
    cmp al, 'W'
    je mv_arriba
    cmp ah, 50h
    je mv_abajo
    cmp al, 's'
    je mv_abajo
    cmp al, 'S'
    je mv_abajo
    cmp ah, 4Bh
    je mv_izq
    cmp al, 'a'
    je mv_izq
    cmp al, 'A'
    je mv_izq
    cmp ah, 4Dh
    je mv_der
    cmp al, 'd'
    je mv_der
    cmp al, 'D'
    je mv_der
    jmp mv_fin
    
mv_arriba:
    cmp jugador_y, 1
    jbe mv_fin
    dec jugador_y
    jmp mv_check
mv_abajo:
    mov ax, jugador_y
    inc ax
    cmp ax, 99
    jae mv_fin
    mov jugador_y, ax
    jmp mv_check
mv_izq:
    cmp jugador_x, 1
    jbe mv_fin
    dec jugador_x
    jmp mv_check
mv_der:
    mov ax, jugador_x
    inc ax
    cmp ax, 99
    jae mv_fin
    mov jugador_x, ax
    jmp mv_check
    
mv_check:
    call colision
    jc mv_restaurar
    jmp mv_fin
    
mv_restaurar:
    mov ax, jugador_x_ant
    mov jugador_x, ax
    mov ax, jugador_y_ant
    mov jugador_y, ax
    
mv_fin:
    pop bx
    pop ax
    ret
mover_jugador ENDP

colision PROC
    push ax
    push bx
    push cx
    push dx
    mov ax, jugador_y
    cmp ax, 100
    jae col_bloquear
    mov bx, jugador_x
    cmp bx, 100
    jae col_bloquear
    mov cx, 100
    mul cx
    add ax, bx
    mov dx, 10000
    cmp ax, dx
    jae col_bloquear
    mov bx, ax
    mov al, mapa_datos[bx]
    cmp al, TILE_GRASS
    je col_ok
    cmp al, TILE_PATH
    je col_ok
col_bloquear:
    stc
    jmp col_fin
col_ok:
    clc
col_fin:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
colision ENDP

; =====================================================
; ACTUALIZAR CÁMARA - MEJORADO
; =====================================================
actualizar_camara PROC
    push ax
    push bx
    
    ; Centrar en jugador
    mov ax, jugador_x
    sub ax, VIEWPORT_W/2
    jge ac_x1
    xor ax, ax
ac_x1:
    mov bx, 100
    sub bx, VIEWPORT_W
    cmp ax, bx
    jle ac_x2
    mov ax, bx
ac_x2:
    mov camara_x, ax
    
    mov ax, jugador_y
    sub ax, VIEWPORT_H/2
    jge ac_y1
    xor ax, ax
ac_y1:
    mov bx, 100
    sub bx, VIEWPORT_H
    cmp ax, bx
    jle ac_y2
    mov ax, bx
ac_y2:
    mov camara_y, ax
    
    pop bx
    pop ax
    ret
actualizar_camara ENDP

; =====================================================
; RENDERIZAR CON DOBLE BUFFER
; =====================================================
renderizar PROC
    push ax
    push cx
    push di
    push es

    mov ax, back_buffer_seg
    or ax, ax
    jz rend_fin
    mov es, ax

    ; Limpiar
    xor di, di
    mov cx, 32000
    xor ax, ax
    cld
    rep stosw
    
    call dibujar_mapa
    call dibujar_player
    call flip_buffer

rend_fin:
    pop es
    pop di
    pop cx
    pop ax
    ret
renderizar ENDP

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
    
    xor di, di
dm_y_loop:
    cmp di, VIEWPORT_H
    jae dm_done
    xor si, si
dm_x_loop:
    cmp si, VIEWPORT_W
    jae dm_next_y
    
    mov ax, camara_y
    add ax, di
    cmp ax, 100
    jae dm_skip_tile
    mov bx, camara_x
    add bx, si
    cmp bx, 100
    jae dm_skip_tile
    
    push dx
    mov dx, 100
    mul dx
    add ax, bx
    pop dx
    
    mov bp, 10000
    cmp ax, bp
    jae dm_skip_tile
    
    push bx
    mov bx, ax
    mov al, mapa_datos[bx]
    pop bx
    
    mov cl, 2
    cmp al, TILE_GRASS
    je dm_draw
    mov cl, 8
    cmp al, TILE_WALL
    je dm_draw
    mov cl, 7
    cmp al, TILE_PATH
    je dm_draw
    mov cl, 9
    cmp al, TILE_WATER
    je dm_draw
    mov cl, 10
    
dm_draw:
    push si
    push di
    mov ax, si
    shl ax, 4
    mov dx, ax
    mov ax, di
    shl ax, 4
    mov bx, ax
    mov al, cl
    call dibujar_tile_buffer
    pop di
    pop si
    
dm_skip_tile:
    inc si
    jmp dm_x_loop
    
dm_next_y:
    inc di
    jmp dm_y_loop
    
dm_done:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_mapa ENDP

dibujar_tile_buffer PROC
    push ax
    push bx
    push cx
    push dx
    push di
    push si
    
    mov cl, al
    mov si, 0
dtb_y:
    cmp si, 16
    jae dtb_done
    mov ax, bx
    add ax, si
    cmp ax, 200
    jae dtb_next_y
    mov di, 320
    mul di
    add ax, dx
    mov di, ax
    push dx
    mov dx, 16
    mov al, cl
dtb_x:
    cmp di, 64000
    jae dtb_skip_pixel
    mov es:[di], al
dtb_skip_pixel:
    inc di
    dec dx
    jnz dtb_x
    pop dx
dtb_next_y:
    inc si
    jmp dtb_y
dtb_done:
    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_tile_buffer ENDP

; =====================================================
; DIBUJAR JUGADOR
; =====================================================
dibujar_player PROC
    push ax
    push bx
    push cx
    push dx
    
    mov ax, jugador_x
    sub ax, camara_x
    js dp_fin
    cmp ax, VIEWPORT_W
    jae dp_fin
    mov bx, jugador_y
    sub bx, camara_y
    js dp_fin
    cmp bx, VIEWPORT_H
    jae dp_fin
    
    shl ax, 4
    add ax, 4
    mov dx, ax
    mov ax, bx
    shl ax, 4
    add ax, 4
    mov bx, ax
    mov al, 14
    call sprite_buffer
    
dp_fin:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_player ENDP

sprite_buffer PROC
    push ax
    push bx
    push cx
    push dx
    push di
    push si
    
    mov cl, al
    mov si, 0
spb_y:
    cmp si, 8
    jae spb_done
    mov ax, bx
    add ax, si
    cmp ax, 200
    jae spb_next_y
    mov di, 320
    mul di
    add ax, dx
    mov di, ax
    push dx
    mov dx, 8
    mov al, cl
spb_x:
    cmp di, 64000
    jae spb_skip
    mov es:[di], al
spb_skip:
    inc di
    dec dx
    jnz spb_x
    pop dx
spb_next_y:
    inc si
    jmp spb_y
spb_done:
    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
sprite_buffer ENDP

; =====================================================
; COPIAR BUFFER A VRAM
; =====================================================
flip_buffer PROC
    push ax
    push cx
    push dx
    push si
    push di
    push ds
    push es
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    
    mov ax, back_buffer_seg
    or ax, ax
    jz fb_done
    mov ds, ax
    mov ax, 0A000h
    mov es, ax

    xor si, si
    xor di, di
    mov cx, 32000
    cld
    rep movsw

fb_done:
    pop es
    pop ds
    pop di
    pop si
    pop dx
    pop cx
    pop ax
    ret
flip_buffer ENDP

END inicio