; =====================================================
; JUEGO DE EXPLORACIÓN - CON SPRITES
; Universidad Nacional - Proyecto II Ciclo 2025
; CARGA MAPA.TXT Y SPRITES DE TILES
; =====================================================

.MODEL SMALL
.STACK 2048

; =====================================================
; CONSTANTES DEL JUEGO - OPTIMIZADAS
; =====================================================
TILE_GRASS  EQU 0
TILE_WALL   EQU 1
TILE_PATH   EQU 2
TILE_WATER  EQU 3
TILE_TREE   EQU 4

TILE_SIZE   EQU 16
SCREEN_W    EQU 320
SCREEN_H    EQU 200
VIEWPORT_W  EQU 12          ; ✅ CAMBIAR: 20 → 12 (más fluido)
VIEWPORT_H  EQU 8           ; ✅ CAMBIAR: 12 → 8 (más fluido)

VIDEO_SEG   EQU 0A000h
PAGE_SIZE   EQU 8000h

.DATA
; === ARCHIVOS ===
archivo_mapa   db 'MAPA.TXT',0
archivo_grass  db 'GRASS.TXT',0
archivo_wall   db 'WALL.TXT',0
archivo_path   db 'PATH.TXT',0
archivo_water  db 'WATER.TXT',0
archivo_tree   db 'TREE.TXT',0
archivo_player db 'PLAYER.TXT',0
handle_archivo dw 0

; === MAPA ===
mapa_ancho  dw 50
mapa_alto   dw 50
mapa_datos  db 2500 dup(0)

; === SPRITES (16x16 = 256 bytes cada uno) ===
sprite_grass  db 256 dup(0)
sprite_wall   db 256 dup(0)
sprite_path   db 256 dup(0)
sprite_water  db 256 dup(0)
sprite_tree   db 256 dup(0)
sprite_player db 64 dup(0)   ; 8x8

buffer_temp db 300 dup(0)

; === JUGADOR ===
jugador_x   dw 25
jugador_y   dw 25
jugador_x_ant dw 25
jugador_y_ant dw 25

; === CÁMARA ===
camara_x    dw 0
camara_y    dw 0

; === PÁGINAS ===
pagina_visible db 0
pagina_dibujo  db 1

; === CONTROL ===
necesita_redibujo db 1

; === MENSAJES ===
msg_titulo  db 'JUEGO DE EXPLORACION CON SPRITES',13,10,'$'
msg_cargando db 'Cargando archivos...$'
msg_ok     db 'OK',13,10,'$'
msg_error  db 'ERROR',13,10,'$'
msg_controles db 13,10,'Controles: Flechas/WASD = Mover, ESC = Salir',13,10
              db 'Presiona tecla...$'

.CODE
inicio:
    mov ax, @data
    mov ds, ax
    mov es, ax

    ; Título
    mov dx, OFFSET msg_titulo
    mov ah, 9
    int 21h

    ; Cargar archivos
    mov dx, OFFSET msg_cargando
    mov ah, 9
    int 21h
    
    call cargar_sprites
    jc error_carga
    
    call cargar_mapa_txt
    jc error_carga
    
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    ; Controles
    mov dx, OFFSET msg_controles
    mov ah, 9
    int 21h
    mov ah, 0
    int 16h

    ; Modo gráfico
    mov ax, 0Dh
    int 10h
    
    mov pagina_visible, 0
    mov pagina_dibujo, 1
    
    mov al, 0
    mov ah, 05h
    int 10h
    
    call actualizar_camara
    call renderizar
    mov necesita_redibujo, 0

bucle_juego:
    mov ah, 1
    int 16h
    jz bucle_juego
    
    mov ah, 0
    int 16h
    
    cmp al, 27
    je terminar
    
    call mover_jugador
    
    cmp necesita_redibujo, 1
    jne bucle_juego
    
    call actualizar_camara
    call renderizar
    mov necesita_redibujo, 0
    
    jmp bucle_juego

error_carga:
    mov dx, OFFSET msg_error
    mov ah, 9
    int 21h

terminar:
    mov ax, 3
    int 10h
    mov ax, 4C00h
    int 21h

; =====================================================
; CARGAR SPRITES
; =====================================================
cargar_sprites PROC
    push ax
    push dx
    push di
    
    ; GRASS
    mov dx, OFFSET archivo_grass
    mov di, OFFSET sprite_grass
    call cargar_sprite_16x16
    jc cs_error
    
    ; WALL
    mov dx, OFFSET archivo_wall
    mov di, OFFSET sprite_wall
    call cargar_sprite_16x16
    jc cs_error
    
    ; PATH
    mov dx, OFFSET archivo_path
    mov di, OFFSET sprite_path
    call cargar_sprite_16x16
    jc cs_error
    
    ; WATER
    mov dx, OFFSET archivo_water
    mov di, OFFSET sprite_water
    call cargar_sprite_16x16
    jc cs_error
    
    ; TREE
    mov dx, OFFSET archivo_tree
    mov di, OFFSET sprite_tree
    call cargar_sprite_16x16
    jc cs_error
    
    ; PLAYER (8x8)
    mov dx, OFFSET archivo_player
    mov di, OFFSET sprite_player
    call cargar_sprite_8x8
    jc cs_error
    
    clc
    jmp cs_fin
    
cs_error:
    stc
    
cs_fin:
    pop di
    pop dx
    pop ax
    ret
cargar_sprites ENDP

; =====================================================
; CARGAR SPRITE 16x16
; =====================================================
cargar_sprite_16x16 PROC
    push ax
    push bx
    push cx
    push si
    
    ; Abrir archivo
    mov ax, 3D00h
    int 21h
    jc csp_error
    
    mov handle_archivo, ax
    mov bx, ax
    
    ; Saltar primera línea (dimensiones)
    mov ah, 3Fh
    mov cx, 10
    mov dx, OFFSET buffer_temp
    int 21h
    
    ; Leer datos
    xor si, si
    
csp_leer:
    mov ah, 3Fh
    mov bx, handle_archivo
    mov cx, 200
    mov dx, OFFSET buffer_temp
    int 21h
    
    cmp ax, 0
    je csp_cerrar
    
    mov cx, ax
    xor bx, bx
    
csp_proc:
    cmp bx, cx
    jae csp_leer
    
    mov al, buffer_temp[bx]
    inc bx
    
    cmp al, ' '
    je csp_proc
    cmp al, 13
    je csp_proc
    cmp al, 10
    je csp_proc
    cmp al, 9
    je csp_proc
    
    cmp al, '0'
    jb csp_proc
    cmp al, '9'
    ja csp_proc
    
    sub al, '0'
    
    mov [di], al
    inc di
    inc si
    
    cmp si, 256
    jb csp_proc
    
csp_cerrar:
    mov ah, 3Eh
    mov bx, handle_archivo
    int 21h
    
    clc
    jmp csp_fin
    
csp_error:
    stc
    
csp_fin:
    pop si
    pop cx
    pop bx
    pop ax
    ret
cargar_sprite_16x16 ENDP

; =====================================================
; CARGAR SPRITE 8x8
; =====================================================
cargar_sprite_8x8 PROC
    push ax
    push bx
    push cx
    push si
    
    mov ax, 3D00h
    int 21h
    jc csp8_error
    
    mov handle_archivo, ax
    mov bx, ax
    
    ; Saltar dimensiones
    mov ah, 3Fh
    mov cx, 10
    mov dx, OFFSET buffer_temp
    int 21h
    
    xor si, si
    
csp8_leer:
    mov ah, 3Fh
    mov bx, handle_archivo
    mov cx, 100
    mov dx, OFFSET buffer_temp
    int 21h
    
    cmp ax, 0
    je csp8_cerrar
    
    mov cx, ax
    xor bx, bx
    
csp8_proc:
    cmp bx, cx
    jae csp8_leer
    
    mov al, buffer_temp[bx]
    inc bx
    
    cmp al, ' '
    je csp8_proc
    cmp al, 13
    je csp8_proc
    cmp al, 10
    je csp8_proc
    
    cmp al, '0'
    jb csp8_proc
    cmp al, '9'
    ja csp8_proc
    
    sub al, '0'
    
    mov [di], al
    inc di
    inc si
    
    cmp si, 64
    jb csp8_proc
    
csp8_cerrar:
    mov ah, 3Eh
    mov bx, handle_archivo
    int 21h
    
    clc
    jmp csp8_fin
    
csp8_error:
    stc
    
csp8_fin:
    pop si
    pop cx
    pop bx
    pop ax
    ret
cargar_sprite_8x8 ENDP

; =====================================================
; CARGAR MAPA
; =====================================================
cargar_mapa_txt PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov ax, 3D00h
    mov dx, OFFSET archivo_mapa
    int 21h
    jc cm_error
    
    mov handle_archivo, ax
    mov bx, ax
    
    ; Saltar dimensiones
    mov ah, 3Fh
    mov cx, 10
    mov dx, OFFSET buffer_temp
    int 21h
    
    mov di, OFFSET mapa_datos
    xor si, si
    
cm_leer:
    mov ah, 3Fh
    mov bx, handle_archivo
    mov cx, 200
    mov dx, OFFSET buffer_temp
    int 21h
    
    cmp ax, 0
    je cm_cerrar
    
    mov cx, ax
    xor bx, bx
    
cm_proc:
    cmp bx, cx
    jae cm_leer
    
    mov al, buffer_temp[bx]
    inc bx
    
    cmp al, ' '
    je cm_proc
    cmp al, 13
    je cm_proc
    cmp al, 10
    je cm_proc
    
    cmp al, '0'
    jb cm_proc
    cmp al, '9'
    ja cm_proc
    
    sub al, '0'
    
    mov [di], al
    inc di
    inc si
    
    cmp si, 2500
    jb cm_proc
    
cm_cerrar:
    mov ah, 3Eh
    mov bx, handle_archivo
    int 21h
    
    clc
    jmp cm_fin
    
cm_error:
    stc
    
cm_fin:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
cargar_mapa_txt ENDP

; =====================================================
; MOVER JUGADOR
; =====================================================
; filepath: c:\ASM\project\proyec.asm
; =====================================================
; MOVER JUGADOR - LÍMITES CORREGIDOS
; =====================================================
mover_jugador PROC
    push ax
    
    mov ax, jugador_x
    mov jugador_x_ant, ax
    mov ax, jugador_y
    mov jugador_y_ant, ax
    
    cmp ah, 48h
    je mj_arr
    cmp al, 'w'
    je mj_arr
    cmp al, 'W'
    je mj_arr
    
    cmp ah, 50h
    je mj_aba
    cmp al, 's'
    je mj_aba
    cmp al, 'S'
    je mj_aba
    
    cmp ah, 4Bh
    je mj_izq
    cmp al, 'a'
    je mj_izq
    cmp al, 'A'
    je mj_izq
    
    cmp ah, 4Dh
    je mj_der
    cmp al, 'd'
    je mj_der
    cmp al, 'D'
    je mj_der
    
    jmp mj_fin
    
mj_arr:
    cmp jugador_y, 1
    jbe mj_fin
    dec jugador_y
    jmp mj_chk
    
mj_aba:
    cmp jugador_y, 48       ; ✅ 50-2 = 48 (límite correcto)
    jae mj_fin
    inc jugador_y
    jmp mj_chk
    
mj_izq:
    cmp jugador_x, 1
    jbe mj_fin
    dec jugador_x
    jmp mj_chk
    
mj_der:
    cmp jugador_x, 48       ; ✅ 50-2 = 48 (límite correcto)
    jae mj_fin
    inc jugador_x
    
mj_chk:
    call colision
    jnc mj_ok
    
    mov ax, jugador_x_ant
    mov jugador_x, ax
    mov ax, jugador_y_ant
    mov jugador_y, ax
    jmp mj_fin
    
mj_ok:
    mov necesita_redibujo, 1
    
mj_fin:
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
    mov bx, 50
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
; ACTUALIZAR CÁMARA - OPTIMIZADA PARA 12x8
actualizar_camara PROC
    push ax
    push bx
    
    ; ✅ CENTRAR X (viewport 12)
    mov ax, jugador_x
    sub ax, VIEWPORT_W/2    ; 6
    jge ac_x1
    xor ax, ax
ac_x1:
    mov bx, 50              ; mapa_ancho
    sub bx, VIEWPORT_W      ; 12
    cmp bx, 0
    jle ac_x2
    cmp ax, bx
    jle ac_x3
    mov ax, bx
    jmp ac_x3
ac_x2:
    xor ax, ax
ac_x3:
    mov camara_x, ax
    
    ; ✅ CENTRAR Y (viewport 8)
    mov ax, jugador_y
    sub ax, VIEWPORT_H/2    ; 4
    jge ac_y1
    xor ax, ax
ac_y1:
    mov bx, 50              ; mapa_alto
    sub bx, VIEWPORT_H      ; 8
    cmp bx, 0
    jle ac_y2
    cmp ax, bx
    jle ac_y3
    mov ax, bx
    jmp ac_y3
ac_y2:
    xor ax, ax
ac_y3:
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
    push es
    
    mov ax, VIDEO_SEG
    mov es, ax
    
    mov al, pagina_dibujo
    xor ah, ah
    mov bx, PAGE_SIZE
    mul bx
    mov di, ax
    
    push di
    mov cx, PAGE_SIZE / 2
    xor ax, ax
    rep stosw
    pop di
    
    call dibujar_mapa_sprites
    call dibujar_jugador_sprite
    
    mov al, pagina_dibujo
    mov bl, pagina_visible
    mov pagina_visible, al
    mov pagina_dibujo, bl
    
    mov al, pagina_visible
    mov ah, 05h
    int 10h
    
    pop es
    pop ax
    ret
renderizar ENDP

; =====================================================
; DIBUJAR MAPA CON SPRITES
; =====================================================
dibujar_mapa_sprites PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    mov al, pagina_dibujo
    xor ah, ah
    mov bx, PAGE_SIZE
    mul bx
    mov bp, ax
    
    xor di, di              ; Y viewport (0-7)
    

dms_y:
    cmp di, VIEWPORT_H      ; ✅ USAR 8 en lugar de 12
    jb dms_y_body
    jmp dms_fin

dms_y_body:
    xor si, si              ; X viewport (0-11)

dms_x:
    cmp si, VIEWPORT_W      ; ✅ USAR 12 en lugar de 20
    jb dms_x_body
    jmp dms_ny

dms_x_body:
    
    ; ✅ VERIFICAR LÍMITES DEL MAPA
    mov ax, camara_y
    add ax, di
    cmp ax, 50              ; mapa_alto
    jae dms_nx
    
    mov bx, camara_x
    add bx, si
    cmp bx, 50              ; mapa_ancho
    jae dms_nx
    
    ; ✅ CALCULAR ÍNDICE EN MAPA
    push dx
    mov dx, 50              ; mapa_ancho
    mul dx
    add ax, bx
    pop dx
    
    ; Verificar que no se salga del array
    cmp ax, 2500
    jae dms_nx
    
    ; Obtener tipo de tile
    push si
    mov si, OFFSET mapa_datos
    add si, ax
    mov al, [si]
    pop si
    
    ; ✅ OBTENER SPRITE SEGÚN TIPO
    push si
    push di
    
    cmp al, TILE_GRASS
    jne dms_check_wall
    mov si, OFFSET sprite_grass
    jmp dms_draw
    
dms_check_wall:
    cmp al, TILE_WALL
    jne dms_check_path
    mov si, OFFSET sprite_wall
    jmp dms_draw
    
dms_check_path:
    cmp al, TILE_PATH
    jne dms_check_water
    mov si, OFFSET sprite_path
    jmp dms_draw
    
dms_check_water:
    cmp al, TILE_WATER
    jne dms_check_tree
    mov si, OFFSET sprite_water
    jmp dms_draw
    
dms_check_tree:
    cmp al, TILE_TREE
    jne dms_default
    mov si, OFFSET sprite_tree
    jmp dms_draw
    
dms_default:
    mov si, OFFSET sprite_grass  ; Por defecto grass
    
dms_draw:
    ; ✅ CALCULAR POSICIÓN EN PANTALLA
    mov ax, di              ; Y en tiles (variable de stack)
    mov dx, TILE_SIZE
    mul dx
    mov dx, ax              ; DX = Y en píxeles
    
    pop di                  ; Recuperar DI original
    push di                 ; Guardarlo de nuevo
    
    mov ax, si              ; X en tiles (variable de stack actual)
    mov cx, TILE_SIZE
    mul cx
    mov cx, ax              ; CX = X en píxeles
    
    call dibujar_sprite_16x16
    
    pop di                  ; Recuperar DI
    pop si                  ; Recuperar SI
    
dms_nx:
    inc si
    jmp dms_x
    
dms_ny:
    inc di
    jmp dms_y
    
dms_fin:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_mapa_sprites ENDP

; =====================================================
; DIBUJAR SPRITE 16x16
; =====================================================
; SI = sprite data, CX = x, DX = y, BP = page offset
dibujar_sprite_16x16 PROC
    push ax
    push bx
    push cx
    push dx
    push di
    push si
    
    ; ✅ VERIFICAR LÍMITES DE PANTALLA PRIMERO
    cmp cx, SCREEN_W
    jae ds16_fin
    cmp dx, SCREEN_H
    jae ds16_fin
    
    xor bx, bx              ; Contador Y
    
ds16_y:
    cmp bx, 16              ; ✅ USAR 16 directamente
    jae ds16_fin
    
    ; ✅ VERIFICAR LÍMITE Y
    mov ax, dx
    add ax, bx
    cmp ax, SCREEN_H
    jae ds16_skip_y
    
    ; ✅ CALCULAR DIRECCIÓN DE VIDEO CORRECTAMENTE
    push dx
    push cx
    
    mov ax, dx
    add ax, bx              ; Y actual
    mov di, 320             ; Ancho de pantalla
    mul di
    add ax, cx              ; + X
    add ax, bp              ; + offset de página
    mov di, ax
    
    pop cx
    pop dx
    
    ; Dibujar fila de 16 píxeles
    push cx
    push bx
    mov cx, 16              ; ✅ USAR 16 directamente
    
ds16_x:
    ; ✅ VERIFICAR LÍMITE X
    push cx
    mov ax, dx
    add ax, cx
    cmp ax, SCREEN_W
    pop cx
    jae ds16_skip_x
    
    mov al, [si]
    cmp al, 0               ; ✅ VERIFICAR TRANSPARENCIA
    je ds16_transp
    
    ; ✅ VERIFICAR QUE DI NO SE SALGA
    cmp di, 64000           ; Límite de memoria video
    jae ds16_transp
    
    mov es:[di], al
    
ds16_transp:
    inc di
    inc si
    loop ds16_x
    
ds16_skip_x:
    pop bx
    pop cx
    
ds16_skip_y:
    inc bx
    jmp ds16_y
    
ds16_fin:
    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_sprite_16x16 ENDP

; =====================================================
; DIBUJAR JUGADOR CON SPRITE
; =====================================================
; dibujar_jugador_sprite PROC
;     push ax
;     push bx
;     push cx
;     push dx
;     push si
;     push di
;     
;     mov ax, jugador_x
;     sub ax, camara_x
;     js djs_fin
;     cmp ax, VIEWPORT_W      ; 12
;     jae djs_fin
;     
;     mov bx, jugador_y
;     sub bx, camara_y
;     js djs_fin
;     cmp bx, VIEWPORT_H      ; 8
;     jae djs_fin
;     
;     shl ax, 4               ; * TILE_SIZE (16)
;     add ax, 4               ; Centrar en tile
;     mov cx, ax
;     
;     shl bx, 4               ; * TILE_SIZE (16)
;     add bx, 4               ; Centrar en tile
;     mov dx, bx
;     
;     ; ✅ VERIFICAR LÍMITES DE PANTALLA
;     cmp cx, SCREEN_W - 8    ; 320 - 8
;     jae djs_fin
;     cmp dx, SCREEN_H - 8    ; 200 - 8
;     jae djs_fin
;     
;     mov si, OFFSET sprite_player
;     
;     xor bx, bx              ; Y counter
; djs_y:
;     cmp bx, 8
;     jae djs_fin
;     
;     ; Calcular dirección de video
;     mov ax, dx
;     add ax, bx              ; Y actual
;     mov di, SCREEN_W        ; 320
;     mul di
;     add ax, cx              ; + X
;     
;     ; Añadir offset de página
;     push bx
;     mov bl, pagina_dibujo
;     xor bh, bh
;     push ax
;     mov ax, PAGE_SIZE
;     mul bx
;     mov bx, ax
;     pop ax
;     add ax, bx
;     pop bx
;     
;     mov di, ax
;     
;     ; Dibujar fila de 8 píxeles
;     push cx
;     push bx
;     mov cx, 8
;     
; djs_x:
;     mov al, [si]
;     cmp al, 0
;     je djs_transp
;     
;     mov es:[di], al
;     
; djs_transp:
;     inc di
;     inc si
;     loop djs_x
;     
;     pop bx
;     pop cx
;     
;     inc bx
;     jmp djs_y
;     
; djs_fin:
;     pop di
;     pop si
;     pop dx
;     pop cx
;     pop bx
;     pop ax
;     ret
; dibujar_jugador_sprite ENDP
; =====================================================
; DIBUJAR JUGADOR CON SPRITE - OPTIMIZADO
; =====================================================
dibujar_jugador_sprite PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; ✅ VERIFICAR SI ESTÁ EN EL VIEWPORT 12x8
    mov ax, jugador_x
    sub ax, camara_x
    jns djs_x_in_view
    jmp djs_fin

djs_x_in_view:
    cmp ax, VIEWPORT_W      ; 12
    jb djs_prepare_y
    jmp djs_fin

djs_prepare_y:
    mov bx, jugador_y
    sub bx, camara_y
    jns djs_y_in_view
    jmp djs_fin

djs_y_in_view:
    cmp bx, VIEWPORT_H      ; 8
    jb djs_prepare_pixels
    jmp djs_fin

djs_prepare_pixels:
    
    ; ✅ CONVERTIR A PÍXELES Y CENTRAR
    shl ax, 4               ; * TILE_SIZE (16)
    add ax, 4               ; Centrar en tile
    mov cx, ax
    
    shl bx, 4               ; * TILE_SIZE (16)
    add bx, 4               ; Centrar en tile
    mov dx, bx
    
    ; ✅ VERIFICAR LÍMITES DE PANTALLA
    cmp cx, SCREEN_W - 8    ; 320 - 8
    jb djs_check_screen_y
    jmp djs_fin

djs_check_screen_y:
    cmp dx, SCREEN_H - 8    ; 200 - 8
    jb djs_draw_setup
    jmp djs_fin

djs_draw_setup:
    
    mov si, OFFSET sprite_player
    
    ; ✅ DIBUJAR SPRITE 8x8 OPTIMIZADO
    xor bx, bx              ; Y counter
djs_y:
    cmp bx, 8
    jb djs_y_body
    jmp djs_fin

djs_y_body:
    
    ; Calcular dirección de video
    mov ax, dx
    add ax, bx              ; Y actual
    mov di, SCREEN_W        ; 320
    mul di
    add ax, cx              ; + X
    
    ; Añadir offset de página
    push bx
    mov bl, pagina_dibujo
    xor bh, bh
    push ax
    mov ax, PAGE_SIZE
    mul bx
    mov bx, ax
    pop ax
    add ax, bx
    pop bx
    
    mov di, ax
    
    ; Dibujar fila de 8 píxeles
    push cx
    push bx
    mov cx, 8
    
djs_x:
    cmp di, 16000           ; ✅ LÍMITE SEGURO PARA PÁGINA
    jae djs_skip
    
    mov al, [si]
    cmp al, 0               ; ✅ VERIFICAR TRANSPARENCIA
    je djs_transp
    
    mov es:[di], al
    
djs_transp:
    inc di
    inc si
    loop djs_x
    
djs_skip:
    pop bx
    pop cx
    
    inc bx
    jmp djs_y
    
djs_fin:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_jugador_sprite ENDP

END inicio