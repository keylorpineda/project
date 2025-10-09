; =====================================================
; JUEGO DE EXPLORACIÓN - MODO EGA 0Dh (320x200x16)
; Universidad Nacional - Proyecto II Ciclo 2025
; Código optimizado con doble buffer y movimiento visible
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
VIEWPORT_W  EQU 20      ; Aumentado para ver más mapa
VIEWPORT_H  EQU 12      ; Aumentado para ver más mapa

.DATA
; === ARCHIVOS ===
archivo_mapa db 'MAPA.TXT',0

; === MAPA ===
mapa_ancho  dw 100
mapa_alto   dw 100
mapa_datos  db 10000 dup(0)

; === JUGADOR ===
jugador_x   dw 50       ; Centro del mapa 100x100
jugador_y   dw 50
jugador_x_ant dw 50
jugador_y_ant dw 50

; === CÁMARA ===
camara_x    dw 0
camara_y    dw 0
camara_x_ant dw 0
camara_y_ant dw 0

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
msg_listo  db 13,10,'Sistema listo. Viewport: 20x12 tiles',13,10
           db 'Controles: Flechas o WASD = Mover, ESC = Salir',13,10
           db 'Presiona tecla para iniciar...$'

; === INDICADOR DE POSICIÓN ===
msg_pos    db 'Pos: $'
msg_coma   db ', $'

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
; GENERAR MAPA PROCEDURAL MEJORADO
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
    ; Calcular coordenadas X,Y
    mov ax, bx
    xor dx, dx
    mov si, 100
    div si          ; AX = Y, DX = X
    
    ; Verificar bordes
    cmp ax, 0
    jne gen_check_ax_max
    jmp gen_wall

gen_check_ax_max:
    cmp ax, 99
    jne gen_check_dx_min
    jmp gen_wall

gen_check_dx_min:
    cmp dx, 0
    jne gen_check_dx_max
    jmp gen_wall

gen_check_dx_max:
    cmp dx, 99
    jne gen_check_done
    jmp gen_wall

gen_check_done:
    
    ; Zona inicio (48-52, 48-52) - siempre césped
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
    ; Crear patrones más interesantes
    push ax
    push dx
    
    ; Crear ríos (líneas de agua)
    cmp ax, 30
    jne no_river1
    cmp dx, 20
    jb no_river1
    cmp dx, 80
    ja no_river1
    mov al, TILE_WATER
    jmp gen_save_pop
    
no_river1:
    cmp ax, 70
    jne no_river2
    cmp dx, 15
    jb no_river2
    cmp dx, 85
    ja no_river2
    mov al, TILE_WATER
    jmp gen_save_pop
    
no_river2:
    ; Crear caminos
    cmp dx, 50
    jne no_path1
    cmp ax, 10
    jb no_path1
    cmp ax, 90
    ja no_path1
    mov al, TILE_PATH
    jmp gen_save_pop
    
no_path1:
    cmp ax, 50
    jne no_path2
    cmp dx, 10
    jb no_path2
    cmp dx, 90
    ja no_path2
    mov al, TILE_PATH
    jmp gen_save_pop
    
no_path2:
    ; Bosques en ciertas zonas
    cmp ax, 20
    jb gen_grass
    cmp ax, 40
    ja check_forest2
    cmp dx, 60
    jb gen_grass
    cmp dx, 80
    ja gen_grass
    mov al, TILE_TREE
    jmp gen_save_pop
    
check_forest2:
    cmp ax, 60
    jb gen_grass
    cmp ax, 80
    ja gen_grass
    cmp dx, 20
    jb gen_grass
    cmp dx, 40
    ja gen_grass
    mov al, TILE_TREE
    jmp gen_save_pop
    
gen_grass:
    mov al, TILE_GRASS
    
gen_save_pop:
    pop dx
    pop ax
    jmp gen_save
    
gen_wall:
    mov al, TILE_WALL
    
gen_save:
    mov [di], al
    inc di
    inc bx
    loop gen_loop_jmp
    jmp gen_done
    
gen_loop_jmp:
    jmp gen_loop
    
gen_done:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
generar_procedural ENDP

; =====================================================
; CARGAR MAPA (simplificado)
; =====================================================
cargar_mapa PROC
    push ax
    push dx
    
    ; Por ahora solo generar procedural
    mov dx, OFFSET msg_generando
    mov ah, 9
    int 21h
    
    call generar_procedural
    
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    pop dx
    pop ax
    ret
cargar_mapa ENDP

; =====================================================
; MOVER JUGADOR CON FEEDBACK VISUAL
; =====================================================
mover_jugador PROC
    push ax
    push bx
    
    ; Guardar posición y cámara anterior
    mov ax, jugador_x
    mov jugador_x_ant, ax
    mov ax, jugador_y
    mov jugador_y_ant, ax
    mov ax, camara_x
    mov camara_x_ant, ax
    mov ax, camara_y
    mov camara_y_ant, ax
    
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
    call actualizar_camara
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
; RENDERIZAR CON INDICADOR DE POSICIÓN
; =====================================================
renderizar PROC
    push ax
    
    ; Seleccionar página oculta
    mov al, pagina_dibujo
    mov ah, 05h
    int 10h
    
    ; Limpiar página
    call limpiar_pantalla
    
    ; Dibujar
    call dibujar_mapa
    call dibujar_player
    call mostrar_posicion
    
    ; Esperar vsync
    mov dx, 03DAh
vsync1:
    in al, dx
    test al, 8
    jnz vsync1
vsync2:
    in al, dx
    test al, 8
    jz vsync2
    
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
; LIMPIAR PANTALLA
; =====================================================
limpiar_pantalla PROC
    push ax
    push bx
    push cx
    push dx
    
    ; Llenar con negro
    xor cx, cx
    xor dx, dx
lp_loop:
    mov ah, 0Ch
    mov al, 0
    mov bh, pagina_dibujo
    int 10h
    
    inc cx
    cmp cx, SCREEN_W
    jb lp_loop
    
    xor cx, cx
    inc dx
    cmp dx, SCREEN_H
    jb lp_loop
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
limpiar_pantalla ENDP

; =====================================================
; MOSTRAR POSICIÓN EN PANTALLA
; =====================================================
mostrar_posicion PROC
    push ax
    push bx
    push cx
    push dx
    
    ; Mostrar coordenadas en esquina superior
    mov cx, 5
    mov dx, 5
    
    ; Dibujar fondo para texto
    mov al, 0
    call draw_rect_8x16
    
    ; Mostrar X
    mov ax, jugador_x
    mov bl, 15      ; Blanco
    call mostrar_numero
    
    ; Separador
    add cx, 20
    mov al, 15
    call draw_pixel
    add cx, 2
    call draw_pixel
    add cx, 2
    
    ; Mostrar Y
    mov ax, jugador_y
    mov bl, 15
    call mostrar_numero
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
mostrar_posicion ENDP

; =====================================================
; MOSTRAR NÚMERO EN PANTALLA
; CX,DX = posición, AX = número, BL = color
; =====================================================
mostrar_numero PROC
    push ax
    push cx
    push dx
    
    ; Simplificado: mostrar solo 2 dígitos
    push ax
    xor ah, ah
    mov al, 10
    div al
    
    ; Decenas
    add al, '0'
    sub al, '0'
    push ax
    mov al, bl
    call draw_digit
    pop ax
    
    add cx, 6
    
    ; Unidades
    mov al, ah
    add al, '0'
    sub al, '0'
    mov al, bl
    call draw_digit
    
    pop ax
    
    pop dx
    pop cx
    pop ax
    ret
mostrar_numero ENDP

; =====================================================
; DIBUJAR DÍGITO SIMPLE
; =====================================================
draw_digit PROC
    ; Simplificado: solo dibujar un punto por dígito
    call draw_pixel
    ret
draw_digit ENDP

; =====================================================
; DIBUJAR PIXEL
; CX = X, DX =; =====================================================
; DIBUJAR PIXEL
; CX = X, DX = Y, AL = color
; =====================================================
draw_pixel PROC
    push ax
    push bx
    
    mov ah, 0Ch
    mov bh, pagina_dibujo
    int 10h
    
    pop bx
    pop ax
    ret
draw_pixel ENDP

; =====================================================
; DIBUJAR RECTÁNGULO PEQUEÑO
; =====================================================
draw_rect_8x16 PROC
    push ax
    push cx
    push dx
    push si
    push di
    
    mov si, 0
dr_y:
    cmp si, 16
    jae dr_done
    
    mov di, 0
dr_x:
    cmp di, 8
    jae dr_ny
    
    push cx
    push dx
    add cx, di
    add dx, si
    call draw_pixel
    pop dx
    pop cx
    
    inc di
    jmp dr_x
    
dr_ny:
    inc si
    jmp dr_y
    
dr_done:
    pop di
    pop si
    pop dx
    pop cx
    pop ax
    ret
draw_rect_8x16 ENDP

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
; ACTUALIZAR CÁMARA - MEJORADA
; =====================================================
actualizar_camara PROC
    push ax
    push bx
    
    ; Centrar X con margen
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
    
    ; Centrar Y con margen
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
; DIBUJAR MAPA - OPTIMIZADO
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
    cmp bx, mapa_ancho
    jae dm_next_x
    add ax, bx
    
    ; Obtener tile
    push si
    push di
    mov bx, OFFSET mapa_datos
    add bx, ax
    mov al, [bx]
    pop di
    pop si
    
    ; Color según tile con variación
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
    call tile_rapido
    
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
; TILE RÁPIDO - Optimizado para velocidad
; AL = color, CX = X, DX = Y
; =====================================================
tile_rapido PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov bl, al      ; Color
    
    ; Dibujar líneas horizontales (más rápido)
    mov si, 0       ; Y offset
    
tr_y:
    cmp si, TILE_SIZE
    jae tr_done
    
    push cx
    push dx
    add dx, si
    
    cmp dx, SCREEN_H
    jae tr_skip_line
    
    ; Dibujar línea horizontal completa
    mov di, 0
tr_x:
    cmp di, TILE_SIZE
    jae tr_skip_line
    
    push cx
    add cx, di
    
    cmp cx, SCREEN_W
    jae tr_skip_pixel
    
    mov ah, 0Ch
    mov al, bl
    mov bh, pagina_dibujo
    int 10h
    
tr_skip_pixel:
    pop cx
    inc di
    jmp tr_x
    
tr_skip_line:
    pop dx
    pop cx
    inc si
    jmp tr_y
    
tr_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
tile_rapido ENDP

; =====================================================
; DIBUJAR JUGADOR - MEJORADO
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
    
    ; Dibujar sprite del jugador con animación
    call dibujar_sprite_jugador
    
dp_fin:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_player ENDP

; =====================================================
; DIBUJAR SPRITE JUGADOR CON FORMA
; CX = X, DX = Y
; =====================================================
dibujar_sprite_jugador PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Dibujar forma de jugador (cruz o diamante)
    ; Para hacerlo más visible
    
    ; Cuerpo principal (8x8)
    mov si, 0
dsj_y:
    cmp si, 8
    jae dsj_borde
    
    mov di, 0
dsj_x:
    cmp di, 8
    jae dsj_next_y
    
    push cx
    push dx
    add cx, di
    add dx, si
    
    cmp cx, SCREEN_W
    jae dsj_skip
    cmp dx, SCREEN_H
    jae dsj_skip
    
    ; Color amarillo brillante para el centro
    mov al, 14
    
    ; Hacer forma de diamante
    mov bx, si
    cmp bx, 0
    je dsj_borde_pixel
    cmp bx, 7
    je dsj_borde_pixel
    cmp di, 0
    je dsj_borde_pixel
    cmp di, 7
    je dsj_borde_pixel
    jmp dsj_draw
    
dsj_borde_pixel:
    mov al, 12      ; Rojo para el borde
    
dsj_draw:
    mov ah, 0Ch
    mov bh, pagina_dibujo
    int 10h
    
dsj_skip:
    pop dx
    pop cx
    inc di
    jmp dsj_x
    
dsj_next_y:
    inc si
    jmp dsj_y
    
dsj_borde:
    ; Dibujar indicador de dirección (pequeña flecha)
    ; Esto hace más evidente el movimiento
    push cx
    push dx
    
    ; Flecha arriba
    sub dx, 2
    mov al, 15      ; Blanco
    call draw_pixel
    
    ; Restaurar posición
    pop dx
    pop cx
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_sprite_jugador ENDP

END inicio