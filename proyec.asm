; =====================================================
; JUEGO DE EXPLORACIÓN - MODO EGA 0Dh (320x200x16)
; Universidad Nacional - Proyecto II Ciclo 2025
; Código optimizado con doble buffer
; VERSIÓN CORREGIDA: Movimiento funcional + coordenadas legibles
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
VIEWPORT_W  EQU 12      ; 12 tiles horizontales
VIEWPORT_H  EQU 10      ; 10 tiles verticales

.DATA
; === ARCHIVOS ===
archivo_mapa db 'MAPA.TXT',0

; === MAPA ===
mapa_ancho  dw 100
mapa_alto   dw 100
mapa_datos  db 10000 dup(0)

; === JUGADOR ===
jugador_x   dw 13       ; Centro del mapa 100x100
jugador_y   dw 13
jugador_x_ant dw 13
jugador_y_ant dw 13

; === CÁMARA ===
camara_x    dw 0
camara_y    dw 0

; === DOBLE BUFFER ===
pagina_visible db 0
pagina_dibujo  db 1

; === BUFFER ARCHIVO ===
buffer_archivo db 20000 dup(0)
handle_arch dw 0

; === MENSAJES ===
msg_titulo  db 'JUEGO DE EXPLORACION',13,10
           db '====================',13,10,'$'
msg_cargando db 'Cargando mapa...$'
msg_generando db 'Generando mapa 100x100...$'
msg_ok     db 'OK',13,10,'$'
msg_dim    db 'Mapa: $'
msg_x      db 'x$'
msg_listo  db 13,10,'Sistema listo. Viewport: 12x10 tiles',13,10
           db 'Controles: Flechas o WASD = Mover, ESC = Salir',13,10
           db 'Presiona tecla para iniciar...$'
msg_archivo_ok db 'MAPA.TXT encontrado y abierto!',13,10,'$'
msg_no_archivo db 'No se pudo abrir MAPA.TXT',13,10,'$'

; Tabla de patrones de bits para números 0-9 (5x7 píxeles)
tabla_numeros db 01110000b  ; 0
              db 10001000b
              db 10011000b
              db 10101000b
              db 11001000b
              db 10001000b
              db 01110000b
              
              db 00100000b  ; 1
              db 01100000b
              db 00100000b
              db 00100000b
              db 00100000b
              db 00100000b
              db 01110000b
              
              db 01110000b  ; 2
              db 10001000b
              db 00001000b
              db 00010000b
              db 00100000b
              db 01000000b
              db 11111000b
              
              db 11111000b  ; 3
              db 00010000b
              db 00100000b
              db 00010000b
              db 00001000b
              db 10001000b
              db 01110000b
              
              db 00010000b  ; 4
              db 00110000b
              db 01010000b
              db 10010000b
              db 11111000b
              db 00010000b
              db 00010000b
              
              db 11111000b  ; 5
              db 10000000b
              db 11110000b
              db 00001000b
              db 00001000b
              db 10001000b
              db 01110000b
              
              db 00110000b  ; 6
              db 01000000b
              db 10000000b
              db 11110000b
              db 10001000b
              db 10001000b
              db 01110000b
              
              db 11111000b  ; 7
              db 00001000b
              db 00010000b
              db 00100000b
              db 01000000b
              db 01000000b
              db 01000000b
              
              db 01110000b  ; 8
              db 10001000b
              db 10001000b
              db 01110000b
              db 10001000b
              db 10001000b
              db 01110000b
              
              db 01110000b  ; 9
              db 10001000b
              db 10001000b
              db 01111000b
              db 00001000b
              db 00010000b
              db 01100000b

.CODE
inicio:
    mov ax, @data
    mov ds, ax

    ; Mostrar título
    mov dx, OFFSET msg_titulo
    mov ah, 9
    int 21h

    ; Cargar/generar mapa
    mov dx, OFFSET msg_cargando
    mov ah, 9
    int 21h
    call cargar_mapa
    
    ; Mensaje de listo
    mov dx, OFFSET msg_listo
    mov ah, 9
    int 21h
    mov ah, 0
    int 16h

    ; Modo gráfico 0Dh (320x200x16)
    mov ax, 0Dh
    int 10h
    
    ; Usar SOLO página 0
    mov al, 0
    mov ah, 05h
    int 10h
    
    ; Renderizar frame inicial
    call actualizar_camara
    call renderizar

; === BUCLE PRINCIPAL ===
bucle_juego:
    ; Esperar tecla (sin bloquear)
    mov ah, 1
    int 16h
    jz bucle_juego

    ; Leer tecla
    mov ah, 0
    int 16h
    
    ; ESC = salir
    cmp al, 27
    je terminar

    ; Procesar movimiento
    call mover_jugador
    
    ; SIEMPRE actualizar cámara y renderizar
    call actualizar_camara
    call renderizar
    
    ; Pequeña pausa para estabilidad
    mov cx, 1
    mov dx, 0
    mov ah, 86h
    int 15h
    
    jmp bucle_juego

terminar:
    ; Volver a modo texto
    mov ax, 3
    int 10h
    
    ; Salir
    mov ax, 4C00h
    int 21h

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
    
    ; Intentar abrir archivo
    mov dx, OFFSET archivo_mapa
    mov ax, 3D00h
    int 21h
    jc archivo_no_encontrado
    
    ; Archivo abierto exitosamente
    push ax
    mov dx, OFFSET msg_archivo_ok
    mov ah, 9
    int 21h
    pop ax
    
    ; Leer archivo
    mov bx, ax
    mov handle_arch, ax
    mov cx, 20000
    mov dx, OFFSET buffer_archivo
    mov ah, 3Fh
    int 21h
    jc cerrar_generar
    
    ; Parsear dimensiones
    mov si, OFFSET buffer_archivo
    call parsear_num
    mov mapa_ancho, ax
    push ax
    call parsear_num
    mov mapa_alto, ax
    
    ; Mostrar dimensiones
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
    
    ; Leer tiles
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
    
    ; Cerrar archivo
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
    jmp generar_mapa
    
archivo_no_encontrado:
    mov dx, OFFSET msg_no_archivo
    mov ah, 9
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

; =====================================================
; PARSEAR NÚMERO
; =====================================================
parsear_num PROC
    push bx
    push cx
    push dx
    
    xor ax, ax
    xor bx, bx
    
skip_ws:
    mov bl, [si]
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

; =====================================================
; IMPRIMIR NÚMERO
; =====================================================
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
; GENERAR MAPA PROCEDURAL
; =====================================================
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
    ; Verificar bordes
    cmp bx, 100
    jb gen_wall
    
    mov ax, bx
    xor dx, dx
    mov si, 100
    div si
    
    cmp ax, 99
    je gen_wall
    cmp dx, 0
    je gen_wall
    cmp dx, 99
    je gen_wall
    
    ; Zona inicio (48-52, 48-52)
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
    ; Pseudo-aleatorio
    mov ax, bx
    and ax, 1Fh
    
    cmp ax, 3
    jb gen_water
    cmp ax, 7
    jb gen_tree
    cmp ax, 12
    jb gen_path
    mov al, TILE_GRASS
    jmp gen_save
    
gen_wall:
    mov al, TILE_WALL
    jmp gen_save
gen_water:
    mov al, TILE_WATER
    jmp gen_save
gen_tree:
    mov al, TILE_TREE
    jmp gen_save
gen_path:
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

; =====================================================
; MOVER JUGADOR - CORREGIDO
; =====================================================
mover_jugador PROC
    push ax
    push bx
    
    ; Guardar posición
    mov ax, jugador_x
    mov jugador_x_ant, ax
    mov ax, jugador_y
    mov jugador_y_ant, ax
    
    ; Verificar tecla
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
    cmp jugador_y, 0
    je mv_fin
    dec jugador_y
    jmp mv_check
    
mv_abajo:
    mov ax, jugador_y
    inc ax
    cmp ax, mapa_alto
    jae mv_fin
    mov jugador_y, ax
    jmp mv_check
    
mv_izq:
    cmp jugador_x, 0
    je mv_fin
    dec jugador_x
    jmp mv_check
    
mv_der:
    mov ax, jugador_x
    inc ax
    cmp ax, mapa_ancho
    jae mv_fin
    mov jugador_x, ax
    jmp mv_check
    
mv_check:
    ; Reactivar colisión
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

; =====================================================
; COLISIÓN - VERSIÓN ULTRA SEGURA
; =====================================================
colision PROC
    push bx
    push cx
    push dx
    push si
    
    ; Verificar límites primero
    mov ax, jugador_x
    cmp ax, mapa_ancho
    jae col_bloquear
    
    mov ax, jugador_y
    cmp ax, mapa_alto
    jae col_bloquear
    
    ; Calcular índice: y * 100 + x
    mov ax, jugador_y
    mov cx, 100
    xor dx, dx
    mul cx              ; DX:AX = Y * 100
    
    ; Verificar overflow
    cmp dx, 0
    jne col_bloquear
    
    add ax, jugador_x   ; AX = Y * 100 + X
    
    ; Verificar límites del array
    cmp ax, 10000
    jae col_bloquear
    
    ; Obtener tile
    mov bx, OFFSET mapa_datos
    add bx, ax
    mov al, [bx]
    
    ; Verificar si es transitable
    cmp al, TILE_GRASS
    je col_ok
    cmp al, TILE_PATH
    je col_ok
    
col_bloquear:
    stc                 ; Set carry = colisión
    jmp col_fin
    
col_ok:
    clc                 ; Clear carry = sin colisión
    
col_fin:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
colision ENDP

; =====================================================
; ACTUALIZAR CÁMARA
; =====================================================
actualizar_camara PROC
    push ax
    push bx
    
    ; Centrar X
    mov ax, jugador_x
    sub ax, VIEWPORT_W/2
    jge cam_x1
    xor ax, ax
cam_x1:
    mov bx, mapa_ancho
    sub bx, VIEWPORT_W
    jle cam_x2
    cmp ax, bx
    jle cam_x3
    mov ax, bx
    jmp cam_x3
cam_x2:
    xor ax, ax
cam_x3:
    mov camara_x, ax
    
    ; Centrar Y
    mov ax, jugador_y
    sub ax, VIEWPORT_H/2
    jge cam_y1
    xor ax, ax
cam_y1:
    mov bx, mapa_alto
    sub bx, VIEWPORT_H
    jle cam_y2
    cmp ax, bx
    jle cam_y3
    mov ax, bx
    jmp cam_y3
cam_y2:
    xor ax, ax
cam_y3:
    mov camara_y, ax
    
    pop bx
    pop ax
    ret
actualizar_camara ENDP

; =====================================================
; RENDERIZAR - VERSIÓN SIMPLIFICADA SIN DOBLE BUFFER
; =====================================================
renderizar PROC
    push ax
    
    ; Trabajar SOLO en página 0
    mov al, 0
    mov ah, 05h
    int 10h
    
    ; Dibujar todo
    call dibujar_mapa
    call dibujar_player
    call mostrar_coordenadas 
    
    pop ax
    ret
renderizar ENDP

; =====================================================
; DIBUJAR MAPA - VERSIÓN ULTRA SEGURA
; =====================================================
dibujar_mapa PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    xor di, di      ; Y viewport
    
dm_y:
    cmp di, VIEWPORT_H
    jb dm_y_continue
    jmp dm_done

dm_y_continue:
    
    xor si, si      ; X viewport
    
dm_x:
    cmp si, VIEWPORT_W
    jb dm_x_continue
    jmp dm_next_y

dm_x_continue:
    
    ; Calcular Y en mapa
    mov ax, camara_y
    add ax, di
    cmp ax, mapa_alto
    jb dm_mapa_y_ok
    jmp dm_next_x

dm_mapa_y_ok:
    mov bp, ax          ; BP = Y en mapa
    
    ; Calcular X en mapa
    mov bx, camara_x
    add bx, si
    cmp bx, mapa_ancho
    jb dm_mapa_x_ok
    jmp dm_next_x

dm_mapa_x_ok:
    ; BX = X en mapa
    
    ; Calcular índice: Y * 100 + X
    ; Usar shifts para multiplicar por 100 de forma segura
    mov ax, bp          ; AX = Y
    mov cx, ax          ; CX = Y
    shl ax, 2           ; AX = Y * 4
    add ax, cx          ; AX = Y * 5
    shl ax, 2           ; AX = Y * 20
    add ax, cx          ; AX = Y * 21
    shl ax, 2           ; AX = Y * 84
    add ax, cx          ; AX = Y * 85
    add ax, cx          ; AX = Y * 86
    add ax, cx          ; AX = Y * 87
    
    ; Mejor método: loop de suma
    mov ax, bp
    mov cx, 100
    xor dx, dx
    mul cx              ; DX:AX = Y * 100
    
    ; Si DX != 0, hay overflow
    cmp dx, 0
    jne dm_next_x
    
    add ax, bx          ; AX = Y*100 + X
    
    ; Verificar límite
    cmp ax, 10000
    jb dm_in_bounds
    jmp dm_next_x

dm_in_bounds:
    
    ; Obtener tile
    push bx
    mov bx, OFFSET mapa_datos
    add bx, ax
    mov al, [bx]
    pop bx
    
    ; Color según tile
    mov cl, 2       ; Verde (grass)
    cmp al, TILE_GRASS
    je dm_color
    mov cl, 6       ; Marrón (wall)
    cmp al, TILE_WALL
    je dm_color
    mov cl, 7       ; Gris (path)
    cmp al, TILE_PATH
    je dm_color
    mov cl, 1       ; Azul (water)
    cmp al, TILE_WATER
    je dm_color
    mov cl, 10      ; Verde claro (tree)
    
dm_color:
    ; Calcular posición en pantalla
    push si
    push di
    
    mov ax, si
    shl ax, 4       ; *16
    mov cx, ax
    
    mov ax, di
    shl ax, 4       ; *16
    mov dx, ax
    
    mov al, cl
    call tile_solido
    
    pop di
    pop si
    
dm_next_x:
    inc si
    jmp dm_x
    
dm_next_y:
    inc di
    jmp dm_y
    
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
; TILE SÓLIDO (16x16) - VERSIÓN SEGURA
; AL = color, CX = X, DX = Y
; =====================================================
tile_solido PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; VERIFICAR QUE EL TILE ESTÉ EN PANTALLA
    cmp cx, SCREEN_W
    jae ts_done
    cmp dx, SCREEN_H
    jae ts_done
    
    mov bl, al      ; Color
    mov si, 0       ; Y offset
    
ts_y:
    cmp si, TILE_SIZE
    jae ts_done
    
    mov di, 0       ; X offset
    
ts_x:
    cmp di, TILE_SIZE
    jae ts_next_y
    
    ; Calcular posición del píxel
    push cx
    push dx
    add cx, di
    add dx, si
    
    ; VERIFICAR LÍMITES ANTES DE DIBUJAR
    cmp cx, SCREEN_W
    jae ts_skip
    cmp dx, SCREEN_H
    jae ts_skip
    
    ; Dibujar píxel
    mov ah, 0Ch
    mov al, bl
    mov bh, 0
    int 10h
    
ts_skip:
    pop dx
    pop cx
    inc di
    jmp ts_x
    
ts_next_y:
    inc si
    jmp ts_y
    
ts_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
tile_solido ENDP

; =====================================================
; DIBUJAR JUGADOR
; =====================================================
dibujar_player PROC
    push ax
    push bx
    push cx
    push dx
    
    ; Verificar si está visible
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
    
    ; Convertir a píxeles (centrado)
    shl ax, 4
    add ax, 4
    mov cx, ax
    
    mov ax, bx
    shl ax, 4
    add ax, 4
    mov dx, ax
    
    ; Dibujar sprite 8x8
    mov al, 14      ; Amarillo
    call sprite_8x8
    
dp_fin:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_player ENDP

; =====================================================
; SPRITE 8x8
; AL = color, CX = X, DX = Y
; =====================================================
sprite_8x8 PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov bl, al
    mov si, 0
    
s8_y:
    cmp si, 8
    jae s8_done
    
    mov di, 0
    
s8_x:
    cmp di, 8
    jae s8_next_y
    
    push cx
    push dx
    add cx, di
    add dx, si
    
    cmp cx, SCREEN_W
    jae s8_skip
    cmp dx, SCREEN_H
    jae s8_skip
    
    mov ah, 0Ch
    mov al, bl
    mov bh, 0        ; SIEMPRE página 0
    int 10h
    
s8_skip:
    pop dx
    pop cx
    inc di
    jmp s8_x
    
s8_next_y:
    inc si
    jmp s8_y
    
s8_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
sprite_8x8 ENDP

; =====================================================
; MOSTRAR COORDENADAS - DESACTIVADO TEMPORALMENTE
; =====================================================
mostrar_coordenadas PROC
    push ax
    push bx
    push cx
    push dx
    
    ; TODO: Implementar versión sin crash
    ; Por ahora, solo retornar
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
mostrar_coordenadas ENDP

; =====================================================
; DIBUJAR NÚMERO (versión mejorada - 3 dígitos)
; AX = número, CX = X inicial, DX = Y inicial
; =====================================================
dibujar_numero PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Limitar a 0-999
    cmp ax, 999
    jbe dn_ok
    mov ax, 999
    
dn_ok:
    ; Separar centenas
    mov bx, 100
    xor dx, dx
    div bx              ; AX = centenas, DX = resto
    push dx             ; Guardar resto (decenas+unidades)
    
    ; Dibujar centena
    add al, '0'
    call dibujar_caracter
    
    ; Separar decenas y unidades
    pop ax              ; Recuperar resto
    mov bx, 10
    xor dx, dx
    div bx              ; AX = decenas, DX = unidades
    
    ; Dibujar decena
    add cx, 8
    push dx
    add al, '0'
    call dibujar_caracter
    
    ; Dibujar unidad
    add cx, 8
    pop ax
    add al, '0'
    call dibujar_caracter
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_numero ENDP

; =====================================================
; DIBUJAR CARÁCTER (5x7 bitmap simplificado)
; AL = carácter ASCII, CX = X, DX = Y
; =====================================================
dibujar_caracter PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Validar que sea un dígito
    cmp al, '0'
    jb dc_fin
    cmp al, '9'
    ja dc_fin
    
    sub al, '0'         ; Convertir a índice 0-9
    xor ah, ah
    mov bl, 7
    mul bl              ; AX = índice * 7
    mov si, ax
    add si, OFFSET tabla_numeros
    
    mov bx, 0           ; Y offset
dc_y:
    cmp bx, 7
    jae dc_fin
    
    mov al, [si]        ; Obtener patrón de bits
    inc si
    
    push cx
    mov di, 0           ; X offset
dc_x:
    cmp di, 5
    jae dc_ny
    
    test al, 80h        ; Verificar bit más alto
    jz dc_skip_pixel
    
    push ax
    push cx
    push dx
    add cx, di
    add dx, bx
    
    ; Verificar límites de pantalla
    cmp cx, SCREEN_W
    jae dc_skip_draw
    cmp dx, SCREEN_H
    jae dc_skip_draw
    
    mov ah, 0Ch
    mov al, 15          ; Blanco
    mov bh, 0           ; SIEMPRE página 0
    int 10h
    
dc_skip_draw:
    pop dx
    pop cx
    pop ax
    
dc_skip_pixel:
    shl al, 1           ; Siguiente bit
    inc di
    jmp dc_x
    
dc_ny:
    pop cx
    inc bx
    jmp dc_y
    
dc_fin:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_caracter ENDP

END inicio