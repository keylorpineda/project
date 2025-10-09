; =====================================================
; JUEGO DE EXPLORACIÓN - MODO EGA 0Dh (320x200x16)
; CON DOBLE BUFFER EN RAM
; Universidad Nacional - Proyecto II Ciclo 2025
; VERSIÓN FUNCIONAL - CORREGIDA
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
VIEWPORT_W  EQU 12
VIEWPORT_H  EQU 10

; Puertos EGA
SEQ_INDEX   EQU 3C4h
SEQ_DATA    EQU 3C5h
GC_INDEX    EQU 3CEh
GC_DATA     EQU 3CFh

.DATA
; === ARCHIVOS ===
archivo_mapa db 'MAPA.TXT',0

; === MAPA ===
mapa_ancho  dw 100
mapa_alto   dw 100
mapa_datos  db 10000 dup(0)

; === JUGADOR ===
jugador_x   dw 50
jugador_y   dw 50
jugador_x_ant dw 50
jugador_y_ant dw 50

; === CÁMARA ===
camara_x    dw 0
camara_y    dw 0

; === BUFFER ARCHIVO ===
buffer_archivo db 20000 dup(0)
handle_arch dw 0

; === DOBLE BUFFER (puntero asignado dinámicamente) ===
back_buffer_seg dw 0

; === MENSAJES ===
msg_titulo  db 'JUEGO DE EXPLORACION - EGA',13,10
           db '==========================',13,10,'$'
msg_cargando db 'Cargando mapa...$'
msg_generando db 'Generando mapa 100x100...$'
msg_ok     db 'OK',13,10,'$'
msg_dim    db 'Mapa: $'
msg_x      db 'x$'
msg_listo  db 13,10,'Sistema listo con DOBLE BUFFER',13,10
           db 'Controles: Flechas/WASD = Mover, ESC = Salir',13,10
           db 'Presiona tecla...$'
msg_archivo_ok db 'MAPA.TXT encontrado!',13,10,'$'
msg_no_archivo db 'No se pudo abrir MAPA.TXT',13,10,'$'
msg_mem_fail  db 'No hay memoria para el doble buffer.',13,10,'$'

.CODE
inicio:
    mov ax, @data
    mov ds, ax
    mov es, ax

    ; Mostrar título
    mov dx, OFFSET msg_titulo
    mov ah, 9
    int 21h

    ; Cargar/generar mapa
    mov dx, OFFSET msg_cargando
    mov ah, 9
    int 21h
    call cargar_mapa

    ; Inicializar buffer de doble búfer
    call init_back_buffer
    jc sin_memoria

    ; Mensaje de listo
    mov dx, OFFSET msg_listo
    mov ah, 9
    int 21h
    mov ah, 0
    int 16h

    ; Modo gráfico 0Dh
    mov ax, 0Dh
    int 10h
    
    ; Inicializar EGA
    call init_ega
    
    ; Renderizar frame inicial
    call actualizar_camara
    call renderizar

; === BUCLE PRINCIPAL ===
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
    
    mov dx, GC_INDEX
    mov al, 5
    out dx, al
    inc dx
    mov al, 0
    out dx, al
    
    mov dx, SEQ_INDEX
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
; INICIALIZAR DOBLE BUFFER DINÁMICO
; =====================================================
init_back_buffer PROC
    push ax
    push bx

    mov ah, 48h
    mov bx, 4000           ; 64000 bytes / 16
    int 21h
    jc ib_error

    mov back_buffer_seg, ax
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
    push bx
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
    pop bx
    pop ax
    ret
liberar_back_buffer ENDP

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
    
    mov dx, OFFSET archivo_mapa
    mov ax, 3D00h
    int 21h
    jc generar_mapa
    
    mov dx, OFFSET msg_archivo_ok
    push ax
    mov ah, 9
    int 21h
    pop ax
    
    mov bx, ax
    mov handle_arch, ax
    mov cx, 20000
    mov dx, OFFSET buffer_archivo
    mov ah, 3Fh
    int 21h
    jc cerrar_generar
    
    mov si, OFFSET buffer_archivo
    call parsear_num
    mov mapa_ancho, ax
    push ax
    call parsear_num
    mov mapa_alto, ax
    
    mov dx, OFFSET msg_dim
    mov ah, 9
    int 21h
    pop ax
    push ax
    call imprimir_num
    mov dx, OFFSET msg_x
    mov ah, 9
    int 21h
    mov ax, mapa_alto
    call imprimir_num
    mov dl, ' '
    mov ah, 2
    int 21h
    pop ax
    
    mov di, OFFSET mapa_datos
    mov ax, mapa_alto
    mov bx, mapa_ancho
    mul bx
    mov cx, ax
    
leer_tiles:
    call parsear_num
    mov [di], al
    inc di
    loop leer_tiles
    
    mov bx, handle_arch
    mov ah, 3Eh
    int 21h
    
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    jmp fin_cargar
    
cerrar_generar:
    mov bx, handle_arch
    mov ah, 3Eh
    int 21h
    
generar_mapa:
    mov dx, OFFSET msg_generando
    mov ah, 9
    int 21h
    call generar_procedural
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
fin_cargar:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
cargar_mapa ENDP

parsear_num PROC
    push bx
    push cx
    push dx
    xor ax, ax
    xor bx, bx
skip_ws:
    mov bl, [si]
    cmp bl, 0
    je done_parse
    inc si
    cmp bl, ' '
    je skip_ws
    cmp bl, 9
    je skip_ws
    cmp bl, 13
    je skip_ws
    cmp bl, 10
    je skip_ws
parse_dig:
    cmp bl, '0'
    jb done_parse
    cmp bl, '9'
    ja done_parse
    sub bl, '0'
    mov cx, 10
    mul cx
    add ax, bx
    mov bl, [si]
    inc si
    jmp parse_dig
done_parse:
    pop dx
    pop cx
    pop bx
    ret
parsear_num ENDP

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

generar_procedural PROC
    push ax
    push bx
    push cx
    push dx
    push di
    
    mov mapa_ancho, 100
    mov mapa_alto, 100
    mov di, OFFSET mapa_datos
    mov cx, 10000
    xor bx, bx
    
gen_loop:
    mov ax, bx
    xor dx, dx
    mov si, 100
    div si
    cmp ax, 0
    je gen_wall
    cmp ax, 99
    je gen_wall
    cmp dx, 0
    je gen_wall
    cmp dx, 99
    je gen_wall
    cmp ax, 48
    jb gen_terrain
    cmp ax, 52
    ja gen_terrain
    cmp dx, 48
    jb gen_terrain
    cmp dx, 52
    ja gen_terrain
    mov al, TILE_GRASS
    jmp gen_save
    
gen_terrain:
    push ax
    mov ax, bx
    add ax, dx
    xor ax, cx
    and ax, 31
    cmp ax, 3
    jb gen_water
    cmp ax, 7
    jb gen_tree
    cmp ax, 12
    jb gen_path
    pop ax
    mov al, TILE_GRASS
    jmp gen_save
    
gen_wall:
    mov al, TILE_WALL
    jmp gen_save
gen_water:
    pop ax
    mov al, TILE_WATER
    jmp gen_save
gen_tree:
    pop ax
    mov al, TILE_TREE
    jmp gen_save
gen_path:
    pop ax
    mov al, TILE_PATH
    
gen_save:
    mov [di], al
    inc di
    inc bx
    loop gen_loop
    
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
generar_procedural ENDP

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

actualizar_camara PROC
    push ax
    push bx
    mov ax, jugador_x
    sub ax, 6
    jge cam_x1
    xor ax, ax
cam_x1:
    cmp ax, 88
    jle cam_x2
    mov ax, 88
cam_x2:
    mov camara_x, ax
    mov ax, jugador_y
    sub ax, 5
    jge cam_y1
    xor ax, ax
cam_y1:
    cmp ax, 90
    jle cam_y2
    mov ax, 90
cam_y2:
    mov camara_y, ax
    pop bx
    pop ax
    ret
actualizar_camara ENDP

; =====================================================
; RENDERIZAR CON DOBLE BUFFER - CORREGIDO
; =====================================================
renderizar PROC
    push ax
    push cx
    push di
    push es

    ; ES = buffer de respaldo
    mov ax, back_buffer_seg
    or ax, ax
    jz rend_fin
    mov es, ax

    ; Limpiar buffer completamente
    xor di, di
    mov cx, 32000
    xor ax, ax
    cld
    rep stosw
    
    ; Dibujar todo
    call dibujar_mapa
    call dibujar_player
    
    ; Copiar a VRAM
    call flip_buffer

rend_fin:
    pop es
    pop di
    pop cx
    pop ax
    ret
renderizar ENDP

; =====================================================
; DIBUJAR MAPA - CORREGIDO
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
    
    ; Posición en mapa
    mov ax, camara_y
    add ax, di
    cmp ax, 100
    jae dm_skip_tile
    
    mov bx, camara_x
    add bx, si
    cmp bx, 100
    jae dm_skip_tile
    
    ; Índice del tile
    push dx
    mov dx, 100
    mul dx
    add ax, bx
    pop dx
    
    mov bp, 10000
    cmp ax, bp
    jae dm_skip_tile
    
    ; Obtener tile y color
    push bx
    mov bx, ax
    mov al, mapa_datos[bx]
    pop bx
    
    mov cl, 2           ; Verde
    cmp al, TILE_GRASS
    je dm_draw
    mov cl, 8           ; Gris oscuro
    cmp al, TILE_WALL
    je dm_draw
    mov cl, 7           ; Gris claro
    cmp al, TILE_PATH
    je dm_draw
    mov cl, 9           ; Azul claro
    cmp al, TILE_WATER
    je dm_draw
    mov cl, 10          ; Verde claro
    
dm_draw:
    ; Calcular posición en pantalla
    push si
    push di
    
    mov ax, si
    shl ax, 4           ; X * 16
    mov dx, ax
    
    mov ax, di
    shl ax, 4           ; Y * 16
    mov bx, ax
    
    ; Dibujar tile
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

; =====================================================
; DIBUJAR TILE EN BUFFER - CORREGIDO
; AL = color, DX = X pantalla, BX = Y pantalla
; =====================================================
dibujar_tile_buffer PROC
    push ax
    push bx
    push cx
    push dx
    push di
    push si
    
    mov cl, al          ; Guardar color
    mov si, 0           ; Y offset
    
dtb_y:
    cmp si, 16
    jae dtb_done
    
    ; Calcular Y total
    mov ax, bx
    add ax, si
    cmp ax, 200
    jae dtb_next_y
    
    ; Calcular offset: Y * 320 + X
    mov di, 320
    mul di              ; AX = Y * 320
    add ax, dx          ; AX = Y * 320 + X
    mov di, ax
    
    ; Dibujar 16 píxeles
    push dx
    mov dx, 16
    mov al, cl
    
dtb_x:
    ; Verificar límites
    cmp di, 64000
    jae dtb_skip_pixel
    
    ; Escribir en buffer
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
; DIBUJAR JUGADOR - CORREGIDO
; =====================================================
dibujar_player PROC
    push ax
    push bx
    push cx
    push dx
    
    ; Verificar visibilidad
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
    
    ; Posición en pantalla (centrado en tile)
    shl ax, 4
    add ax, 4
    mov dx, ax
    
    mov ax, bx
    shl ax, 4
    add ax, 4
    mov bx, ax
    
    ; Dibujar sprite
    mov al, 14          ; Amarillo
    call sprite_buffer
    
dp_fin:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_player ENDP

; =====================================================
; SPRITE EN BUFFER - CORREGIDO
; AL = color, DX = X, BX = Y
; =====================================================
sprite_buffer PROC
    push ax
    push bx
    push cx
    push dx
    push di
    push si
    
    mov cl, al          ; Color
    mov si, 0           ; Y offset
    
spb_y:
    cmp si, 8
    jae spb_done
    
    ; Calcular Y total
    mov ax, bx
    add ax, si
    cmp ax, 200
    jae spb_next_y
    
    ; Offset: Y * 320 + X
    mov di, 320
    mul di
    add ax, dx
    mov di, ax
    
    ; Dibujar 8 píxeles
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
; COPIAR BUFFER A VRAM - CORREGIDO
; =====================================================
flip_buffer PROC
    push ax
    push cx
    push dx
    push si
    push di
    push ds
    push es
    
    ; Configurar EGA
    mov dx, SEQ_INDEX
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    
    ; DS = buffer, ES = VRAM
    mov ax, back_buffer_seg
    or ax, ax
    jz fb_done
    mov ds, ax
    mov ax, 0A000h
    mov es, ax

    ; Copiar buffer
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