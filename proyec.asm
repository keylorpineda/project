; JUEGO EGA - MOVIMIENTO SUAVE Y FLUIDO (ESTILO ZELDA NES)
; Universidad Nacional - Proyecto II Ciclo 2025
; Modo 10h (640x350, 16 colores)
; =====================================================

.MODEL SMALL
.STACK 2048

TILE_GRASS1   EQU 0
TILE_GRASS2   EQU 1
TILE_FLOWER   EQU 2
TILE_PATH     EQU 3
TILE_WATER    EQU 4
TILE_TREE     EQU 5
TILE_SAND     EQU 6
TILE_ROCK     EQU 7
TILE_SNOW     EQU 8
TILE_ICE      EQU 9
TILE_MOUNTAIN EQU 10
TILE_HILL     EQU 11
TILE_BUSH     EQU 12
TILE_DIRT     EQU 13
TILE_LAVA     EQU 14
TILE_BRIDGE   EQU 15

TILE_SIZE      EQU 16
VIEWPORT_W     EQU 20
VIEWPORT_H     EQU 12
VIDEO_SEG      EQU 0A000h
VELOCIDAD      EQU 2          ; Píxeles por frame (2 = suave y rápido)

DIR_ABAJO      EQU 0
DIR_ARRIBA     EQU 1
DIR_IZQUIERDA  EQU 2
DIR_DERECHA    EQU 3

.DATA
archivo_mapa   db 'MAPA.TXT',0
archivo_grass1 db 'SPRITES\GRASS_1.TXT',0
archivo_grass2 db 'SPRITES\GRASS_2.TXT',0
archivo_flower db 'SPRITES\FLOWER_1.TXT',0
archivo_path   db 'SPRITES\PATH_2.TXT',0
archivo_water  db 'SPRITES\WATER_2.TXT',0
archivo_tree   db 'SPRITES\TREE_1.TXT',0
archivo_sand   db 'SPRITES\SAND_1.TXT',0
archivo_rock   db 'SPRITES\ROCK_1.TXT',0
archivo_snow   db 'SPRITES\SNOW_1.TXT',0
archivo_ice    db 'SPRITES\ICE_1.TXT',0
archivo_mountain db 'SPRITES\MOUNTA_1.TXT',0
archivo_hill   db 'SPRITES\HILL_1.TXT',0
arquivo_bush   db 'SPRITES\BUSH_1.TXT',0
arquivo_dirt   db 'SPRITES\DIRT_1.TXT',0
arquivo_lava   db 'SPRITES\LAVA_1.TXT',0
arquivo_bridge db 'SPRITES\BRIDGE_1.TXT',0

archivo_player_up_a    db 'SPRITES\PLAYER\UP1.TXT',0
archivo_player_up_b    db 'SPRITES\PLAYER\UP2.TXT',0
archivo_player_down_a  db 'SPRITES\PLAYER\DOWN1.TXT',0
archivo_player_down_b  db 'SPRITES\PLAYER\DOWN2.TXT',0
archivo_player_izq_a   db 'SPRITES\PLAYER\LEFT1.TXT',0
archivo_player_izq_b   db 'SPRITES\PLAYER\LEFT2.TXT',0
archivo_player_der_a   db 'SPRITES\PLAYER\RIGHT1.TXT',0
archivo_player_der_b   db 'SPRITES\PLAYER\RIGHT2.TXT',0

; === MAPA 50x50 ===
mapa_datos  db 2500 dup(0)

; === SPRITES ===
sprite_grass1   db 256 dup(0)
sprite_grass2   db 256 dup(0)
sprite_flower   db 256 dup(0)
sprite_path     db 256 dup(0)
sprite_water    db 256 dup(0)
sprite_tree     db 256 dup(0)
sprite_sand     db 256 dup(0)
sprite_rock     db 256 dup(0)
sprite_snow     db 256 dup(0)
sprite_ice      db 256 dup(0)
sprite_mountain db 256 dup(0)
sprite_hill     db 256 dup(0)
sprite_bush     db 256 dup(0)
sprite_dirt     db 256 dup(0)
sprite_lava     db 256 dup(0)
sprite_bridge   db 256 dup(0)

; === SPRITES DEL JUGADOR ===
jugador_up_a    db 256 dup(0)
jugador_up_b    db 256 dup(0)
jugador_down_a  db 256 dup(0)
jugador_down_b  db 256 dup(0)
jugador_izq_a   db 256 dup(0)
jugador_izq_b   db 256 dup(0)
jugador_der_a   db 256 dup(0)
jugador_der_b   db 256 dup(0)

buffer_temp db 300 dup(0)

; === JUGADOR ===
jugador_px  dw 400          ; Posición en píxeles
jugador_py  dw 400
jugador_dir db DIR_ABAJO
jugador_frame db 0

; === ESTADO DE MOVIMIENTO ===
moviendo db 0                ; 0 = quieto, 1 = en movimiento
pasos_dados db 0             ; Contador para animación
anim_delay db 0              ; Delay entre frames de animación

; === CÁMARA ===
camara_px   dw 240
camara_py   dw 304

; === DOBLE BUFFER ===
pagina_visible db 0
pagina_dibujo  db 1

; === VIEWPORT ===
viewport_x  dw 160
viewport_y  dw 79

; === VARIABLES AUXILIARES ===
temp_offset     dw 0
inicio_tile_x   dw 0
inicio_tile_y   dw 0
offset_px_x     dw 0
offset_px_y     dw 0

; === MENSAJES ===
msg_titulo  db 'JUEGO EGA - Movimiento Suave Estilo Zelda',13,10,'$'
msg_cargando db 'Cargando archivos...',13,10,'$'
msg_mapa    db 'Mapa: $'
msg_grass1 db 'Grass 1: $'
msg_grass2 db 'Grass 2: $'
msg_flower db 'Flower: $'
msg_path   db 'Path: $'
msg_water  db 'Water: $'
msg_tree   db 'Tree: $'
msg_sand   db 'Sand: $'
msg_rock   db 'Rock: $'
msg_snow   db 'Snow: $'
msg_ice    db 'Ice: $'
msg_mountain db 'Mountain: $'
msg_hill   db 'Hill: $'
msg_bush   db 'Bush: $'
msg_dirt   db 'Dirt: $'
msg_lava   db 'Lava: $'
msg_bridge db 'Bridge: $'
msg_anim    db 'Animaciones: $'
msg_ok      db 'OK',13,10,'$'
msg_error   db 'ERROR',13,10,'$'
msg_controles db 13,10,'WASD/Flechas = Mover (mantener), ESC = Salir',13,10
              db 'Presiona tecla...$'

.CODE
inicio:
    mov ax, @data
    mov ds, ax
    
    mov dx, OFFSET msg_titulo
    mov ah, 9
    int 21h
    
    mov dx, OFFSET msg_cargando
    mov ah, 9
    int 21h
    
    ; CARGAR MAPA
    mov dx, OFFSET msg_mapa
    mov ah, 9
    int 21h
    call cargar_mapa
    jnc cm_ok
    jmp error_carga
cm_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    ; CARGAR SPRITES DE TERRENO
    call cargar_sprites_terreno
    jnc st_ok
    jmp error_carga
st_ok:
    
    ; CARGAR ANIMACIONES DEL JUGADOR
    mov dx, OFFSET msg_anim
    mov ah, 9
    int 21h
    call cargar_animaciones_jugador
    jnc anim_ok
    jmp error_carga
anim_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    mov dx, OFFSET msg_controles
    mov ah, 9
    int 21h
    mov ah, 0
    int 16h
    
    ; Cambiar a modo EGA
    mov ax, 10h
    int 10h
    
    ; Centrar cámara inicial
    call centrar_camara
    
    ; Renderizar ambas páginas
    call renderizar_en_pagina_0
    call renderizar_en_pagina_1
    
    ; Mostrar página 0
    mov ah, 5
    mov al, 0
    int 10h

; =====================================================
; BUCLE PRINCIPAL - MOVIMIENTO SUAVE
; =====================================================
bucle_juego:
    ; 1. ESPERAR RETRACE
    call esperar_retrace
    
    ; 2. LEER ESTADO DEL TECLADO
    call procesar_movimiento_continuo
    
    ; 3. ACTUALIZAR ANIMACIÓN
    call actualizar_animacion
    
    ; 4. ACTUALIZAR CÁMARA SUAVEMENTE
    call centrar_camara
    
    ; 5. RENDERIZAR EN PÁGINA OCULTA
    mov al, pagina_dibujo
    test al, 1
    jz render_p0
    
    call renderizar_en_pagina_1
    jmp SHORT cambiar_pagina
    
render_p0:
    call renderizar_en_pagina_0
    
cambiar_pagina:
    ; 6. CAMBIAR PÁGINA VISIBLE
    mov ah, 5
    mov al, pagina_dibujo
    int 10h
    
    xor pagina_dibujo, 1
    xor pagina_visible, 1
    
    jmp bucle_juego

error_carga:
    mov dx, OFFSET msg_error
    mov ah, 9
    int 21h
    mov ah, 0
    int 16h

fin_juego:
    mov ax, 3
    int 10h
    mov ax, 4C00h
    int 21h

; =====================================================
; PROCESAR MOVIMIENTO CONTINUO
; =====================================================
procesar_movimiento_continuo PROC
    push ax
    push bx
    push cx
    push dx
    
    ; Limpiar buffer de teclado si hay teclas viejas
    mov ah, 1
    int 16h
    jz pmc_no_tecla
    
    ; Leer tecla sin esperar
    mov ah, 0
    int 16h
    
    ; Verificar ESC
    cmp al, 27
    je fin_juego
    
    ; Guardar tecla
    mov bl, al
    mov bh, ah
    
    ; Verificar movimiento
    test bl, bl
    jz pmc_usar_scan
    mov al, bl
    jmp SHORT pmc_verificar
    
pmc_usar_scan:
    mov al, bh
    
pmc_verificar:
    ; ARRIBA
    cmp al, 48h        ; Flecha arriba
    je pmc_arriba
    cmp al, 'w'
    je pmc_arriba
    cmp al, 'W'
    je pmc_arriba
    
    ; ABAJO
    cmp al, 50h        ; Flecha abajo
    je pmc_abajo
    cmp al, 's'
    je pmc_abajo
    cmp al, 'S'
    je pmc_abajo
    
    ; IZQUIERDA
    cmp al, 4Bh        ; Flecha izquierda
    je pmc_izquierda
    cmp al, 'a'
    je pmc_izquierda
    cmp al, 'A'
    je pmc_izquierda
    
    ; DERECHA
    cmp al, 4Dh        ; Flecha derecha
    je pmc_derecha
    cmp al, 'd'
    je pmc_derecha
    cmp al, 'D'
    je pmc_derecha
    
    jmp SHORT pmc_no_movimiento

pmc_arriba:
    mov jugador_dir, DIR_ARRIBA
    mov ax, jugador_py
    sub ax, VELOCIDAD
    cmp ax, 16
    jb pmc_no_movimiento
    
    ; Verificar colisión en nueva posición
    mov cx, jugador_px
    shr cx, 4
    mov dx, ax
    shr dx, 4
    call verificar_tile_transitable
    jnc pmc_no_movimiento
    
    ; Mover
    mov jugador_py, ax
    mov moviendo, 1
    jmp SHORT pmc_fin

pmc_abajo:
    mov jugador_dir, DIR_ABAJO
    mov ax, jugador_py
    add ax, VELOCIDAD
    cmp ax, 784
    ja pmc_no_movimiento
    
    mov cx, jugador_px
    shr cx, 4
    mov dx, ax
    shr dx, 4
    call verificar_tile_transitable
    jnc pmc_no_movimiento
    
    mov jugador_py, ax
    mov moviendo, 1
    jmp SHORT pmc_fin

pmc_izquierda:
    mov jugador_dir, DIR_IZQUIERDA
    mov ax, jugador_px
    sub ax, VELOCIDAD
    cmp ax, 16
    jb pmc_no_movimiento
    
    mov cx, ax
    shr cx, 4
    mov dx, jugador_py
    shr dx, 4
    call verificar_tile_transitable
    jnc pmc_no_movimiento
    
    mov jugador_px, ax
    mov moviendo, 1
    jmp SHORT pmc_fin

pmc_derecha:
    mov jugador_dir, DIR_DERECHA
    mov ax, jugador_px
    add ax, VELOCIDAD
    cmp ax, 784
    ja pmc_no_movimiento
    
    mov cx, ax
    shr cx, 4
    mov dx, jugador_py
    shr dx, 4
    call verificar_tile_transitable
    jnc pmc_no_movimiento
    
    mov jugador_px, ax
    mov moviendo, 1
    jmp SHORT pmc_fin

pmc_no_movimiento:
    mov moviendo, 0
    jmp SHORT pmc_fin

pmc_no_tecla:
    mov moviendo, 0

pmc_fin:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
procesar_movimiento_continuo ENDP

; =====================================================
; ACTUALIZAR ANIMACIÓN
; =====================================================
actualizar_animacion PROC
    push ax
    
    ; Solo animar si está en movimiento
    cmp moviendo, 0
    je aa_fin
    
    ; Incrementar contador de pasos
    inc pasos_dados
    mov al, pasos_dados
    
    ; Cambiar frame cada 4 píxeles (más suave)
    cmp al, 4
    jb aa_fin
    
    ; Reset contador
    mov pasos_dados, 0
    
    ; Toggle frame
    xor jugador_frame, 1
    
aa_fin:
    pop ax
    ret
actualizar_animacion ENDP

; =====================================================
; CENTRAR CÁMARA SUAVEMENTE
; =====================================================
centrar_camara PROC
    push ax
    push bx
    push cx
    
    ; Calcular posición objetivo X
    mov ax, jugador_px
    sub ax, 160
    jge cc_x_pos
    xor ax, ax
cc_x_pos:
    cmp ax, 480
    jle cc_x_ok
    mov ax, 480
cc_x_ok:
    mov bx, ax
    
    ; Interpolar suavemente (smooth scrolling)
    mov ax, camara_px
    cmp ax, bx
    je cc_y_check
    
    jl cc_x_mover_der
    
    ; Mover cámara izquierda
    sub ax, VELOCIDAD
    cmp ax, bx
    jge cc_x_set
    mov ax, bx
    jmp SHORT cc_x_set
    
cc_x_mover_der:
    add ax, VELOCIDAD
    cmp ax, bx
    jle cc_x_set
    mov ax, bx
    
cc_x_set:
    mov camara_px, ax
    
cc_y_check:
    ; Calcular posición objetivo Y
    mov ax, jugador_py
    sub ax, 96
    jge cc_y_pos
    xor ax, ax
cc_y_pos:
    cmp ax, 608
    jle cc_y_ok
    mov ax, 608
cc_y_ok:
    mov bx, ax
    
    ; Interpolar suavemente
    mov ax, camara_py
    cmp ax, bx
    je cc_fin
    
    jl cc_y_mover_abajo
    
    ; Mover cámara arriba
    sub ax, VELOCIDAD
    cmp ax, bx
    jge cc_y_set
    mov ax, bx
    jmp SHORT cc_y_set
    
cc_y_mover_abajo:
    add ax, VELOCIDAD
    cmp ax, bx
    jle cc_y_set
    mov ax, bx
    
cc_y_set:
    mov camara_py, ax
    
cc_fin:
    pop cx
    pop bx
    pop ax
    ret
centrar_camara ENDP

; =====================================================
; VERIFICAR SI TILE ES TRANSITABLE
; =====================================================
verificar_tile_transitable PROC
    push ax
    push bx
    push dx
    
    cmp cx, 50
    jae vtt_no_transitable
    cmp dx, 50
    jae vtt_no_transitable
    
    mov ax, dx
    mov bx, 50
    mul bx
    add ax, cx
    mov bx, ax
    
    mov al, [mapa_datos + bx]
    
    cmp al, TILE_WATER
    je vtt_no_transitable
    cmp al, TILE_TREE
    je vtt_no_transitable
    cmp al, TILE_ROCK
    je vtt_no_transitable
    cmp al, TILE_MOUNTAIN
    je vtt_no_transitable
    cmp al, TILE_BUSH
    je vtt_no_transitable
    cmp al, TILE_LAVA
    je vtt_no_transitable

    pop dx
    pop bx
    pop ax
    stc
    ret

vtt_no_transitable:
    pop dx
    pop bx
    pop ax
    clc
    ret
verificar_tile_transitable ENDP

; =====================================================
; CARGAR SPRITES DE TERRENO
; =====================================================
cargar_sprites_terreno PROC
    push ax
    push dx
    push di
    
    mov dx, OFFSET msg_grass1
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_grass1
    mov di, OFFSET sprite_grass1
    call cargar_sprite_16x16
    jnc cst_1
    jmp cst_error
cst_1:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h

    mov dx, OFFSET msg_grass2
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_grass2
    mov di, OFFSET sprite_grass2
    call cargar_sprite_16x16
    jnc cst_2
    jmp cst_error
cst_2:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h

    mov dx, OFFSET msg_flower
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_flower
    mov di, OFFSET sprite_flower
    call cargar_sprite_16x16
    jnc cst_3
    jmp cst_error
cst_3:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h

    mov dx, OFFSET msg_path
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_path
    mov di, OFFSET sprite_path
    call cargar_sprite_16x16
    jnc cst_4
    jmp cst_error
cst_4:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    mov dx, OFFSET msg_water
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_water
    mov di, OFFSET sprite_water
    call cargar_sprite_16x16
    jnc cst_5
    jmp cst_error
cst_5:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    mov dx, OFFSET msg_tree
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_tree
    mov di, OFFSET sprite_tree
    call cargar_sprite_16x16
    jnc cst_6
    jmp cst_error
cst_6:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h

    mov dx, OFFSET msg_sand
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_sand
    mov di, OFFSET sprite_sand
    call cargar_sprite_16x16
    jnc cst_7
    jmp cst_error
cst_7:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h

    mov dx, OFFSET msg_rock
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_rock
    mov di, OFFSET sprite_rock
    call cargar_sprite_16x16
    jnc cst_8
    jmp cst_error
cst_8:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h

    mov dx, OFFSET msg_snow
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_snow
    mov di, OFFSET sprite_snow
    call cargar_sprite_16x16
    jnc cst_9
    jmp cst_error
cst_9:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h

    mov dx, OFFSET msg_ice
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_ice
    mov di, OFFSET sprite_ice
    call cargar_sprite_16x16
    jnc cst_10
    jmp cst_error
cst_10:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h

    mov dx, OFFSET msg_mountain
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_mountain
    mov di, OFFSET sprite_mountain
    call cargar_sprite_16x16
    jnc cst_11
    jmp cst_error
cst_11:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h

    mov dx, OFFSET msg_hill
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_hill
    mov di, OFFSET sprite_hill
    call cargar_sprite_16x16
    jnc cst_12
    jmp cst_error
cst_12:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h

    mov dx, OFFSET msg_bush
    mov ah, 9
    int 21h
    mov dx, OFFSET arquivo_bush
    mov di, OFFSET sprite_bush
    call cargar_sprite_16x16
    jnc cst_13
    jmp cst_error
cst_13:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h

    mov dx, OFFSET msg_dirt
    mov ah, 9
    int 21h
    mov dx, OFFSET arquivo_dirt
    mov di, OFFSET sprite_dirt
    call cargar_sprite_16x16
    jnc cst_14
    jmp cst_error
cst_14:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h

    mov dx, OFFSET msg_lava
    mov ah, 9
    int 21h
    mov dx, OFFSET arquivo_lava
    mov di, OFFSET sprite_lava
    call cargar_sprite_16x16
    jnc cst_15
    jmp cst_error
cst_15:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h

    mov dx, OFFSET msg_bridge
    mov ah, 9
    int 21h
    mov dx, OFFSET arquivo_bridge
    mov di, OFFSET sprite_bridge
    call cargar_sprite_16x16
    jnc cst_ok
    jmp cst_error
cst_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    clc
    jmp SHORT cst_fin

cst_error:
    stc

cst_fin:
    pop di
    pop dx
    pop ax
    ret
cargar_sprites_terreno ENDP

; =====================================================
; CARGAR ANIMACIONES DEL JUGADOR
; =====================================================
cargar_animaciones_jugador PROC
    push ax
    push dx
    push di
    
    mov dx, OFFSET archivo_player_up_a
    mov di, OFFSET jugador_up_a
    call cargar_sprite_16x16
    jc caj_error
    
    mov dx, OFFSET archivo_player_up_b
    mov di, OFFSET jugador_up_b
    call cargar_sprite_16x16
    jc caj_error
    
    mov dx, OFFSET archivo_player_down_a
    mov di, OFFSET jugador_down_a
    call cargar_sprite_16x16
    jc caj_error
    
    mov dx, OFFSET archivo_player_down_b
    mov di, OFFSET jugador_down_b
    call cargar_sprite_16x16
    jc caj_error
    
    mov dx, OFFSET archivo_player_izq_a
    mov di, OFFSET jugador_izq_a
    call cargar_sprite_16x16
    jc caj_error
    
    mov dx, OFFSET archivo_player_izq_b
    mov di, OFFSET jugador_izq_b
    call cargar_sprite_16x16
    jc caj_error
    
    mov dx, OFFSET archivo_player_der_a
    mov di, OFFSET jugador_der_a
    call cargar_sprite_16x16
    jc caj_error
    
    mov dx, OFFSET archivo_player_der_b
    mov di, OFFSET jugador_der_b
    call cargar_sprite_16x16
    jc caj_error
    
    clc
    jmp SHORT caj_fin
    
caj_error:
    stc
    
caj_fin:
    pop di
    pop dx
    pop ax
    ret
cargar_animaciones_jugador ENDP

; =====================================================
; OBTENER SPRITE DEL JUGADOR
; =====================================================
obtener_sprite_jugador PROC
    push ax
    push bx
    
    mov al, jugador_dir
    mov bl, jugador_frame
    
    cmp al, DIR_ABAJO
    jne osj_arr
    test bl, bl
    jz osj_down_a
    mov si, OFFSET jugador_down_b
    jmp SHORT osj_fin
osj_down_a:
    mov si, OFFSET jugador_down_a
    jmp SHORT osj_fin
    
osj_arr:
    cmp al, DIR_ARRIBA
    jne osj_izq
    test bl, bl
    jz osj_up_a
    mov si, OFFSET jugador_up_b
    jmp SHORT osj_fin
osj_up_a:
    mov si, OFFSET jugador_up_a
    jmp SHORT osj_fin
    
osj_izq:
    cmp al, DIR_IZQUIERDA
    jne osj_der
    test bl, bl
    jz osj_izq_a
    mov si, OFFSET jugador_izq_b
    jmp SHORT osj_fin
osj_izq_a:
    mov si, OFFSET jugador_izq_a
    jmp SHORT osj_fin
    
osj_der:
    test bl, bl
    jz osj_der_a
    mov si, OFFSET jugador_der_b
    jmp SHORT osj_fin
osj_der_a:
    mov si, OFFSET jugador_der_a
    
osj_fin:
    pop bx
    pop ax
    ret
obtener_sprite_jugador ENDP

; =====================================================
; RENDERIZAR EN PÁGINA 0
; =====================================================
renderizar_en_pagina_0 PROC
    push ax
    push es
    
    mov ax, VIDEO_SEG
    mov es, ax
    mov ax, 0
    call dibujar_todo_en_offset
    
    pop es
    pop ax
    ret
renderizar_en_pagina_0 ENDP

; =====================================================
; RENDERIZAR EN PÁGINA 1
; =====================================================
renderizar_en_pagina_1 PROC
    push ax
    push es
    
    mov ax, VIDEO_SEG
    mov es, ax
    mov ax, 8000h
    call dibujar_todo_en_offset
    
    pop es
    pop ax
    ret
renderizar_en_pagina_1 ENDP

; =====================================================
; DIBUJAR TODO EN OFFSET
; =====================================================
dibujar_todo_en_offset PROC
    push ax
    
    mov temp_offset, ax
    call dibujar_mapa_en_offset
    call dibujar_jugador_en_offset
    
    pop ax
    ret
dibujar_todo_en_offset ENDP

; =====================================================
; DIBUJAR MAPA EN OFFSET
; =====================================================
dibujar_mapa_en_offset PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    ; Calcular tile de inicio
    mov ax, camara_px
    shr ax, 4
    mov inicio_tile_x, ax
    
    mov ax, camara_py
    shr ax, 4
    mov inicio_tile_y, ax
    
    ; Calcular offset de píxeles
    mov ax, camara_px
    and ax, 15
    mov offset_px_x, ax
    
    mov ax, camara_py
    and ax, 15
    mov offset_px_y, ax
    
    xor bp, bp

dmo_fila:
    cmp bp, 13
    jae dmo_fin
    
    xor si, si

dmo_col:
    cmp si, 21
    jae dmo_next_fila
    
    ; Verificar límites
    mov ax, inicio_tile_y
    add ax, bp
    cmp ax, 50
    jae dmo_next_col
    
    mov bx, inicio_tile_x
    add bx, si
    cmp bx, 50
    jae dmo_next_col
    
    ; Obtener tile del mapa
    push dx
    mov dx, 50
    mul dx
    add ax, bx
    pop dx
    mov bx, ax
    
    mov al, [mapa_datos + bx]
    call obtener_sprite_tile
    
    ; Calcular posición en pantalla
    push si
    push bp
    
    mov ax, si
    shl ax, 4
    sub ax, offset_px_x
    add ax, viewport_x
    mov cx, ax
    
    mov ax, bp
    shl ax, 4
    sub ax, offset_px_y
    add ax, viewport_y
    mov dx, ax
    
    call dibujar_sprite_16x16_en_offset
    
    pop bp
    pop si
    
dmo_next_col:
    inc si
    jmp dmo_col
    
dmo_next_fila:
    inc bp
    jmp dmo_fila
    
dmo_fin:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_mapa_en_offset ENDP

; =====================================================
; OBTENER SPRITE DE TILE
; =====================================================
obtener_sprite_tile PROC
    push ax
    push bx
    
    mov bl, al
    mov di, OFFSET sprite_grass1
    
    cmp bl, TILE_GRASS2
    jne ost_2
    mov di, OFFSET sprite_grass2
    jmp ost_fin
ost_2:
    cmp bl, TILE_FLOWER
    jne ost_3
    mov di, OFFSET sprite_flower
    jmp ost_fin
ost_3:
    cmp bl, TILE_PATH
    jne ost_4
    mov di, OFFSET sprite_path
    jmp ost_fin
ost_4:
    cmp bl, TILE_WATER
    jne ost_5
    mov di, OFFSET sprite_water
    jmp ost_fin
ost_5:
    cmp bl, TILE_TREE
    jne ost_6
    mov di, OFFSET sprite_tree
    jmp ost_fin
ost_6:
    cmp bl, TILE_SAND
    jne ost_7
    mov di, OFFSET sprite_sand
    jmp ost_fin
ost_7:
    cmp bl, TILE_ROCK
    jne ost_8
    mov di, OFFSET sprite_rock
    jmp ost_fin
ost_8:
    cmp bl, TILE_SNOW
    jne ost_9
    mov di, OFFSET sprite_snow
    jmp ost_fin
ost_9:
    cmp bl, TILE_ICE
    jne ost_10
    mov di, OFFSET sprite_ice
    jmp ost_fin
ost_10:
    cmp bl, TILE_MOUNTAIN
    jne ost_11
    mov di, OFFSET sprite_mountain
    jmp ost_fin
ost_11:
    cmp bl, TILE_HILL
    jne ost_12
    mov di, OFFSET sprite_hill
    jmp ost_fin
ost_12:
    cmp bl, TILE_BUSH
    jne ost_13
    mov di, OFFSET sprite_bush
    jmp ost_fin
ost_13:
    cmp bl, TILE_DIRT
    jne ost_14
    mov di, OFFSET sprite_dirt
    jmp ost_fin
ost_14:
    cmp bl, TILE_LAVA
    jne ost_15
    mov di, OFFSET sprite_lava
    jmp ost_fin
ost_15:
    cmp bl, TILE_BRIDGE
    jne ost_fin
    mov di, OFFSET sprite_bridge

ost_fin:
    pop bx
    pop ax
    ret
obtener_sprite_tile ENDP

; =====================================================
; DIBUJAR JUGADOR EN OFFSET
; =====================================================
dibujar_jugador_en_offset PROC
    push ax
    push cx
    push dx
    push si
    
    ; Calcular posición en pantalla
    mov ax, jugador_px
    sub ax, camara_px
    add ax, viewport_x
    mov cx, ax
    
    mov ax, jugador_py
    sub ax, camara_py
    add ax, viewport_y
    mov dx, ax
    
    ; Obtener sprite correcto
    call obtener_sprite_jugador
    mov di, si
    
    call dibujar_sprite_16x16_en_offset
    
    pop si
    pop dx
    pop cx
    pop ax
    ret
dibujar_jugador_en_offset ENDP

; =====================================================
; DIBUJAR SPRITE 16x16
; =====================================================
dibujar_sprite_16x16_en_offset PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push bp
    
    mov si, di
    mov bp, 16
    
ds16_fila:
    mov bx, cx
    push bp
    mov bp, 16
    
ds16_pixel:
    lodsb
    test al, al
    jz ds16_skip
    
    call escribir_pixel_en_offset
    
ds16_skip:
    inc cx
    dec bp
    jnz ds16_pixel
    
    mov cx, bx
    pop bp
    inc dx
    dec bp
    jnz ds16_fila
    
    pop bp
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_sprite_16x16_en_offset ENDP

; =====================================================
; ESCRIBIR PÍXEL EN OFFSET
; =====================================================
escribir_pixel_en_offset PROC
    push ax
    push bx
    push cx
    push dx
    push di
    
    mov bl, al
    
    ; Calcular offset en memoria de video
    mov ax, dx
    mov di, 80
    mul di
    add ax, temp_offset
    mov di, ax
    
    mov ax, cx
    shr ax, 3
    add di, ax
    
    ; Calcular máscara de bit
    and cx, 7
    mov al, 80h
    shr al, cl
    mov ah, al
    
    ; Configurar Graphics Controller
    mov dx, 3CEh
    
    ; Set/Reset Register
    mov al, 0
    out dx, al
    inc dx
    mov al, bl
    out dx, al
    dec dx
    
    ; Enable Set/Reset
    mov al, 1
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    dec dx
    
    ; Bit Mask
    mov al, 8
    out dx, al
    inc dx
    mov al, ah
    out dx, al
    
    ; Escribir píxel
    mov al, es:[di]
    mov es:[di], al
    
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
escribir_pixel_en_offset ENDP

; =====================================================
; ESPERAR RETRACE VERTICAL
; =====================================================
esperar_retrace PROC
    push ax
    push dx
    
    mov dx, 3DAh
    
er_wait_end:
    in al, dx
    test al, 8
    jnz er_wait_end
    
er_wait_start:
    in al, dx
    test al, 8
    jz er_wait_start
    
    pop dx
    pop ax
    ret
esperar_retrace ENDP

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
    push bp
    
    mov ax, 3D00h
    mov dx, OFFSET archivo_mapa
    int 21h
    jc cm_error
    
    mov bx, ax
    call saltar_linea
    
    mov di, OFFSET mapa_datos
    xor bp, bp
    
cm_leer:
    mov ah, 3Fh
    mov cx, 200
    mov dx, OFFSET buffer_temp
    int 21h
    
    cmp ax, 0
    je cm_cerrar
    
    mov cx, ax
    xor si, si

cm_proc:
    cmp si, cx
    jae cm_leer

    mov al, [buffer_temp + si]
    inc si
    
    cmp al, ' '
    je cm_proc
    cmp al, 13
    je cm_proc
    cmp al, 10
    je cm_proc
    cmp al, 9
    je cm_proc
    
    cmp al, '0'
    jb cm_chk_upper
    cmp al, '9'
    ja cm_chk_upper
    sub al, '0'
    jmp cm_store

cm_chk_upper:
    cmp al, 'A'
    jb cm_chk_lower
    cmp al, 'F'
    ja cm_chk_lower
    sub al, 'A'
    add al, 10
    jmp cm_store

cm_chk_lower:
    cmp al, 'a'
    jb cm_proc
    cmp al, 'f'
    ja cm_proc
    sub al, 'a'
    add al, 10

cm_store:
    mov [di], al
    inc di
    inc bp
    cmp bp, 2500
    jb cm_proc
    
cm_cerrar:
    mov ah, 3Eh
    int 21h
    clc
    jmp SHORT cm_fin
    
cm_error:
    stc
    
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
; CARGAR SPRITE 16x16
; =====================================================
cargar_sprite_16x16 PROC
    push ax
    push bx
    push cx
    push si
    push bp
    
    mov ax, 3D00h
    int 21h
    jc cs16_error
    
    mov bx, ax
    call saltar_linea
    
    xor bp, bp
    
cs16_leer:
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

    mov al, [buffer_temp + si]
    inc si
    
    cmp al, ' '
    je cs16_proc
    cmp al, 13
    je cs16_proc
    cmp al, 10
    je cs16_proc
    cmp al, 9
    je cs16_proc
    
    cmp al, '0'
    jb cs16_proc
    cmp al, '9'
    jbe cs16_dec
    
    and al, 0DFh
    cmp al, 'A'
    jb cs16_proc
    cmp al, 'F'
    ja cs16_proc
    sub al, 'A' - 10
    jmp SHORT cs16_guardar

cs16_dec:
    sub al, '0'

cs16_guardar:
    mov [di], al
    inc di
    inc bp
    cmp bp, 256
    jb cs16_proc
    
cs16_cerrar:
    mov ah, 3Eh
    int 21h
    clc
    jmp SHORT cs16_fin
    
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
; SALTAR LÍNEA
; =====================================================
saltar_linea PROC
    push ax
    push cx
    push dx
    
sl_loop:
    mov ah, 3Fh
    mov cx, 1
    mov dx, OFFSET buffer_temp
    int 21h
    
    cmp ax, 0
    je sl_fin
    
    mov al, [buffer_temp]
    cmp al, 10
    je sl_fin
    cmp al, 13
    jne sl_loop
    
sl_fin:
    pop dx
    pop cx
    pop ax
    ret
saltar_linea ENDP

END inicio