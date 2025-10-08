; Proyecto de Exploración - Fase 1
; 8086/8088 TASM - Modo EGA 640x350 16 colores
; Implementa: Viewport, Doble Buffer, Movimiento

.MODEL SMALL
.STACK 256

; === CONSTANTES ===
TILE_SIZE       EQU 16
MAP_MAX_W       EQU 100
MAP_MAX_H       EQU 100
VIEWPORT_W      EQU 160     ; 10 tiles x 16
VIEWPORT_H      EQU 96      ; 6 tiles x 16
SCREEN_W        EQU 640
SCREEN_H        EQU 350

; Tipos de tiles
TILE_GRASS      EQU 0
TILE_WALL       EQU 1  
TILE_PATH       EQU 2
TILE_WATER      EQU 3
TILE_TREE       EQU 4
TILE_ROCK       EQU 5

.DATA
; === MAPA Y RECURSOS ===
map_width       dw 0
map_height      dw 0
map_data        db MAP_MAX_W * MAP_MAX_H dup(0)

; Recursos (máx 50)
resources       db 50 * 5 dup(0)   ; R, X, Y, Tipo, Cantidad
num_resources   dw 0

; === BUFFERS ===
buffer_seg      dw 0                ; Segmento para doble buffer

; === ESTADO DEL JUEGO ===
player_x        dw 3                ; Posición en tiles
player_y        dw 3
camera_x        dw 0
camera_y        dw 0

; === ARCHIVOS ===
map_file        db 'mapa.txt',0
file_handle     dw 0

; === MENSAJES ===
msg_loading     db 'Cargando mapa...$'
msg_error       db 'Error: No se pudo cargar mapa.txt$'
msg_start       db 'Use flechas para mover, ESC para salir$'

; === BUFFERS DE LECTURA ===
line_buffer     db 256 dup(0)
temp_number     dw 0

.CODE
main PROC
    mov ax, @data
    mov ds, ax
    
    ; Mostrar mensaje de carga
    mov dx, OFFSET msg_loading
    mov ah, 09h
    int 21h
    
    ; Reservar memoria para doble buffer
    call AllocateBuffer
    jc main_error
    
    ; Cargar mapa desde archivo
    call LoadMap
    jc main_error
    
    ; Inicializar modo gráfico EGA
    mov ax, 0010h
    int 10h
    
    ; Inicializar cámara
    call UpdateCamera
    
game_loop:
    ; Limpiar buffer
    call ClearBuffer
    
    ; Dibujar mundo en buffer
    call RenderWorld
    
    ; Dibujar jugador
    call RenderPlayer
    
    ; Dibujar recursos
    call RenderResources
    
    ; Copiar buffer a pantalla
    call FlipBuffer
    
    ; Verificar input
    mov ah, 01h
    int 16h
    jz game_loop
    
    ; Leer tecla
    mov ah, 00h
    int 16h
    
    ; Procesar teclas
    cmp ah, 48h     ; Arriba
    je move_up
    cmp ah, 50h     ; Abajo
    je move_down
    cmp ah, 4Bh     ; Izquierda
    je move_left
    cmp ah, 4Dh     ; Derecha
    je move_right
    cmp al, 27      ; ESC
    je main_exit
    jmp game_loop

move_up:
    cmp player_y, 1
    jbe game_loop
    dec player_y
    call CheckCollision
    jc move_up_undo
    call UpdateCamera
    jmp game_loop
move_up_undo:
    inc player_y
    jmp game_loop

move_down:
    mov ax, player_y
    inc ax
    cmp ax, map_height
    jae game_loop
    inc player_y
    call CheckCollision
    jc move_down_undo
    call UpdateCamera
    jmp game_loop
move_down_undo:
    dec player_y
    jmp game_loop

move_left:
    cmp player_x, 1
    jbe game_loop
    dec player_x
    call CheckCollision
    jc move_left_undo
    call UpdateCamera
    jmp game_loop
move_left_undo:
    inc player_x
    jmp game_loop

move_right:
    mov ax, player_x
    inc ax
    cmp ax, map_width
    jae game_loop
    inc player_x
    call CheckCollision
    jc move_right_undo
    call UpdateCamera
    jmp game_loop
move_right_undo:
    dec player_x
    jmp game_loop

main_error:
    mov dx, OFFSET msg_error
    mov ah, 09h
    int 21h
    mov ah, 00h
    int 16h

main_exit:
    call FreeBuffer
    mov ax, 0003h
    int 10h
    mov ax, 4C00h
    int 21h
main ENDP

; === CARGAR MAPA DESDE ARCHIVO ===
LoadMap PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Abrir archivo
    mov dx, OFFSET map_file
    mov ax, 3D00h
    int 21h
    jc lm_error
    mov file_handle, ax
    
    ; Leer dimensiones
    call ReadLine
    call ParseDimensions
    jc lm_close_error
    
    ; Validar dimensiones
    cmp map_width, 0
    je lm_close_error
    cmp map_width, MAP_MAX_W
    ja lm_close_error
    cmp map_height, 0
    je lm_close_error
    cmp map_height, MAP_MAX_H
    ja lm_close_error
    
    ; Leer datos del mapa
    mov cx, map_height
    xor si, si          ; Índice de fila
lm_read_rows:
    push cx
    call ReadLine
    call ParseMapRow
    pop cx
    inc si
    loop lm_read_rows
    
    ; Leer recursos (líneas que empiezan con R)
    xor di, di
lm_read_resources:
    call ReadLine
    mov al, line_buffer
    cmp al, 0
    je lm_close
    cmp al, 'R'
    jne lm_read_resources
    
    call ParseResource
    inc di
    cmp di, 50
    jl lm_read_resources
    
lm_close:
    mov num_resources, di
    mov bx, file_handle
    mov ah, 3Eh
    int 21h
    clc
    jmp lm_exit
    
lm_close_error:
    mov bx, file_handle
    mov ah, 3Eh
    int 21h
    
lm_error:
    stc
    
lm_exit:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
LoadMap ENDP

; === LEER LÍNEA DEL ARCHIVO ===
ReadLine PROC
    push ax
    push bx
    push cx
    push dx
    push di
    
    ; Limpiar buffer
    mov di, OFFSET line_buffer
    mov cx, 256
    xor al, al
    rep stosb
    
    mov di, OFFSET line_buffer
    mov bx, file_handle
    
rl_loop:
    ; Leer un byte
    mov cx, 1
    mov dx, di
    mov ah, 3Fh
    int 21h
    jc rl_done
    cmp ax, 0
    je rl_done
    
    ; Verificar fin de línea
    mov al, [di]
    cmp al, 10      ; LF
    je rl_done
    cmp al, 13      ; CR
    je rl_loop      ; Ignorar CR
    
    inc di
    cmp di, OFFSET line_buffer + 255
    jl rl_loop
    
rl_done:
    mov byte ptr [di], 0
    
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ReadLine ENDP

; === PARSEAR DIMENSIONES ===
ParseDimensions PROC
    push si
    
    mov si, OFFSET line_buffer
    call ParseNumber
    mov map_width, ax
    call SkipSpaces
    call ParseNumber
    mov map_height, ax
    
    pop si
    ret
ParseDimensions ENDP

; === PARSEAR FILA DEL MAPA ===
ParseMapRow PROC
    push ax
    push bx
    push cx
    push si
    push di
    
    mov bx, si          ; Fila actual
    mov ax, map_width
    mul bx
    mov di, ax
    add di, OFFSET map_data
    
    mov si, OFFSET line_buffer
    xor cx, cx          ; Columna
    
pmr_loop:
    cmp cx, map_width
    jge pmr_done
    
    call SkipSpaces
    call ParseNumber
    mov [di], al
    inc di
    inc cx
    jmp pmr_loop
    
pmr_done:
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret
ParseMapRow ENDP

; === PARSEAR RECURSO ===
ParseResource PROC
    push ax
    push bx
    push si
    push di
    
    mov si, OFFSET line_buffer
    inc si              ; Saltar 'R'
    
    mov ax, num_resources
    mov bx, 5
    mul bx
    mov di, ax
    add di, OFFSET resources
    
    mov byte ptr [di], 'R'
    inc di
    
    call SkipSpaces
    call ParseNumber
    mov [di], al        ; X
    inc di
    
    call SkipSpaces
    call ParseNumber
    mov [di], al        ; Y
    inc di
    
    call SkipSpaces
    call ParseNumber
    mov [di], al        ; Tipo
    inc di
    
    call SkipSpaces
    call ParseNumber
    mov [di], al        ; Cantidad
    
    pop di
    pop si
    pop bx
    pop ax
    ret
ParseResource ENDP

; === PARSEAR NÚMERO ===
ParseNumber PROC
    push bx
    push cx
    
    xor ax, ax
    xor bx, bx
    
pn_loop:
    mov bl, [si]
    cmp bl, '0'
    jb pn_done
    cmp bl, '9'
    ja pn_done
    
    sub bl, '0'
    mov cx, 10
    mul cx
    add ax, bx
    inc si
    jmp pn_loop
    
pn_done:
    pop cx
    pop bx
    ret
ParseNumber ENDP

; === SALTAR ESPACIOS ===
SkipSpaces PROC
    push ax
ss_loop:
    mov al, [si]
    cmp al, ' '
    je ss_next
    cmp al, 9       ; TAB
    je ss_next
    pop ax
    ret
ss_next:
    inc si
    jmp ss_loop
SkipSpaces ENDP

; === VERIFICAR COLISIÓN ===
CheckCollision PROC
    push ax
    push bx
    push si
    
    ; Obtener tile en posición del jugador
    mov ax, player_y
    mul map_width
    add ax, player_x
    mov si, ax
    add si, OFFSET map_data
    
    mov al, [si]
    cmp al, TILE_WALL
    je cc_collision
    cmp al, TILE_WATER
    je cc_collision
    cmp al, TILE_TREE
    je cc_collision
    cmp al, TILE_ROCK
    je cc_collision
    
    clc
    jmp cc_exit
    
cc_collision:
    stc
    
cc_exit:
    pop si
    pop bx
    pop ax
    ret
CheckCollision ENDP

; === ACTUALIZAR CÁMARA ===
UpdateCamera PROC
    push ax
    
    ; Centrar en jugador X
    mov ax, player_x
    sub ax, 5
    cmp ax, 0
    jge uc_check_max_x
    xor ax, ax
uc_check_max_x:
    push ax
    mov ax, map_width
    sub ax, 10
    mov bx, ax
    pop ax
    cmp ax, bx
    jle uc_set_x
    mov ax, bx
uc_set_x:
    mov camera_x, ax
    
    ; Centrar en jugador Y
    mov ax, player_y
    sub ax, 3
    cmp ax, 0
    jge uc_check_max_y
    xor ax, ax
uc_check_max_y:
    push ax
    mov ax, map_height
    sub ax, 6
    mov bx, ax
    pop ax
    cmp ax, bx
    jle uc_set_y
    mov ax, bx
uc_set_y:
    mov camera_y, ax
    
    pop ax
    ret
UpdateCamera ENDP

; === RENDERIZAR MUNDO ===
RenderWorld PROC
    push ax
    push bx
    push cx
    push dx
    push si
    
    xor cx, cx      ; Fila viewport
rw_row:
    cmp cx, 6
    jge rw_done
    
    xor bx, bx      ; Columna viewport
rw_col:
    cmp bx, 10
    jge rw_next_row
    
    ; Obtener tile del mapa
    push bx
    push cx
    
    mov ax, camera_y
    add ax, cx
    mul map_width
    add ax, camera_x
    add ax, bx
    mov si, ax
    add si, OFFSET map_data
    mov dl, [si]
    
    ; Calcular posición en pantalla
    mov ax, bx
    shl ax, 4       ; * 16
    push ax
    mov ax, cx
    shl ax, 4       ; * 16
    mov cx, ax
    pop bx
    
    call DrawTile
    
    pop cx
    pop bx
    
    inc bx
    jmp rw_col
    
rw_next_row:
    inc cx
    jmp rw_row
    
rw_done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
RenderWorld ENDP

; === DIBUJAR TILE ===
DrawTile PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Seleccionar color según tipo
    cmp dl, TILE_GRASS
    jne dt_check1
    mov dl, 2       ; Verde
    jmp dt_draw
dt_check1:
    cmp dl, TILE_WALL
    jne dt_check2
    mov dl, 4       ; Rojo
    jmp dt_draw
dt_check2:
    cmp dl, TILE_PATH
    jne dt_check3
    mov dl, 6       ; Marrón
    jmp dt_draw
dt_check3:
    cmp dl, TILE_WATER
    jne dt_check4
    mov dl, 1       ; Azul
    jmp dt_draw
dt_check4:
    cmp dl, TILE_TREE
    jne dt_check5
    mov dl, 10      ; Verde claro
    jmp dt_draw
dt_check5:
    cmp dl, TILE_ROCK
    jne dt_default
    mov dl, 8       ; Gris
    jmp dt_draw
dt_default:
    mov dl, 7       ; Blanco
    
dt_draw:
    ; Dibujar cuadrado 16x16 en buffer
    mov si, 0
dt_row_loop:
    cmp si, TILE_SIZE
    jge dt_done
    
    push cx
    push bx
    
    mov di, 0
dt_col_loop:
    cmp di, TILE_SIZE
    jge dt_next_row
    
    call PutPixelBuffer
    inc bx
    inc di
    jmp dt_col_loop
    
dt_next_row:
    pop bx
    pop cx
    inc cx
    inc si
    jmp dt_row_loop
    
dt_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DrawTile ENDP

; === RENDERIZAR JUGADOR ===
RenderPlayer PROC
    push ax
    push bx
    push cx
    push dx
    
    ; Posición relativa al viewport
    mov ax, player_x
    sub ax, camera_x
    shl ax, 4
    add ax, 4
    mov bx, ax
    
    mov ax, player_y
    sub ax, camera_y
    shl ax, 4
    add ax, 4
    mov cx, ax
    
    ; Dibujar cuadrado amarillo 8x8
    mov dl, 14      ; Amarillo
    mov si, 0
rp_row:
    cmp si, 8
    jge rp_done
    
    push cx
    push bx
    mov di, 0
rp_col:
    cmp di, 8
    jge rp_next
    
    call PutPixelBuffer
    inc bx
    inc di
    jmp rp_col
    
rp_next:
    pop bx
    pop cx
    inc cx
    inc si
    jmp rp_row
    
rp_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
RenderPlayer ENDP

; === RENDERIZAR RECURSOS ===
RenderResources PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov cx, num_resources
    cmp cx, 0
    je rr_done
    
    mov si, OFFSET resources
rr_loop:
    push cx
    
    ; Verificar si es recurso válido
    cmp byte ptr [si], 'R'
    jne rr_next
    
    ; Obtener coordenadas
    xor ah, ah
    mov al, [si+1]      ; X
    mov bx, ax
    mov al, [si+2]      ; Y
    mov dx, ax
    
    ; Verificar si está en viewport
    cmp bx, camera_x
    jl rr_next
    mov ax, camera_x
    add ax, 10
    cmp bx, ax
    jge rr_next
    
    cmp dx, camera_y
    jl rr_next
    mov ax, camera_y
    add ax, 6
    cmp dx, ax
    jge rr_next
    
    ; Calcular posición en pantalla
    sub bx, camera_x
    shl bx, 4
    add bx, 6           ; Centrar
    
    sub dx, camera_y
    shl dx, 4
    add dx, 6
    mov cx, dx
    
    ; Color según tipo
    mov al, [si+3]
    cmp al, 1
    jne rr_type2
    mov dl, 12          ; Rojo claro
    jmp rr_draw
rr_type2:
    cmp al, 2
    jne rr_type3
    mov dl, 11          ; Cyan claro
    jmp rr_draw
rr_type3:
    mov dl, 13          ; Magenta claro
    
rr_draw:
    ; Dibujar diamante 4x4
    push si
    call DrawDiamond
    pop si
    
rr_next:
    add si, 5
    pop cx
    loop rr_loop
    
rr_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
RenderResources ENDP

; === DIBUJAR DIAMANTE ===
DrawDiamond PROC
    push bx
    push cx
    
    call PutPixelBuffer
    inc bx
    call PutPixelBuffer
    inc bx
    call PutPixelBuffer
    inc bx
    call PutPixelBuffer
    
    sub bx, 3
    inc cx
    call PutPixelBuffer
    add bx, 3
    call PutPixelBuffer
    
    sub bx, 3
    inc cx
    call PutPixelBuffer
    inc bx
    call PutPixelBuffer
    inc bx
    call PutPixelBuffer
    inc bx
    call PutPixelBuffer
    
    pop cx
    pop bx
    ret
DrawDiamond ENDP

; === ALLOCAR BUFFER ===
AllocateBuffer PROC
    push bx
    
    mov bx, 200     ; Párrafos para buffer
    mov ah, 48h
    int 21h
    jc ab_error
    
    mov buffer_seg, ax
    clc
    jmp ab_done
    
ab_error:
    stc
    
ab_done:
    pop bx
    ret
AllocateBuffer ENDP

; === LIBERAR BUFFER ===
FreeBuffer PROC
    push ax
    push es
    
    mov ax, buffer_seg
    or ax, ax
    jz fb_done
    
    mov es, ax
    mov ah, 49h
    int 21h
    
fb_done:
    pop es
    pop ax
    ret
FreeBuffer ENDP

; === LIMPIAR BUFFER ===
ClearBuffer PROC
    push ax
    push cx
    push di
    push es
    
    mov ax, buffer_seg
    mov es, ax
    xor di, di
    xor ax, ax
    mov cx, 1600
    rep stosw
    
    pop es
    pop di
    pop cx
    pop ax
    ret
ClearBuffer ENDP

; === PONER PIXEL EN BUFFER ===
PutPixelBuffer PROC
    push ax
    push bx
    push cx
    push di
    push es
    
    ; Verificar límites
    cmp bx, VIEWPORT_W
    jae ppb_done
    cmp cx, VIEWPORT_H
    jae ppb_done
    
    mov ax, buffer_seg
    mov es, ax
    
    ; Calcular offset
    mov ax, cx
    mov di, 20      ; Ancho en bytes
    mul di
    mov di, ax
    mov ax, bx
    shr ax, 3
    add di, ax
    
    ; Máscara de bit
    mov cx, bx
    and cx, 7
    mov al, 80h
    shr al, cl
    
    or es:[di], al
    
ppb_done:
    pop es
    pop di
    pop cx
    pop bx
    pop ax
    ret
PutPixelBuffer ENDP

; === COPIAR BUFFER A PANTALLA ===
FlipBuffer PROC
    push ax
    push cx
    push si
    push di
    push ds
    push es
    
    ; Configurar transferencia
    mov ax, buffer_seg
    mov ds, ax
    mov ax, 0A000h
    mov es, ax
    
    ; Configurar planos EGA
    mov dx, 03C4h
    mov ax, 0F02h
    out dx, ax
    
    ; Copiar datos
    xor si, si
    mov di, 100     ; Offset para centrar
    mov cx, 1920    ; Bytes a copiar
    rep movsb
    
    pop es
    pop ds
    pop di
    pop si
    pop cx
    pop ax
    ret
FlipBuffer ENDP

END main