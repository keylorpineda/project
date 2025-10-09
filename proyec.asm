; JUEGO DE EXPLORACIÓN - VERSIÓN CON DOBLE BUFFER
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

TILE_SIZE      EQU 20
SCREEN_W       EQU 640
SCREEN_H       EQU 350
VIEWPORT_W     EQU 32
VIEWPORT_H     EQU 17
BUFFER_PIXELS  EQU 28000

.DATA
; === ARCHIVOS ===
archivo_mapa    db 'MAPA.TXT',0

; === MAPA ===
mapa_ancho  dw 20
mapa_alto   dw 12
mapa_datos  db 300 dup(0)

; === JUGADOR ===
jugador_x   dw 1
jugador_y   dw 1
jugador_x_ant dw 1
jugador_y_ant dw 1

; === CÁMARA ===
camara_x    dw 0
camara_y    dw 0
camara_x_ant dw 0
camara_y_ant dw 0

; === BUFFER ===
buffer_temp db 2048 dup(0)
buffer_size dw 0
handle_arch dw 0

; === DOBLE BUFFER ===
; Buffer para almacenar la pantalla completa antes de mostrarla
; Nota: limitar el tamaño del buffer para mantenerse dentro del segmento de datos.
buffer_pantalla db BUFFER_PIXELS dup(0)  ; Buffer simplificado para modo 13h simulado

; === VARIABLES PARA DIBUJAR ===
draw_x_start dw 0
draw_y_start dw 0
draw_x_end   dw 0
draw_y_end   dw 0
draw_color   db 0

; === MENSAJES ===
msg_1  db 'Cargando...',13,10,'$'
msg_2  db 'Mapa: $'
msg_4  db 'OK',13,10,'$'
msg_6  db 'Listo - Presiona tecla',13,10,'$'
msg_7  db 'Error Fatal',13,10,'$'

; === DATOS MAPA HARDCODED ===
datos_mapa_prueba db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
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
    call renderizar_con_buffer

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

    ; Guardar posición anterior
    mov ax, jugador_x
    mov jugador_x_ant, ax
    mov ax, jugador_y
    mov jugador_y_ant, ax
    
    ; Guardar cámara anterior
    mov ax, camara_x
    mov camara_x_ant, ax
    mov ax, camara_y
    mov camara_y_ant, ax

    ; Mover
    call mover

    ; Verificar colisión
    call verificar
    jc restaurar

    ; Actualizar cámara
    call actualizar_camara
    
    ; Siempre renderizar con buffer para evitar parpadeo
    call renderizar_con_buffer
    jmp bucle

restaurar:
    mov ax, jugador_x_ant
    mov jugador_x, ax
    mov ax, jugador_y_ant
    mov jugador_y, ax
    jmp bucle

salir:
    mov ax, 3
    int 10h
    mov ax, 4C00h
    int 21h

; ========================================
; RENDERIZAR CON BUFFER
; ========================================
renderizar_con_buffer PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Paso 1: Limpiar buffer
    call limpiar_buffer_pantalla
    
    ; Paso 2: Dibujar todo en el buffer
    call dibujar_mapa_en_buffer
    call dibujar_jugador_en_buffer
    
    ; Paso 3: Volcar buffer a pantalla
    call volcar_buffer_a_pantalla
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
renderizar_con_buffer ENDP

; ========================================
; LIMPIAR BUFFER PANTALLA
; ========================================
limpiar_buffer_pantalla PROC
    push ax
    push cx
    push di
    push es
    
    mov ax, ds
    mov es, ax
    mov di, OFFSET buffer_pantalla
    xor al, al  ; Color negro
    mov cx, BUFFER_PIXELS  ; Limpiar solo lo necesario
    rep stosb
    
    pop es
    pop di
    pop cx
    pop ax
    ret
limpiar_buffer_pantalla ENDP

; ========================================
; DIBUJAR MAPA EN BUFFER
; ========================================
dibujar_mapa_en_buffer PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    xor di, di  ; Y del viewport
dmb_y:
    cmp di, VIEWPORT_H
    jae dmb_fin

    xor si, si  ; X del viewport
dmb_x:
    cmp si, VIEWPORT_W
    jae dmb_ny

    ; Calcular posición en el mapa
    mov ax, camara_y
    add ax, di
    cmp ax, mapa_alto
    jae dmb_nx

    mov bx, mapa_ancho
    mul bx
    mov bx, camara_x
    add bx, si
    cmp bx, mapa_ancho
    jae dmb_nx
    add ax, bx

    push si
    push di
    
    ; Obtener tile del mapa
    mov bx, OFFSET mapa_datos
    add bx, ax
    mov al, [bx]

    ; Calcular posición en píxeles
    mov cx, si
    mov bx, TILE_SIZE
    push ax
    mov ax, cx
    mul bx
    mov cx, ax  ; CX = X en píxeles
    pop ax

    push ax
    mov ax, di
    mul bx
    mov dx, ax  ; DX = Y en píxeles
    pop ax

    ; Dibujar tile en buffer
    call dibujar_tile_en_buffer

    pop di
    pop si

dmb_nx:
    inc si
    jmp dmb_x

dmb_ny:
    inc di
    jmp dmb_y

dmb_fin:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_mapa_en_buffer ENDP

; ========================================
; DIBUJAR TILE EN BUFFER
; ========================================
dibujar_tile_en_buffer PROC
    push ax
    push bx
    push cx
    push dx

    ; Determinar color según tipo de tile
    mov bl, 2  ; Verde por defecto (grass)
    
    cmp al, TILE_WALL
    jne dtb_1
    mov bl, 6  ; Marrón
    jmp dtb_ok
dtb_1:
    cmp al, TILE_PATH
    jne dtb_2
    mov bl, 7  ; Gris
    jmp dtb_ok
dtb_2:
    cmp al, TILE_WATER
    jne dtb_3
    mov bl, 1  ; Azul
    jmp dtb_ok
dtb_3:
    cmp al, TILE_TREE
    jne dtb_ok
    mov bl, 10  ; Verde claro

dtb_ok:
    mov al, bl
    call dibujar_rect_en_buffer

    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_tile_en_buffer ENDP

; ========================================
; DIBUJAR RECTÁNGULO EN BUFFER
; ========================================
dibujar_rect_en_buffer PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov bp, sp
    push ax  ; Guardar color en stack
    
    mov si, cx  ; X inicial
    mov di, dx  ; Y inicial

    ; Calcular límites
    add cx, TILE_SIZE  ; X final
    add dx, TILE_SIZE  ; Y final

drb_y:
    cmp di, dx
    jae drb_fin
    cmp di, SCREEN_H
    jae drb_fin
    
    push si  ; Guardar X inicial
drb_x:
    cmp si, cx
    jae drb_ny
    cmp si, SCREEN_W
    jae drb_ny
    
    ; Calcular offset en buffer
    push cx
    push dx
    
    mov ax, di
    mov dx, 640
    mul dx
    add ax, si
    
    ; Verificar límite del buffer
    cmp ax, BUFFER_PIXELS
    jae drb_skip
    
    mov bx, ax
    
    ; Recuperar color del stack
    mov al, [bp-14]  ; Color guardado
    mov byte ptr [buffer_pantalla + bx], al
    
drb_skip:
    pop dx
    pop cx
    
    inc si
    jmp drb_x

drb_ny:
    pop si  ; Recuperar X inicial
    inc di
    jmp drb_y

drb_fin:
    pop ax  ; Limpiar color del stack
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_rect_en_buffer ENDP

; ========================================
; DIBUJAR JUGADOR EN BUFFER
; ========================================
dibujar_jugador_en_buffer PROC
    push ax
    push bx
    push cx
    push dx

    ; Calcular posición relativa a la cámara
    mov ax, jugador_x
    sub ax, camara_x
    js djb_fin
    cmp ax, VIEWPORT_W
    jae djb_fin

    mov bx, jugador_y
    sub bx, camara_y
    js djb_fin
    cmp bx, VIEWPORT_H
    jae djb_fin

    ; Convertir a píxeles
    mov cx, TILE_SIZE
    mul cx
    add ax, TILE_SIZE/2 - 4
    mov cx, ax

    mov ax, bx
    mov dx, TILE_SIZE
    mul dx
    add ax, TILE_SIZE/2 - 4
    mov dx, ax

    ; Dibujar cuadrado de 8x8
    mov bx, 8
djb_y:
    push cx
    push dx
    push bx

    mov bx, 8
djb_x:
    cmp cx, SCREEN_W
    jae djb_nx
    cmp dx, SCREEN_H
    jae djb_nx

    ; Escribir pixel en buffer
    push bx
    push cx
    push dx
    
    ; Calcular offset
    mov ax, dx
    mov bx, 640
    mul bx
    add ax, cx
    mov bx, ax
    
    ; Color amarillo para el jugador
    mov byte ptr [buffer_pantalla + bx], 14
    
    pop dx
    pop cx
    pop bx

djb_nx:
    inc cx
    dec bx
    jnz djb_x

    pop bx
    pop dx
    pop cx
    inc dx
    dec bx
    jnz djb_y

djb_fin:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_jugador_en_buffer ENDP

volcar_buffer_a_pantalla PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Esperar retrazado vertical
    mov dx, 03DAh
vb_wait1:
    in al, dx
    test al, 8
    jnz vb_wait1
vb_wait2:
    in al, dx
    test al, 8
    jz vb_wait2
    
    ; Solo dibujar el área visible (viewport)
    xor di, di  ; Y
vb_y:
    cmp di, 340  ; Solo hasta 340 para evitar overflow
    jae vb_fin
    
    xor si, si  ; X
vb_x:
    cmp si, 640
    jae vb_ny
    
    ; Calcular offset en buffer
    push dx
    mov ax, di
    mov dx, 640
    mul dx
    add ax, si
    mov bx, ax
    pop dx
    
    ; Verificar que no excedemos el buffer
    cmp bx, BUFFER_PIXELS
    jae vb_skip
    
    ; Leer color del buffer
    mov al, byte ptr [buffer_pantalla + bx]
    
    ; Solo dibujar si no es negro (optimización)
    cmp al, 0
    je vb_skip
    
    ; Dibujar pixel en pantalla
    mov cx, si  ; X
    mov dx, di  ; Y
    mov ah, 0Ch
    push bx
    mov bh, 0
    int 10h
    pop bx
    
vb_skip:
    inc si
    jmp vb_x

vb_ny:
    inc di
    jmp vb_y

vb_fin:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
volcar_buffer_a_pantalla ENDP

; ========================================
; CARGAR MAPA
; ========================================
cargar_mapa PROC
    push ax
    push cx
    push si
    push di

    ; Usar datos hardcoded directamente
    mov mapa_ancho, 20
    mov mapa_alto, 12
    
    mov si, OFFSET datos_mapa_prueba
    mov di, OFFSET mapa_datos
    mov cx, 240
    rep movsb
    
    pop di
    pop si
    pop cx
    pop ax
    ret
cargar_mapa ENDP

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
    jae m_fin
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
    jae m_fin
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

    ; Verificar límites del mapa
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

    ; Calcular posición en el mapa
    mov ax, jugador_y
    mov bx, mapa_ancho
    mul bx
    add ax, jugador_x

    ; Obtener tile
    mov si, OFFSET mapa_datos
    add si, ax
    mov al, [si]

    ; Verificar si es transitable
    cmp al, TILE_GRASS
    je v_ok
    cmp al, TILE_PATH
    je v_ok

v_col:
    stc  ; Set carry = colisión
    jmp v_fin

v_ok:
    clc  ; Clear carry = OK

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

    ; Calcular posición X de la cámara
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

    ; Calcular posición Y de la cámara
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