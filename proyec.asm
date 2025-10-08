; Proyecto de Exploración - OPTIMIZADO CON DOUBLE BUFFER
; 8086/8088 TASM - Modo EGA 640x350 16 colores
; Sistema de viewport con renderizado directo a memoria

.MODEL SMALL
.STACK 512

; === CONSTANTES ===
TILE_SIZE       EQU 16
MAP_MAX_W       EQU 100
MAP_MAX_H       EQU 100
VIEWPORT_W      EQU 10          ; Tiles visibles (10 * 16 = 160px)
VIEWPORT_H      EQU 6           ; Tiles visibles (6 * 16 = 96px)
SCREEN_W        EQU 640
SCREEN_H        EQU 350

; Tipos de tiles
TILE_GRASS      EQU 0
TILE_WALL       EQU 1  
TILE_PATH       EQU 2
TILE_WATER      EQU 3
TILE_TREE       EQU 4
TILE_ROCK       EQU 5

; Segmentos de memoria
VIDEO_SEG       EQU 0A000h
BUFFER_SEG      EQU 09000h      ; Segmento para buffer

.DATA
; === MAPA Y RECURSOS ===
map_width       dw 0
map_height      dw 0
map_data        db MAP_MAX_W * MAP_MAX_H dup(0)
resources       db 50 * 5 dup(0)
num_resources   dw 0

; === ESTADO DEL JUEGO ===
player_x        dw 5
player_y        dw 5
camera_x        dw 0
camera_y        dw 0

; === SPRITES (Solo datos, sin dimensiones repetidas) ===
sprite_grass    db 256 dup(2)   ; Verde oscuro
sprite_wall     db 256 dup(8)   ; Gris
sprite_path     db 256 dup(6)   ; Marrón
sprite_water    db 256 dup(9)   ; Azul claro
sprite_tree     db 256 dup(10)  ; Verde claro
sprite_rock     db 256 dup(7)   ; Gris claro
sprite_player   db 64 dup(14)   ; Amarillo

; === MENSAJES ===
msg_loading     db 'Cargando...$'
msg_success     db 13,10,'Listo! [ESC]=Salir [WASD/Flechas]=Mover$'

.CODE
main PROC
    mov ax, @data
    mov ds, ax
    
    ; Mostrar mensaje
    mov dx, OFFSET msg_loading
    mov ah, 09h
    int 21h
    
    ; Crear mapa por defecto
    call CreateDefaultMap
    call InitSprites
    
    ; Mostrar instrucciones
    mov dx, OFFSET msg_success
    mov ah, 09h
    int 21h
    
    ; Esperar tecla
    mov ah, 00h
    int 16h
    
    ; Configurar modo EGA 640x350 16 colores
    mov ax, 0010h
    int 10h
    
    ; Configurar segmento extra para buffer
    mov ax, BUFFER_SEG
    mov es, ax
    
    ; Limpiar buffer
    call ClearBuffer
    
    ; Render inicial
    call UpdateCamera
    call RenderToBuffer
    call CopyBufferToScreen
    
    ; === GAME LOOP ===
game_loop:
    ; Revisar tecla (no bloqueante)
    mov ah, 01h
    int 16h
    jz game_loop            ; Si no hay tecla, seguir esperando
    
    ; Leer tecla
    mov ah, 00h
    int 16h
    
    ; ESC = salir
    cmp al, 27
    je exit_game
    
    ; Guardar posición anterior
    push player_x
    push player_y
    
    ; Procesar movimiento
    call ProcessInput
    jnc input_moved         ; Si CF=0, hubo movimiento
    
    ; No hubo movimiento
    pop ax
    pop ax
    jmp game_loop

input_moved:
    ; Verificar colisión
    call CheckCollision
    jnc move_ok             ; Si CF=0, no hay colisión
    
    ; Hay colisión, restaurar posición
    pop player_y
    pop player_x
    jmp game_loop

move_ok:
    pop ax                  ; Limpiar stack
    pop ax
    
    ; Actualizar y redibujar
    call UpdateCamera
    call ClearBuffer
    call RenderToBuffer
    call CopyBufferToScreen
    
    jmp game_loop

exit_game:
    ; Volver a modo texto
    mov ax, 0003h
    int 10h
    
    ; Salir al DOS
    mov ax, 4C00h
    int 21h
main ENDP

; === PROCESAR INPUT ===
ProcessInput PROC
    ; AH = scan code, AL = ASCII
    ; Retorna CF=1 si no hubo movimiento, CF=0 si sí
    
    ; Flechas
    cmp ah, 48h             ; Arriba
    je pi_up
    cmp ah, 50h             ; Abajo
    je pi_down
    cmp ah, 4Bh             ; Izquierda
    je pi_left
    cmp ah, 4Dh             ; Derecha
    je pi_right
    
    ; WASD
    cmp al, 'w'
    je pi_up
    cmp al, 'W'
    je pi_up
    cmp al, 's'
    je pi_down
    cmp al, 'S'
    je pi_down
    cmp al, 'a'
    je pi_left
    cmp al, 'A'
    je pi_left
    cmp al, 'd'
    je pi_right
    cmp al, 'D'
    je pi_right
    
    ; No es movimiento
    stc
    ret

pi_up:
    cmp player_y, 1
    jle pi_no_move
    dec player_y
    clc
    ret

pi_down:
    mov ax, player_y
    inc ax
    cmp ax, map_height
    jge pi_no_move
    inc player_y
    clc
    ret

pi_left:
    cmp player_x, 1
    jle pi_no_move
    dec player_x
    clc
    ret

pi_right:
    mov ax, player_x
    inc ax
    cmp ax, map_width
    jge pi_no_move
    inc player_x
    clc
    ret

pi_no_move:
    stc
    ret
ProcessInput ENDP

; === VERIFICAR COLISIÓN ===
CheckCollision PROC
    push ax
    push bx
    push si
    
    ; Calcular offset en mapa
    mov ax, player_y
    mov bx, map_width
    mul bx
    add ax, player_x
    mov si, ax
    add si, OFFSET map_data
    
    ; Obtener tipo de tile
    mov al, [si]
    
    ; Tiles transitables
    cmp al, TILE_GRASS
    je cc_ok
    cmp al, TILE_PATH
    je cc_ok
    
    ; Obstáculo
    stc
    jmp cc_exit

cc_ok:
    clc

cc_exit:
    pop si
    pop bx
    pop ax
    ret
CheckCollision ENDP

; === ACTUALIZAR CÁMARA ===
UpdateCamera PROC
    push ax
    push bx
    
    ; Centrar en X
    mov ax, player_x
    sub ax, 5               ; VIEWPORT_W / 2
    jns uc_x_ok
    xor ax, ax
uc_x_ok:
    mov bx, map_width
    sub bx, VIEWPORT_W
    cmp ax, bx
    jle uc_x_set
    mov ax, bx
uc_x_set:
    mov camera_x, ax
    
    ; Centrar en Y
    mov ax, player_y
    sub ax, 3               ; VIEWPORT_H / 2
    jns uc_y_ok
    xor ax, ax
uc_y_ok:
    mov bx, map_height
    sub bx, VIEWPORT_H
    cmp ax, bx
    jle uc_y_set
    mov ax, bx
uc_y_set:
    mov camera_y, ax
    
    pop bx
    pop ax
    ret
UpdateCamera ENDP

; === LIMPIAR BUFFER ===
ClearBuffer PROC
    push ax
    push cx
    push di
    push es
    
    mov ax, BUFFER_SEG
    mov es, ax
    xor di, di
    xor ax, ax              ; Color negro
    mov cx, 32000           ; 64000 bytes / 2
    rep stosw
    
    pop es
    pop di
    pop cx
    pop ax
    ret
ClearBuffer ENDP

; === RENDERIZAR TODO AL BUFFER ===
RenderToBuffer PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Para cada tile visible
    xor dx, dx              ; Y del viewport (0-5)

rtb_row:
    cmp dx, VIEWPORT_H
    jge rtb_done
    
    xor cx, cx              ; X del viewport (0-9)

rtb_col:
    cmp cx, VIEWPORT_W
    jge rtb_next_row
    
    push cx
    push dx
    
    ; Calcular posición en mapa
    mov ax, camera_y
    add ax, dx
    mov bx, map_width
    mul bx
    add ax, camera_x
    add ax, cx
    mov si, ax
    add si, OFFSET map_data
    
    ; Obtener tipo de tile
    xor ah, ah
    mov al, [si]
    
    ; Calcular posición en pantalla
    pop bx                  ; Y del viewport
    push bx
    shl bx, 4               ; Y * 16
    
    pop dx
    pop cx
    push cx
    push dx
    
    mov dx, cx
    shl dx, 4               ; X * 16
    
    ; Dibujar tile al buffer
    call DrawTileToBuffer
    
    pop dx
    pop cx
    inc cx
    jmp rtb_col

rtb_next_row:
    inc dx
    jmp rtb_row

rtb_done:
    ; Dibujar jugador
    call DrawPlayerToBuffer
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
RenderToBuffer ENDP

; === DIBUJAR TILE AL BUFFER ===
; Entrada: AL=tipo, DX=X, BX=Y
DrawTileToBuffer PROC
    push ax
    push si
    
    ; Seleccionar sprite
    mov si, OFFSET sprite_grass
    cmp al, TILE_WALL
    jne dttb_2
    mov si, OFFSET sprite_wall
    jmp dttb_draw
dttb_2:
    cmp al, TILE_PATH
    jne dttb_3
    mov si, OFFSET sprite_path
    jmp dttb_draw
dttb_3:
    cmp al, TILE_WATER
    jne dttb_4
    mov si, OFFSET sprite_water
    jmp dttb_draw
dttb_4:
    cmp al, TILE_TREE
    jne dttb_5
    mov si, OFFSET sprite_tree
    jmp dttb_draw
dttb_5:
    cmp al, TILE_ROCK
    jne dttb_draw
    mov si, OFFSET sprite_rock

dttb_draw:
    ; DX=X, BX=Y, SI=sprite
    push cx
    mov cx, 16              ; Ancho
    push bx
    mov bx, 16              ; Alto
    call DrawSpriteToBuffer
    pop bx
    pop cx
    
    pop si
    pop ax
    ret
DrawTileToBuffer ENDP

; === DIBUJAR SPRITE AL BUFFER ===
; Entrada: SI=datos, DX=X, BX=Y, CX=ancho, BX en stack=alto
DrawSpriteToBuffer PROC
    push ax
    push bx
    push cx
    push dx
    push di
    push es
    
    mov ax, BUFFER_SEG
    mov es, ax
    
    ; Calcular offset inicial: Y*80 + X/8
    mov ax, bx
    mov di, 80
    mul di
    mov di, ax              ; DI = Y * 80
    
    mov ax, dx
    shr ax, 3               ; X / 8
    add di, ax              ; DI = offset base
    
    ; Obtener alto del stack
    mov bp, sp
    mov bx, [bp+12]         ; Alto (ajustado por pushes)
    
    ; Para cada fila
dstb_row:
    cmp bx, 0
    je dstb_done
    
    push di
    push cx
    push dx
    
    ; Para cada pixel de la fila
dstb_pixel:
    cmp cx, 0
    je dstb_next_row
    
    ; Leer color
    lodsb
    
    ; Si no es transparente
    cmp al, 0
    je dstb_skip
    
    ; Escribir pixel
    push ax
    push bx
    push cx
    push dx
    
    ; Calcular posición exacta
    mov ax, dx
    and ax, 7               ; X mod 8
    mov cl, al
    mov al, 80h
    shr al, cl              ; Máscara de bit
    
    ; Escribir en plano de color
    push di
    mov ah, al
    mov al, 8               ; Bit Mask Register
    mov dx, 03CEh
    out dx, ax
    
    mov al, [es:di]         ; Latch
    mov [es:di], ah         ; Escribir
    pop di
    
    pop dx
    pop cx
    pop bx
    pop ax

dstb_skip:
    inc dx                  ; Siguiente X
    
    ; Si cruzamos byte
    test dl, 7
    jnz dstb_same_byte
    inc di                  ; Siguiente byte

dstb_same_byte:
    dec cx
    jmp dstb_pixel

dstb_next_row:
    pop dx
    pop cx
    pop di
    add di, 80              ; Siguiente fila
    dec bx
    jmp dstb_row

dstb_done:
    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DrawSpriteToBuffer ENDP

; === DIBUJAR JUGADOR AL BUFFER ===
DrawPlayerToBuffer PROC
    push ax
    push bx
    push cx
    push dx
    push si
    
    ; Calcular posición en viewport
    mov ax, player_x
    sub ax, camera_x
    cmp ax, VIEWPORT_W
    jge dptb_done
    
    mov dx, ax
    shl dx, 4
    add dx, 4               ; Centrar en tile
    
    mov ax, player_y
    sub ax, camera_y
    cmp ax, VIEWPORT_H
    jge dptb_done
    
    mov bx, ax
    shl bx, 4
    add bx, 4               ; Centrar en tile
    
    ; Dibujar sprite
    mov si, OFFSET sprite_player
    mov cx, 8               ; Ancho
    push bx
    mov bx, 8               ; Alto
    call DrawSpriteToBuffer
    pop bx

dptb_done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DrawPlayerToBuffer ENDP

; === COPIAR BUFFER A PANTALLA ===
CopyBufferToScreen PROC
    push ax
    push cx
    push si
    push di
    push ds
    push es
    
    ; DS = buffer, ES = video
    mov ax, BUFFER_SEG
    mov ds, ax
    mov ax, VIDEO_SEG
    mov es, ax
    
    xor si, si
    xor di, di
    mov cx, 32000           ; 64000 / 2
    rep movsw
    
    pop es
    pop ds
    pop di
    pop si
    pop cx
    pop ax
    ret
CopyBufferToScreen ENDP

; === CREAR MAPA POR DEFECTO ===
CreateDefaultMap PROC
    push ax
    push bx
    push cx
    push di
    
    mov map_width, 20
    mov map_height, 15
    
    ; Patrón simple
    mov di, OFFSET map_data
    mov cx, 300
    xor bx, bx

cdm_loop:
    mov ax, bx
    and ax, 15
    cmp al, 0
    jne cdm_1
    mov byte ptr [di], TILE_WALL
    jmp cdm_next
cdm_1:
    cmp al, 5
    jne cdm_2
    mov byte ptr [di], TILE_WATER
    jmp cdm_next
cdm_2:
    cmp al, 10
    jne cdm_3
    mov byte ptr [di], TILE_TREE
    jmp cdm_next
cdm_3:
    mov byte ptr [di], TILE_GRASS

cdm_next:
    inc di
    inc bx
    loop cdm_loop
    
    call CreateBorders
    
    pop di
    pop cx
    pop bx
    pop ax
    ret
CreateDefaultMap ENDP

; === CREAR BORDES ===
CreateBorders PROC
    push ax
    push bx
    push cx
    push di
    
    ; Borde superior
    mov di, OFFSET map_data
    mov cx, map_width
cb_top:
    mov byte ptr [di], TILE_WALL
    inc di
    loop cb_top
    
    ; Borde inferior
    mov ax, map_height
    dec ax
    mul map_width
    add ax, OFFSET map_data
    mov di, ax
    mov cx, map_width
cb_bottom:
    mov byte ptr [di], TILE_WALL
    inc di
    loop cb_bottom
    
    ; Bordes laterales
    mov cx, map_height
    mov di, OFFSET map_data
cb_sides:
    mov byte ptr [di], TILE_WALL
    push di
    add di, map_width
    dec di
    mov byte ptr [di], TILE_WALL
    pop di
    add di, map_width
    loop cb_sides
    
    pop di
    pop cx
    pop bx
    pop ax
    ret
CreateBorders ENDP

; === INICIALIZAR SPRITES ===
InitSprites PROC
    push ax
    push cx
    push di
    
    ; Sprites ya inicializados con valores por defecto
    ; Esta versión optimizada usa inicialización estática
    
    pop di
    pop cx
    pop ax
    ret
InitSprites ENDP

END main