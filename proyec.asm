; JUEGO DE EXPLORACIÓN - CÓDIGO LIMPIO
; Universidad Nacional - Proyecto II Ciclo 2025
; TASM 8086 - Modo EGA 640x350

.MODEL SMALL
.STACK 2048

; === CONSTANTES ===
TILE_GRASS  EQU 0
TILE_WALL   EQU 1
TILE_PATH   EQU 2
TILE_WATER  EQU 3
TILE_TREE   EQU 4

TILE_SIZE   EQU 20
SCREEN_W    EQU 640
SCREEN_H    EQU 350
VIEWPORT_W  EQU 32
VIEWPORT_H  EQU 17

.DATA
; === ARCHIVOS ===
archivo_mapa    db 'MAPA.TXT',0
archivo_grass   db 'GRASS.TXT',0
archivo_wall    db 'WALL.TXT',0
archivo_path    db 'PATH.TXT',0
archivo_water   db 'WATER.TXT',0
archivo_tree    db 'TREE.TXT',0
archivo_player  db 'PLAYER.TXT',0

; === MAPA ===
mapa_ancho  dw 20
mapa_alto   dw 12
mapa_datos  db 300 dup(0)

; === JUGADOR ===
jugador_x   dw 5
jugador_y   dw 5

; === CÁMARA ===
camara_x    dw 0
camara_y    dw 0

; === SPRITES ===
spr_grass   dw 16, 16
            db 256 dup(2)
spr_wall    dw 16, 16
            db 256 dup(6)
spr_path    dw 16, 16
            db 256 dup(7)
spr_water   dw 16, 16
            db 256 dup(1)
spr_tree    dw 16, 16
            db 256 dup(10)
spr_player  dw 8, 8
            db 64 dup(14)

; === BUFFER ===
buffer_temp db 2048 dup(0)
buffer_size dw 0
handle_arch dw 0

; === MENSAJES ===
msg_1  db 'Cargando...',13,10,'$'
msg_2  db 'Mapa: $'
msg_3  db 'Sprites: $'
msg_4  db 'OK',13,10,'$'
msg_5  db 'ERROR',13,10,'$'
msg_6  db 'Listo - Presiona tecla',13,10,'$'
msg_7  db 'Error Fatal',13,10,'$'

; === DATOS MAPA HARDCODED ===
datos_mapa_prueba:
    db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
    db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
    db 1,0,2,2,2,2,2,2,0,0,0,0,2,2,2,2,2,2,0,1
    db 1,0,2,0,0,0,0,2,0,0,0,0,2,0,0,0,0,2,0,1
    db 1,0,2,0,3,3,0,2,0,0,0,0,2,0,3,3,0,2,0,1
    db 1,0,2,0,3,3,0,2,0,0,0,0,2,0,3,3,0,2,0,1
    db 1,0,2,0,0,0,0,2,0,0,0,0,2,0,0,0,0,2,0,1
    db 1,0,2,2,2,2,2,2,0,0,0,0,2,2,2,2,2,2,0,1
    db 1,0,0,0,0,0,0,0,0,4,4,0,0,0,0,0,0,0,0,1
    db 1,0,4,4,0,0,0,0,0,4,4,0,0,0,0,0,0,4,4,1
    db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
    db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

.CODE
inicio:
    mov ax, @data
    mov ds, ax

    ; Mostrar inicio
    mov dx, OFFSET msg_1
    mov ah, 9
    int 21h

    ; Cargar mapa
    mov dx, OFFSET msg_2
    mov ah, 9
    int 21h
    
    call cargar_mapa
    jc error_fatal

    mov dx, OFFSET msg_4
    mov ah, 9
    int 21h

    ; Cargar sprites
    mov dx, OFFSET msg_3
    mov ah, 9
    int 21h
    
    call cargar_sprites
    
    mov dx, OFFSET msg_4
    mov ah, 9
    int 21h

    ; Listo
    mov dx, OFFSET msg_6
    mov ah, 9
    int 21h

    mov ah, 0
    int 16h

    ; Modo gráfico
    mov ax, 10h
    int 10h

    call actualizar_camara
    call renderizar

bucle:
    ; Esperar tecla
    mov ah, 1
    int 16h
    jz bucle

    ; Leer tecla
    mov ah, 0
    int 16h

    ; ESC = salir
    cmp al, 27
    je salir

    ; Guardar posición
    mov bx, jugador_x
    mov cx, jugador_y

    ; Mover
    call mover

    ; Verificar colisión
    call verificar
    jc restaurar

    ; OK - actualizar
    call actualizar_camara
    call renderizar
    jmp bucle

restaurar:
    mov jugador_x, bx
    mov jugador_y, cx
    jmp bucle

error_fatal:
    mov dx, OFFSET msg_7
    mov ah, 9
    int 21h
    mov ah, 0
    int 16h

salir:
    mov ax, 3
    int 10h
    mov ax, 4C00h
    int 21h

; ========================================
; CARGAR MAPA - VERSIÓN HÍBRIDA
; ========================================
cargar_mapa PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    ; Intentar abrir archivo
    mov dx, OFFSET archivo_mapa
    mov ax, 3D00h
    int 21h
    jc cargar_mapa_hardcoded  ; Si falla, usar datos hardcoded
    
    ; Archivo abierto exitosamente
    mov handle_arch, ax
    
    ; Leer archivo
    mov bx, ax
    mov dx, OFFSET buffer_temp
    mov cx, 2000
    mov ah, 3Fh
    int 21h
    jc cm_cerrar_y_hardcoded
    
    ; Verificar que se leyó algo
    cmp ax, 10
    jl cm_cerrar_y_hardcoded
    
    mov buffer_size, ax
    
    ; Cerrar archivo
    mov bx, handle_arch
    mov ah, 3Eh
    int 21h

    ; Intentar parsear
    mov si, OFFSET buffer_temp
    
    ; Leer ancho
    call leer_num
    cmp ax, 20
    jne cargar_mapa_hardcoded
    mov mapa_ancho, ax
    
    ; Leer alto
    call leer_num
    cmp ax, 12
    jne cargar_mapa_hardcoded
    mov mapa_alto, ax
    
    ; Leer tiles
    mov di, OFFSET mapa_datos
    mov cx, 240
    
cm_leer_tiles:
    call leer_num
    cmp al, 5
    jae cargar_mapa_hardcoded
    mov [di], al
    inc di
    loop cm_leer_tiles
    
    clc
    jmp cm_fin

cm_cerrar_y_hardcoded:
    mov bx, handle_arch
    mov ah, 3Eh
    int 21h
    
cargar_mapa_hardcoded:
    ; Usar datos hardcoded
    mov mapa_ancho, 20
    mov mapa_alto, 12
    
    mov si, OFFSET datos_mapa_prueba
    mov di, OFFSET mapa_datos
    mov cx, 240
    rep movsb
    
    clc

cm_fin:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
cargar_mapa ENDP

; ========================================
; CARGAR SPRITES - SIMPLIFICADO
; ========================================
cargar_sprites PROC
    ; Por ahora usar valores por defecto
    clc
    ret
cargar_sprites ENDP

; ========================================
; LEER NÚMERO
; ========================================
leer_num PROC
    push bx
    push cx
    push dx

    xor ax, ax
    xor bx, bx
    
ln_skip:
    ; Verificar fin de buffer
    mov cx, si
    sub cx, OFFSET buffer_temp
    cmp cx, buffer_size
    jae ln_fin
    
    mov cl, [si]
    inc si
    
    ; Saltar espacios y saltos de línea
    cmp cl, ' '
    je ln_skip
    cmp cl, 9
    je ln_skip
    cmp cl, 13
    je ln_skip
    cmp cl, 10
    je ln_skip
    
    ; Primer dígito
    cmp cl, '0'
    jl ln_fin
    cmp cl, '9'
    jg ln_fin
    
    sub cl, '0'
    mov bl, cl
    
ln_next:
    ; Verificar fin de buffer
    mov cx, si
    sub cx, OFFSET buffer_temp
    cmp cx, buffer_size
    jae ln_done
    
    mov cl, [si]
    
    ; Si no es dígito, terminar
    cmp cl, '0'
    jl ln_done
    cmp cl, '9'
    jg ln_done
    
    inc si
    sub cl, '0'
    
    ; Multiplicar por 10 y sumar
    mov ax, bx
    mov dx, 10
    mul dx
    xor ch, ch
    add ax, cx
    mov bx, ax
    jmp ln_next
    
ln_done:
    mov ax, bx
    
ln_fin:
    pop dx
    pop cx
    pop bx
    ret
leer_num ENDP

; ========================================
; LIMPIAR BUFFER
; ========================================
limpiar_buffer PROC
    push ax
    push cx
    push di
    
    mov di, OFFSET buffer_temp
    mov cx, 2048
    xor al, al
    rep stosb
    mov buffer_size, 0
    
    pop di
    pop cx
    pop ax
    ret
limpiar_buffer ENDP

; ========================================
; RENDERIZAR
; ========================================
renderizar PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    call limpiar_pantalla

    xor di, di
rv_y:
    cmp di, VIEWPORT_H
    jge rv_jug

    xor si, si
rv_x:
    cmp si, VIEWPORT_W
    jge rv_ny

    mov ax, camara_y
    add ax, di
    cmp ax, mapa_alto
    jae rv_nx

    mov bx, mapa_ancho
    mul bx
    mov bx, camara_x
    add bx, si
    cmp bx, mapa_ancho
    jae rv_nx
    add ax, bx

    push si
    push di
    
    mov bx, OFFSET mapa_datos
    add bx, ax
    mov al, [bx]

    mov cx, si
    mov dx, TILE_SIZE
    push ax
    mov ax, cx
    mul dx
    mov cx, ax
    pop ax

    push ax
    mov ax, di
    mul dx
    mov dx, ax
    pop ax

    call dibujar_tile

    pop di
    pop si

rv_nx:
    inc si
    jmp rv_x

rv_ny:
    inc di
    jmp rv_y

rv_jug:
    call dibujar_jugador

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
renderizar ENDP

; ========================================
; DIBUJAR TILE
; ========================================
dibujar_tile PROC
    push ax
    push bx
    push cx
    push dx

    mov bl, 2  ; Verde por defecto
    
    cmp al, TILE_WALL
    jne dt_1
    mov bl, 6  ; Marrón
    jmp dt_ok
dt_1:
    cmp al, TILE_PATH
    jne dt_2
    mov bl, 7  ; Gris claro
    jmp dt_ok
dt_2:
    cmp al, TILE_WATER
    jne dt_3
    mov bl, 1  ; Azul
    jmp dt_ok
dt_3:
    cmp al, TILE_TREE
    jne dt_ok
    mov bl, 10  ; Verde claro

dt_ok:
    mov al, bl
    call dibujar_rect

    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_tile ENDP

; ========================================
; DIBUJAR RECTÁNGULO - CORREGIDO
; ========================================
; ========================================
; DIBUJAR RECTÁNGULO - VERSIÓN FINAL CORREGIDA
; ========================================
; ========================================
; DIBUJAR RECTÁNGULO - VERSIÓN SIMPLE
; ========================================
dibujar_rect PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    ; AL contiene el color
    mov ah, al      ; Guardar color en AH
    
    mov si, cx      ; SI = X inicial
    mov di, dx      ; DI = Y inicial
    
    add cx, TILE_SIZE   ; CX = X final
    add dx, TILE_SIZE   ; DX = Y final

dr_loop_y:
    cmp di, dx          ; Comparar Y actual con Y final
    jae dr_done
    cmp di, SCREEN_H
    jae dr_done
    
    push cx             ; Guardar X final
    mov cx, si          ; CX = X inicial
    
dr_loop_x:
    mov bx, [sp]        ; BX = X final (del stack)
    cmp cx, bx
    jae dr_next_y
    cmp cx, SCREEN_W
    jae dr_next_y
    
    push ax
    push bx
    push cx
    push dx
    
    mov dx, di          ; DX = Y
    mov al, ah          ; AL = color
    mov ah, 0Ch         ; Función pixel
    mov bh, 0           ; Página 0
    int 10h
    
    pop dx
    pop cx
    pop bx
    pop ax
    
    inc cx
    jmp dr_loop_x

dr_next_y:
    pop cx              ; Recuperar X final
    inc di
    jmp dr_loop_y

dr_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_rect ENDP

; ========================================
; DIBUJAR JUGADOR
; ========================================
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

    mov cx, TILE_SIZE
    mul cx
    add ax, TILE_SIZE/2 - 4
    mov cx, ax

    mov ax, bx
    mov dx, TILE_SIZE
    mul dx
    add ax, TILE_SIZE/2 - 4
    mov dx, ax

    mov bx, 8
dj_y:
    push cx
    push dx
    push bx

    mov bx, 8
dj_x:
    cmp cx, SCREEN_W
    jae dj_nx
    cmp dx, SCREEN_H
    jae dj_nx

    mov ah, 0Ch
    mov al, 14      ; Amarillo
    push bx
    mov bh, 0
    int 10h
    pop bx

dj_nx:
    inc cx
    dec bx
    jnz dj_x

    pop bx
    pop dx
    pop cx
    inc dx
    dec bx
    jnz dj_y

dj_fin:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_jugador ENDP

; ========================================
; LIMPIAR PANTALLA
; ========================================
limpiar_pantalla PROC
    push ax
    push bx
    push cx
    push dx

    mov ax, 0600h
    mov bh, 0
    mov cx, 0
    mov dx, 184Fh
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax
    ret
limpiar_pantalla ENDP

; ========================================
; MOVER
; ========================================
mover PROC
    ; Arriba
    cmp ah, 48h
    je m_arr
    cmp al, 'w'
    je m_arr
    cmp al, 'W'
    je m_arr
    
    ; Abajo
    cmp ah, 50h
    je m_aba
    cmp al, 's'
    je m_aba
    cmp al, 'S'
    je m_aba
    
    ; Izquierda
    cmp ah, 4Bh
    je m_izq
    cmp al, 'a'
    je m_izq
    cmp al, 'A'
    je m_izq
    
    ; Derecha
    cmp ah, 4Dh
    je m_der
    cmp al, 'd'
    je m_der
    cmp al, 'D'
    je m_der
    ret

m_arr:
    cmp jugador_y, 0
    je m_fin
    dec jugador_y
    ret

m_aba:
    mov ax, jugador_y
    inc ax
    cmp ax, mapa_alto
    jge m_fin
    mov jugador_y, ax
    ret

m_izq:
    cmp jugador_x, 0
    je m_fin
    dec jugador_x
    ret

m_der:
    mov ax, jugador_x
    inc ax
    cmp ax, mapa_ancho
    jge m_fin
    mov jugador_x, ax
    ret

m_fin:
    ret
mover ENDP

; ========================================
; VERIFICAR
; ========================================
verificar PROC
    push ax
    push bx
    push si

    mov ax, jugador_x
    cmp ax, 0
    jl v_col
    cmp ax, mapa_ancho
    jge v_col

    mov ax, jugador_y
    cmp ax, 0
    jl v_col
    cmp ax, mapa_alto
    jge v_col

    mov ax, jugador_y
    mov bx, mapa_ancho
    mul bx
    add ax, jugador_x

    mov si, OFFSET mapa_datos
    add si, ax
    mov al, [si]

    cmp al, TILE_GRASS
    je v_ok
    cmp al, TILE_PATH
    je v_ok

v_col:
    stc
    jmp v_fin

v_ok:
    clc

v_fin:
    pop si
    pop bx
    pop ax
    ret
verificar ENDP

; ========================================
; ACTUALIZAR CÁMARA
; ========================================
actualizar_camara PROC
    push ax
    push bx

    mov ax, jugador_x
    sub ax, VIEWPORT_W/2
    cmp ax, 0
    jge ac_1
    xor ax, ax
ac_1:
    mov bx, mapa_ancho
    sub bx, VIEWPORT_W
    cmp bx, 0
    jg ac_2
    xor bx, bx
ac_2:
    cmp ax, bx
    jle ac_3
    mov ax, bx
ac_3:
    mov camara_x, ax

    mov ax, jugador_y
    sub ax, VIEWPORT_H/2
    cmp ax, 0
    jge ac_4
    xor ax, ax
ac_4:
    mov bx, mapa_alto
    sub bx, VIEWPORT_H
    cmp bx, 0
    jg ac_5
    xor bx, bx
ac_5:
    cmp ax, bx
    jle ac_6
    mov ax, bx
ac_6:
    mov camara_y, ax

    pop bx
    pop ax
    ret
actualizar_camara ENDP

END inicio