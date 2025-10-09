; =====================================================
; JUEGO EGA - VRAM con DOBLE BUFFER
; Universidad Nacional - Proyecto II Ciclo 2025
; Modo 10h (640x350, 16 colores)
; =====================================================
; 
; DESCRIPCIÓN GENERAL:
; Este juego implementa un sistema de exploración en modo gráfico EGA
; con las siguientes características principales:
; - Mapa de 50x50 tiles cargado desde archivo
; - Sistema de viewport (ventana) de 20x12 tiles
; - Sprites de 16x16 píxeles para tiles del mapa
; - Sprite de 8x8 píxeles para el jugador
; - Doble buffer para evitar parpadeo
; - Sistema de cámara que sigue al jugador
; - Detección de colisiones
;
; =====================================================

.MODEL SMALL
.STACK 2048

; =====================================================
; CONSTANTES DEL JUEGO
; =====================================================
; Tipos de tiles en el mapa
TILE_GRASS  EQU 0    ; Césped (transitable)
TILE_WALL   EQU 1    ; Pared (no transitable)
TILE_PATH   EQU 2    ; Camino (transitable)
TILE_WATER  EQU 3    ; Agua (no transitable)
TILE_TREE   EQU 4    ; Árbol (no transitable)

; Dimensiones
TILE_SIZE   EQU 16   ; Cada tile es 16x16 píxeles
VIEWPORT_W  EQU 20   ; Viewport: 20 tiles de ancho
VIEWPORT_H  EQU 12   ; Viewport: 12 tiles de alto

; Segmento de video EGA
VIDEO_SEG   EQU 0A000h

.DATA
; === VARIABLES DE CONTROL ===
tecla_actual db 0       ; Última tecla presionada
frame_counter db 0      ; Contador para throttling
delay_movimiento db 0   ; Delay entre movimientos (0-2)

; === VARIABLES DE MOVIMIENTO SUAVE ===
velocidad_movimiento dw 2          ; Píxeles por frame
jugador_subpixel_x   dw 0          ; Posición subpixel X (0-15)
jugador_subpixel_y   dw 0          ; Posición subpixel Y (0-15)

; =====================================================
; ARCHIVOS DE RECURSOS
; =====================================================
archivo_mapa   db 'MAPA.TXT',0      ; Mapa 50x50
archivo_grass  db 'GRASS.TXT',0     ; Sprite césped
archivo_wall   db 'WALL.TXT',0      ; Sprite pared
archivo_path   db 'PATH.TXT',0      ; Sprite camino
archivo_water  db 'WATER.TXT',0     ; Sprite agua
archivo_tree   db 'TREE.TXT',0      ; Sprite árbol
archivo_player db 'PLAYER.TXT',0    ; Sprite jugador

; =====================================================
; DATOS DEL MAPA Y SPRITES
; =====================================================
; Mapa: 50x50 = 2500 bytes
; Cada byte representa un tipo de tile (0-4)
mapa_datos  db 2500 dup(0)

; Sprites de tiles: 16x16 = 256 bytes cada uno
sprite_grass  db 256 dup(0)
sprite_wall   db 256 dup(0)
sprite_path   db 256 dup(0)
sprite_water  db 256 dup(0)
sprite_tree   db 256 dup(0)

; Sprite del jugador: 8x8 = 64 bytes
sprite_player db 64 dup(0)

; Buffer temporal para lectura de archivos
buffer_temp db 300 dup(0)

; =====================================================
; VARIABLES DEL JUGADOR
; =====================================================
; Posición del jugador en el mapa (en tiles)
jugador_x   dw 10    ; Columna (0-49)
jugador_y   dw 6     ; Fila (0-49)

; =====================================================
; VARIABLES DE LA CÁMARA (CON SCROLL SUAVE)
; =====================================================
; La cámara determina qué porción del mapa se muestra
camara_x        dw 0    ; Tile superior izquierdo (columna)
camara_y        dw 0    ; Tile superior izquierdo (fila)
camara_x_pixel  dw 0    ; Offset en píxeles dentro del tile (0-15)
camara_y_pixel  dw 0    ; Offset en píxeles dentro del tile (0-15)

; =====================================================
; VARIABLES DE DOBLE BUFFER
; =====================================================
; El doble buffer evita parpadeo:
; - Una página se muestra mientras se dibuja en la otra
; - Al terminar de dibujar, se intercambian
pagina_visible db 0      ; Página que se muestra (0 o 1)
pagina_dibujo  db 1      ; Página donde se dibuja (0 o 1)
offset_pagina  dw 0      ; Offset en VRAM (0 o 8000h)

; =====================================================
; POSICIÓN DEL VIEWPORT EN PANTALLA
; =====================================================
; El viewport es la ventana donde se dibuja el juego
viewport_x  dw 160       ; X inicial en píxeles
viewport_y  dw 79        ; Y inicial en píxeles
scroll_offset_x dw 0     ; Offset para scroll (no usado)
scroll_offset_y dw 0

; =====================================================
; MENSAJES DE TEXTO
; =====================================================
msg_titulo  db 'JUEGO EGA - VRAM + Doble Buffer',13,10,'$'
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
; =====================================================
; PUNTO DE ENTRADA DEL PROGRAMA
; =====================================================
inicio:
    mov ax, @data
    mov ds, ax
    
    ; Mostrar título
    mov dx, OFFSET msg_titulo
    mov ah, 9
    int 21h
    
    ; Mostrar mensaje de carga
    mov dx, OFFSET msg_cargando
    mov ah, 9
    int 21h
    
    ; =====================================================
    ; CARGAR TODOS LOS RECURSOS
    ; =====================================================
    
    ; CARGAR MAPA (50x50)
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
    
    ; CARGAR SPRITE GRASS
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
    
    ; CARGAR SPRITE WALL
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
    
    ; CARGAR SPRITE PATH
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
    
    ; CARGAR SPRITE WATER
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
    
    ; CARGAR SPRITE TREE
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
    
    ; CARGAR SPRITE PLAYER
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
    
    ; Esperar tecla antes de iniciar
    mov dx, OFFSET msg_controles
    mov ah, 9
    int 21h
    mov ah, 0
    int 16h
    
    ; =====================================================
    ; INICIALIZAR MODO GRÁFICO
    ; =====================================================
    mov ax, 10h         ; Modo 10h = EGA 640x350, 16 colores
    int 10h
    
    ; Configurar doble buffer
    ; Página 0: offset 0
    ; Página 1: offset 8000h (mitad de la VRAM)
    mov pagina_visible, 0
    mov pagina_dibujo, 1
    mov offset_pagina, 8000h
    
    ; Centrar cámara en jugador
    call actualizar_camara_suave
    
    ; Renderizar primera frame en AMBAS páginas para evitar flash
    mov offset_pagina, 0
    call renderizar_todo
    mov offset_pagina, 8000h
    call renderizar_todo
    
    ; Mostrar página 0
    mov ah, 5
    mov al, 0
    int 10h
    
    ; Esperar vsync para sincronizar
    call esperar_vsync

; =====================================================
; BUCLE PRINCIPAL DEL JUEGO (VERSIÓN ULTRA OPTIMIZADA)
; =====================================================
bucle_juego:
    ; Esperar retrazado vertical para evitar tearing
    call esperar_vsync
    
    ; Procesar entrada RÁPIDAMENTE
    call procesar_input
    
    ; Calcular offset de página de dibujo
    mov al, pagina_dibujo
    test al, 1
    jz offset_pagina_0
    mov offset_pagina, 8000h
    jmp dibujar_frame
offset_pagina_0:
    mov offset_pagina, 0
    
dibujar_frame:
    ; Dibujar en página oculta
    call renderizar_todo
    
    ; Mostrar inmediatamente la página dibujada
    mov ah, 5
    mov al, pagina_dibujo
    int 10h
    
    ; Intercambiar páginas
    xor pagina_dibujo, 1
    xor pagina_visible, 1
    
    jmp bucle_juego

; =====================================================
; MANEJO DE ERRORES Y SALIDA
; =====================================================
error_carga:
    mov dx, OFFSET msg_error
    mov ah, 9
    int 21h
    mov ah, 0
    int 16h

fin_juego:
    mov ax, 3           ; Volver a modo texto
    int 10h
    mov ax, 4C00h       ; Terminar programa
    int 21h

; =====================================================
; FUNCIÓN: renderizar_todo
; =====================================================
; Dibuja un frame completo del juego:
; 1. Limpia el viewport
; 2. Dibuja los tiles del mapa
; 3. Dibuja el jugador
;
; ENTRADA: offset_pagina debe estar configurado
; SALIDA: Frame completo dibujado en VRAM
; =====================================================
renderizar_todo PROC
    push ax
    push es
    
    ; Apuntar ES al segmento de video
    mov ax, VIDEO_SEG
    mov es, ax
    
    ; Limpiar el área del viewport
    call limpiar_viewport
    
    ; Dibujar todos los tiles visibles
    call dibujar_mapa_rapido
    
    ; Dibujar el jugador encima
    call dibujar_jugador_rapido
    
    pop es
    pop ax
    ret
renderizar_todo ENDP

; =====================================================
; FUNCIÓN: limpiar_viewport
; =====================================================
; Limpia el área del viewport llenándola de color negro.
; Esto es necesario antes de dibujar cada frame.
;
; ENTRADA: ES = VIDEO_SEG, offset_pagina configurado
; SALIDA: Viewport limpio (píxeles en 0)
; REGISTROS: Preserva todos
; =====================================================
limpiar_viewport PROC
    push ax
    push bx
    push cx
    push dx
    push di
    
    ; Configurar EGA para escribir en todos los planos
    mov dx, 3C4h        ; Puerto del Sequencer
    mov ax, 0F02h       ; Map Mask = 1111b (todos los planos)
    out dx, ax
    
    ; BX = fila actual en píxeles
    mov bx, viewport_y
    ; CX = contador de líneas (12 tiles * 16 píxeles)
    mov cx, VIEWPORT_H * 16
    
lv_loop:
    ; Calcular offset en VRAM para esta línea
    ; offset = fila * 80 + offset_pagina + (viewport_x / 8)
    mov ax, bx
    mov di, 80          ; Bytes por línea en modo EGA
    mul di
    add ax, offset_pagina
    mov di, ax
    
    ; Sumar columna inicial (viewport_x convertido a bytes)
    mov ax, viewport_x
    shr ax, 3           ; Dividir entre 8 (píxeles por byte)
    add di, ax
    
    ; Limpiar 40 bytes (320 píxeles = 20 tiles * 16)
    push cx
    mov cx, 40          ; Ancho del viewport en bytes
    xor al, al          ; Color negro
    rep stosb           ; Escribir AL en ES:DI, CX veces
    pop cx
    
    inc bx              ; Siguiente línea
    loop lv_loop
    
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
limpiar_viewport ENDP

; =====================================================
; FUNCIÓN: dibujar_mapa_rapido (CON SCROLL SUAVE)
; =====================================================
; Dibuja todos los tiles visibles en el viewport.
; Considera el offset de píxeles para scroll suave.
;
; ENTRADA: camara_x, camara_y, camara_x_pixel, camara_y_pixel
;          ES = VIDEO_SEG, offset_pagina configurado
; SALIDA: Mapa dibujado en el viewport con scroll suave
; REGISTROS: Preserva todos
; =====================================================
dibujar_mapa_rapido PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    ; BP = fila actual del viewport (-1 a VIEWPORT_H)
    ; Dibujamos un tile extra en cada dirección para scroll suave
    mov bp, -1
    
dmr_fila:
    cmp bp, VIEWPORT_H + 1
    jb dmr_fila_procesar
    jmp dmr_fin

dmr_fila_procesar:
    ; SI = columna actual del viewport (-1 a VIEWPORT_W)
    mov si, -1
    
dmr_col:
    cmp si, VIEWPORT_W + 1
    jb dmr_col_procesar
    jmp dmr_next_fila

dmr_col_procesar:
    
    ; Calcular posición en el mapa
    mov ax, camara_y
    add ax, bp
    cmp ax, 0
    jl dmr_next_col
    cmp ax, 50
    jae dmr_next_col
    
    mov bx, camara_x
    add bx, si
    cmp bx, 0
    jl dmr_next_col
    cmp bx, 50
    jae dmr_next_col
    
    ; Calcular índice en mapa_datos
    push dx
    mov dx, 50
    mul dx
    add ax, bx
    pop dx
    
    ; Obtener tipo de tile
    mov bx, ax
    mov al, BYTE PTR [mapa_datos + bx]
    
    ; Seleccionar sprite
    mov di, OFFSET sprite_grass
    
    cmp al, TILE_WALL
    jne dmr_check_path
    mov di, OFFSET sprite_wall
    jmp short dmr_draw

dmr_check_path:
    cmp al, TILE_PATH
    jne dmr_check_water
    mov di, OFFSET sprite_path
    jmp short dmr_draw

dmr_check_water:
    cmp al, TILE_WATER
    jne dmr_check_tree
    mov di, OFFSET sprite_water
    jmp short dmr_draw

dmr_check_tree:
    cmp al, TILE_TREE
    jne dmr_draw
    mov di, OFFSET sprite_tree

dmr_draw:
    push si
    push bp
    
    ; Calcular posición en pantalla CON OFFSET de scroll
    ; X = SI * 16 + viewport_x - camara_x_pixel
    mov ax, si
    shl ax, 4
    add ax, viewport_x
    sub ax, camara_x_pixel
    mov cx, ax
    
    ; Y = BP * 16 + viewport_y - camara_y_pixel
    mov ax, bp
    shl ax, 4
    add ax, viewport_y
    sub ax, camara_y_pixel
    mov dx, ax
    
    ; Dibujar sprite
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
; FUNCIÓN: dibujar_jugador_rapido
; =====================================================
; Dibuja el sprite del jugador en su posición relativa
; al viewport. El jugador se dibuja centrado en su tile.
;
; ENTRADA: jugador_x, jugador_y, camara_x, camara_y
;          ES = VIDEO_SEG, offset_pagina configurado
; SALIDA: Jugador dibujado en el viewport
; REGISTROS: Preserva todos
; =====================================================
dibujar_jugador_rapido PROC
    push ax
    push bx
    push cx
    push dx
    
    ; Calcular posición relativa al viewport (en tiles)
    ; tile_x_viewport = jugador_x - camara_x
    mov ax, jugador_x
    sub ax, camara_x
    js djr_fin          ; Si es negativo, está fuera
    cmp ax, VIEWPORT_W
    jae djr_fin         ; Si >= ancho, está fuera
    
    ; Convertir a píxeles y sumar offset del viewport
    shl ax, 4           ; Multiplicar por 16 píxeles
    add ax, viewport_x
    add ax, 4           ; Centrar sprite 8x8 en tile 16x16
    mov cx, ax          ; CX = X en píxeles
    
    ; Calcular Y
    mov ax, jugador_y
    sub ax, camara_y
    js djr_fin
    cmp ax, VIEWPORT_H
    jae djr_fin
    
    shl ax, 4
    add ax, viewport_y
    add ax, 4           ; Centrar verticalmente
    mov dx, ax          ; DX = Y en píxeles
    
    ; Dibujar sprite del jugador
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
; FUNCIÓN: dibujar_sprite_16x16_vram
; =====================================================
; Dibuja un sprite de 16x16 píxeles en VRAM.
; Cada píxel con valor 0 se considera transparente.
;
; ENTRADA: CX = X en píxeles
;          DX = Y en píxeles
;          DI = puntero al sprite (256 bytes)
;          ES = VIDEO_SEG, offset_pagina configurado
; SALIDA: Sprite dibujado
; REGISTROS: Preserva todos
; =====================================================
dibujar_sprite_16x16_vram PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push bp
    
    mov si, di          ; SI = puntero al sprite
    mov bp, 16          ; 16 filas
    
ds16v_fila:
    mov bx, cx          ; Guardar X inicial
    push bp
    mov bp, 16          ; 16 píxeles por fila
    
ds16v_pixel:
    lodsb               ; Leer píxel en AL, incrementar SI
    test al, al         ; ¿Es 0 (transparente)?
    jz ds16v_skip
    
    ; Escribir píxel en (CX, DX)
    call escribir_pixel_ega
    
ds16v_skip:
    inc cx              ; Siguiente columna
    dec bp
    jnz ds16v_pixel
    
    mov cx, bx          ; Restaurar X
    pop bp
    inc dx              ; Siguiente fila
    dec bp
    jnz ds16v_fila
    
    pop bp
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_sprite_16x16_vram ENDP

; =====================================================
; FUNCIÓN: dibujar_sprite_8x8_vram
; =====================================================
; Dibuja un sprite de 8x8 píxeles en VRAM.
; Similar a dibujar_sprite_16x16_vram pero más pequeño.
;
; ENTRADA: CX = X en píxeles
;          DX = Y en píxeles
;          SI = puntero al sprite (64 bytes)
;          ES = VIDEO_SEG, offset_pagina configurado
; SALIDA: Sprite dibujado
; REGISTROS: Preserva todos
; =====================================================
dibujar_sprite_8x8_vram PROC
    push ax
    push bx
    push cx
    push dx
    push bp
    
    mov bp, 8           ; 8 filas
    
ds8v_fila:
    mov bx, cx          ; Guardar X inicial
    push bp
    mov bp, 8           ; 8 píxeles por fila
    
ds8v_pixel:
    lodsb               ; Leer píxel
    test al, al         ; ¿Transparente?
    jz ds8v_skip
    
    call escribir_pixel_ega
    
ds8v_skip:
    inc cx
    dec bp
    jnz ds8v_pixel
    
    mov cx, bx          ; Restaurar X
    pop bp
    inc dx
    dec bp
    jnz ds8v_fila
    
    pop bp
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_sprite_8x8_vram ENDP

; =====================================================
; FUNCIÓN: escribir_pixel_ega
; =====================================================
; Escribe un píxel en VRAM usando el modo planar de EGA.
; En modo EGA, cada píxel de 4 bits se almacena en 4 planos.
;
; ENTRADA: CX = X en píxeles
;          DX = Y en píxeles
;          AL = color (0-15)
;          ES = VIDEO_SEG, offset_pagina configurado
; SALIDA: Píxel escrito en VRAM
; REGISTROS: Preserva todos excepto flags
; =====================================================
escribir_pixel_ega PROC
    push ax
    push bx
    push cx
    push dx
    push di
    
    mov bl, al          ; Guardar color en BL
    
    ; Calcular offset en VRAM
    ; offset = Y * 80 + offset_pagina + (X / 8)
    mov ax, dx
    mov di, 80
    mul di              ; AX = Y * 80
    add ax, offset_pagina
    mov di, ax
    
    mov ax, cx
    shr ax, 3           ; X / 8
    add di, ax          ; DI = offset del byte
    
    ; Calcular máscara de bit dentro del byte
    ; bit = 7 - (X % 8)
    and cx, 7           ; CX = X % 8
    mov al, 80h         ; Máscara inicial (bit 7)
    shr al, cl          ; Desplazar a la posición correcta
    mov ah, al          ; AH = máscara de bit
    
    ; Configurar Graphics Controller de EGA
    mov dx, 3CEh        ; Puerto del Graphics Controller
    
    ; Set/Reset Register = color
    mov al, 0           ; Registro 0
    out dx, al
    inc dx
    mov al, bl          ; Color
    out dx, al
    dec dx
    
    ; Enable Set/Reset = 0Fh (todos los planos)
    mov al, 1           ; Registro 1
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    dec dx
    
    ; Bit Mask = máscara del bit
    mov al, 8           ; Registro 8
    out dx, al
    inc dx
    mov al, ah          ; Máscara
    out dx, al
    
    ; Escribir en VRAM (activa el latching)
    mov al, es:[di]     ; Leer (cargar latches)
    stosb               ; Escribir (aplicar máscara y color)
    
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
escribir_pixel_ega ENDP

; =====================================================
; FUNCIÓN: mover_jugador
; =====================================================
; Procesa la entrada del teclado y mueve al jugador.
; Verifica colisiones antes de confirmar el movimiento.
;
; ENTRADA: AH = scan code, AL = carácter ASCII
; SALIDA: jugador_x, jugador_y actualizados
; REGISTROS: Preserva todos
; =====================================================
mover_jugador PROC
    push ax
    
    ; Verificar tecla ARRIBA
    cmp ah, 48h         ; Scan code de flecha arriba
    je mj_arr
    cmp al, 'w'
    je mj_arr
    cmp al, 'W'
    je mj_arr
    
    ; Verificar tecla ABAJO
    cmp ah, 50h         ; Scan code de flecha abajo
    je mj_aba
    cmp al, 's'
    je mj_aba
    cmp al, 'S'
    je mj_aba
    
    ; Verificar tecla IZQUIERDA
    cmp ah, 4Bh
    je mj_izq
    cmp al, 'a'
    je mj_izq
    cmp al, 'A'
    je mj_izq
    
    ; Verificar tecla DERECHA
    cmp ah, 4Dh
    je mj_der
    cmp al, 'd'
    je mj_der
    cmp al, 'D'
    je mj_der
    
    jmp mj_fin

mj_arr:
    cmp jugador_y, 1
    jbe mj_fin          ; No puede ir más arriba
    dec jugador_y
    call verificar_colision
    jnc mj_fin          ; Sin colisión, movimiento OK
    inc jugador_y       ; Colisión, revertir movimiento
    jmp mj_fin

mj_aba:
    cmp jugador_y, 48
    jae mj_fin          ; No puede ir más abajo
    inc jugador_y
    call verificar_colision
    jnc mj_fin
    dec jugador_y
    jmp mj_fin

mj_izq:
    cmp jugador_x, 1
    jbe mj_fin          ; No puede ir más a la izquierda
    dec jugador_x
    call verificar_colision
    jnc mj_fin
    inc jugador_x
    jmp mj_fin

mj_der:
    cmp jugador_x, 48
    jae mj_fin          ; No puede ir más a la derecha
    inc jugador_x
    call verificar_colision
    jnc mj_fin
    dec jugador_x

mj_fin:
    pop ax
    ret
mover_jugador ENDP

; =====================================================
; FUNCIÓN: esperar_vsync
; =====================================================
; Espera al retrazado vertical del monitor para evitar
; tearing y sincronizar el framerate con el monitor.
;
; SALIDA: Ninguna
; REGISTROS: Preserva todos
; =====================================================
esperar_vsync PROC
    push ax
    push dx
    
    ; Puerto de estado del CRT
    mov dx, 3DAh
    
ev_wait_retrace:
    in al, dx
    test al, 08h        ; Bit 3 = retrazado vertical
    jnz ev_wait_retrace ; Esperar a que termine el anterior
    
ev_wait_display:
    in al, dx
    test al, 08h
    jz ev_wait_display  ; Esperar al siguiente retrazado
    
    pop dx
    pop ax
    ret
esperar_vsync ENDP

; =====================================================
; FUNCIÓN: procesar_input
; =====================================================
; Procesa entrada del teclado de manera eficiente.
; Mueve al jugador PIXEL por PIXEL para scroll suave.
;
; SALIDA: Jugador movido si corresponde
; REGISTROS: Preserva todos
; =====================================================
procesar_input PROC
    push ax
    push bx
    
    ; Verificar buffer de teclado
    mov ah, 1
    int 16h
    jz pi_no_tecla
    
    ; Peek tecla sin consumir buffer
    mov ah, 1
    int 16h
    
    ; Guardar valores
    push ax
    mov bh, ah          ; BH = scan code
    mov bl, al          ; BL = ASCII
    pop ax
    
    ; Solo consumir si es ESC
    mov al, bl
    cmp al, 27
    jne pi_procesar
    
    ; Consumir ESC y salir
    mov ah, 0
    int 16h
    jmp fin_juego
    
pi_procesar:
    ; Procesar movimiento con el scan code
    mov ah, bh
    call mover_suave
    call actualizar_camara_suave
    jmp pi_fin
    
pi_no_tecla:
    ; Limpiar buffer si no hay tecla
    mov ah, 1
    int 16h
    jz pi_fin
    mov ah, 0
    int 16h
    
pi_fin:
    pop bx
    pop ax
    ret
procesar_input ENDP

; =====================================================
; FUNCIÓN: mover_suave
; =====================================================
; Mueve al jugador píxel por píxel para scroll suave.
; Verifica colisiones cuando cruza a un nuevo tile.
;
; ENTRADA: AH = scan code de la tecla
; SALIDA: jugador_x, jugador_y, subpíxeles actualizados
; REGISTROS: Preserva todos
; =====================================================
mover_suave PROC
    push ax
    push bx
    push cx
    push dx
    
    ; ARRIBA
    cmp ah, 48h
    jne ms_check_w
    jmp ms_arr

ms_check_w:
    cmp ah, 11h         ; W
    jne ms_check_down
    jmp ms_arr

ms_check_down:
    cmp ah, 50h
    jne ms_check_s
    jmp ms_aba

ms_check_s:
    cmp ah, 1Fh         ; S
    jne ms_check_left
    jmp ms_aba

ms_check_left:
    cmp ah, 4Bh
    jne ms_check_a
    jmp ms_izq

ms_check_a:
    cmp ah, 1Eh         ; A
    jne ms_check_right
    jmp ms_izq

ms_check_right:
    cmp ah, 4Dh
    jne ms_check_d
    jmp ms_der

ms_check_d:
    cmp ah, 20h         ; D
    je ms_der
    jmp ms_fin

ms_arr:
    ; Mover hacia arriba (decrementar Y)
    mov ax, jugador_subpixel_y
    sub ax, velocidad_movimiento
    jns ms_arr_ok
    
    ; Cruzar al tile anterior
    cmp jugador_y, 1
    ja ms_arr_cruzar
    jmp ms_fin

ms_arr_cruzar:
    
    ; Verificar colisión en nuevo tile
    dec jugador_y
    call verificar_colision
    jc ms_arr_colision
    
    ; Sin colisión, ajustar subpíxel
    add ax, 16
    mov jugador_subpixel_y, ax
    jmp ms_fin
    
ms_arr_colision:
    inc jugador_y
    mov jugador_subpixel_y, 0
    jmp ms_fin
    
ms_arr_ok:
    mov jugador_subpixel_y, ax
    jmp ms_fin

ms_aba:
    ; Mover hacia abajo
    mov ax, jugador_subpixel_y
    add ax, velocidad_movimiento
    cmp ax, 16
    jb ms_aba_ok
    
    ; Cruzar al siguiente tile
    cmp jugador_y, 48
    jb ms_aba_cruzar
    jmp ms_fin

ms_aba_cruzar:
    
    inc jugador_y
    call verificar_colision
    jc ms_aba_colision
    
    sub ax, 16
    mov jugador_subpixel_y, ax
    jmp ms_fin
    
ms_aba_colision:
    dec jugador_y
    mov jugador_subpixel_y, 15
    jmp ms_fin
    
ms_aba_ok:
    mov jugador_subpixel_y, ax
    jmp ms_fin

ms_izq:
    ; Mover hacia la izquierda
    mov ax, jugador_subpixel_x
    sub ax, velocidad_movimiento
    jns ms_izq_ok
    
    cmp jugador_x, 1
    jbe ms_fin
    
    dec jugador_x
    call verificar_colision
    jc ms_izq_colision
    
    add ax, 16
    mov jugador_subpixel_x, ax
    jmp ms_fin
    
ms_izq_colision:
    inc jugador_x
    mov jugador_subpixel_x, 0
    jmp ms_fin
    
ms_izq_ok:
    mov jugador_subpixel_x, ax
    jmp ms_fin

ms_der:
    ; Mover hacia la derecha
    mov ax, jugador_subpixel_x
    add ax, velocidad_movimiento
    cmp ax, 16
    jb ms_der_ok
    
    cmp jugador_x, 48
    jae ms_fin
    
    inc jugador_x
    call verificar_colision
    jc ms_der_colision
    
    sub ax, 16
    mov jugador_subpixel_x, ax
    jmp ms_fin
    
ms_der_colision:
    dec jugador_x
    mov jugador_subpixel_x, 15
    jmp ms_fin
    
ms_der_ok:
    mov jugador_subpixel_x, ax

ms_fin:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
mover_suave ENDP

; =====================================================
; FUNCIÓN: actualizar_camara_suave
; =====================================================
; Actualiza la cámara para seguir al jugador con
; scroll suave píxel por píxel.
;
; ENTRADA: jugador_x, jugador_y, subpíxeles
; SALIDA: camara_x, camara_y, offsets en píxeles
; REGISTROS: Preserva todos
; =====================================================
actualizar_camara_suave PROC
    push ax
    push bx
    push cx
    push dx
    
    ; Calcular posición del jugador en píxeles absolutos
    ; pos_pixel_x = jugador_x * 16 + jugador_subpixel_x
    mov ax, jugador_x
    shl ax, 4           ; * 16
    add ax, jugador_subpixel_x
    mov bx, ax          ; BX = posición X del jugador en píxeles
    
    ; Calcular posición objetivo de la cámara
    ; centro_viewport = 10 tiles * 16 = 160 píxeles
    sub ax, 160         ; Centrar en X
    jge acs_x_ok
    xor ax, ax
acs_x_ok:
    ; Límite máximo: (50-20)*16 = 480 píxeles
    cmp ax, 480
    jle acs_x_limit
    mov ax, 480
acs_x_limit:
    ; AX = offset de cámara en píxeles totales
    ; Dividir en tile + offset
    mov cx, ax
    shr ax, 4           ; AX = tile
    mov camara_x, ax
    
    and cx, 15          ; CX = offset en píxeles
    mov camara_x_pixel, cx
    
    ; Repetir para Y
    mov ax, jugador_y
    shl ax, 4
    add ax, jugador_subpixel_y
    
    sub ax, 96          ; Centrar en Y (6 tiles * 16)
    jge acs_y_ok
    xor ax, ax
acs_y_ok:
    cmp ax, 608         ; (50-12)*16
    jle acs_y_limit
    mov ax, 608
acs_y_limit:
    mov cx, ax
    shr ax, 4
    mov camara_y, ax
    
    and cx, 15
    mov camara_y_pixel, cx
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
actualizar_camara_suave ENDP

; =====================================================
; FUNCIÓN: verificar_colision
; =====================================================
; Verifica si el jugador puede estar en su posición actual.
; Solo permite movimiento en tiles de GRASS y PATH.
;
; ENTRADA: jugador_x, jugador_y (posición a verificar)
; SALIDA: CF = 1 si hay colisión, CF = 0 si es transitable
; REGISTROS: Preserva todos
; =====================================================
verificar_colision PROC
    push ax
    push bx
    push si
    
    ; Calcular índice en el mapa
    ; indice = jugador_y * 50 + jugador_x
    mov ax, jugador_y
    mov bx, 50
    mul bx              ; AX = jugador_y * 50
    add ax, jugador_x   ; AX = índice
    
    ; Verificar límites del mapa
    cmp ax, 2500
    jae vc_col          ; Fuera de límites = colisión
    
    ; Obtener tipo de tile en esa posición
    mov si, OFFSET mapa_datos
    add si, ax
    mov al, BYTE PTR [si]        ; AL = tipo de tile
    
    ; Verificar si es transitable
    cmp al, TILE_GRASS
    je vc_ok
    cmp al, TILE_PATH
    je vc_ok
    
vc_col:
    stc                 ; CF = 1 (colisión)
    jmp vc_fin
    
vc_ok:
    clc                 ; CF = 0 (sin colisión)
    
vc_fin:
    pop si
    pop bx
    pop ax
    ret
verificar_colision ENDP

; =====================================================
; FUNCIÓN: cargar_mapa
; =====================================================
; Carga el archivo MAPA.TXT y llena el array mapa_datos.
; El archivo debe contener 2500 números (0-4) que
; representan los tipos de tiles.
;
; Formato esperado:
; [Primera línea: comentario o dimensiones - ignorada]
; [2500 números separados por espacios/saltos de línea]
;
; ENTRADA: archivo_mapa (nombre del archivo)
; SALIDA: mapa_datos lleno con los tiles
;         CF = 0 si OK, CF = 1 si error
; REGISTROS: Preserva todos
; =====================================================
cargar_mapa PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    ; Abrir archivo
    mov ax, 3D00h       ; Función: abrir archivo (solo lectura)
    mov dx, OFFSET archivo_mapa
    int 21h
    jc cm_error         ; Si CF=1, hubo error
    
    mov bx, ax          ; BX = file handle
    
    ; Saltar primera línea (comentario)
    call saltar_linea
    
    ; Preparar destino
    mov di, OFFSET mapa_datos
    xor bp, bp          ; BP = contador de tiles leídos
    
cm_leer:
    ; Leer bloque del archivo
    mov ah, 3Fh         ; Función: leer archivo
    mov cx, 200         ; Leer 200 bytes
    mov dx, OFFSET buffer_temp
    int 21h
    
    ; AX = bytes leídos
    cmp ax, 0
    je cm_cerrar        ; Si 0, fin del archivo
    
    mov cx, ax          ; CX = bytes a procesar
    xor si, si          ; SI = índice en buffer

cm_proc:
    cmp si, cx
    jae cm_leer         ; Si procesamos todo, leer más

    ; Leer carácter
    mov al, BYTE PTR [buffer_temp + si]
    inc si
    
    ; Ignorar espacios, tabs, CR, LF
    cmp al, ' '
    je cm_proc
    cmp al, 13
    je cm_proc
    cmp al, 10
    je cm_proc
    cmp al, 9
    je cm_proc
    
    ; Verificar si es dígito (0-9)
    cmp al, '0'
    jb cm_proc
    cmp al, '9'
    ja cm_proc
    
    ; Convertir ASCII a número
    sub al, '0'         ; '0' -> 0, '1' -> 1, etc.
    
    ; Guardar en mapa
    mov BYTE PTR [di], al
    inc di
    inc bp

    ; ¿Ya leímos 2500 tiles?
    cmp bp, 2500
    jb cm_proc
    
cm_cerrar:
    ; Cerrar archivo
    mov ah, 3Eh
    int 21h
    clc                 ; CF = 0 (éxito)
    jmp cm_fin
    
cm_error:
    stc                 ; CF = 1 (error)
    
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
; FUNCIÓN: cargar_sprite_16x16
; =====================================================
; Carga un sprite de 16x16 píxeles desde un archivo.
; El archivo debe contener 256 números (0-15) que
; representan los colores de cada píxel.
;
; Formato esperado:
; [Primera línea: dimensiones - ignorada]
; [256 números (16x16) separados por espacios/saltos]
;
; ENTRADA: DX = puntero al nombre del archivo
;          DI = puntero al buffer destino (256 bytes)
; SALIDA: Sprite cargado en el buffer
;         CF = 0 si OK, CF = 1 si error
; REGISTROS: Preserva todos
; =====================================================
cargar_sprite_16x16 PROC
    push ax
    push bx
    push cx
    push si
    push bp
    
    ; Abrir archivo
    mov ax, 3D00h
    int 21h
    jc cs16_error
    
    mov bx, ax          ; BX = file handle
    
    ; Saltar primera línea
    call saltar_linea
    
    xor bp, bp          ; BP = contador de píxeles
    
cs16_leer:
    ; Leer bloque
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

    mov al, BYTE PTR [buffer_temp + si]
    inc si
    
    ; Ignorar whitespace
    cmp al, ' '
    je cs16_proc
    cmp al, 13
    je cs16_proc
    cmp al, 10
    je cs16_proc
    cmp al, 9
    je cs16_proc
    
    ; Verificar dígito
    cmp al, '0'
    jb cs16_proc
    cmp al, '9'
    ja cs16_proc
    
    ; Convertir y guardar
    sub al, '0'
    mov BYTE PTR [di], al
    inc di
    inc bp

    ; ¿Ya leímos 256 píxeles?
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
; FUNCIÓN: cargar_sprite_8x8
; =====================================================
; Carga un sprite de 8x8 píxeles desde un archivo.
; Similar a cargar_sprite_16x16 pero con 64 píxeles.
;
; Formato esperado:
; [Primera línea: dimensiones - ignorada]
; [64 números (8x8) separados por espacios/saltos]
;
; ENTRADA: DX = puntero al nombre del archivo
;          DI = puntero al buffer destino (64 bytes)
; SALIDA: Sprite cargado en el buffer
;         CF = 0 si OK, CF = 1 si error
; REGISTROS: Preserva todos
; =====================================================
cargar_sprite_8x8 PROC
    push ax
    push bx
    push cx
    push si
    push bp
    
    ; Abrir archivo
    mov ax, 3D00h
    int 21h
    jc cs8_error
    
    mov bx, ax
    
    ; Saltar primera línea
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

    mov al, BYTE PTR [buffer_temp + si]
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
    mov BYTE PTR [di], al
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
; FUNCIÓN: saltar_linea
; =====================================================
; Lee caracteres del archivo hasta encontrar un
; salto de línea (LF o CR). Útil para ignorar
; la primera línea de los archivos de datos.
;
; ENTRADA: BX = file handle
; SALIDA: Posición del archivo avanzada
; REGISTROS: Preserva todos
; =====================================================
saltar_linea PROC
    push ax
    push cx
    push dx
    
sl_loop:
    ; Leer 1 byte
    mov ah, 3Fh
    mov cx, 1
    mov dx, OFFSET buffer_temp
    int 21h
    
    ; Si no se leyó nada, terminar
    cmp ax, 0
    je sl_fin
    
    ; Verificar si es LF (10)
    mov al, BYTE PTR [buffer_temp]
    cmp al, 10
    je sl_fin
    
    ; Verificar si es CR (13)
    cmp al, 13
    jne sl_loop
    
sl_fin:
    pop dx
    pop cx
    pop ax
    ret
saltar_linea ENDP

END inicio