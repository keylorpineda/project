; JUEGO EGA - Universidad Nacional - Proyecto II Ciclo 2025
; VERSIÓN CORREGIDA Y FUNCIONAL
.MODEL SMALL
.STACK 2048

TILE_GRASS1   EQU 0
TILE_PATH     EQU 3
TILE_WATER    EQU 4
TILE_TREE     EQU 5
TILE_SAND     EQU 6
TILE_SNOW     EQU 8
TILE_ICE      EQU 9
TILE_WALL     EQU 10
TILE_DIRT     EQU 13
TILE_LAVA     EQU 14
TILE_ROCK     EQU 7
TILE_BRIDGE   EQU 15

TILE_SIZE      EQU 16
VIDEO_SEG      EQU 0A000h
VELOCIDAD      EQU 4

DIR_ABAJO      EQU 0
DIR_ARRIBA     EQU 1
DIR_IZQUIERDA  EQU 2
DIR_DERECHA    EQU 3

.DATA
archivo_mapa   db 'MAPA.TXT',0
archivo_grass1 db 'SPRITES\GRASS_1.TXT',0
archivo_path   db 'SPRITES\PATH_2.TXT',0
archivo_water  db 'SPRITES\WATER_2.TXT',0
archivo_tree   db 'SPRITES\TREE_1.TXT',0
archivo_sand   db 'SPRITES\SAND_1.TXT',0
archivo_snow   db 'SPRITES\SNOW_1.TXT',0
archivo_ice    db 'SPRITES\ICE_1.TXT',0
archivo_wall   db 'SPRITES\WALL_1.TXT',0
arquivo_dirt   db 'SPRITES\DIRT_1.TXT',0
arquivo_lava   db 'SPRITES\LAVA_1.TXT',0
arquivo_bridge db 'SPRITES\BRIDGE_1.TXT',0
archivo_rock   db 'SPRITES\ROCK_1.TXT',0

archivo_player_up_a    db 'SPRITES\PLAYER\UP1.TXT',0
arquivo_player_up_b    db 'SPRITES\PLAYER\UP2.TXT',0
archivo_player_down_a  db 'SPRITES\PLAYER\DOWN1.TXT',0
archivo_player_down_b  db 'SPRITES\PLAYER\DOWN2.TXT',0
archivo_player_izq_a   db 'SPRITES\PLAYER\LEFT1.TXT',0
archivo_player_izq_b   db 'SPRITES\PLAYER\LEFT2.TXT',0
archivo_player_der_a   db 'SPRITES\PLAYER\RIGHT1.TXT',0
archivo_player_der_b   db 'SPRITES\PLAYER\RIGHT2.TXT',0

mapa_datos  db 10000 dup(0)

sprite_grass1_temp   db 256 dup(0)
sprite_path_temp     db 256 dup(0)
sprite_water_temp    db 256 dup(0)
sprite_tree_temp     db 256 dup(0)
sprite_sand_temp     db 256 dup(0)
sprite_snow_temp     db 256 dup(0)
sprite_ice_temp      db 256 dup(0)
sprite_wall_temp     db 256 dup(0)
sprite_dirt_temp     db 256 dup(0)
sprite_lava_temp     db 256 dup(0)
sprite_rock_temp     db 256 dup(0)
sprite_bridge_temp   db 256 dup(0)

sprite_grass1   db 128 dup(0)
sprite_path     db 128 dup(0)
sprite_water    db 128 dup(0)
sprite_tree     db 128 dup(0)
sprite_sand     db 128 dup(0)
sprite_snow     db 128 dup(0)
sprite_ice      db 128 dup(0)
sprite_wall     db 128 dup(0)
sprite_dirt     db 128 dup(0)
sprite_lava     db 128 dup(0)
sprite_rock     db 128 dup(0)
sprite_bridge   db 128 dup(0)

jugador_up_a_temp    db 1024 dup(0)
jugador_up_b_temp    db 1024 dup(0)
jugador_down_a_temp  db 1024 dup(0)
jugador_down_b_temp  db 1024 dup(0)
jugador_izq_a_temp   db 1024 dup(0)
jugador_izq_b_temp   db 1024 dup(0)
jugador_der_a_temp   db 1024 dup(0)
jugador_der_b_temp   db 1024 dup(0)

jugador_up_a    db 512 dup(0)    
jugador_up_b    db 512 dup(0)
jugador_down_a  db 512 dup(0)
jugador_down_b  db 512 dup(0)
jugador_izq_a   db 512 dup(0)
jugador_izq_b   db 512 dup(0)
jugador_der_a   db 512 dup(0)
jugador_der_b   db 512 dup(0)

buffer_temp db 300 dup(0)

jugador_px  dw 400
jugador_py  dw 400
jugador_dir db DIR_ABAJO
jugador_frame db 0

jugador_px_old  dw 400
jugador_py_old  dw 400
frame_old       db 0

moviendo db 0
pasos_dados db 0

camara_px   dw 240
camara_py   dw 304

camara_px_old   dw 240
camara_py_old   dw 304

pagina_visible db 0
pagina_dibujo  db 1

viewport_x  dw 160
viewport_y  dw 79

temp_offset     dw 0
inicio_tile_x   dw 0
inicio_tile_y   dw 0
temp_fila dw 0
temp_col  dw 0

dirty_count dw 0
dirty_list  dw 308 dup(0)

scroll_offset_x dw 0
scroll_offset_y dw 0

INCLUDE OPTDATA.INC

msg_titulo  db 'JUEGO EGA - Universidad Nacional',13,10,'$'
msg_cargando db 'Cargando archivos...',13,10,'$'
msg_mapa    db 'Mapa: $'
msg_sprites db 'Sprites terreno: $'
msg_anim    db 'Sprites jugador: $'
msg_convert db 'Convirtiendo...$'
msg_tablas  db 'Lookup tables: $' 
msg_ok      db 'OK',13,10,'$'
msg_error   db 'ERROR',13,10,'$'
msg_controles db 13,10,'WASD = Mover, ESC = Salir',13,10
              db 'Presiona tecla...$'

.CODE
inicio:
    mov ax, @data
    mov ds, ax
    mov dx, OFFSET msg_cargando
    mov ah, 9
    int 21h
    
    ; ===== FASE 2: CARGAR MAPA =====
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
    
    ; ===== FASE 3: CARGAR SPRITES =====
    mov dx, OFFSET msg_sprites
    mov ah, 9
    int 21h
    call cargar_sprites_terreno
    jnc st_ok
    jmp error_carga
st_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    ; ===== FASE 4: CARGAR ANIMACIONES =====
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
    
    ; ===== FASE 5: CONVERTIR A PLANAR =====
mov dx, OFFSET msg_convert
mov ah, 9
int 21h
call convertir_todos_sprites_planar
mov dx, OFFSET msg_ok
mov ah, 9
int 21h

; ===== FASE 5B: PRE-CALCULAR MÁSCARAS (CRÍTICO) =====
mov dx, OFFSET msg_convert
mov ah, 9
int 21h
call precalcular_mascaras_tiles
call precalcular_mascaras_jugador
mov dx, OFFSET msg_ok
mov ah, 9
int 21h

; ===== FASE 6: INICIALIZAR TABLAS =====
mov dx, OFFSET msg_tablas
    mov ah, 9
    int 21h
    call inicializar_lookup_tables
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    call debug_verificar_todo


mov dx, OFFSET msg_controles
mov ah, 9
int 21h
mov ah, 0
int 16h

; ===== ENTRAR A MODO GRÁFICO =====
mov ax, 10h
int 10h

; ===== CONFIGURAR PALETA =====
call inicializar_paleta_ega

; ===== CONFIGURAR REGISTROS EGA =====
; Sequence Controller - Map Mask
mov dx, 3C4h
mov al, 2
out dx, al
inc dx
mov al, 0Fh         ; Habilitar los 4 planos
out dx, al

; Graphics Controller - Modo de escritura
mov dx, 3CEh
mov al, 5
out dx, al
inc dx
mov al, 0           ; Write Mode 0
out dx, al

; Graphics Controller - Bit Mask
mov dx, 3CEh
mov al, 8
out dx, al
inc dx
mov al, 0FFh
out dx, al

; ===== LIMPIAR AMBAS PÁGINAS =====
mov ax, VIDEO_SEG
mov es, ax

; Limpiar página 0 (offset 0)
xor di, di
mov cx, 14000       ; 28000 bytes / 2 = 14000 words
xor ax, ax
rep stosw

; Limpiar página 1 (offset 8000h)
mov di, 8000h
mov cx, 14000
xor ax, ax
rep stosw

; ===== INICIALIZAR JUEGO =====
call centrar_camara

mov ax, camara_px
mov camara_px_old, ax
mov ax, camara_py
mov camara_py_old, ax

; ✅ Marcar TODO como sucio para el primer renderizado
push ds
pop es
mov cx, 10000
mov di, OFFSET dirty_tiles
mov al, 1
rep stosb

; Restaurar ES al segmento de video
mov ax, VIDEO_SEG
mov es, ax

; ✅ Renderizar AMBAS páginas inicialmente
mov temp_offset, 0
call dibujar_mapa_en_offset
call dibujar_jugador_en_offset

mov temp_offset, 8000h
call dibujar_mapa_en_offset
call dibujar_jugador_en_offset

; ✅ Limpiar dirty tiles DESPUÉS de renderizar ambas
call limpiar_tiles_sucios

; ✅ Guardar estado inicial
mov ax, jugador_px
mov jugador_px_old, ax
mov ax, jugador_py
mov jugador_py_old, ax
mov al, jugador_frame
mov frame_old, al

; ✅ Mostrar página 0 y configurar variables
mov ah, 5
mov al, 0
int 10h

mov pagina_visible, 0
mov pagina_dibujo, 1

; ===== BUCLE PRINCIPAL OPTIMIZADO =====
bucle_juego:
    call procesar_movimiento_continuo
    call actualizar_animacion
    call centrar_camara
    
    ; Verificar cambios de posición
    mov ax, jugador_px
    cmp ax, jugador_px_old
    jne bg_hay_cambio
    
    mov ax, jugador_py
    cmp ax, jugador_py_old
    jne bg_hay_cambio
    
    mov al, jugador_frame
    cmp al, frame_old
    jne bg_hay_cambio
    
    mov ax, camara_px
    cmp ax, camara_px_old
    jne bg_hay_cambio
    
    mov ax, camara_py
    cmp ax, camara_py_old
    jne bg_hay_cambio

    ; Sin cambios, solo esperar vsync
    call esperar_retrace
    jmp bucle_juego
    
bg_hay_cambio:
    ; Verificar si la cámara se movió
    mov ax, camara_px
    cmp ax, camara_px_old
    jne bg_camara_movio
    mov ax, camara_py
    cmp ax, camara_py_old
    je bg_solo_jugador
    
bg_camara_movio:
    ; Cámara movida = marcar todo el viewport
    call marcar_viewport_completo
    jmp bg_marcar_jugador_done
    
bg_solo_jugador:
    ; Solo jugador movido = marcar regiones específicas
    
    ; Guardar posición actual
    push jugador_px
    push jugador_py
    
    ; Marcar región antigua
    mov ax, jugador_px_old
    mov bx, jugador_py_old
    mov jugador_px, ax
    mov jugador_py, bx
    call marcar_region_jugador
    
    ; Restaurar posición actual
    pop jugador_py
    pop jugador_px
    
    ; Marcar región nueva
    call marcar_region_jugador
    
bg_marcar_jugador_done:
    ; ✅ CRÍTICO: Esperar retrace ANTES de renderizar
    call esperar_retrace
    
    ; Renderizar en página oculta
    mov al, pagina_dibujo
    test al, 1
    jz bg_render_p0
    
    ; Renderizar en página 1 (offset 8000h)
    mov temp_offset, 8000h
    call dibujar_mapa_en_offset
    call dibujar_jugador_en_offset
    jmp bg_flip
    
bg_render_p0:
    ; Renderizar en página 0 (offset 0)
    mov temp_offset, 0
    call dibujar_mapa_en_offset
    call dibujar_jugador_en_offset
    
bg_flip:
    ; Cambiar página visible (sin espera adicional)
    mov ah, 5
    mov al, pagina_dibujo
    int 10h
    
    ; Intercambiar variables de página
    xor pagina_dibujo, 1
    xor pagina_visible, 1
    
    ; Guardar estado para próximo frame
    mov ax, jugador_px
    mov jugador_px_old, ax
    mov ax, jugador_py
    mov jugador_py_old, ax
    mov al, jugador_frame
    mov frame_old, al
    mov ax, camara_px
    mov camara_px_old, ax
    mov ax, camara_py
    mov camara_py_old, ax
    
    ; Limpiar dirty tiles al final
    call limpiar_tiles_sucios
    
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

inicializar_paleta_ega PROC
    mov dx, 3C0h
    mov al, 20h
    out dx, al
    ret
inicializar_paleta_ega ENDP

procesar_movimiento_continuo PROC
    push ax
    push bx
    push cx
    push dx
    
    mov ah, 1
    int 16h
    jnz pmc_tiene_tecla
    jmp pmc_no_tecla

pmc_tiene_tecla:
    mov ah, 0
    int 16h
    
    ; CRÍTICO: Verificar ESC primero
    cmp ah, 01h
    je pmc_salir
    cmp al, 27
    je pmc_salir
    
    mov bl, al
    mov bh, ah

    test bl, bl
    jz pmc_usar_scan
    mov al, bl
    jmp pmc_normalizar

pmc_usar_scan:
    mov al, bh

pmc_normalizar:
    cmp al, 'a'
    jb pmc_verificar
    cmp al, 'z'
    ja pmc_verificar
    and al, 5Fh

pmc_verificar:
    cmp al, 48h
    je pmc_arriba
    cmp al, 'W'
    je pmc_arriba

    cmp al, 50h
    je pmc_abajo
    cmp al, 'S'
    je pmc_abajo

    cmp al, 4Bh
    jne pmc_verificar_a
    jmp pmc_izquierda

pmc_verificar_a:
    cmp al, 'A'
    jne pmc_verificar_derecha_scan
    jmp pmc_izquierda

pmc_verificar_derecha_scan:
    cmp al, 4Dh
    jne pmc_verificar_derecha_letra
    jmp pmc_derecha

pmc_verificar_derecha_letra:
    cmp al, 'D'
    jne pmc_no_movimiento_local
    jmp pmc_derecha

pmc_no_movimiento_local:
    jmp pmc_no_movimiento

pmc_salir:
    ; ✅ Salida limpia sin afectar el stack
    pop dx
    pop cx
    pop bx
    pop ax
    
    ; Restaurar modo texto
    mov ax, 3
    int 10h
    
    ; Salir a DOS
    mov ax, 4C00h
    int 21h

pmc_arriba:
    mov jugador_dir, DIR_ARRIBA
    mov ax, jugador_py
    sub ax, VELOCIDAD
    cmp ax, 16
    jae pmc_arriba_dentro_limite
    jmp pmc_no_movimiento

pmc_arriba_dentro_limite:
    mov cx, jugador_px
    shr cx, 4
    mov dx, ax
    sub dx, 8
    shr dx, 4
    call verificar_tile_transitable
    jc pmc_arriba_transitable
    jmp pmc_no_movimiento

pmc_arriba_transitable:
    mov jugador_py, ax
    mov moviendo, 1
    jmp pmc_fin

pmc_abajo:
    mov jugador_dir, DIR_ABAJO
    mov ax, jugador_py
    add ax, VELOCIDAD
    cmp ax, 1584        ; ✅ CAMBIO: 100×16-16 = 1584 (antes 784)
    jbe pmc_abajo_dentro_limite
    jmp pmc_no_movimiento

pmc_abajo_dentro_limite:
    mov cx, jugador_px
    shr cx, 4
    mov dx, ax
    shr dx, 4
    call verificar_tile_transitable
    jc pmc_abajo_transitable
    jmp pmc_no_movimiento

pmc_abajo_transitable:
    mov jugador_py, ax
    mov moviendo, 1
    jmp pmc_fin

pmc_izquierda:
    mov jugador_dir, DIR_IZQUIERDA
    mov ax, jugador_px
    sub ax, VELOCIDAD
    cmp ax, 16
    jae pmc_izquierda_dentro_limite
    jmp pmc_no_movimiento

pmc_izquierda_dentro_limite:
    mov cx, ax
    sub cx, 8
    shr cx, 4
    mov dx, jugador_py
    shr dx, 4
    call verificar_tile_transitable
    jc pmc_izquierda_transitable
    jmp pmc_no_movimiento

pmc_izquierda_transitable:
    mov jugador_px, ax
    mov moviendo, 1
    jmp pmc_fin

pmc_derecha:
    mov jugador_dir, DIR_DERECHA
    mov ax, jugador_px
    add ax, VELOCIDAD
    cmp ax, 1584        ; ✅ CAMBIO: 100×16-16 = 1584 (antes 784)
    jbe pmc_derecha_dentro_limite
    jmp pmc_no_movimiento

pmc_derecha_dentro_limite:
    mov cx, ax
    add cx, 8
    shr cx, 4
    mov dx, jugador_py
    shr dx, 4
    call verificar_tile_transitable
    jc pmc_derecha_transitable
    jmp pmc_no_movimiento

pmc_derecha_transitable:
    mov jugador_px, ax
    mov moviendo, 1
    jmp pmc_fin

pmc_no_movimiento:
    mov moviendo, 0
    jmp pmc_fin

pmc_no_tecla:
    mov moviendo, 0

pmc_fin:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
procesar_movimiento_continuo ENDP

actualizar_animacion PROC
    push ax
    
    cmp moviendo, 0
    je aa_fin
    
    inc pasos_dados
    mov al, pasos_dados
    cmp al, 4
    jb aa_fin
    
    mov pasos_dados, 0
    xor jugador_frame, 1
    
aa_fin:
    pop ax
    ret
actualizar_animacion ENDP

centrar_camara PROC
    push ax
    push bx
    push dx
    
    ; Calcular objetivo
    mov ax, jugador_px
    sub ax, 160
    jge cc_x_pos
    xor ax, ax
cc_x_pos:
    cmp ax, 1280
    jle cc_x_limite
    mov ax, 1280
cc_x_limite:
    ; ✅ SNAP a múltiplos de 16 (NO 8)
    and ax, 0FFF0h
    
    ; Solo actualizar si cambió >= 16 píxeles
    mov bx, camara_px
    sub bx, ax
    jns cc_x_abs
    neg bx
cc_x_abs:
    cmp bx, 16              ; ✅ Umbral aumentado
    jb cc_y_check
    mov camara_px, ax
    
cc_y_check:
    mov ax, jugador_py
    sub ax, 96
    jge cc_y_pos
    xor ax, ax
cc_y_pos:
    cmp ax, 1408
    jle cc_y_limite
    mov ax, 1408
cc_y_limite:
    and ax, 0FFF0h
    
    mov bx, camara_py
    sub bx, ax
    jns cc_y_abs
    neg bx
cc_y_abs:
    cmp bx, 16              ; ✅ Umbral aumentado
    jb cc_fin
    mov camara_py, ax
    
cc_fin:
    pop dx
    pop bx
    pop ax
    ret
centrar_camara ENDP

verificar_tile_transitable PROC
    call verificar_tile_transitable_opt
    ret
verificar_tile_transitable ENDP

convertir_todos_sprites_planar PROC
    push si
    push di
    push bp
    
    ; ===== TILES 16x16 CON MÁSCARAS =====
    mov si, OFFSET sprite_grass1_temp
    mov di, OFFSET sprite_grass1
    mov bp, OFFSET sprite_grass1_mask
    call convertir_sprite_a_planar_opt

    mov si, OFFSET sprite_path_temp
    mov di, OFFSET sprite_path
    mov bp, OFFSET sprite_path_mask
    call convertir_sprite_a_planar_opt
    
    mov si, OFFSET sprite_water_temp
    mov di, OFFSET sprite_water
    mov bp, OFFSET sprite_water_mask
    call convertir_sprite_a_planar_opt
    
    mov si, OFFSET sprite_tree_temp
    mov di, OFFSET sprite_tree
    mov bp, OFFSET sprite_tree_mask
    call convertir_sprite_a_planar_opt
    
    mov si, OFFSET sprite_sand_temp
    mov di, OFFSET sprite_sand
    mov bp, OFFSET sprite_sand_mask
    call convertir_sprite_a_planar_opt

    mov si, OFFSET sprite_rock_temp        ; ← AGREGAR ESTO
mov di, OFFSET sprite_rock             ; ← AGREGAR ESTO
mov bp, OFFSET sprite_rock_mask        ; ← AGREGAR ESTO
call convertir_sprite_a_planar_opt  

    mov si, OFFSET sprite_snow_temp
    mov di, OFFSET sprite_snow
    mov bp, OFFSET sprite_snow_mask
    call convertir_sprite_a_planar_opt
    
    mov si, OFFSET sprite_ice_temp
    mov di, OFFSET sprite_ice
    mov bp, OFFSET sprite_ice_mask
    call convertir_sprite_a_planar_opt
    
    mov si, OFFSET sprite_wall_temp
    mov di, OFFSET sprite_wall
    mov bp, OFFSET sprite_wall_mask
    call convertir_sprite_a_planar_opt

    mov si, OFFSET sprite_dirt_temp
    mov di, OFFSET sprite_dirt
    mov bp, OFFSET sprite_dirt_mask
    call convertir_sprite_a_planar_opt
    
    mov si, OFFSET sprite_lava_temp
    mov di, OFFSET sprite_lava
    mov bp, OFFSET sprite_lava_mask
    call convertir_sprite_a_planar_opt
    
    mov si, OFFSET sprite_bridge_temp
    mov di, OFFSET sprite_bridge
    mov bp, OFFSET sprite_bridge_mask
    call convertir_sprite_a_planar_opt
    
    ; ===== JUGADOR 32x32 CON MÁSCARAS =====
    mov si, OFFSET jugador_up_a_temp
    mov di, OFFSET jugador_up_a
    mov bp, OFFSET jugador_up_a_mask
    call convertir_sprite_32x32_a_planar_opt
    
    mov si, OFFSET jugador_up_b_temp
    mov di, OFFSET jugador_up_b
    mov bp, OFFSET jugador_up_b_mask
    call convertir_sprite_32x32_a_planar_opt
    
    mov si, OFFSET jugador_down_a_temp
    mov di, OFFSET jugador_down_a
    mov bp, OFFSET jugador_down_a_mask
    call convertir_sprite_32x32_a_planar_opt
    
    mov si, OFFSET jugador_down_b_temp
    mov di, OFFSET jugador_down_b
    mov bp, OFFSET jugador_down_b_mask
    call convertir_sprite_32x32_a_planar_opt
    
    mov si, OFFSET jugador_izq_a_temp
    mov di, OFFSET jugador_izq_a
    mov bp, OFFSET jugador_izq_a_mask
    call convertir_sprite_32x32_a_planar_opt
    
    mov si, OFFSET jugador_izq_b_temp
    mov di, OFFSET jugador_izq_b
    mov bp, OFFSET jugador_izq_b_mask
    call convertir_sprite_32x32_a_planar_opt
    
    mov si, OFFSET jugador_der_a_temp
    mov di, OFFSET jugador_der_a
    mov bp, OFFSET jugador_der_a_mask
    call convertir_sprite_32x32_a_planar_opt
    
    mov si, OFFSET jugador_der_b_temp
    mov di, OFFSET jugador_der_b
    mov bp, OFFSET jugador_der_b_mask
    call convertir_sprite_32x32_a_planar_opt
    
    pop bp
    pop di
    pop si
    ret
convertir_todos_sprites_planar ENDP

cargar_sprites_terreno PROC
    push dx
    push di
    
    mov dx, OFFSET archivo_grass1
    mov di, OFFSET sprite_grass1_temp
    call cargar_sprite_16x16
    jnc cst_load_path
    jmp cst_error

cst_load_path:
    mov dx, OFFSET archivo_path
    mov di, OFFSET sprite_path_temp
    call cargar_sprite_16x16
    jnc cst_load_water
    jmp cst_error

cst_load_water:
    mov dx, OFFSET archivo_water
    mov di, OFFSET sprite_water_temp
    call cargar_sprite_16x16
    jnc cst_load_tree
    jmp cst_error

cst_load_tree:
    mov dx, OFFSET archivo_tree
    mov di, OFFSET sprite_tree_temp
    call cargar_sprite_16x16
    jnc cst_load_sand
    jmp cst_error

cst_load_sand:
    mov dx, OFFSET archivo_sand
    mov di, OFFSET sprite_sand_temp
    call cargar_sprite_16x16
    jnc cst_load_rock
    jmp cst_error

cst_load_rock:              ; ← AGREGAR ESTO
    mov dx, OFFSET archivo_rock
    mov di, OFFSET sprite_rock_temp
    call cargar_sprite_16x16
    jnc cst_load_snow
    jmp cst_error

cst_load_snow:
    mov dx, OFFSET archivo_snow
    mov di, OFFSET sprite_snow_temp
    call cargar_sprite_16x16
    jnc cst_load_ice
    jmp cst_error

cst_load_ice:
    mov dx, OFFSET archivo_ice
    mov di, OFFSET sprite_ice_temp
    call cargar_sprite_16x16
    jnc cst_load_wall
    jmp cst_error

cst_load_wall:
    mov dx, OFFSET archivo_wall
    mov di, OFFSET sprite_wall_temp
    call cargar_sprite_16x16
    jnc cst_load_dirt
    jmp cst_error

cst_load_dirt:
    mov dx, OFFSET arquivo_dirt
    mov di, OFFSET sprite_dirt_temp
    call cargar_sprite_16x16
    jnc cst_load_lava
    jmp cst_error

cst_load_lava:
    mov dx, OFFSET arquivo_lava
    mov di, OFFSET sprite_lava_temp
    call cargar_sprite_16x16
    jnc cst_load_bridge
    jmp cst_error

cst_load_bridge:
    mov dx, OFFSET arquivo_bridge
    mov di, OFFSET sprite_bridge_temp
    call cargar_sprite_16x16
    jnc cst_success
    jmp cst_error

cst_success:
    clc
    jmp cst_fin

cst_error:
    stc

cst_fin:
    pop di
    pop dx
    ret
cargar_sprites_terreno ENDP

; REEMPLAZAR cargar_animaciones_jugador COMPLETO:

cargar_animaciones_jugador PROC
    push dx
    push di
    
    mov dx, OFFSET archivo_player_up_a
    mov di, OFFSET jugador_up_a_temp
    call cargar_sprite_32x32        ; CAMBIO AQUÍ
    jnc caj_load_up_b
    jmp caj_error

caj_load_up_b:
    mov dx, OFFSET arquivo_player_up_b
    mov di, OFFSET jugador_up_b_temp
    call cargar_sprite_32x32        ; CAMBIO AQUÍ
    jnc caj_load_down_a
    jmp caj_error

caj_load_down_a:
    mov dx, OFFSET archivo_player_down_a
    mov di, OFFSET jugador_down_a_temp
    call cargar_sprite_32x32        ; CAMBIO AQUÍ
    jnc caj_load_down_b
    jmp caj_error

caj_load_down_b:
    mov dx, OFFSET archivo_player_down_b
    mov di, OFFSET jugador_down_b_temp
    call cargar_sprite_32x32        ; CAMBIO AQUÍ
    jnc caj_load_left_a
    jmp caj_error

caj_load_left_a:
    mov dx, OFFSET archivo_player_izq_a
    mov di, OFFSET jugador_izq_a_temp
    call cargar_sprite_32x32        ; CAMBIO AQUÍ
    jnc caj_load_left_b
    jmp caj_error

caj_load_left_b:
    mov dx, OFFSET archivo_player_izq_b
    mov di, OFFSET jugador_izq_b_temp
    call cargar_sprite_32x32        ; CAMBIO AQUÍ
    jnc caj_load_right_a
    jmp caj_error

caj_load_right_a:
    mov dx, OFFSET archivo_player_der_a
    mov di, OFFSET jugador_der_a_temp
    call cargar_sprite_32x32        ; CAMBIO AQUÍ
    jnc caj_load_right_b
    jmp caj_error

caj_load_right_b:
    mov dx, OFFSET archivo_player_der_b
    mov di, OFFSET jugador_der_b_temp
    call cargar_sprite_32x32        ; CAMBIO AQUÍ
    jnc caj_success
    jmp caj_error

caj_success:
    clc
    jmp caj_fin
    
caj_error:
    stc
    
caj_fin:
    pop di
    pop dx
    ret
cargar_animaciones_jugador ENDP

obtener_sprite_jugador PROC
    push ax
    push bx
    
    mov al, jugador_dir
    mov bl, jugador_frame
    
    cmp al, DIR_ABAJO
    jne osj_arr
    test bl, bl
    jz osj_down_a
    mov di, OFFSET jugador_down_b           ; ✅ DI = DATA
    mov si, OFFSET jugador_down_b_mask      ; ✅ SI = MASK
    jmp osj_fin
osj_down_a:
    mov di, OFFSET jugador_down_a           ; ✅ DI = DATA
    mov si, OFFSET jugador_down_a_mask      ; ✅ SI = MASK
    jmp osj_fin
    
osj_arr:
    cmp al, DIR_ARRIBA
    jne osj_izq
    test bl, bl
    jz osj_up_a
    mov di, OFFSET jugador_up_b
    mov si, OFFSET jugador_up_b_mask
    jmp osj_fin
osj_up_a:
    mov di, OFFSET jugador_up_a
    mov si, OFFSET jugador_up_a_mask
    jmp osj_fin
    
osj_izq:
    cmp al, DIR_IZQUIERDA
    jne osj_der
    test bl, bl
    jz osj_izq_a
    mov di, OFFSET jugador_izq_b
    mov si, OFFSET jugador_izq_b_mask
    jmp osj_fin
osj_izq_a:
    mov di, OFFSET jugador_izq_a
    mov si, OFFSET jugador_izq_a_mask
    jmp osj_fin
    
osj_der:
    test bl, bl
    jz osj_der_a
    mov di, OFFSET jugador_der_b
    mov si, OFFSET jugador_der_b_mask
    jmp osj_fin
osj_der_a:
    mov di, OFFSET jugador_der_a
    mov si, OFFSET jugador_der_a_mask
    
osj_fin:
    pop bx
    pop ax
    ret
obtener_sprite_jugador ENDP

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

dibujar_todo_en_offset PROC
    push ax
    
    mov temp_offset, ax
    call dibujar_mapa_en_offset
    call dibujar_jugador_en_offset
    
    pop ax
    ret
dibujar_todo_en_offset ENDP

; filepath: c:\ASM\project\proyec.asm

; REEMPLAZAR la sección problemática (línea ~1900-1930):

dibujar_mapa_en_offset PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    ; ✅ SOLO recorrer tiles sucios
    xor bp, bp              ; BP = índice en dirty_list

dmo_loop:
    mov ax, dirty_count
    cmp bp, ax
    jb dmo_tiene_tile
    jmp dmo_fin

dmo_tiene_tile:
    ; Obtener índice del tile sucio
    mov bx, bp
    shl bx, 1
    mov ax, [dirty_list + bx]

    ; Calcular tile_x, tile_y desde índice
    xor dx, dx
    mov cx, 100
    div cx              ; AX = Y, DX = X

    mov bx, dx          ; BX = tile_x
    mov dx, ax          ; DX = tile_y

    ; Verificar si está en viewport
    mov ax, dx
    cmp ax, inicio_tile_y
    jae dmo_check_y_max
    jmp dmo_next

dmo_check_y_max:
    mov cx, inicio_tile_y
    add cx, 14
    cmp ax, cx
    jb dmo_check_x_min
    jmp dmo_next

dmo_check_x_min:
    mov ax, bx
    cmp ax, inicio_tile_x
    jae dmo_check_x_max
    jmp dmo_next

dmo_check_x_max:
    mov cx, inicio_tile_x
    add cx, 22
    cmp ax, cx
    jb dmo_dibujar
    jmp dmo_next

dmo_dibujar:
    ; Calcular índice en mapa
    push bx
    mov bx, dx
    shl bx, 1
    mov ax, [mul100_table + bx]
    pop bx
    push bx
    add ax, bx
    mov bx, ax
    mov al, [mapa_datos + bx]
    pop bx
    
    ; Obtener sprite
    call obtener_sprite_tile
    
    ; Calcular posición en pantalla
    sub bx, inicio_tile_x
    sub dx, inicio_tile_y
    shl bx, 4
    shl dx, 4
    add bx, viewport_x
    add dx, viewport_y
    sub bx, scroll_offset_x
    sub dx, scroll_offset_y
    
    mov cx, bx
    
    ; Dibujar
    push di
    push si
    call dibujar_sprite_planar_16x16_opt
    pop si
    pop di
    
dmo_next:
    inc bp
    jmp dmo_loop
    
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

obtener_sprite_tile PROC
    ; Entrada: AL = tipo de tile
    ; Salida: DI = datos, SI = máscara
    
    cmp al, TILE_PATH
    jne ost_2
    mov di, OFFSET sprite_path
    mov si, OFFSET sprite_path_mask
    ret
    
ost_2:
    cmp al, TILE_WATER
    jne ost_3
    mov di, OFFSET sprite_water
    mov si, OFFSET sprite_water_mask
    ret
    
ost_3:
    cmp al, TILE_TREE
    jne ost_4
    mov di, OFFSET sprite_tree
    mov si, OFFSET sprite_tree_mask
    ret
    
ost_4:
    cmp al, TILE_SAND
    jne ost_5
    mov di, OFFSET sprite_sand
    mov si, OFFSET sprite_sand_mask
    ret
    
ost_5:
    cmp al, TILE_TREE
    jne ost_6
    mov di, OFFSET sprite_rock
    mov si, OFFSET sprite_rock_mask
    ret
    
ost_6:
    cmp al, TILE_SNOW
    jne ost_7
    mov di, OFFSET sprite_snow
    mov si, OFFSET sprite_snow_mask
    ret
    
ost_7:
    cmp al, TILE_ICE
    jne ost_8
    mov di, OFFSET sprite_ice
    mov si, OFFSET sprite_ice_mask
    ret
    
ost_8:
    cmp al, TILE_WALL
    jne ost_9
    mov di, OFFSET sprite_wall
    mov si, OFFSET sprite_wall_mask
    ret
    
ost_9:
    cmp al, TILE_DIRT
    jne ost_10
    mov di, OFFSET sprite_dirt
    mov si, OFFSET sprite_dirt_mask
    ret
    
ost_10:
    cmp al, TILE_LAVA
    jne ost_11
    mov di, OFFSET sprite_lava
    mov si, OFFSET sprite_lava_mask
    ret
    
ost_11:
    cmp al, TILE_BRIDGE
    jne ost_default
    mov di, OFFSET sprite_bridge
    mov si, OFFSET sprite_bridge_mask
    ret
    
ost_default:
    mov di, OFFSET sprite_grass1
    mov si, OFFSET sprite_grass1_mask
    ret
obtener_sprite_tile ENDP

dibujar_jugador_en_offset PROC
    push ax
    push cx
    push dx
    push si
    push di
    
    ; Calcular posición relativa al viewport
    mov ax, jugador_px
    sub ax, camara_px
    add ax, viewport_x
    sub ax, 16               ; Centrar sprite (32/2)
    mov cx, ax
    
    mov ax, jugador_py
    sub ax, camara_py
    add ax, viewport_y
    sub ax, 16
    mov dx, ax
    
    call obtener_sprite_jugador    

    call dibujar_sprite_planar_32x32_opt
    
    pop di
    pop si
    pop dx
    pop cx
    pop ax
    ret
dibujar_jugador_en_offset ENDP

esperar_retrace PROC
    push ax
    push dx
    
    mov dx, 3DAh
    
    ; ✅ Esperar final de retrace anterior (evita empezar a mitad)
er_wait_display:
    in al, dx
    test al, 8
    jnz er_wait_display
    
    ; ✅ Esperar inicio del próximo retrace
er_wait_vblank:
    in al, dx
    test al, 8
    jz er_wait_vblank
    
    ; ✅ CRÍTICO: Esperar 3 scanlines para estabilidad
    mov cx, 3
er_wait_scanlines:
    in al, dx
    test al, 1          ; Horizontal retrace
    jnz er_wait_scanlines
er_wait_next:
    in al, dx
    test al, 1
    jz er_wait_next
    loop er_wait_scanlines
    
    pop dx
    pop ax
    ret
esperar_retrace ENDP

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
    cmp bp, 10000       ; ✅ CAMBIO: 100×100 = 10,000 (antes 2500)
    jb cm_proc
    
cm_cerrar:
    mov ah, 3Eh
    int 21h
    clc
    jmp cm_fin
    
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
    jmp cs16_guardar

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

cargar_sprite_32x32 PROC
    push ax
    push bx
    push cx
    push si
    push bp
    
    mov ax, 3D00h
    int 21h
    jc cs32_error
    
    mov bx, ax
    call saltar_linea
    
    xor bp, bp
    
cs32_leer:
    mov ah, 3Fh
    mov cx, 200
    push dx
    mov dx, OFFSET buffer_temp
    int 21h
    pop dx
    
    cmp ax, 0
    je cs32_cerrar
    
    mov cx, ax
    xor si, si

cs32_proc:
    cmp si, cx
    jae cs32_leer

    mov al, [buffer_temp + si]
    inc si
    
    cmp al, ' '
    je cs32_proc
    cmp al, 13
    je cs32_proc
    cmp al, 10
    je cs32_proc
    cmp al, 9
    je cs32_proc
    
    cmp al, '0'
    jb cs32_proc
    cmp al, '9'
    jbe cs32_dec
    
    and al, 0DFh
    cmp al, 'A'
    jb cs32_proc
    cmp al, 'F'
    ja cs32_proc
    sub al, 'A' - 10
    jmp cs32_guardar

cs32_dec:
    sub al, '0'

cs32_guardar:
    mov [di], al
    inc di
    inc bp
    cmp bp, 1024        ; 32x32 = 1024
    jb cs32_proc
    
cs32_cerrar:
    mov ah, 3Eh
    int 21h
    clc
    jmp cs32_fin
    
cs32_error:
    stc
    
cs32_fin:
    pop bp
    pop si
    pop cx
    pop bx
    pop ax
    ret
cargar_sprite_32x32 ENDP

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

debug_mostrar_tile PROC
    push ax
    push bx
    push cx
    push dx
    
    ; Obtener tile en posición (15, 19)
    mov bx, 19
    shl bx, 1
    mov ax, [mul100_table + bx]
    add ax, 15
    mov bx, ax
    
    mov al, [mapa_datos + bx]
    
    ; Convertir a ASCII y mostrar
    add al, '0'
    mov [msg_error], al     ; Reutilizar buffer
    mov dx, OFFSET msg_error
    mov ah, 9
    int 21h
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
debug_mostrar_tile ENDP

debug_verificar_mapa PROC
    push ax
    push bx
    
    ; Verificar tile en (25, 25) - debería ser no-cero
    mov bx, 25
    shl bx, 1
    mov ax, [mul100_table + bx]
    add ax, 25
    mov bx, ax
    
    mov al, [mapa_datos + bx]
    
    ; Si es 0, hay un problema
    test al, al
    jnz dvm_ok
    
    ; Mostrar error
    mov ax, 3
    int 10h
    mov dx, OFFSET msg_error
    mov ah, 9
    int 21h
    mov ah, 0
    int 16h
    
dvm_ok:
    pop bx
    pop ax
    ret
debug_verificar_mapa ENDP


debug_verificar_todo PROC
    push ax
    push bx
    
    ; Verificar que mul100_table esté inicializada
    mov bx, 2               ; mul100_table[1]
    mov ax, [mul100_table + bx]
    cmp ax, 100
    je dvt_tabla_ok
    
    ; ERROR: Tabla no inicializada
    mov ax, 3
    int 10h
    mov dx, OFFSET msg_error
    mov ah, 9
    int 21h
    mov ah, 0
    int 16h
    jmp fin_juego
    
dvt_tabla_ok:
    ; Verificar que el mapa tenga datos
    mov al, [mapa_datos + 0]
    test al, al
    jnz dvt_mapa_ok
    
    ; ERROR: Mapa vacío
    mov ax, 3
    int 10h
    mov dx, OFFSET msg_error
    mov ah, 9
    int 21h
    mov ah, 0
    int 16h
    jmp fin_juego
    
dvt_mapa_ok:
    pop bx
    pop ax
    ret
debug_verificar_todo ENDP
INCLUDE OPTCODE.INC

END inicio
