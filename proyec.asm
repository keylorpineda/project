; =====================================================
; JUEGO DE EXPLORACIÓN - MODO EGA 0Dh (320x200x16)
; Universidad Nacional - Proyecto II Ciclo 2025
; Viewport pequeño con movimiento visible
; =====================================================

.MODEL SMALL
.STACK 4096

; === CONSTANTES ===
TILE_GRASS  EQU 0
TILE_WALL   EQU 1
TILE_PATH   EQU 2
TILE_WATER  EQU 3
TILE_TREE   EQU 4

TILE_SIZE   EQU 20      ; Tiles más grandes
SCREEN_W    EQU 320
SCREEN_H    EQU 200
VIEWPORT_W  EQU 10      ; Solo 10 tiles horizontales (200 píxeles)
VIEWPORT_H  EQU 8       ; Solo 8 tiles verticales (160 píxeles)

.DATA
; === MAPA ===
mapa_ancho  dw 50       ; Mapa más pequeño para mejor rendimiento
mapa_alto   dw 50
mapa_datos  db 2500 dup(0)

; === JUGADOR ===
jugador_x   dw 25       ; Centro del mapa
jugador_y   dw 25
jugador_x_ant dw 25
jugador_y_ant dw 25

; === CÁMARA ===
camara_x    dw 20
camara_y    dw 21

; === DOBLE BUFFER ===
pagina_visible db 0
pagina_dibujo  db 1

; === MENSAJES ===
msg_titulo  db 'JUEGO DE EXPLORACION',13,10
           db '====================',13,10,'$'
msg_generando db 'Generando mapa 50x50...$'
msg_ok     db 'OK',13,10,'$'
msg_listo  db 13,10,'Viewport: 10x8 tiles (200x160 pixels)',13,10
           db 'El mapa se mueve alrededor del jugador',13,10
           db 'Controles: Flechas/WASD = Mover, ESC = Salir',13,10
           db 'Presiona tecla para iniciar...$'

.CODE
inicio:
    mov ax, @data
    mov ds, ax

    ; Mostrar título
    mov dx, OFFSET msg_titulo
    mov ah, 9
    int 21h

    ; Generar mapa
    mov dx, OFFSET msg_generando
    mov ah, 9
    int 21h
    call generar_mapa_simple
    
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
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
    
    ; ESC = salir
    cmp al, 27
    je terminar

    ; Procesar movimiento
    call mover_jugador
    
    jmp bucle_juego

terminar:
    ; Volver a modo texto
    mov ax, 3
    int 10h
    
    ; Salir
    mov ax, 4C00h
    int 21h

; =====================================================
; GENERAR MAPA SIMPLE CON PATRONES CLAROS
; =====================================================
generar_mapa_simple PROC
    push ax
    push bx
    push cx
    push dx
    push di
    
    mov di, OFFSET mapa_datos
    xor dx, dx      ; Y = 0
    
gen_y:
    cmp dx, 50
    jae gen_done
    
    xor cx, cx      ; X = 0
gen_x:
    cmp cx, 50
    jae gen_next_y
    
    ; Bordes = muros
    cmp dx, 0
    je gen_muro
    cmp dx, 49
    je gen_muro
    cmp cx, 0
    je gen_muro
    cmp cx, 49
    je gen_muro
    
    ; Centro (23-27, 23-27) = césped limpio
    cmp dx, 23
    jb gen_pattern
    cmp dx, 27
    ja gen_pattern
    cmp cx, 23
    jb gen_pattern
    cmp cx, 27
    ja gen_pattern
    mov al, TILE_GRASS
    jmp gen_store
    
gen_pattern:
    ; Crear patrón de tablero de ajedrez para ver movimiento
    mov ax, dx
    add ax, cx
    and ax, 3
    
    cmp ax, 0
    je gen_agua
    cmp ax, 1
    je gen_arbol
    cmp ax, 2
    je gen_camino
    mov al, TILE_GRASS
    jmp gen_store
    
gen_agua:
    mov al, TILE_WATER
    jmp gen_store
    
gen_arbol:
    mov al, TILE_TREE
    jmp gen_store
    
gen_camino:
    mov al, TILE_PATH
    jmp gen_store
    
gen_muro:
    mov al, TILE_WALL
    
gen_store:
    mov [di], al
    inc di
    inc cx
    jmp gen_x
    
gen_next_y:
    inc dx
    jmp gen_y
    
gen_done:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
generar_mapa_simple ENDP

; =====================================================
; MOVER JUGADOR
; =====================================================
mover_jugador PROC
    push ax
    push bx
    
    ; Guardar posición anterior
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
    cmp jugador_y, 1
    jle mv_fin
    dec jugador_y
    jmp mv_check
    
mv_abajo:
    cmp jugador_y, 48
    jge mv_fin
    inc jugador_y
    jmp mv_check
    
mv_izq:
    cmp jugador_x, 1
    jle mv_fin
    dec jugador_x
    jmp mv_check
    
mv_der:
    cmp jugador_x, 48
    jge mv_fin
    inc jugador_x
    jmp mv_check
    
mv_check:
    call verificar_colision
    jc mv_restaurar
    
    ; Actualizar cámara y renderizar
    call actualizar_camara
    call renderizar
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
; VERIFICAR COLISIÓN
; =====================================================
verificar_colision PROC
    push ax
    push bx
    push si
    
    mov ax, jugador_y
    mov bx, 50      ; ancho del mapa
    mul bx
    add ax, jugador_x
    
    mov si, OFFSET mapa_datos
    add si, ax
    mov al, [si]
    
    ; Solo césped y camino son transitables
    cmp al, TILE_GRASS
    je vc_ok
    cmp al, TILE_PATH
    je vc_ok
    
    stc     ; Colisión
    jmp vc_fin
    
vc_ok:
    clc     ; Sin colisión
    
vc_fin:
    pop si
    pop bx
    pop ax
    ret
verificar_colision ENDP

; =====================================================
; ACTUALIZAR CÁMARA (SEGUIR AL JUGADOR)
; =====================================================
actualizar_camara PROC
    push ax
    push bx
    
    ; Centrar cámara en jugador X
    mov ax, jugador_x
    sub ax, VIEWPORT_W/2
    cmp ax, 0
    jge ac_x1
    xor ax, ax
ac_x1:
    mov bx, 50          ; ancho mapa
    sub bx, VIEWPORT_W
    cmp ax, bx
    jle ac_x2
    mov ax, bx
ac_x2:
    mov camara_x, ax
    
    ; Centrar cámara en jugador Y
    mov ax, jugador_y
    sub ax, VIEWPORT_H/2
    cmp ax, 0
    jge ac_y1
    xor ax, ax
ac_y1:
    mov bx, 50          ; alto mapa
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
; RENDERIZAR
; =====================================================
renderizar PROC
    push ax
    
    ; Seleccionar página oculta
    mov al, pagina_dibujo
    mov ah, 05h
    int 10h
    
    ; Limpiar pantalla con borde
    call limpiar_con_borde
    
    ; Dibujar viewport
    call dibujar_viewport
    
    ; Dibujar jugador (siempre en el centro del viewport)
    call dibujar_jugador
    
    ; Mostrar info
    call mostrar_info
    
    ; Esperar vsync
    mov dx, 03DAh
vs1:
    in al, dx
    test al, 8
    jnz vs1
vs2:
    in al, dx
    test al, 8
    jz vs2
    
    ; Intercambiar páginas
    mov al, pagina_dibujo
    mov bl, pagina_visible
    mov pagina_visible, al
    mov pagina_dibujo, bl
    
    ; Mostrar página visible
    mov al, pagina_visible
    mov ah, 05h
    int 10h
    
    pop ax
    ret
renderizar ENDP

; =====================================================
; LIMPIAR CON BORDE
; =====================================================
limpiar_con_borde PROC
    push ax
    push bx
    push cx
    push dx
    
    ; Llenar toda la pantalla con color de borde (gris oscuro)
    xor dx, dx
lcb_y:
    cmp dx, SCREEN_H
    jae lcb_done
    
    xor cx, cx
lcb_x:
    cmp cx, SCREEN_W
    jae lcb_ny
    
    mov ah, 0Ch
    mov al, 8       ; Gris oscuro para el borde
    mov bh, pagina_dibujo
    int 10h
    
    inc cx
    jmp lcb_x
    
lcb_ny:
    inc dx
    jmp lcb_y
    
lcb_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
limpiar_con_borde ENDP

; =====================================================
; DIBUJAR VIEWPORT (VENTANA DEL MUNDO)
; =====================================================
dibujar_viewport PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Offset para centrar viewport en pantalla
    mov bp, 60      ; Offset X (centrar 200 píxeles en 320)
    
    xor di, di      ; Tile Y
dv_y:
    cmp di, VIEWPORT_H
    jae dv_done
    
    xor si, si      ; Tile X
dv_x:
    cmp si, VIEWPORT_W
    jae dv_ny
    
    ; Calcular posición en el mapa
    mov ax, camara_y
    add ax, di
    mov bx, 50      ; ancho mapa
    mul bx
    add ax, camara_x
    add ax, si
    
    ; Obtener tile
    mov bx, OFFSET mapa_datos
    add bx, ax
    mov al, [bx]
    
    ; Calcular posición en pantalla
    mov cx, si
    mov dx, TILE_SIZE
    push ax
    mov ax, cx
    mul dx
    add ax, bp      ; Añadir offset X
    mov cx, ax
    pop ax
    
    push ax
    mov ax, di
    mul dx
    add ax, 20      ; Offset Y
    mov dx, ax
    pop ax
    
    ; Dibujar tile
    call dibujar_tile
    
    inc si
    jmp dv_x
    
dv_ny:
    inc di
    jmp dv_y
    
dv_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_viewport ENDP

; =====================================================
; DIBUJAR TILE
; AL = tipo, CX = X, DX = Y
; =====================================================
dibujar_tile PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Seleccionar color
    mov bl, 2       ; Verde (grass)
    cmp al, TILE_GRASS
    je dt_color
    mov bl, 6       ; Marrón (wall)
    cmp al, TILE_WALL
    je dt_color
    mov bl, 7       ; Gris (path)
    cmp al, TILE_PATH
    je dt_color
    mov bl, 1       ; Azul (water)
    cmp al, TILE_WATER    ; Continuación de dibujar_tile
    je dt_color
    mov bl, 10      ; Verde claro (tree)
    
dt_color:
    ; Dibujar tile de 20x20
    mov si, 0
dt_y:
    cmp si, TILE_SIZE
    jae dt_done
    
    mov di, 0
dt_x:
    cmp di, TILE_SIZE
    jae dt_ny
    
    push cx
    push dx
    add cx, di
    add dx, si
    
    ; Verificar límites
    cmp cx, SCREEN_W
    jae dt_skip
    cmp dx, SCREEN_H
    jae dt_skip
    
    mov ah, 0Ch
    mov al, bl
    mov bh, pagina_dibujo
    int 10h
    
dt_skip:
    pop dx
    pop cx
    inc di
    jmp dt_x
    
dt_ny:
    inc si
    jmp dt_y
    
dt_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_tile ENDP

; =====================================================
; DIBUJAR JUGADOR (SIEMPRE EN CENTRO DEL VIEWPORT)
; =====================================================
dibujar_jugador PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Calcular posición del jugador relativa a la cámara
    mov ax, jugador_x
    sub ax, camara_x
    
    ; Si el jugador está visible en el viewport
    cmp ax, 0
    jl dj_fin
    cmp ax, VIEWPORT_W
    jge dj_fin
    
    mov bx, jugador_y
    sub bx, camara_y
    
    cmp bx, 0
    jl dj_fin
    cmp bx, VIEWPORT_H
    jge dj_fin
    
    ; Convertir a píxeles y centrar en tile
    mov cx, TILE_SIZE
    mul cx
    add ax, 60      ; Offset X del viewport
    add ax, 6       ; Centrar en tile
    mov cx, ax
    
    mov ax, bx
    mov dx, TILE_SIZE
    mul dx
    add ax, 20      ; Offset Y del viewport
    add ax, 6       ; Centrar en tile
    mov dx, ax
    
    ; Dibujar jugador como círculo/diamante
    ; Parte superior
    push cx
    push dx
    add cx, 4
    call pixel_jugador
    pop dx
    pop cx
    
    ; Segunda línea
    push dx
    add dx, 1
    push cx
    add cx, 3
    call pixel_jugador
    add cx, 2
    call pixel_jugador
    pop cx
    pop dx
    
    ; Tercera línea
    push dx
    add dx, 2
    push cx
    add cx, 2
    call pixel_jugador
    add cx, 4
    call pixel_jugador
    pop cx
    pop dx
    
    ; Línea central (más ancha)
    push dx
    add dx, 3
    push cx
    add cx, 1
    mov si, 6
dj_centro:
    call pixel_jugador
    inc cx
    dec si
    jnz dj_centro
    pop cx
    pop dx
    
    ; Línea inferior central
    push dx
    add dx, 4
    push cx
    add cx, 1
    mov si, 6
dj_centro2:
    call pixel_jugador
    inc cx
    dec si
    jnz dj_centro2
    pop cx
    pop dx
    
    ; Penúltima línea
    push dx
    add dx, 5
    push cx
    add cx, 2
    call pixel_jugador
    add cx, 4
    call pixel_jugador
    pop cx
    pop dx
    
    ; Última línea
    push dx
    add dx, 6
    push cx
    add cx, 3
    call pixel_jugador
    add cx, 2
    call pixel_jugador
    pop cx
    pop dx
    
    ; Parte inferior
    add dx, 7
    add cx, 4
    call pixel_jugador
    
dj_fin:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_jugador ENDP

; =====================================================
; PIXEL JUGADOR
; CX = X, DX = Y
; =====================================================
pixel_jugador PROC
    push ax
    push bx
    
    mov ah, 0Ch
    mov al, 14      ; Amarillo brillante
    mov bh, pagina_dibujo
    int 10h
    
    ; Dibujar borde negro para resaltar
    push cx
    push dx
    dec cx
    mov al, 0
    int 10h
    add cx, 2
    int 10h
    pop dx
    pop cx
    
    push cx
    push dx
    dec dx
    mov al, 0
    int 10h
    add dx, 2
    int 10h
    pop dx
    pop cx
    
    pop bx
    pop ax
    ret
pixel_jugador ENDP

; =====================================================
; MOSTRAR INFO (POSICIÓN Y VIEWPORT)
; =====================================================
mostrar_info PROC
    push ax
    push bx
    push cx
    push dx
    
    ; Mostrar "POS:" en la parte superior
    mov cx, 5
    mov dx, 5
    mov al, 15      ; Blanco
    
    ; P
    call draw_letra_P
    add cx, 6
    
    ; O
    call draw_letra_O
    add cx, 6
    
    ; S
    call draw_letra_S
    add cx, 6
    
    ; :
    call draw_dos_puntos
    add cx, 6
    
    ; Mostrar coordenadas X,Y
    mov ax, jugador_x
    call mostrar_numero_simple
    
    add cx, 15
    mov al, 15
    call draw_coma
    add cx, 5
    
    mov ax, jugador_y
    call mostrar_numero_simple
    
    ; Dibujar marco del viewport
    call dibujar_marco_viewport
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
mostrar_info ENDP

; =====================================================
; DIBUJAR MARCO DEL VIEWPORT
; =====================================================
dibujar_marco_viewport PROC
    push ax
    push cx
    push dx
    
    ; Marco superior
    mov cx, 59
    mov dx, 19
    mov al, 15
dmv_top:
    cmp cx, 261
    jae dmv_left
    call draw_pixel_simple
    inc cx
    jmp dmv_top
    
dmv_left:
    ; Marco izquierdo
    mov cx, 59
    mov dx, 19
dmv_left_loop:
    cmp dx, 181
    jae dmv_right
    call draw_pixel_simple
    inc dx
    jmp dmv_left_loop
    
dmv_right:
    ; Marco derecho
    mov cx, 260
    mov dx, 19
dmv_right_loop:
    cmp dx, 181
    jae dmv_bottom
    call draw_pixel_simple
    inc dx
    jmp dmv_right_loop
    
dmv_bottom:
    ; Marco inferior
    mov cx, 59
    mov dx, 180
dmv_bottom_loop:
    cmp cx, 261
    jae dmv_done
    call draw_pixel_simple
    inc cx
    jmp dmv_bottom_loop
    
dmv_done:
    pop dx
    pop cx
    pop ax
    ret
dibujar_marco_viewport ENDP

; =====================================================
; FUNCIONES DE DIBUJO DE TEXTO SIMPLE
; =====================================================
draw_pixel_simple PROC
    push ax
    push bx
    mov ah, 0Ch
    mov bh, pagina_dibujo
    int 10h
    pop bx
    pop ax
    ret
draw_pixel_simple ENDP

draw_letra_P PROC
    push cx
    push dx
    ; Dibujar P simple (5x5)
    call draw_pixel_simple
    inc dx
    call draw_pixel_simple
    inc dx
    call draw_pixel_simple
    inc dx
    call draw_pixel_simple
    inc dx
    call draw_pixel_simple
    sub dx, 4
    inc cx
    call draw_pixel_simple
    inc cx
    call draw_pixel_simple
    inc dx
    inc dx
    call draw_pixel_simple
    dec cx
    call draw_pixel_simple
    pop dx
    pop cx
    ret
draw_letra_P ENDP

draw_letra_O PROC
    push cx
    push dx
    ; Dibujar O simple (5x5)
    inc cx
    call draw_pixel_simple
    inc cx
    call draw_pixel_simple
    dec cx
    dec cx
    inc dx
    call draw_pixel_simple
    add cx, 3
    call draw_pixel_simple
    inc dx
    call draw_pixel_simple
    sub cx, 3
    call draw_pixel_simple
    inc dx
    call draw_pixel_simple
    add cx, 3
    call draw_pixel_simple
    inc dx
    inc cx
    call draw_pixel_simple
    dec cx
    call draw_pixel_simple
    pop dx
    pop cx
    ret
draw_letra_O ENDP

draw_letra_S PROC
    push cx
    push dx
    ; Dibujar S simple
    inc cx
    call draw_pixel_simple
    inc cx
    call draw_pixel_simple
    sub cx, 2
    inc dx
    call draw_pixel_simple
    inc dx
    inc cx
    call draw_pixel_simple
    inc dx
    inc cx
    call draw_pixel_simple
    inc dx
    sub cx, 2
    call draw_pixel_simple
    inc cx
    call draw_pixel_simple
    pop dx
    pop cx
    ret
draw_letra_S ENDP

draw_dos_puntos PROC
    push dx
    add dx, 1
    call draw_pixel_simple
    add dx, 2
    call draw_pixel_simple
    pop dx
    ret
draw_dos_puntos ENDP

draw_coma PROC
    push dx
    add dx, 3
    call draw_pixel_simple
    inc dx
    call draw_pixel_simple
    pop dx
    ret
draw_coma ENDP

mostrar_numero_simple PROC
    push ax
    push cx
    push dx
    
    ; Mostrar solo decenas y unidades
    push ax
    mov bl, 10
    div bl
    
    ; Decenas
    add al, '0'
    cmp al, '0'
    je mns_unidades
    sub al, '0'
    call draw_digito_simple
    
mns_unidades:
    add cx, 5
    mov al, ah
    add al, '0'
    sub al, '0'
    call draw_digito_simple
    
    pop ax
    pop dx
    pop cx
    pop ax
    ret
mostrar_numero_simple ENDP

draw_digito_simple PROC
    ; Simplificado: solo puntos para representar dígitos
    push cx
    push dx
    push ax
    
    mov al, 15
    call draw_pixel_simple
    inc cx
    call draw_pixel_simple
    inc cx
    call draw_pixel_simple
    
    pop ax
    pop dx
    pop cx
    ret
draw_digito_simple ENDP

END inicio