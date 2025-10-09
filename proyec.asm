; =====================================================
; JUEGO DE EXPLORACIÓN - MODO EGA 0Dh (320x200x16)
; Universidad Nacional - Proyecto II Ciclo 2025
; Código optimizado con doble buffer
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
jugador_x   dw 15       ; Centro del mapa 100x100
jugador_y   dw 15
jugador_x_ant dw 15
jugador_y_ant dw 15

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
    
    ; Configurar doble buffer
    mov pagina_visible, 0
    mov pagina_dibujo, 1
    
    ; Activar página 0
    mov al, 0
    mov ah, 05h
    int 10h
    
    ; Renderizar frame inicial
    call actualizar_camara
    call renderizar

; === BUCLE PRINCIPAL ===
bucle_juego:
    ; Esperar tecla
    mov ah, 1
    int 16h
    jz bucle_juego

    ; Leer tecla
    mov ah, 0
    int 16h
    
    ; Limpiar buffer de teclado
vaciar_buffer:
    push ax
    mov ah, 1
    int 16h
    jz buffer_vacio
    mov ah, 0
    int 16h
    jmp vaciar_buffer
    
buffer_vacio:
    pop ax
    
    ; ESC = salir
    cmp al, 27
    je terminar

    ; Procesar movimiento
    call mover_jugador
    
    ; Renderizar
    call renderizar
    
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
; MOVER JUGADOR
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
    call colision
    jc mv_restaurar
    ;call actualizar_camara
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
; COLISIÓN
; =====================================================
colision PROC
    push ax
    push bx
    push si
    
    mov ax, jugador_y
    mov bx, mapa_ancho
    mul bx
    add ax, jugador_x
    
    mov si, OFFSET mapa_datos
    add si, ax
    mov al, [si]
    
    cmp al, TILE_GRASS
    je col_ok
    cmp al, TILE_PATH
    je col_ok
    
    stc
    jmp col_fin
    
col_ok:
    clc
    
col_fin:
    pop si
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
; RENDERIZAR
; =====================================================
renderizar PROC
    push ax
    
    ; Seleccionar página oculta
    mov al, pagina_dibujo
    mov ah, 05h
    int 10h
    
    ; Dibujar
    call dibujar_mapa
    call dibujar_player
    call mostrar_coordenadas 
    
    ; Intercambiar páginas
    mov al, pagina_dibujo
    mov bl, pagina_visible
    mov pagina_visible, al
    mov pagina_dibujo, bl
    
    ; Mostrar
    mov al, pagina_visible
    mov ah, 05h
    int 10h
    
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
    
    xor di, di      ; Y viewport
    
dm_y:
    cmp di, VIEWPORT_H
    jae dm_done
    
    xor si, si      ; X viewport
    
dm_x:
    cmp si, VIEWPORT_W
    jae dm_next_y
    
    ; Posición en mapa
    mov ax, camara_y
    add ax, di
    cmp ax, mapa_alto
    jae dm_next_x
    
    mov bx, mapa_ancho
    mul bx
    mov bx, camara_x
    add bx, si
    add ax, bx
    
    ; Obtener tile
    push si
    push di
    mov si, OFFSET mapa_datos
    add si, ax
    mov al, [si]
    pop di
    pop si
    
    ; Color según tile
    mov bl, 2       ; Verde (grass)
    cmp al, TILE_GRASS
    je dm_color
    mov bl, 6       ; Marrón (wall)
    cmp al, TILE_WALL
    je dm_color
    mov bl, 7       ; Gris (path)
    cmp al, TILE_PATH
    je dm_color
    mov bl, 1       ; Azul (water)
    cmp al, TILE_WATER
    je dm_color
    mov bl, 10      ; Verde claro (tree)
    
dm_color:
    ; Dibujar tile
    push si
    push di
    
    mov ax, si
    shl ax, 4       ; *16
    mov cx, ax
    
    mov ax, di
    shl ax, 4       ; *16
    mov dx, ax
    
    mov al, bl
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
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_mapa ENDP

; =====================================================
; TILE SÓLIDO (16x16)
; AL = color, CX = X, DX = Y
; =====================================================
tile_solido PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov bl, al      ; Color
    mov si, 0       ; Y offset
    
ts_y:
    cmp si, TILE_SIZE
    jae ts_done
    
    mov di, 0       ; X offset
    
ts_x:
    cmp di, TILE_SIZE
    jae ts_next_y
    
    ; Calcular posición
    push cx
    push dx
    add cx, di
    add dx, si
    
    cmp cx, SCREEN_W
    jae ts_skip
    cmp dx, SCREEN_H
    jae ts_skip
    
    ; Dibujar píxel
    mov ah, 0Ch
    mov al, bl
    mov bh, pagina_dibujo
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
    mov bh, pagina_dibujo
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

mostrar_coordenadas PROC
    push ax
    push bx
    push cx
    push dx
    push si
    
    ; Dibujar recuadro negro para las coordenadas
    mov cx, 250
    mov dx, 5
    mov si, 0
mc_fondo:
    cmp si, 10
    jae mc_numeros
    
    push cx
    mov di, 0
mc_fondo_x:
    cmp di, 60
    jae mc_fondo_ny
    
    mov ah, 0Ch
    mov al, 0  ; Negro
    mov bh, pagina_dibujo
    int 10h
    
    inc cx
    inc di
    jmp mc_fondo_x
    
mc_fondo_ny:
    pop cx
    inc dx
    inc si
    jmp mc_fondo
    
mc_numeros:
    ; Mostrar X
    mov cx, 255
    mov dx, 5
    
    ; Dibujar "X:"
    mov ah, 0Ch
    mov al, 15  ; Blanco
    mov bh, pagina_dibujo
    int 10h
    add cx, 2
    int 10h
    add cx, 2
    int 10h
    
    ; Mostrar valor de X
    add cx, 5
    mov ax, jugador_x
    mov bl, 10
    div bl
    
    ; Decenas
    push ax
    add al, '0'
    sub al, '0'
    mov si, 0
mc_x_dec:
    cmp si, al
    jae mc_x_uni
    
    push cx
    mov ah, 0Ch
    mov al, 15
    mov bh, pagina_dibujo
    int 10h
    pop cx
    add cx, 2
    inc si
    jmp mc_x_dec
    
mc_x_uni:
    ; Unidades
    pop ax
    mov al, ah
    add cx, 5
    mov si, 0
mc_x_uni_loop:
    cmp si, al
    jae mc_y
    
    push cx
    mov ah, 0Ch
    mov al, 15
    mov bh, pagina_dibujo
    int 10h
    pop cx
    add cx, 2
    inc si
    jmp mc_x_uni_loop
    
mc_y:
    ; Mostrar Y
    mov cx, 255
    mov dx, 10
    
    ; Dibujar "Y:"
    mov ah, 0Ch
    mov al, 15
    mov bh, pagina_dibujo
    int 10h
    add cx, 2
    int 10h
    add cx, 2
    int 10h
    add cx, 2
    int 10h
    
    ; Mostrar valor de Y
    add cx, 3
    mov ax, jugador_y
    mov bl, 10
    div bl
    
    ; Decenas
    push ax
    add al, '0'
    sub al, '0'
    mov si, 0
mc_y_dec:
    cmp si, al
    jae mc_y_uni
    
    push cx
    mov ah, 0Ch
    mov al, 15
    mov bh, pagina_dibujo
    int 10h
    pop cx
    add cx, 2
    inc si
    jmp mc_y_dec
    
mc_y_uni:
    ; Unidades
    pop ax
    mov al, ah
    add cx, 5
    mov si, 0
mc_y_uni_loop:
    cmp si, al
    jae mc_fin
    
    push cx
    mov ah, 0Ch
    mov al, 15
    mov bh, pagina_dibujo
    int 10h
    pop cx
    add cx, 2
    inc si
    jmp mc_y_uni_loop
    
mc_fin:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
mostrar_coordenadas ENDP
END inicio