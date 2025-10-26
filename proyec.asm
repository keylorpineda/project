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
archivo_dirt   db 'SPRITES\DIRT_1.TXT',0
archivo_lava   db 'SPRITES\LAVA_1.TXT',0
archivo_bridge db 'SPRITES\BRIDGE_1.TXT',0
archivo_rock   db 'SPRITES\ROCK_1.TXT',0

archivo_player_up_a    db 'SPRITES\PLAYER\UP1.TXT',0
archivo_player_up_b    db 'SPRITES\PLAYER\UP2.TXT',0
archivo_player_down_a  db 'SPRITES\PLAYER\DOWN1.TXT',0
archivo_player_down_b  db 'SPRITES\PLAYER\DOWN2.TXT',0
archivo_player_izq_a   db 'SPRITES\PLAYER\LEFT1.TXT',0
archivo_player_izq_b   db 'SPRITES\PLAYER\LEFT2.TXT',0
archivo_player_der_a   db 'SPRITES\PLAYER\RIGHT1.TXT',0
archivo_player_der_b   db 'SPRITES\PLAYER\RIGHT2.TXT',0

mapa_datos  db 10000 dup(0)

sprite_buffer_16   db 256 dup(0)
sprite_buffer_32   db 1024 dup(0)

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

pagina_visible db 0
pagina_dibujo  db 1

viewport_x  dw 160
viewport_y  dw 79

temp_offset     dw 0
inicio_tile_x   dw 0
inicio_tile_y   dw 0
temp_fila dw 0
temp_col  dw 0

scroll_offset_x dw 0
scroll_offset_y dw 0
; ============================================
; SISTEMA DE INVENTARIO Y RECURSOS
; ============================================

; Estado del inventario
inventario_abierto db 0          ; 0 = cerrado, 1 = abierto
inventario_toggle_bloqueado db 0 ; Evita rebotes al abrir/cerrar
requiere_redibujar db 0          ; Fuerza un render cuando cambia el estado
tecla_e_presionada db 0
; Estructura de items (3 tipos de recursos × 5 instancias cada uno)
; Tipo 1: Cristales (azul)
; Tipo 2: Gemas (rojo)
; Tipo 3: Monedas (amarillo)

MAX_ITEMS EQU 8
MAX_TIPOS_RECURSO EQU 3
META_POR_TIPO EQU 2              ; Necesitamos 2 de cada tipo para ganar

; Contador de recursos recolectados por tipo
recursos_tipo1 db 0              ; Cristales recolectados
recursos_tipo2 db 0              ; Gemas recolectadas
recursos_tipo3 db 0              ; Monedas recolectadas

; Mapa de bits de recursos ya recolectados (15 bits, uno por cada instancia)
; Bit set = recurso ya recogido
recursos_recogidos dw 0

NUM_RECURSOS EQU 15

recursos_mapa       db NUM_RECURSOS * 3 dup(0)   ; [x, y, tipo]
recursos_cantidad   db NUM_RECURSOS dup(0)       ; Cantidad por recurso
num_recursos_cargados db 0                      ; Total cargado desde mapa
inventario_slots       db MAX_ITEMS dup(0)
inventario_cantidades  db MAX_ITEMS dup(0)

player_left_temp   dw 0
player_right_temp  dw 0
player_top_temp    dw 0
player_bottom_temp dw 0

; Variables auxiliares para carga de recursos desde el mapa
carga_recursos_estado      db 0
carga_recursos_guardar     db 0
carga_recursos_comentario  db 0
carga_recursos_char_pend   db 0
carga_recursos_tiene_pend  db 0
carga_recursos_handle      dw 0
carga_recursos_temp        dw 0
carga_recursos_offset      dw 0

sprite_cristal      db 128 dup(0)
sprite_gema         db 128 dup(0)
sprite_moneda       db 128 dup(0)

archivo_cristal db 'SPRITES\CRYSTAL.TXT',0
archivo_gema    db 'SPRITES\GEM.TXT',0
archivo_moneda  db 'SPRITES\COIN.TXT',0
archivo_btn_jugar_n   db 'SPRITES\MENU\BTN_JUGAR_N.TXT',0
archivo_btn_jugar_s   db 'SPRITES\MENU\BTN_JUGAR_S.TXT',0
archivo_btn_opciones_n db 'SPRITES\MENU\BTN_OPCIONES_N.TXT',0
archivo_btn_opciones_s db 'SPRITES\MENU\BTN_OPCIONES_S.TXT',0
archivo_btn_salir_n    db 'SPRITES\MENU\BTN_SALIR_N.TXT',0
archivo_btn_salir_s    db 'SPRITES\MENU\BTN_SALIR_S.TXT',0
archivo_fondo_menu     db 'SPRITES\MENU\FONDO_MENU.TXT',0

COLOR_FONDO      EQU 0    ; Negro
COLOR_MARCO      EQU 7    ; Blanco
COLOR_TEXTO      EQU 14   ; Amarillo
COLOR_BARRA_VACIA EQU 8   ; Gris oscuro
COLOR_BARRA_LLENA EQU 10  ; Verde claro
COLOR_ITEM_SLOT  EQU 1    ; Azul oscuro

msg_inventario  db 'INVENTARIO',0
msg_recursos    db 'RECURSOS',0
msg_cristales   db 'CRISTALES:',0
msg_gemas       db 'GEMAS:',0
msg_monedas     db 'MONEDAS:',0
msg_objetivo    db 'OBJETIVO: 2/TIPO',0
msg_progreso    db 'PROGRESO:',0
msg_completado  db 'COMPLETADO!',0
msg_slash       db '/',0



INV_X           EQU 80           ; ✅ CAMBIO: Más a la izquierda (era 160)
INV_Y           EQU 40           ; ✅ CAMBIO: Más arriba (era 50)
INV_WIDTH       EQU 480          ; ✅ CAMBIO: Más ancho (era 320)
INV_HEIGHT      EQU 270          ; ✅ CAMBIO: Más alto (era 250)

; Zonas del panel
ZONA_PLAYER_X   EQU 100          ; ✅ CAMBIO: Jugador a la izquierda (era 170)
ZONA_PLAYER_Y   EQU 80           ; ✅ CAMBIO: (era 80, mantener)
ZONA_PLAYER_W   EQU 64

ZONA_ITEMS_X    EQU 180          ; ✅ CAMBIO: Items al centro (era 250)
ZONA_ITEMS_Y    EQU 70           ; ✅ CAMBIO: Más arriba (era 80)
ITEM_SIZE       EQU 40           ; ✅ CAMBIO: Era 32
ITEM_SPACING    EQU 8            ; ✅ CAMBIO: Era 4
ITEM_TOTAL      EQU 48           ; ✅ CAMBIO: 40+8 (Era 36)
ITEM_ICON_OFFSET EQU 12          ; ✅ CAMBIO: (40-16)/2 (Era 8)
ITEM_COUNT_OFFSET_X EQU 28       ; ✅ CAMBIO: (Era 20)
ITEM_COUNT_OFFSET_Y EQU 28

ZONA_STATS_X    EQU 420          ; ✅ CAMBIO: Estadísticas a la derecha (era 352)
ZONA_STATS_Y    EQU 70           ; ✅ CAMBIO: Más arriba (era 80)
ZONA_STATS_W    EQU 120          ; ✅ CAMBIO: Más ancho (era 80)

STAT_VAL_OFFSET     EQU 88       ; ✅ CAMBIO: Más espacio para el texto (era 64)
STAT_SLASH_OFFSET   EQU 104      ; ✅ CAMBIO: (era 80)
STAT_META_OFFSET    EQU 112      ; ✅ CAMBIO: (era 88)
; Animación de recolección
anim_recoger_activa db 0
anim_recoger_frame  db 0
anim_recoger_x      dw 0
anim_recoger_y      dw 0

; ============================================
; MENÚ PRINCIPAL
; ============================================
MENU_BTN_WIDTH   EQU 32
MENU_BTN_HEIGHT  EQU 16
MENU_BTN_PIXELS  EQU MENU_BTN_WIDTH * MENU_BTN_HEIGHT

currentSelection    db 0
menuResult          db 0FFh
mousePresent        db 0
mouseX              dw 320
mouseY              dw 175
mouseBtn            db 0
lastMouseBtn        db 0
mouseOverButton     db 0FFh

btnPlayX1           dw 304
btnPlayY1           dw 150
btnPlayX2           dw 304 + MENU_BTN_WIDTH - 1
btnPlayY2           dw 150 + MENU_BTN_HEIGHT - 1

btnOptionsX1        dw 304
btnOptionsY1        dw 190
btnOptionsX2        dw 304 + MENU_BTN_WIDTH - 1
btnOptionsY2        dw 190 + MENU_BTN_HEIGHT - 1

btnExitX1           dw 304
btnExitY1           dw 230
btnExitX2           dw 304 + MENU_BTN_WIDTH - 1
btnExitY2           dw 230 + MENU_BTN_HEIGHT - 1

menu_btn_jugar_n_width   dw 0
menu_btn_jugar_n_height  dw 0
menu_btn_jugar_n_data    db MENU_BTN_PIXELS dup(0)
menu_btn_jugar_s_width   dw 0
menu_btn_jugar_s_height  dw 0
menu_btn_jugar_s_data    db MENU_BTN_PIXELS dup(0)
menu_btn_opciones_n_width dw 0
menu_btn_opciones_n_height dw 0
menu_btn_opciones_n_data  db MENU_BTN_PIXELS dup(0)
menu_btn_opciones_s_width dw 0
menu_btn_opciones_s_height dw 0
menu_btn_opciones_s_data  db MENU_BTN_PIXELS dup(0)
menu_btn_salir_n_width    dw 0
menu_btn_salir_n_height   dw 0
menu_btn_salir_n_data     db MENU_BTN_PIXELS dup(0)
menu_btn_salir_s_width    dw 0
menu_btn_salir_s_height   dw 0
menu_btn_salir_s_data     db MENU_BTN_PIXELS dup(0)

menu_loader_dest          dw 0
menu_loader_max_size      dw 0
menu_loader_expected      dw 0
menu_loader_width         dw 0
menu_loader_height        dw 0
menu_loader_pixels_read   dw 0
menu_loader_file_handle   dw 0
menu_loader_stage         db 0
menu_loader_path          dw 0

menu_tmp_width            dw 0
menu_tmp_width_counter    dw 0
menu_tmp_height_counter   dw 0

menu_title         db 'JUEGO EGA - MENU PRINCIPAL',0
menu_subtitle      db 'USA W/S O EL MOUSE PARA NAVEGAR',0
menu_subtitle2     db 'ENTER O CLICK IZQUIERDO PARA SELECCIONAR',0
menu_options_title db 'OPCIONES',0
menu_options_line1 db 'SONIDO: ALTAVOCES PC ACTIVOS',0
menu_options_line2 db 'CONTROLES: WASD O FLECHAS',0
menu_options_line3 db 'CLICK O ENTER PARA VOLVER',0

texto_color_actual  db 0
font_base_x_temp    dw 0
font_base_y_temp    dw 0
font_row_mask       db 0
numero_buffer       db 6 dup(0)

font_8x8 LABEL BYTE
    ; '0'
    db 00111100b,01000010b,01000110b,01001010b,01010010b,01100010b,01000010b,00111100b
    ; '1'
    db 00011000b,00101000b,01001000b,00001000b,00001000b,00001000b,00001000b,01111110b
    ; '2'
    db 00111100b,01000010b,00000010b,00000100b,00001000b,00010000b,00100000b,01111110b
    ; '3'
    db 00111100b,01000010b,00000010b,00011100b,00000010b,00000010b,01000010b,00111100b
    ; '4'
    db 00000100b,00001100b,00010100b,00100100b,01000100b,01111110b,00000100b,00000100b
    ; '5'
    db 01111110b,01000000b,01000000b,01111100b,00000010b,00000010b,01000010b,00111100b
    ; '6'
    db 00111100b,01000010b,01000000b,01111100b,01000010b,01000010b,01000010b,00111100b
    ; '7'
    db 01111110b,00000010b,00000100b,00001000b,00010000b,00100000b,00100000b,00100000b
    ; '8'
    db 00111100b,01000010b,01000010b,00111100b,01000010b,01000010b,01000010b,00111100b
    ; '9'
    db 00111100b,01000010b,01000010b,01000010b,00111110b,00000010b,01000010b,00111100b
    ; 'A'
    db 00011000b,00100100b,01000010b,01000010b,01111110b,01000010b,01000010b,00000000b
    ; 'B'
    db 01111100b,01000010b,01000010b,01111100b,01000010b,01000010b,01111100b,00000000b
    ; 'C'
    db 00111100b,01000010b,01000000b,01000000b,01000000b,01000010b,00111100b,00000000b
    ; 'D'
    db 01111000b,01000100b,01000010b,01000010b,01000010b,01000100b,01111000b,00000000b
    ; 'E'
    db 01111110b,01000000b,01000000b,01111100b,01000000b,01000000b,01111110b,00000000b
    ; 'F'
    db 01111110b,01000000b,01000000b,01111100b,01000000b,01000000b,01000000b,00000000b
    ; 'G'
    db 00111100b,01000010b,01000000b,01011110b,01000010b,01000010b,00111100b,00000000b
    ; 'H'
    db 01000010b,01000010b,01000010b,01111110b,01000010b,01000010b,01000010b,00000000b
    ; 'I'
    db 00111100b,00011000b,00011000b,00011000b,00011000b,00011000b,00111100b,00000000b
    ; 'J'
    db 00011110b,00000100b,00000100b,00000100b,00000100b,01000100b,00111000b,00000000b
    ; 'K'
    db 01000010b,01000100b,01001000b,01110000b,01001000b,01000100b,01000010b,00000000b
    ; 'L'
    db 01000000b,01000000b,01000000b,01000000b,01000000b,01000000b,01111110b,00000000b
    ; 'M'
    db 01000010b,01100110b,01011010b,01000010b,01000010b,01000010b,01000010b,00000000b
    ; 'N'
    db 01000010b,01100010b,01010010b,01001010b,01000110b,01000010b,01000010b,00000000b
    ; 'O'
    db 00111100b,01000010b,01000010b,01000010b,01000010b,01000010b,00111100b,00000000b
    ; 'P'
    db 01111100b,01000010b,01000010b,01111100b,01000000b,01000000b,01000000b,00000000b
    ; 'Q'
    db 00111100b,01000010b,01000010b,01000010b,01001010b,01000110b,00111110b,00000000b
    ; 'R'
    db 01111100b,01000010b,01000010b,01111100b,01001000b,01000100b,01000010b,00000000b
    ; 'S'
    db 00111110b,01000000b,01000000b,00111100b,00000010b,00000010b,01111100b,00000000b
    ; 'T'
    db 01111110b,00011000b,00011000b,00011000b,00011000b,00011000b,00011000b,00000000b
    ; 'U'
    db 01000010b,01000010b,01000010b,01000010b,01000010b,01000010b,00111100b,00000000b
    ; 'V'
    db 01000010b,01000010b,01000010b,01000010b,00100100b,00100100b,00011000b,00000000b
    ; 'W'
    db 01000010b,01000010b,01000010b,01000010b,01011010b,01100110b,01000010b,00000000b
    ; 'X'
    db 01000010b,00100100b,00011000b,00011000b,00011000b,00100100b,01000010b,00000000b
    ; 'Y'
    db 01000010b,00100100b,00011000b,00011000b,00011000b,00011000b,00011000b,00000000b
    ; 'Z'
    db 01111110b,00000010b,00000100b,00001000b,00010000b,00100000b,01111110b,00000000b
    ; ':'
    db 00000000b,00011000b,00011000b,00000000b,00000000b,00011000b,00011000b,00000000b
    ; '/'
    db 00000010b,00000100b,00001000b,00010000b,00100000b,01000000b,10000000b,00000000b
    ; '!'
    db 00011000b,00011000b,00011000b,00011000b,00011000b,00000000b,00011000b,00000000b

INCLUDE OPTDATA.INC

msg_titulo  db 'JUEGO EGA - Universidad Nacional',13,10,'$'
msg_cargando db 'Cargando archivos...',13,10,'$'
msg_mapa    db 'Mapa: $'
msg_sprites db 'Sprites terreno: $'
msg_anim    db 'Sprites jugador: $'
msg_convert db 'Generando mascaras...$'
msg_tablas  db 'Lookup tables: $'
msg_menu    db 'Sprites menu: $'
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
    call cargar_recursos_desde_mapa
    jnc crm_ok
    jmp error_carga
crm_ok:
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
    
    ; ===== FASE 5: PRE-CALCULAR MÁSCARAS (CRÍTICO) =====
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

    mov dx, OFFSET msg_menu
    mov ah, 9
    int 21h
    call cargar_sprites_menu
    jnc csmenu_ok
    jmp error_carga
csmenu_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h

    call mostrar_menu_principal
    cmp al, 2
    je fin_juego

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

; **CRÍTICO**: Renderizar PÁGINA 0 primero
    mov temp_offset, 0
    call dibujar_mapa_en_offset
    call dibujar_jugador_en_offset

; **CRÍTICO**: Renderizar PÁGINA 1
    mov temp_offset, 8000h
    call dibujar_mapa_en_offset
    call dibujar_jugador_en_offset

; Guardar estado inicial
    mov ax, jugador_px
    mov jugador_px_old, ax
    mov ax, jugador_py
    mov jugador_py_old, ax
    mov al, jugador_frame
    mov frame_old, al

; **CRÍTICO**: Mostrar página 0 y configurar variables
mov ah, 5
mov al, 0
int 10h

mov pagina_visible, 0
mov pagina_dibujo, 1

; ===== BUCLE PRINCIPAL =====
bucle_juego:
    call verificar_colision_recursos
    
    ; Actualizar animación de recolección
    call actualizar_animacion_recoger
    
    call procesar_movimiento_continuo
    call actualizar_animacion
    call centrar_camara_suave
    
    ; Verificar victoria
    call verificar_victoria
    jnc bg_continuar
    
    ; ¡VICTORIA! Mostrar pantalla de victoria y salir
    call pantalla_victoria
    jmp fin_juego  
    
    bg_continuar:
    ; Verificar si algo cambió
    mov ax, jugador_px
    cmp ax, jugador_px_old
    jne bg_hay_cambio
    
    mov ax, jugador_py
    cmp ax, jugador_py_old
    jne bg_hay_cambio
    
    mov al, jugador_frame
    cmp al, frame_old
    jne bg_hay_cambio

    cmp requiere_redibujar, 0
    jne bg_hay_cambio

    ; Si no hay cambios, solo esperar
    call esperar_retrace
    jmp bucle_juego

bg_hay_cambio:
    ; Actualizar estado
    mov ax, jugador_px
    mov jugador_px_old, ax
    
    mov ax, jugador_py
    mov jugador_py_old, ax

    mov al, jugador_frame
    mov frame_old, al

    mov al, requiere_redibujar
    cmp al, 0
    je bg_redraw_reset
    dec al
    mov requiere_redibujar, al
    jmp bg_redraw_done

bg_redraw_reset:
    mov requiere_redibujar, 0

bg_redraw_done:

    ; Esperar vertical retrace
    call esperar_retrace
    
    ; Renderizar en la página que NO está visible
    mov al, pagina_dibujo
    test al, 1
    jz bg_render_p0
    
    ; Renderizar en página 1
    mov temp_offset, 8000h
    call limpiar_pagina_actual
    call dibujar_mapa_en_offset
    call dibujar_jugador_en_offset
    call dibujar_inventario
    jmp bg_cambiar_pagina
    
bg_render_p0:
    ; Renderizar en página 0
    mov temp_offset, 0
    call limpiar_pagina_actual
    call dibujar_mapa_en_offset
    call dibujar_jugador_en_offset
    call dibujar_inventario
    
bg_cambiar_pagina:
    ; Cambiar página visible
    mov ah, 5
    mov al, pagina_dibujo
    int 10h
    
    ; Intercambiar páginas
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
    
    mov tecla_e_presionada, 0
    mov moviendo, 0
    jmp pmc_fin

pmc_tiene_tecla:
    mov ah, 0
    int 16h
    
    cmp ah, 01h
    jne pmc_check_ascii
    jmp pmc_salir

pmc_check_ascii:
    cmp al, 27
    jne pmc_continuar
    jmp pmc_salir

pmc_continuar:
    
    mov bl, al
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
    cmp al, 'E'
    jne pmc_verificar_movimiento
    
    cmp tecla_e_presionada, 1
    jne pmc_toggle_e
    jmp pmc_fin

pmc_toggle_e:
    
    mov tecla_e_presionada, 1
    xor inventario_abierto, 1
    mov moviendo, 0
    
    ; =============================================================
    ; ESTA ES LA CORRECCIÓN:
    ; Forzar redibujado en AMBAS páginas para limpiar el "fantasma"
    ; =============================================================
    mov requiere_redibujar, 2
    
    jmp pmc_fin

pmc_verificar_movimiento:
    cmp inventario_abierto, 1
    jne pmc_verificar_teclas
    jmp pmc_no_movimiento

pmc_verificar_teclas:
    
    cmp al, 48h
    jne pmc_check_w
    jmp pmc_ir_arriba

pmc_check_w:
    cmp al, 'W'
    jne pmc_check_down
    jmp pmc_ir_arriba

pmc_check_down:
    cmp al, 50h
    jne pmc_check_s
    jmp pmc_ir_abajo

pmc_check_s:
    cmp al, 'S'
    jne pmc_check_left
    jmp pmc_ir_abajo

pmc_check_left:
    cmp al, 4Bh
    jne pmc_check_a
    jmp pmc_ir_izquierda

pmc_check_a:
    cmp al, 'A'
    jne pmc_check_right
    jmp pmc_ir_izquierda

pmc_check_right:
    cmp al, 4Dh
    jne pmc_check_d
    jmp pmc_ir_derecha

pmc_check_d:
    cmp al, 'D'
    jne pmc_default
    jmp pmc_ir_derecha

pmc_default:
    jmp pmc_no_movimiento

pmc_salir:
    pop dx
    pop cx
    pop bx
    pop ax
    mov ax, 3
    int 10h
    mov ax, 4C00h
    int 21h

pmc_arriba:
    mov jugador_dir, DIR_ARRIBA
    mov ax, jugador_py
    sub ax, VELOCIDAD
    cmp ax, 16
    jae pmc_arriba_continuar
    jmp pmc_no_movimiento

pmc_arriba_continuar:
    mov cx, jugador_px
    shr cx, 4
    mov dx, ax
    sub dx, 8
    shr dx, 4
    call verificar_tile_transitable
    jnc pmc_arriba_bloqueado
    mov jugador_py, ax
    mov moviendo, 1
    jmp pmc_fin

pmc_arriba_bloqueado:
    jmp pmc_no_movimiento

pmc_abajo:
    mov jugador_dir, DIR_ABAJO
    mov ax, jugador_py
    add ax, VELOCIDAD
    cmp ax, 1584
    jbe pmc_abajo_continuar
    jmp pmc_no_movimiento

pmc_abajo_continuar:
    mov cx, jugador_px
    shr cx, 4
    mov dx, ax
    shr dx, 4
    call verificar_tile_transitable
    jnc pmc_abajo_bloqueado
    mov jugador_py, ax
    mov moviendo, 1
    jmp pmc_fin

pmc_abajo_bloqueado:
    jmp pmc_no_movimiento

pmc_izquierda:
    mov jugador_dir, DIR_IZQUIERDA
    mov ax, jugador_px
    sub ax, VELOCIDAD
    cmp ax, 16
    jae pmc_izquierda_continuar
    jmp pmc_no_movimiento

pmc_izquierda_continuar:
    mov cx, ax
    sub cx, 8
    shr cx, 4
    mov dx, jugador_py
    shr dx, 4
    call verificar_tile_transitable
    jnc pmc_izquierda_bloqueado
    mov jugador_px, ax
    mov moviendo, 1
    jmp pmc_fin

pmc_izquierda_bloqueado:
    jmp pmc_no_movimiento

pmc_derecha:
    mov jugador_dir, DIR_DERECHA
    mov ax, jugador_px
    add ax, VELOCIDAD
    cmp ax, 1584
    jbe pmc_derecha_continuar
    jmp pmc_no_movimiento

pmc_derecha_continuar:
    mov cx, ax
    add cx, 8
    shr cx, 4
    mov dx, jugador_py
    shr dx, 4
    call verificar_tile_transitable
    jnc pmc_derecha_bloqueado
    mov jugador_px, ax
    mov moviendo, 1
    jmp pmc_fin

pmc_derecha_bloqueado:
    jmp pmc_no_movimiento

pmc_ir_arriba:
    jmp pmc_arriba

pmc_ir_abajo:
    jmp pmc_abajo

pmc_ir_izquierda:
    jmp pmc_izquierda

pmc_ir_derecha:
    jmp pmc_derecha

pmc_no_movimiento:
    mov moviendo, 0

pmc_fin:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
procesar_movimiento_continuo ENDP

; ============================================
; PROCEDIMIENTO NUEVO PARA LIMPIAR PANTALLA
; ============================================
limpiar_pagina_actual PROC
    push ax
    push cx
    push dx
    push di
    push es

    ; Habilitar TODOS los planos de video
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al

    mov ax, VIDEO_SEG
    mov es, ax
    
    ; DI = 0 (Página 0) o 8000h (Página 1)
    mov di, temp_offset 
    
    ; 14000 palabras = 28000 bytes (toda la pagina)
    mov cx, 14000       
    
    ; Color 0 (negro)
    xor ax, ax          
    
    ; Llena la memoria de video
    rep stosw           

    pop es
    pop di
    pop dx
    pop cx
    pop ax
    ret
limpiar_pagina_actual ENDP

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
    call reproducir_sonido_paso

aa_fin:
    pop ax
    ret
actualizar_animacion ENDP

reproducir_sonido_paso PROC
    push ax
    push bx
    push cx
    push dx

    mov al, 0B6h
    out 43h, al

    mov ax, 0F89h           ; ≈300 Hz, tono grave similar a pasos
    out 42h, al             ; Enviar byte bajo
    mov al, ah
    out 42h, al             ; Enviar byte alto

    in al, 61h
    mov bl, al
    or al, 3
    out 61h, al

    mov cx, 600             ; Pulso corto
 rsp_delay:
    loop rsp_delay

    mov al, bl
    out 61h, al

    mov cx, 150             ; Breve silencio para simular paso
 rsp_silencio:
    loop rsp_silencio

    pop dx
    pop cx
    pop bx
    pop ax
    ret
reproducir_sonido_paso ENDP

reproducir_sonido_recoleccion PROC
    push ax
    push bx
    push cx
    push dx

    mov al, 0B6h
    out 43h, al

    ; Primer tono agudo
    mov ax, 089Bh             ; ≈ 542 Hz
    out 42h, al
    mov al, ah
    out 42h, al

    in al, 61h
    mov bl, al
    or al, 3
    out 61h, al

    mov cx, 450
rsc_delay1:
    loop rsc_delay1

    ; Segundo tono más agudo
    mov ax, 06D6h             ; ≈ 682 Hz
    out 42h, al
    mov al, ah
    out 42h, al

    mov cx, 350
rsc_delay2:
    loop rsc_delay2

    mov al, bl
    out 61h, al

    mov cx, 200
rsc_silencio:
    loop rsc_silencio

    pop dx
    pop cx
    pop bx
    pop ax
    ret
reproducir_sonido_recoleccion ENDP

centrar_camara PROC
    push ax
    push bx
    
    ; Alinear cámara a múltiplos de 16
    mov ax, jugador_px
    sub ax, 160
    jge cc_x_pos
    xor ax, ax
cc_x_pos:
    cmp ax, 1280        ; ✅ CAMBIO: 100×16-320 = 1280 (antes 480)
    jle cc_x_ok
    mov ax, 1280
cc_x_ok:
    mov camara_px, ax
    
    mov ax, jugador_py
    sub ax, 96
    jge cc_y_pos
    xor ax, ax
cc_y_pos:
    cmp ax, 1408        ; ✅ CAMBIO: 100×16-192 = 1408 (antes 608)
    jle cc_y_ok
    mov ax, 1408
cc_y_ok:
    mov camara_py, ax
    
    pop bx
    pop ax
    ret
centrar_camara ENDP

verificar_tile_transitable PROC
    call verificar_tile_transitable_opt
    ret
verificar_tile_transitable ENDP


cargar_sprites_terreno PROC
    push dx
    push di
    push si
    push bp

    mov dx, OFFSET archivo_grass1
    mov di, OFFSET sprite_buffer_16
    call cargar_sprite_16x16
    jnc cst_ok_grass1
    jmp cst_error
cst_ok_grass1:
    mov si, OFFSET sprite_buffer_16
    mov di, OFFSET sprite_grass1
    mov bp, OFFSET sprite_grass1_mask
    call convertir_sprite_a_planar_opt

    mov dx, OFFSET archivo_path
    mov di, OFFSET sprite_buffer_16
    call cargar_sprite_16x16
    jnc cst_ok_path
    jmp cst_error
cst_ok_path:
    mov si, OFFSET sprite_buffer_16
    mov di, OFFSET sprite_path
    mov bp, OFFSET sprite_path_mask
    call convertir_sprite_a_planar_opt

    mov dx, OFFSET archivo_water
    mov di, OFFSET sprite_buffer_16
    call cargar_sprite_16x16
    jnc cst_ok_water
    jmp cst_error
cst_ok_water:
    mov si, OFFSET sprite_buffer_16
    mov di, OFFSET sprite_water
    mov bp, OFFSET sprite_water_mask
    call convertir_sprite_a_planar_opt

    mov dx, OFFSET archivo_tree
    mov di, OFFSET sprite_buffer_16
    call cargar_sprite_16x16
    jnc cst_ok_tree
    jmp cst_error
cst_ok_tree:
    mov si, OFFSET sprite_buffer_16
    mov di, OFFSET sprite_tree
    mov bp, OFFSET sprite_tree_mask
    call convertir_sprite_a_planar_opt

    mov dx, OFFSET archivo_sand
    mov di, OFFSET sprite_buffer_16
    call cargar_sprite_16x16
    jnc cst_ok_sand
    jmp cst_error
cst_ok_sand:
    mov si, OFFSET sprite_buffer_16
    mov di, OFFSET sprite_sand
    mov bp, OFFSET sprite_sand_mask
    call convertir_sprite_a_planar_opt

    mov dx, OFFSET archivo_rock
    mov di, OFFSET sprite_buffer_16
    call cargar_sprite_16x16
    jnc cst_ok_rock
    jmp cst_error
cst_ok_rock:
    mov si, OFFSET sprite_buffer_16
    mov di, OFFSET sprite_rock
    mov bp, OFFSET sprite_rock_mask
    call convertir_sprite_a_planar_opt

    mov dx, OFFSET archivo_snow
    mov di, OFFSET sprite_buffer_16
    call cargar_sprite_16x16
    jnc cst_ok_snow
    jmp cst_error
cst_ok_snow:
    mov si, OFFSET sprite_buffer_16
    mov di, OFFSET sprite_snow
    mov bp, OFFSET sprite_snow_mask
    call convertir_sprite_a_planar_opt

    mov dx, OFFSET archivo_ice
    mov di, OFFSET sprite_buffer_16
    call cargar_sprite_16x16
    jnc cst_ok_ice
    jmp cst_error
cst_ok_ice:
    mov si, OFFSET sprite_buffer_16
    mov di, OFFSET sprite_ice
    mov bp, OFFSET sprite_ice_mask
    call convertir_sprite_a_planar_opt

    mov dx, OFFSET archivo_wall
    mov di, OFFSET sprite_buffer_16
    call cargar_sprite_16x16
    jnc cst_ok_wall
    jmp cst_error
cst_ok_wall:
    mov si, OFFSET sprite_buffer_16
    mov di, OFFSET sprite_wall
    mov bp, OFFSET sprite_wall_mask
    call convertir_sprite_a_planar_opt

    mov dx, OFFSET archivo_dirt
    mov di, OFFSET sprite_buffer_16
    call cargar_sprite_16x16
    jnc cst_ok_dirt
    jmp cst_error
cst_ok_dirt:
    mov si, OFFSET sprite_buffer_16
    mov di, OFFSET sprite_dirt
    mov bp, OFFSET sprite_dirt_mask
    call convertir_sprite_a_planar_opt

    mov dx, OFFSET archivo_lava
    mov di, OFFSET sprite_buffer_16
    call cargar_sprite_16x16
    jnc cst_ok_lava
    jmp cst_error
cst_ok_lava:
    mov si, OFFSET sprite_buffer_16
    mov di, OFFSET sprite_lava
    mov bp, OFFSET sprite_lava_mask
    call convertir_sprite_a_planar_opt

    mov dx, OFFSET archivo_bridge
    mov di, OFFSET sprite_buffer_16
    call cargar_sprite_16x16
    jnc cst_ok_bridge
    jmp cst_error
cst_ok_bridge:
    mov si, OFFSET sprite_buffer_16
    mov di, OFFSET sprite_bridge
    mov bp, OFFSET sprite_bridge_mask
    call convertir_sprite_a_planar_opt

    mov dx, OFFSET archivo_cristal
    mov di, OFFSET sprite_buffer_16
    call cargar_sprite_16x16
    jnc cst_ok_cristal
    jmp cst_error
cst_ok_cristal:
    mov si, OFFSET sprite_buffer_16
    mov di, OFFSET sprite_cristal
    mov bp, OFFSET sprite_cristal_mask
    call convertir_sprite_a_planar_opt

    mov dx, OFFSET archivo_gema
    mov di, OFFSET sprite_buffer_16
    call cargar_sprite_16x16
    jnc cst_ok_gema
    jmp cst_error
cst_ok_gema:
    mov si, OFFSET sprite_buffer_16
    mov di, OFFSET sprite_gema
    mov bp, OFFSET sprite_gema_mask
    call convertir_sprite_a_planar_opt

    mov dx, OFFSET archivo_moneda
    mov di, OFFSET sprite_buffer_16
    call cargar_sprite_16x16
    jnc cst_ok_moneda
    jmp cst_error
cst_ok_moneda:
    mov si, OFFSET sprite_buffer_16
    mov di, OFFSET sprite_moneda
    mov bp, OFFSET sprite_moneda_mask
    call convertir_sprite_a_planar_opt

    clc
    jmp cst_fin

cst_error:
    stc

cst_fin:
    pop bp
    pop si
    pop di
    pop dx
    ret
cargar_sprites_terreno ENDP

; REEMPLAZAR cargar_animaciones_jugador COMPLETO:

cargar_animaciones_jugador PROC
    push dx
    push di
    push si
    push bp

    mov dx, OFFSET archivo_player_up_a
    mov di, OFFSET sprite_buffer_32
    call cargar_sprite_32x32
    jnc caj_ok_up_a
    jmp caj_error
caj_ok_up_a:
    mov si, OFFSET sprite_buffer_32
    mov di, OFFSET jugador_up_a
    mov bp, OFFSET jugador_up_a_mask
    call convertir_sprite_32x32_a_planar_opt

    mov dx, OFFSET archivo_player_up_b
    mov di, OFFSET sprite_buffer_32
    call cargar_sprite_32x32
    jnc caj_ok_up_b
    jmp caj_error
caj_ok_up_b:
    mov si, OFFSET sprite_buffer_32
    mov di, OFFSET jugador_up_b
    mov bp, OFFSET jugador_up_b_mask
    call convertir_sprite_32x32_a_planar_opt

    mov dx, OFFSET archivo_player_down_a
    mov di, OFFSET sprite_buffer_32
    call cargar_sprite_32x32
    jnc caj_ok_down_a
    jmp caj_error
caj_ok_down_a:
    mov si, OFFSET sprite_buffer_32
    mov di, OFFSET jugador_down_a
    mov bp, OFFSET jugador_down_a_mask
    call convertir_sprite_32x32_a_planar_opt

    mov dx, OFFSET archivo_player_down_b
    mov di, OFFSET sprite_buffer_32
    call cargar_sprite_32x32
    jnc caj_ok_down_b
    jmp caj_error
caj_ok_down_b:
    mov si, OFFSET sprite_buffer_32
    mov di, OFFSET jugador_down_b
    mov bp, OFFSET jugador_down_b_mask
    call convertir_sprite_32x32_a_planar_opt

    mov dx, OFFSET archivo_player_izq_a
    mov di, OFFSET sprite_buffer_32
    call cargar_sprite_32x32
    jnc caj_ok_izq_a
    jmp caj_error
caj_ok_izq_a:
    mov si, OFFSET sprite_buffer_32
    mov di, OFFSET jugador_izq_a
    mov bp, OFFSET jugador_izq_a_mask
    call convertir_sprite_32x32_a_planar_opt

    mov dx, OFFSET archivo_player_izq_b
    mov di, OFFSET sprite_buffer_32
    call cargar_sprite_32x32
    jnc caj_ok_izq_b
    jmp caj_error
caj_ok_izq_b:
    mov si, OFFSET sprite_buffer_32
    mov di, OFFSET jugador_izq_b
    mov bp, OFFSET jugador_izq_b_mask
    call convertir_sprite_32x32_a_planar_opt

    mov dx, OFFSET archivo_player_der_a
    mov di, OFFSET sprite_buffer_32
    call cargar_sprite_32x32
    jnc caj_ok_der_a
    jmp caj_error
caj_ok_der_a:
    mov si, OFFSET sprite_buffer_32
    mov di, OFFSET jugador_der_a
    mov bp, OFFSET jugador_der_a_mask
    call convertir_sprite_32x32_a_planar_opt

    mov dx, OFFSET archivo_player_der_b
    mov di, OFFSET sprite_buffer_32
    call cargar_sprite_32x32
    jnc caj_ok_der_b
    jmp caj_error
caj_ok_der_b:
    mov si, OFFSET sprite_buffer_32
    mov di, OFFSET jugador_der_b
    mov bp, OFFSET jugador_der_b_mask
    call convertir_sprite_32x32_a_planar_opt

    clc
    jmp caj_fin

caj_error:
    stc

caj_fin:
    pop bp
    pop si
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

dibujar_mapa_en_offset PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    ; Calcular tile inicial de la cámara
    mov ax, camara_px
    shr ax, 4
    mov inicio_tile_x, ax
    
    mov ax, camara_py
    shr ax, 4
    mov inicio_tile_y, ax
    
    xor bp, bp              ; BP = fila actual (0-12)

dmo_fila:
    cmp bp, 13
    jae dmo_fin
    
    xor si, si              ; SI = columna actual (0-20)

dmo_col:
    cmp si, 21
    jae dmo_next_fila
    
    ; ===== Calcular tile_y =====
    mov ax, inicio_tile_y
    add ax, bp
    cmp ax, 100
    jae dmo_next_col
    
    ; ===== Calcular índice en mapa (Y × 100 + X) =====
    mov bx, ax
    shl bx, 1
    mov ax, [mul100_table + bx]
    
    mov bx, inicio_tile_x
    add bx, si
    cmp bx, 100
    jae dmo_next_col
    
    add ax, bx
    
    ; ===== Leer tipo de tile =====
    mov bx, ax
    mov al, [mapa_datos + bx]
    
    cmp al, 15
    ja dmo_next_col
    
    ; ===== Guardar registros de BUCLE (col, fila) =====
    push si                 ; [Stack]: col
    push bp                 ; [Stack]: fila, col
    
    ; ===== Obtener sprite (pone DI=data, SI=mask) =====
    call obtener_sprite_tile
    
    push si                 ; [Stack]: mask_ptr, fila, col
    push di                 ; [Stack]: data_ptr, mask_ptr, fila, col
    
    ; --- Crear Stack Frame ---
    push bp                 ; Guardar BP (fila)
    mov bp, sp              ; BP es ahora el puntero de pila

    ; Calcular DX (Y) usando BP
    mov ax, [bp+6]          ; AX = fila
    shl ax, 4               
    add ax, viewport_y
    mov dx, ax              ; DX = Y
    
    ; Calcular CX (X) usando BP
    mov ax, [bp+8]          ; AX = col
    shl ax, 4               
    add ax, viewport_x
    mov cx, ax              ; CX = X
    
    ; --- Destruir Stack Frame ---
    pop bp                  ; Restaurar BP (fila)
    
    pop di                  ; Restaurar DI (data_ptr)
    pop si                  ; Restaurar SI (mask_ptr)

    ; Llamar a dibujar con DI, SI, CX, DX correctos
    call dibujar_sprite_planar_16x16_opt
    
    ; ===== Restaurar registros de BUCLE =====
    pop bp                  
    pop si                  
    
dmo_next_col:
    inc si                  
    jmp dmo_col
    
dmo_next_fila:
    inc bp                  
    jmp dmo_fila
    
dmo_fin:
call dibujar_recursos_en_mapa
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
    push ax
    push bx
    
    mov bl, al
    
    ; Default: GRASS1
    mov di, OFFSET sprite_grass1
    mov si, OFFSET sprite_grass1_mask
    
    cmp bl, TILE_PATH
    jne ost_water
    mov di, OFFSET sprite_path
    mov si, OFFSET sprite_path_mask
    jmp ost_fin
    
ost_water:
    cmp bl, TILE_WATER
    jne ost_tree
    mov di, OFFSET sprite_water
    mov si, OFFSET sprite_water_mask
    jmp ost_fin
    
ost_tree:
    cmp bl, TILE_TREE
    jne ost_sand
    mov di, OFFSET sprite_tree
    mov si, OFFSET sprite_tree_mask
    jmp ost_fin
    
ost_sand:
    cmp bl, TILE_SAND
    jne ost_rock
    mov di, OFFSET sprite_sand
    mov si, OFFSET sprite_sand_mask
    jmp ost_fin
    
ost_rock:                   ; ← AGREGAR ESTO
    cmp bl, TILE_ROCK       ; ← AGREGAR ESTO
    jne ost_snow            ; ← AGREGAR ESTO
    mov di, OFFSET sprite_rock       ; ← AGREGAR ESTO
    mov si, OFFSET sprite_rock_mask  ; ← AGREGAR ESTO
    jmp ost_fin         
ost_snow:
    cmp bl, TILE_SNOW
    jne ost_ice
    mov di, OFFSET sprite_snow
    mov si, OFFSET sprite_snow_mask
    jmp ost_fin
    
ost_ice:
    cmp bl, TILE_ICE
    jne ost_wall
    mov di, OFFSET sprite_ice
    mov si, OFFSET sprite_ice_mask
    jmp ost_fin
    
ost_wall:
    cmp bl, TILE_WALL
    jne ost_dirt
    mov di, OFFSET sprite_wall
    mov si, OFFSET sprite_wall_mask
    jmp ost_fin
    
ost_dirt:
    cmp bl, TILE_DIRT
    jne ost_lava
    mov di, OFFSET sprite_dirt
    mov si, OFFSET sprite_dirt_mask
    jmp ost_fin
    
ost_lava:
    cmp bl, TILE_LAVA
    jne ost_bridge
    mov di, OFFSET sprite_lava
    mov si, OFFSET sprite_lava_mask
    jmp ost_fin
    
ost_bridge:
    cmp bl, TILE_BRIDGE
    jne ost_fin
    mov di, OFFSET sprite_bridge
    mov si, OFFSET sprite_bridge_mask

ost_fin:
    pop bx
    pop ax
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
    sub ax, 16
    mov cx, ax
    
    mov ax, jugador_py
    sub ax, camara_py
    add ax, viewport_y
    sub ax, 16
    mov dx, ax
    
    call obtener_sprite_jugador
    call dibujar_sprite_planar_32x32_opt
    
    ; Dibujar animación de recolección
    call dibujar_animacion_recoger
    
    ; Dibujar panel de inventario (si está abierto)
    ; call dibujar_inventario  <--- ESTA LÍNEA SE ELIMINA
    
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
    
    ; Esperar hasta que NO esté en retrace (evita empezar a mitad)
er_wait_not_retrace:
    in al, dx
    test al, 8
    jnz er_wait_not_retrace
    
    ; Ahora esperar hasta que EMPIECE el retrace
er_wait_start:
    in al, dx
    test al, 8
    jz er_wait_start
    
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

cargar_recursos_obtener_char PROC
    push dx
    push cx
    push bx

    cmp carga_recursos_tiene_pend, 0
    je croc_leer

    mov al, carga_recursos_char_pend
    mov carga_recursos_tiene_pend, 0
    clc
    jmp croc_fin

croc_leer:
    mov bx, carga_recursos_handle
    mov ah, 3Fh
    mov cx, 1
    mov dx, OFFSET buffer_temp
    int 21h
    cmp ax, 0
    jne croc_ok
    stc
    jmp croc_fin

croc_ok:
    mov al, [buffer_temp]
    clc

croc_fin:
    pop bx
    pop cx
    pop dx
    ret
cargar_recursos_obtener_char ENDP

cargar_recursos_leer_numero PROC
    push bx
    push cx
    push dx
    push si

    mov carga_recursos_temp, 0

crln_loop:
    sub al, '0'
    mov ah, 0
    mov si, ax
    mov ax, carga_recursos_temp
    mov cx, 10
    mul cx
    add ax, si
    mov carga_recursos_temp, ax

    call cargar_recursos_obtener_char
    jc crln_fin

    cmp al, '0'
    jb crln_set_pend
    cmp al, '9'
    jbe crln_loop

crln_set_pend:
    mov carga_recursos_char_pend, al
    mov carga_recursos_tiene_pend, 1

crln_fin:
    mov ax, carga_recursos_temp

    pop si
    pop dx
    pop cx
    pop bx
    ret
cargar_recursos_leer_numero ENDP

cargar_recursos_desde_mapa PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov recursos_tipo1, 0
    mov recursos_tipo2, 0
    mov recursos_tipo3, 0
    mov recursos_recogidos, 0
    mov num_recursos_cargados, 0

    cld
    mov di, OFFSET recursos_mapa
    mov cx, NUM_RECURSOS * 3
    mov al, 0
    rep stosb

    mov di, OFFSET recursos_cantidad
    mov cx, NUM_RECURSOS
    mov al, 0
    rep stosb

    mov di, OFFSET inventario_slots
    mov cx, MAX_ITEMS
    mov al, 0
    rep stosb

    mov di, OFFSET inventario_cantidades
    mov cx, MAX_ITEMS
    mov al, 0
    rep stosb

    mov carga_recursos_estado, 0
    mov carga_recursos_guardar, 0
    mov carga_recursos_comentario, 0
    mov carga_recursos_tiene_pend, 0

    mov ax, 3D00h
    mov dx, OFFSET archivo_mapa
    int 21h
    jnc crm_open_ok
    jmp crm_error

crm_open_ok:
    mov carga_recursos_handle, ax

crm_loop:
    call cargar_recursos_obtener_char
    jnc crm_continuar_lectura
    jmp crm_fin_lectura

crm_continuar_lectura:

    cmp carga_recursos_comentario, 0
    je crm_no_comentario
    cmp al, 10
    jne crm_loop
    mov carga_recursos_comentario, 0
    jmp crm_loop

crm_no_comentario:
    cmp al, ';'
    jne crm_no_puntoycoma
    mov carga_recursos_comentario, 1
    jmp crm_loop

crm_no_puntoycoma:
    cmp carga_recursos_estado, 0
    jne crm_estado_en_progreso

    cmp al, 'R'
    je crm_inicio_recurso
    cmp al, 'r'
    jne crm_loop

crm_inicio_recurso:
    cmp num_recursos_cargados, NUM_RECURSOS
    jb crm_guardar
    mov carga_recursos_guardar, 0
    mov carga_recursos_estado, 1
    jmp crm_loop

crm_guardar:
    mov carga_recursos_guardar, 1
    mov al, num_recursos_cargados
    mov ah, 0
    mov bl, 3
    mul bl
    mov carga_recursos_offset, ax
    mov carga_recursos_estado, 1
    jmp crm_loop

crm_estado_en_progreso:
    cmp al, ' '
    je crm_loop
    cmp al, 9
    je crm_loop
    cmp al, 13
    je crm_loop
    cmp al, 10
    je crm_loop

    cmp al, '0'
    jb crm_loop
    cmp al, '9'
    ja crm_loop

    call cargar_recursos_leer_numero
    mov bx, ax

    cmp carga_recursos_estado, 1
    jne crm_estado_y
    mov carga_recursos_estado, 2
    cmp carga_recursos_guardar, 0
    je crm_estado_x_skip
    mov di, carga_recursos_offset
    mov al, bl
    mov [recursos_mapa + di], al
crm_estado_x_skip:
    jmp crm_loop

crm_estado_y:
    cmp carga_recursos_estado, 2
    jne crm_estado_tipo
    mov carga_recursos_estado, 3
    cmp carga_recursos_guardar, 0
    je crm_estado_y_skip
    mov di, carga_recursos_offset
    mov al, bl
    mov [recursos_mapa + di + 1], al
crm_estado_y_skip:
    jmp crm_loop

crm_estado_tipo:
    cmp carga_recursos_estado, 3
    jne crm_estado_cant
    mov carga_recursos_estado, 4
    cmp carga_recursos_guardar, 0
    je crm_estado_tipo_skip
    mov di, carga_recursos_offset
    mov al, bl
    mov [recursos_mapa + di + 2], al
crm_estado_tipo_skip:
    jmp crm_loop

crm_estado_cant:
    mov carga_recursos_estado, 0
    cmp carga_recursos_guardar, 0
    je crm_estado_cant_skip

    cmp bx, 255
    jbe crm_cant_ok
    mov bx, 255

crm_cant_ok:
    mov al, num_recursos_cargados
    mov ah, 0
    mov si, ax
    mov al, bl
    mov [recursos_cantidad + si], al

    inc num_recursos_cargados
    mov carga_recursos_guardar, 0
    jmp crm_loop

crm_estado_cant_skip:
    jmp crm_loop

crm_fin_lectura:
    mov bx, carga_recursos_handle
    mov ah, 3Eh
    int 21h
    clc
    jmp crm_fin

crm_error:
    stc

crm_fin:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
cargar_recursos_desde_mapa ENDP

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
INCLUDE INVCODE.INC
INCLUDE MENU.INC

END inicio
