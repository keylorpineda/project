; =====================================================
; JUEGO DE EXPLORACIÓN - DOBLE BUFFER EN RAM
; Universidad Nacional - Proyecto II Ciclo 2025
; Modo 10h (640x350 EGA) con buffer manual en RAM
; =====================================================

.MODEL SMALL
.STACK 2048

; =====================================================
; CONSTANTES
; =====================================================
TILE_GRASS  EQU 0
TILE_WALL   EQU 1
TILE_PATH   EQU 2
TILE_WATER  EQU 3
TILE_TREE   EQU 4

TILE_SIZE   EQU 16
SCREEN_W    EQU 640
SCREEN_H    EQU 350
VIEWPORT_W  EQU 20          ; 20 tiles × 16 = 320 píxeles
VIEWPORT_H  EQU 12          ; 12 tiles × 16 = 192 píxeles

VIDEO_SEG   EQU 0A000h

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

; === SPRITES ===
sprite_grass  db 256 dup(0)
sprite_wall   db 256 dup(0)
sprite_path   db 256 dup(0)
sprite_water  db 256 dup(0)
sprite_tree   db 256 dup(0)
sprite_player db 64 dup(0)

buffer_temp db 300 dup(0)

; === JUGADOR ===
jugador_x   dw 25
jugador_y   dw 25
jugador_x_ant dw 25
jugador_y_ant dw 25

; === CÁMARA ===
camara_x    dw 0
camara_y    dw 0

; === CONTROL ===
necesita_redibujo db 1

; === OFFSCREEN BUFFER (zona oculta en RAM) ===
; Tamaño viewport: 320×192 píxeles = 61,440 píxeles
; En modo planar EGA: 61,440 bytes (1 byte = 2 píxeles)
buffer_viewport_size EQU 30720  ; 320×192/2
buffer_viewport db 30720 dup(0)

; === MENSAJES ===
msg_titulo  db 'JUEGO DE EXPLORACION - EGA 640x350',13,10
            db 'Doble buffer en RAM',13,10,'$'
msg_cargando db 'Cargando archivos...',13,10,'$'
msg_mapa    db '- Mapa: $'
msg_grass   db '- Grass: $'
msg_wall    db '- Wall: $'
msg_path    db '- Path: $'
msg_water   db '- Water: $'
msg_tree    db '- Tree: $'
msg_player  db '- Player: $'
msg_ok      db 'OK',13,10,'$'
msg_error   db 'ERROR!',13,10,'$'
msg_controles db 13,10,'Controles:',13,10
              db '  Flechas/WASD = Mover',13,10
              db '  ESC = Salir',13,10,13,10
              db 'Presiona una tecla...$'

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
    
    ; Mapa
    mov dx, OFFSET msg_mapa
    mov ah, 9
    int 21h
    call cargar_mapa_txt
    jc error_carga_jmp
    jmp mapa_ok
    
error_carga_jmp:
    jmp error_carga
    
mapa_ok:
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    ; Grass
    mov dx, OFFSET msg_grass
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_grass
    mov di, OFFSET sprite_grass
    call cargar_sprite_16x16
    jc error_carga_jmp
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    ; Wall
    mov dx, OFFSET msg_wall
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_wall
    mov di, OFFSET sprite_wall
    call cargar_sprite_16x16
    jc error_carga_jmp
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    ; Path
    mov dx, OFFSET msg_path
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_path
    mov di, OFFSET sprite_path
    call cargar_sprite_16x16
    jc error_carga_jmp
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    ; Water
    mov dx, OFFSET msg_water
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_water
    mov di, OFFSET sprite_water
    call cargar_sprite_16x16
    jc error_carga_jmp
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    ; Tree
    mov dx, OFFSET msg_tree
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_tree
    mov di, OFFSET sprite_tree
    call cargar_sprite_16x16
    jc error_carga_jmp
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    ; Player
    mov dx, OFFSET msg_player
    mov ah, 9
    int 21h
    mov dx, OFFSET archivo_player
    mov di, OFFSET sprite_player
    call cargar_sprite_8x8
    jc error_carga_jmp
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    ; Controles
    mov dx, OFFSET msg_controles
    mov ah, 9
    int 21h
    mov ah, 0
    int 16h

    ; ✅ Modo gráfico EGA 640x350 16 colores
    mov ax, 10h
    int 10h
    
    call actualizar_camara
    call renderizar
    mov necesita_redibujo, 0

bucle_juego:
    ; Verificar si hay tecla
    mov ah, 1
    int 16h
    jz no_tecla
    jmp hay_tecla
    
no_tecla:
    jmp bucle_juego
    
hay_tecla:
    ; Leer tecla
    mov ah, 0
    int 16h
    
    ; ESC?
    cmp al, 27
    jne check_mover
    jmp terminar
    
check_mover:
    call mover_jugador
    
    ; ¿Necesita redibujo?
    cmp necesita_redibujo, 1
    jne no_redibujar
    jmp hacer_redibujo
    
no_redibujar:
    jmp bucle_juego
    
hacer_redibujo:
    call actualizar_camara
    call renderizar
    mov necesita_redibujo, 0
    jmp bucle_juego

error_carga:
    mov dx, OFFSET msg_error
    mov ah, 9
    int 21h
    mov ah, 0
    int 16h

terminar:
    mov ax, 3
    int 10h
    mov ax, 4C00h
    int 21h

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
    jc csp_error_jmp
    jmp csp_ok
    
csp_error_jmp:
    jmp csp_error
    
csp_ok:
    mov handle_archivo, ax
    mov bx, ax
    
    ; Saltar primera línea
    mov ah, 3Fh
    mov cx, 20
    mov dx, OFFSET buffer_temp
    int 21h
    
    xor si, si
    
csp_leer:
    mov ah, 3Fh
    mov bx, handle_archivo
    mov cx, 200
    mov dx, OFFSET buffer_temp
    int 21h
    
    cmp ax, 0
    jne csp_proc_start
    jmp csp_cerrar
    
csp_proc_start:
    mov cx, ax
    xor bx, bx
    
csp_proc:
    cmp bx, cx
    jb csp_proc_cont
    jmp csp_leer
    
csp_proc_cont:
    mov al, buffer_temp[bx]
    inc bx
    
    ; Filtrar espacios y saltos
    cmp al, ' '
    je csp_proc
    cmp al, 13
    je csp_proc
    cmp al, 10
    je csp_proc
    cmp al, 9
    je csp_proc
    
    ; ¿Es dígito?
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
    jmp csp_cerrar
    
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
    jc csp8_error_jmp
    jmp csp8_ok
    
csp8_error_jmp:
    jmp csp8_error
    
csp8_ok:
    mov handle_archivo, ax
    mov bx, ax
    
    ; Saltar dimensiones
    mov ah, 3Fh
    mov cx, 20
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
    jne csp8_proc_start
    jmp csp8_cerrar
    
csp8_proc_start:
    mov cx, ax
    xor bx, bx
    
csp8_proc:
    cmp bx, cx
    jb csp8_proc_cont
    jmp csp8_leer
    
csp8_proc_cont:
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
    jmp csp8_cerrar
    
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
    jc cm_error_jmp
    jmp cm_ok
    
cm_error_jmp:
    jmp cm_error
    
cm_ok:
    mov handle_archivo, ax
    mov bx, ax
    
    ; Saltar dimensiones
    mov ah, 3Fh
    mov cx, 20
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
    jne cm_proc_start
    jmp cm_cerrar
    
cm_proc_start:
    mov cx, ax
    xor bx, bx
    
cm_proc:
    cmp bx, cx
    jb cm_proc_cont
    jmp cm_leer
    
cm_proc_cont:
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
    jmp cm_cerrar
    
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
mover_jugador PROC
    push ax
    
    mov ax, jugador_x
    mov jugador_x_ant, ax
    mov ax, jugador_y
    mov jugador_y_ant, ax
    
    cmp ah, 48h
    jne mj_check_w
    jmp mj_arr
    
mj_check_w:
    cmp al, 'w'
    je mj_arr
    cmp al, 'W'
    je mj_arr
    
    cmp ah, 50h
    jne mj_check_s
    jmp mj_aba
    
mj_check_s:
    cmp al, 's'
    je mj_aba
    cmp al, 'S'
    je mj_aba
    
    cmp ah, 4Bh
    jne mj_check_a
    jmp mj_izq
    
mj_check_a:
    cmp al, 'a'
    je mj_izq
    cmp al, 'A'
    je mj_izq
    
    cmp ah, 4Dh
    jne mj_check_d
    jmp mj_der
    
mj_check_d:
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
    cmp jugador_y, 48
    jae mj_fin
    inc jugador_y
    jmp mj_chk
    
mj_izq:
    cmp jugador_x, 1
    jbe mj_fin
    dec jugador_x
    jmp mj_chk
    
mj_der:
    cmp jugador_x, 48
    jae mj_fin
    inc jugador_x
    
mj_chk:
    call colision
    jnc mj_ok_jmp
    jmp mj_restaurar
    
mj_ok_jmp:
    jmp mj_ok
    
mj_restaurar:
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
    
    cmp ax, 2500
    jae col_error
    
    mov si, OFFSET mapa_datos
    add si, ax
    mov al, [si]
    
    cmp al, TILE_GRASS
    je col_ok
    cmp al, TILE_PATH
    je col_ok
    
col_error:
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
    jge ac_x1
    xor ax, ax
    
ac_x1:
    mov bx, 50
    sub bx, VIEWPORT_W
    cmp bx, 0
    jle ac_x2
    jmp ac_x3
    
ac_x2:
    xor ax, ax
    jmp ac_x_fin
    
ac_x3:
    cmp ax, bx
    jle ac_x_fin
    mov ax, bx
    
ac_x_fin:
    mov camara_x, ax
    
    ; Centrar Y
    mov ax, jugador_y
    sub ax, VIEWPORT_H/2
    jge ac_y1
    xor ax, ax
    
ac_y1:
    mov bx, 50
    sub bx, VIEWPORT_H
    cmp bx, 0
    jle ac_y2
    jmp ac_y3
    
ac_y2:
    xor ax, ax
    jmp ac_y_fin
    
ac_y3:
    cmp ax, bx
    jle ac_y_fin
    mov ax, bx
    
ac_y_fin:
    mov camara_y, ax
    
    pop bx
    pop ax
    ret
actualizar_camara ENDP

; =====================================================
; RENDERIZAR - CON DOBLE BUFFER EN RAM
; =====================================================
renderizar PROC
    push ax
    push es
    push di
    push cx
    
    ; ✅ PASO 1: Dibujar en buffer de RAM (memoria oculta)
    push ds
    pop es
    mov di, OFFSET buffer_viewport
    mov cx, buffer_viewport_size
    xor ax, ax
    rep stosb
    
    call dibujar_mapa_buffer
    call dibujar_jugador_buffer
    
    ; ✅ PASO 2: Copiar buffer completo a memoria de video
    call copiar_buffer_a_video
    
    pop cx
    pop di
    pop es
    pop ax
    ret
renderizar ENDP

; =====================================================
; DIBUJAR MAPA EN BUFFER RAM
; =====================================================
dibujar_mapa_buffer PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    xor di, di
    
dmb_y:
    cmp di, VIEWPORT_H
    jb dmb_y_ok
    jmp dmb_fin
    
dmb_y_ok:
    xor si, si
    
dmb_x:
    cmp si, VIEWPORT_W
    jb dmb_x_ok
    jmp dmb_ny
    
dmb_x_ok:
    ; Calcular posición en mapa
    mov ax, camara_y
    add ax, di
    cmp ax, 50
    jae dmb_nx
    
    mov bx, camara_x
    add bx, si
    cmp bx, 50
    jae dmb_nx
    
    ; Índice en mapa
    push dx
    mov dx, 50
    mul dx
    add ax, bx
    pop dx
    
    cmp ax, 2500
    jae dmb_nx
    
    ; Obtener tile
    push si
    push di
    push bx
    mov bx, OFFSET mapa_datos
    add bx, ax
    mov al, [bx]
    pop bx
    pop di
    pop si
    
    ; Guardar coordenadas
    push si
    push di
    
    ; Seleccionar sprite
    cmp al, TILE_GRASS
    jne dmb_wall
    mov bp, OFFSET sprite_grass
    jmp dmb_draw
    
dmb_wall:
    cmp al, TILE_WALL
    jne dmb_path
    mov bp, OFFSET sprite_wall
    jmp dmb_draw
    
dmb_path:
    cmp al, TILE_PATH
    jne dmb_water
    mov bp, OFFSET sprite_path
    jmp dmb_draw
    
dmb_water:
    cmp al, TILE_WATER
    jne dmb_tree
    mov bp, OFFSET sprite_water
    jmp dmb_draw
    
dmb_tree:
    cmp al, TILE_TREE
    jne dmb_default
    mov bp, OFFSET sprite_tree
    jmp dmb_draw
    
dmb_default:
    mov bp, OFFSET sprite_grass
    
dmb_draw:
    ; Calcular posición en buffer
    pop di
    pop bx
    
    mov ax, bx
    mov cx, TILE_SIZE
    mul cx
    mov cx, ax
    
    mov ax, di
    mov dx, TILE_SIZE
    mul dx
    mov dx, ax
    
    mov si, bp
    call dibujar_sprite_buffer
    
    mov si, bx
    
dmb_nx:
    inc si
    jmp dmb_x
    
dmb_ny:
    inc di
    jmp dmb_y
    
dmb_fin:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_mapa_buffer ENDP

; =====================================================
; DIBUJAR SPRITE EN BUFFER RAM
; CX = X, DX = Y, SI = dirección sprite
; =====================================================
dibujar_sprite_buffer PROC
    push ax
    push bx
    push cx
    push dx
    push di
    push si
    
    cmp cx, 320 - 16
    jae dsb_fin_jmp
    cmp dx, 192 - 16
    jae dsb_fin_jmp
    jmp dsb_ok
    
dsb_fin_jmp:
    jmp dsb_fin
    
dsb_ok:
    xor bx, bx
    
dsb_y:
    cmp bx, 16
    jb dsb_y_ok
    jmp dsb_fin
    
dsb_y_ok:
    ; Calcular offset en buffer
    mov ax, dx
    add ax, bx
    push dx
    mov dx, 320
    mul dx
    pop dx
    add ax, cx
    
    ; Convertir a offset en buffer_viewport
    mov di, OFFSET buffer_viewport
    add di, ax
    
    push cx
    push bx
    mov cx, 16
    
dsb_x:
    mov al, [si]
    cmp al, 0
    je dsb_skip_px
    
    mov [di], al
    
dsb_skip_px:
    inc di
    inc si
    loop dsb_x
    
    pop bx
    pop cx
    
    inc bx
    jmp dsb_y
    
dsb_fin:
    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_sprite_buffer ENDP

; =====================================================
; DIBUJAR JUGADOR EN BUFFER
; =====================================================
dibujar_jugador_buffer PROC
    push ax
    push bx
    push cx
    push dx
    
    ; Verificar viewport
    mov ax, jugador_x
    sub ax, camara_x
    js djb_fin_jmp
    cmp ax, VIEWPORT_W
    jae djb_fin_jmp
    jmp djb_ok1
    
djb_fin_jmp:
    jmp djb_fin
    
djb_ok1:
    mov bx, jugador_y
    sub bx, camara_y
    js djb_fin_jmp
    cmp bx, VIEWPORT_H
    jae djb_fin_jmp
    
    ; Convertir a píxeles
    shl ax, 4
    add ax, 4
    mov cx, ax
    
    shl bx, 4
    add bx, 4
    mov dx, bx
    
    ; Dibujar en buffer
    mov al, 14
    call dibujar_rect_buffer
    
djb_fin:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_jugador_buffer ENDP

; =====================================================
; DIBUJAR RECTÁNGULO EN BUFFER
; CX = X, DX = Y, AL = color
; =====================================================
dibujar_rect_buffer PROC
    push ax
    push bx
    push cx
    push dx
    push di
    push si

    mov bl, al
    xor si, si
    
drb_y:
    cmp si, 8
    jb drb_y_ok
    jmp drb_fin
    
drb_y_ok:
    mov ax, dx
    add ax, si
    push dx
    mov dx, 320
    mul dx
    pop dx
    add ax, cx
    
    mov di, OFFSET buffer_viewport
    add di, ax
    
    push cx
    push bx
    mov cx, 8
    
drb_x:
    mov al, bl
    mov [di], al
    inc di
    loop drb_x
    
    pop bx
    pop cx
    
    inc si
    jmp drb_y

drb_fin:
    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_rect_buffer ENDP

; =====================================================
; COPIAR BUFFER A MEMORIA DE VIDEO
; ✅ Esta es la "transición suave" del doble buffer
; =====================================================
copiar_buffer_a_video PROC
    push ax
    push cx
    push si
    push di
    push es
    push ds
    
    ; ES = memoria de video
    mov ax, VIDEO_SEG
    mov es, ax
    
    ; DS = segmento de datos
    mov ax, @data
    mov ds, ax
    
    ; SI = buffer fuente
    mov si, OFFSET buffer_viewport
    
    ; DI = inicio viewport en video (centrado en pantalla)
    ; X = (640 - 320) / 2 = 160
    ; Y = (350 - 192) / 2 = 79
    mov ax, 79
    mov bx, 80              ; 640/8 = 80 bytes por línea en EGA
    mul bx
    add ax, 160 / 8         ; 160 píxeles = 20 bytes
    mov di, ax
    
    ; Copiar línea por línea
    mov cx, 192             ; 192 líneas
    
cbv_linea:
    push cx
    push di
    push si
    
    ; Copiar 320 píxeles = 40 bytes (320/8)
    mov cx, 40
    rep movsb
    
    pop si
    pop di
    pop cx
    
    ; Siguiente línea en buffer
    add si, 320
    
    ; Siguiente línea en video
    add di, 80
    
    loop cbv_linea
    
    pop ds
    pop es
    pop di
    pop si
    pop cx
    pop ax
    ret
copiar_buffer_a_video ENDP

END inicio