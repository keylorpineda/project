; Programa para modo gráfico EGA 640x350 16 colores con doble buffer
; Ensamblador 8086/8088 - Sintaxis TASM

.MODEL SMALL                      ; Usar modelo de memoria small (código y datos < 64K)
.STACK 100h                       ; Reservar 256 bytes para la pila

; ===== Pantalla (hardware EGA) =====
SCREEN_WIDTH      EQU 640         ; Ancho de pantalla en píxeles
SCREEN_HEIGHT     EQU 350         ; Alto de pantalla en píxeles
VRAM_BYTES_PER_SCAN EQU 80        ; 640/8 bytes por línea en VRAM

; ===== Viewport lógico (tu buffer off-screen) =====
VIEWPORT_WIDTH    EQU 160         ; Ancho del viewport en píxeles
VIEWPORT_HEIGHT   EQU 100         ; Alto del viewport en píxeles
BYTES_PER_SCAN    EQU 20          ; VIEWPORT_WIDTH/8 = 20 bytes por línea
PLANE_SIZE        EQU 2000        ; 20 * 100 = 2000 bytes por plano
PLANE_PARAGRAPHS  EQU 128 
VIEWPORT_PIXELS   EQU VIEWPORT_WIDTH * VIEWPORT_HEIGHT
VIEWPORT_BYTES    EQU PLANE_SIZE  ; 2000 bytes para el viewport
LINE_BUFFER_SIZE  EQU 128   

.DATA                             ; Segmento de datos
Plane0Segment    dw 0             ; Segmento del plano 0 (bit de peso 1)
Plane1Segment    dw 0             ; Segmento del plano 1 (bit de peso 2)
Plane2Segment    dw 0             ; Segmento del plano 2 (bit de peso 4)
Plane3Segment    dw 0             ; Segmento del plano 3 (bit de peso 8)
psp_seg          dw 0             ; Para PSP segment

; ===== Sistema de tiles - FASE 1 =====
TILE_SIZE         EQU 16          ; Tamaño de cada tile (16x16 píxeles)
MAX_MAP_WIDTH     EQU 50          ; Máximo ancho del mapa en tiles
MAX_MAP_HEIGHT    EQU 35          ; Máximo alto del mapa en tiles
MAX_MAP_SIZE      EQU 1750        ; MAX_MAP_WIDTH * MAX_MAP_HEIGHT

; Tiles visibles en viewport 160x100
VIEWPORT_TILES_X  EQU 10          ; 160/16 = 10 tiles horizontales
VIEWPORT_TILES_Y  EQU 6           ; 100/16 = 6 tiles verticales (con margen)

; Buffer para el mapa de tiles
map_data          db MAX_MAP_SIZE dup(0)  ; Matriz de tiles del mapa
map_width         dw 0            ; Ancho actual del mapa en tiles
map_height        dw 0            ; Alto actual del mapa en tiles
map_loaded        db 0            ; Flag: 1 = mapa cargado correctamente

; Posición de la cámara (en tiles)
camera_tile_x     dw 0            ; Tile X superior izquierdo visible
camera_tile_y     dw 0            ; Tile Y superior izquierdo visible

; Colores para tipos de tiles (EGA estándar)
TILE_EMPTY        EQU 0           ; Tipo 0: Vacío/Muro (negro)
TILE_WALL         EQU 8           ; Tipo 1: Muro (gris oscuro)
TILE_FLOOR        EQU 2           ; Tipo 2: Piso (verde)
TILE_WATER        EQU 1           ; Tipo 3: Agua (azul)

; ===== Offsets para centrar el viewport dentro de 640x350 =====
viewport_x_offset dw 30           ; Centrar horizontalmente (corregido)
viewport_y_offset dw 125          ; Centrar verticalmente (corregido)

msg_err          db 'ERROR: Alloc fallo. Codigo: $'
msg_free         db ' (free block: $'
msg_shrink_fail  db 'Shrink fail',13,10,'$'
crlf             db 13,10,'$'
mapHandle        dw 0FFFFh        ; Handle actual del archivo del mapa o -1
mapW             dw 0             ; Ancho del mapa en tiles
mapH             dw 0             ; Alto del mapa en tiles
mapFileName      db 'mapa.txt',0  ; Nombre del archivo de mapa (ASCIIZ)
lineBuffer       db LINE_BUFFER_SIZE dup (0) ; Buffer para lectura de líneas
readChar         db 0             ; Byte temporal de lectura
x_pos            dw 20            ; Posición inicial X de la línea roja
y_pos            dw 20            ; Posición inicial Y de la línea roja
line_len         dw 80            ; Longitud de la línea roja
speed_dx         dw 1             ; Velocidad horizontal (1 píxel)
speed_dy         dw 1   
debug_msg        db 'Map loaded: W=', 0
debug_msg2       db ' H=', 0

.CODE                             ; Segmento de código

main PROC
    mov ax, @data
    mov ds, ax

    call ShrinkProgramMemory
    call InitOffScreenBuffer
    cmp ax, 0
    je main_ok_print

    ; Imprimir código de error y salir
    call PrintHexAX
    mov dx, OFFSET msg_err
    mov ah, 09h
    int 21h
    mov ah, 4Ch
    mov al, 8
    int 21h

main_ok_print:
    mov ax, 0010h
    int 10h
    
    call CheckGraphicsMode
    call ClearScreen
    
    ; Cargar mapa
    call LoadMapFromFile
    
    ; Verificar que el mapa se cargó
    cmp map_loaded, 0
    je main_use_default
    jmp main_map_ready

main_use_default:
    call CreateDefaultMap

main_map_ready:
    ; Inicializar posición de cámara
    mov camera_tile_x, 0
    mov camera_tile_y, 0

    ; FIX: Cambiar RENDERMAPVIEWPORT a RenderMapViewport (capitalización correcta)
main_game_loop:
    call RenderMapViewport    ; FIX: Nombre correcto del procedimiento
    call DrawRedLine
    call BlitBufferToScreen

    call ReadKeyNonBlocking
    cmp ax, 0
    je main_no_key

    cmp al, 1Bh             ; ESC para salir
    je main_exit_loop

    cmp al, 'W'
    jne main_check_s
    mov ax, camera_tile_y
    cmp ax, 0
    je main_handled
    dec ax
    mov camera_tile_y, ax
    jmp main_handled

main_check_s:
    cmp al, 'S'
    jne main_check_a
    mov ax, camera_tile_y
    mov bx, map_height
    sub bx, VIEWPORT_TILES_Y
    cmp bx, 0
    jge main_check_s_limit
    mov bx, 0
main_check_s_limit:
    cmp ax, bx
    jae main_handled
    inc ax
    mov camera_tile_y, ax
    jmp main_handled

main_check_a:
    cmp al, 'A'
    jne main_check_d
    mov ax, camera_tile_x
    cmp ax, 0
    je main_handled
    dec ax
    mov camera_tile_x, ax
    jmp main_handled

main_check_d:
    cmp al, 'D'
    jne main_handled
    mov ax, camera_tile_x
    mov bx, map_width
    sub bx, VIEWPORT_TILES_X
    cmp bx, 0
    jge main_check_d_limit
    mov bx, 0
main_check_d_limit:
    cmp ax, bx
    jae main_handled
    inc ax
    mov camera_tile_x, ax

main_handled:
main_no_key:
    mov cl, 3
    call DelayTicks
    jmp main_game_loop

main_exit_loop:
    mov ax, 0003h
    int 10h
    call ReleaseOffScreenBuffer
    mov ax, 4C00h
    int 21h
main ENDP

; ===== RUTINAS BÁSICAS =====

PrintHexAX PROC
    push ax
    push bx
    push cx
    push dx
    push si
    mov dx, ax
    mov bx, ax
    mov si, 4
    mov cl, 12
@phex_loop:
    mov ax, dx
    shr ax, cl
    and al, 0Fh
    mov dl, '0'
    cmp al, 9
    jbe @phex_num
    mov dl, 'A'
    add dl, al
    sub dl, 10
    jmp @phex_print
@phex_num:
    add dl, al
@phex_print:
    mov ah, 02h
    int 21h
    shl dx, 1
    shl dx, 1
    shl dx, 1
    shl dx, 1
    shr bx, 4
    dec si
    jnz @phex_loop
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
PrintHexAX ENDP

CheckGraphicsMode PROC
    push ax
    push bx
    
    mov ah, 0Fh
    int 10h
    cmp al, 10h
    je @cgm_mode_ok
    
    mov ax, 000Eh
    int 10h
    mov ah, 0Fh
    int 10h
    cmp al, 0Eh
    je @cgm_mode_ok
    
    mov ax, 0004h
    int 10h
    
@cgm_mode_ok:
    pop bx
    pop ax
    ret
CheckGraphicsMode ENDP

ShrinkProgramMemory PROC
    push ax
    push bx
    push cx
    push dx
    push es

    mov ah, 51h
    int 21h
    mov psp_seg, bx

    mov es, psp_seg
    mov bx, 1000h  ; Reducir a tamaño razonable
    mov ah, 4Ah
    int 21h
    jc @spm_shrink_fail

    xor ax, ax
    jmp @spm_exit

@spm_shrink_fail:
    mov ax, 1

@spm_exit:
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ShrinkProgramMemory ENDP

InitOffScreenBuffer PROC
    push bx
    push cx
    push dx
    push es

    mov Plane0Segment, 0
    mov Plane1Segment, 0
    mov Plane2Segment, 0
    mov Plane3Segment, 0

    mov bx, PLANE_PARAGRAPHS

    mov ah, 48h
    int 21h
    jc @iosb_AllocationFailed
    mov Plane0Segment, ax

    mov ah, 48h
    mov bx, PLANE_PARAGRAPHS
    int 21h
    jc @iosb_AllocationFailed
    mov Plane1Segment, ax

    mov ah, 48h
    mov bx, PLANE_PARAGRAPHS
    int 21h
    jc @iosb_AllocationFailed
    mov Plane2Segment, ax

    mov ah, 48h
    mov bx, PLANE_PARAGRAPHS
    int 21h
    jc @iosb_AllocationFailed
    mov Plane3Segment, ax

    xor ax, ax
    jmp @iosb_InitExit

@iosb_AllocationFailed:
    push ax
    call ReleaseOffScreenBuffer
    pop ax

@iosb_InitExit:
    pop es
    pop dx
    pop cx
    pop bx
    ret
InitOffScreenBuffer ENDP

ReleaseOffScreenBuffer PROC
    push ax
    push es

    mov ax, Plane0Segment
    or ax, ax
    jz @rosb_SkipFree0
    mov es, ax
    mov ah, 49h
    int 21h
    mov Plane0Segment, 0
@rosb_SkipFree0:

    mov ax, Plane1Segment
    or ax, ax
    jz @rosb_SkipFree1
    mov es, ax
    mov ah, 49h
    int 21h
    mov Plane1Segment, 0
@rosb_SkipFree1:

    mov ax, Plane2Segment
    or ax, ax
    jz @rosb_SkipFree2
    mov es, ax
    mov ah, 49h
    int 21h
    mov Plane2Segment, 0
@rosb_SkipFree2:

    mov ax, Plane3Segment
    or ax, ax
    jz @rosb_SkipFree3
    mov es, ax
    mov ah, 49h
    int 21h
    mov Plane3Segment, 0
@rosb_SkipFree3:

    pop es
    pop ax
    ret
ReleaseOffScreenBuffer ENDP

ClearOffScreenBuffer PROC
    cld
    push ax
    push cx
    push di
    push es

    mov ax, Plane0Segment
    or ax, ax
    jz @cosb_SkipPlane0
    mov es, ax
    xor ax, ax
    xor di, di
    mov cx, PLANE_SIZE
    rep stosb
@cosb_SkipPlane0:

    mov ax, Plane1Segment
    or ax, ax
    jz @cosb_SkipPlane1
    mov es, ax
    xor ax, ax
    xor di, di
    mov cx, PLANE_SIZE
    rep stosb
@cosb_SkipPlane1:

    mov ax, Plane2Segment
    or ax, ax
    jz @cosb_SkipPlane2
    mov es, ax
    xor ax, ax
    xor di, di
    mov cx, PLANE_SIZE
    rep stosb
@cosb_SkipPlane2:

    mov ax, Plane3Segment
    or ax, ax
    jz @cosb_SkipPlane3
    mov es, ax
    xor ax, ax
    xor di, di
    mov cx, PLANE_SIZE
    rep stosb
@cosb_SkipPlane3:

    pop es
    pop di
    pop cx
    pop ax
    ret
ClearOffScreenBuffer ENDP

ClearScreen PROC
    push ax
    push bx
    push cx
    push dx
    push di
    push es

    mov ax, 0A000h
    mov es, ax

    mov dx, 03C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    dec dx

    xor di, di
    mov al, 0
    mov cx, 28000
    rep stosb

    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ClearScreen ENDP

; ===== RUTINAS DE ARCHIVO =====

OpenFile PROC
    push dx
    mov ah, 3Dh
    xor al, al
    int 21h
    jc @of_open_error
    mov mapHandle, ax
    clc
    pop dx
    ret

@of_open_error:
    mov mapHandle, 0FFFFh
    stc
    pop dx
    ret
OpenFile ENDP

CloseFile PROC
    push ax
    push bx
    mov ax, mapHandle
    cmp ax, 0FFFFh
    je @cf_close_done
    mov bx, ax
    mov ah, 3Eh
    int 21h
    mov mapHandle, 0FFFFh
@cf_close_done:
    pop bx
    pop ax
    ret
CloseFile ENDP

ReadLine PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    mov ax, ds
    mov es, ax
    mov di, OFFSET lineBuffer
    mov cx, LINE_BUFFER_SIZE
    xor al, al
    rep stosb

    mov bx, mapHandle
    cmp bx, 0FFFFh
    je @rl_rl_done

    mov di, OFFSET lineBuffer

@rl_rl_next:
    mov ah, 3Fh
    mov cx, 1
    mov dx, OFFSET readChar
    int 21h
    jc @rl_rl_done
    cmp ax, 0
    je @rl_rl_done

    mov al, readChar
    cmp al, 0Dh
    je @rl_rl_next
    cmp al, 0Ah
    je @rl_rl_done

    cmp di, OFFSET lineBuffer + LINE_BUFFER_SIZE - 1
    jae @rl_rl_next

    mov [di], al
    inc di
    jmp @rl_rl_next

@rl_rl_done:
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ReadLine ENDP

ParseTwoInts PROC
    push ax
    push bx
    push cx
    push dx
    push si

    mov mapW, 0
    mov mapH, 0
    mov si, OFFSET lineBuffer

@pti_skip_ws1:
    mov al, [si]
    cmp al, 0
    je @pti_store_width
    cmp al, ' '
    je @pti_adv_ws1
    cmp al, 9
    je @pti_adv_ws1
    jmp @pti_parse_width
@pti_adv_ws1:
    inc si
    jmp @pti_skip_ws1

@pti_parse_width:
    xor ax, ax
@pti_width_loop:
    mov al, [si]
    cmp al, '0'
    jb @pti_store_width
    cmp al, '9'
    ja @pti_store_width
    mov dl, [si]
    sub dl, '0'
    xor dh, dh
    mov cx, ax
    shl ax, 1
    shl cx, 3
    add ax, cx
    add ax, dx
    inc si
    jmp @pti_width_loop

@pti_store_width:
    mov mapW, ax

@pti_skip_ws2:
    mov al, [si]
    cmp al, 0
    je @pti_done_parse
    cmp al, ' '
    je @pti_adv_ws2
    cmp al, 9
    je @pti_adv_ws2
    jmp @pti_parse_height
@pti_adv_ws2:
    inc si
    jmp @pti_skip_ws2

@pti_parse_height:
    xor ax, ax
@pti_height_loop:
    mov al, [si]
    cmp al, '0'
    jb @pti_store_height
    cmp al, '9'
    ja @pti_store_height
    mov dl, [si]
    sub dl, '0'
    xor dh, dh
    mov cx, ax
    shl ax, 1
    shl cx, 3
    add ax, cx
    add ax, dx
    inc si
    jmp @pti_height_loop

@pti_store_height:
    mov mapH, ax

@pti_done_parse:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ParseTwoInts ENDP

ParseNextInt PROC
    push bx
    push cx
    push dx

@pni_skip_ws:
    mov al, [si]
    cmp al, 0
    je @pni_return_zero
    cmp al, ' '
    je @pni_next_char
    cmp al, 9
    je @pni_next_char
    cmp al, ','
    je @pni_next_char
    cmp al, 13
    je @pni_next_char
    cmp al, 10
    je @pni_next_char
    
    cmp al, '0'
    jb @pni_return_zero
    cmp al, '9'
    ja @pni_return_zero
    jmp @pni_parse_number

@pni_next_char:
    inc si
    jmp @pni_skip_ws

@pni_parse_number:
    xor dx, dx

@pni_digit_loop:
    mov al, [si]
    cmp al, '0'
    jb @pni_done
    cmp al, '9'
    ja @pni_done
    
    sub al, '0'
    mov bl, al
    mov ax, dx
    mov cx, 10
    mul cx
    add ax, bx
    mov dx, ax
    inc si
    jmp @pni_digit_loop

@pni_done:
    mov ax, dx
    jmp @pni_exit

@pni_return_zero:
    xor ax, ax

@pni_exit:
    pop dx
    pop cx
    pop bx
    ret
ParseNextInt ENDP

ClearMapData PROC
    push ax
    push cx
    push dx
    push di
    push es

    xor ax, ax
    mov cx, MAX_MAP_SIZE
    mov di, OFFSET map_data
    mov dx, ds
    mov es, dx
    rep stosb

    mov map_loaded, 0
    mov map_width, 0
    mov map_height, 0

    pop es
    pop di
    pop dx
    pop cx
    pop ax
    ret
ClearMapData ENDP

CreateDefaultMap PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    call ClearMapData

    mov ax, 10
    mov map_width, ax
    mov ax, 6
    mov map_height, ax

    mov map_loaded, 1

    mov di, OFFSET map_data
    mov cx, 60
    xor bx, bx

@cdm_fill_loop:
    mov ax, bx
    mov dx, 0
    mov si, 10
    div si
    
    cmp ax, 0
    je @cdm_wall
    cmp ax, 5
    je @cdm_wall  
    cmp dx, 0
    je @cdm_wall
    cmp dx, 9
    je @cdm_wall
    
    cmp ax, 2
    jne @cdm_check_floor
    cmp dx, 4
    je @cdm_water
    cmp dx, 5
    je @cdm_water
    
@cdm_check_floor:
    mov al, 2
    jmp @cdm_store

@cdm_water:
    mov al, 3
    jmp @cdm_store

@cdm_wall:
    mov al, 1

@cdm_store:
    mov [di], al
    inc di
    inc bx
    dec cx
    jnz @cdm_fill_loop

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
CreateDefaultMap ENDP

; ===== RUTINAS DE DIBUJO =====

GetTileAt PROC
    push dx
    push si
    push di

    cmp bx, map_width
    jae @gta_out_of_bounds
    cmp cx, map_height  
    jae @gta_out_of_bounds

    mov ax, cx
    mul map_width
    add ax, bx
    
    cmp ax, MAX_MAP_SIZE
    jae @gta_out_of_bounds
    
    mov si, OFFSET map_data
    add si, ax
    mov al, [si]
    jmp @gta_done

@gta_out_of_bounds:
    mov al, TILE_EMPTY

@gta_done:
    pop di
    pop si
    pop dx
    ret
GetTileAt ENDP

RenderMapViewport PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    call ClearOffScreenBuffer
    call ClampCameraPosition

    xor bp, bp

RenderMapViewport_RowLoop:
    cmp bp, VIEWPORT_TILES_Y
    jae RenderMapViewport_Done

    mov ax, bp
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    mov si, ax

    mov ax, camera_tile_y
    add ax, bp
    mov dx, ax

    xor cx, cx

RenderMapViewport_ColLoop:
    cmp cx, VIEWPORT_TILES_X
    jae RenderMapViewport_NextRow

    push cx

    mov ax, camera_tile_x
    add ax, cx
    mov bx, ax

    mov cx, dx
    call GetTileAt
    mov dl, al

    pop ax

    mov bx, ax
    shl bx, 1
    shl bx, 1
    shl bx, 1
    shl bx, 1

    mov cx, si
    call DrawTile

    mov cx, ax
    inc cx
    jmp RenderMapViewport_ColLoop

RenderMapViewport_NextRow:
    inc bp
    jmp RenderMapViewport_RowLoop

RenderMapViewport_Done:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
RenderMapViewport ENDP

DrawPixel PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    cmp bx, VIEWPORT_WIDTH
    jae @dp_exit_pixel
    cmp cx, VIEWPORT_HEIGHT
    jae @dp_exit_pixel

    mov dh, dl

    mov ax, BYTES_PER_SCAN
    mul cx
    mov di, ax

    mov si, bx
    mov ax, si
    shr ax, 3
    add di, ax

    mov ax, si
    and ax, 7
    mov cl, 7
    sub cl, al
    mov al, 1
    shl al, cl
    mov bl, al
    mov bh, bl
    not bh

    mov si, di

    mov ax, Plane0Segment
    or ax, ax
    jz @dp_NextPlane0
    mov es, ax
    mov di, si
    mov al, bh
    and BYTE PTR es:[di], al
    test dh, 1
    jz @dp_NextPlane0
    mov al, bl
    or BYTE PTR es:[di], al
@dp_NextPlane0:

    mov ax, Plane1Segment
    or ax, ax
    jz @dp_NextPlane1
    mov es, ax
    mov di, si
    mov al, bh
    and BYTE PTR es:[di], al
    test dh, 2
    jz @dp_NextPlane1
    mov al, bl
    or BYTE PTR es:[di], al
@dp_NextPlane1:

    mov ax, Plane2Segment
    or ax, ax
    jz @dp_NextPlane2
    mov es, ax
    mov di, si
    mov al, bh
    and BYTE PTR es:[di], al
    test dh, 4
    jz @dp_NextPlane2
    mov al, bl
    or BYTE PTR es:[di], al
@dp_NextPlane2:

    mov ax, Plane3Segment
    or ax, ax
    jz @dp_NextPlane3
    mov es, ax
    mov di, si
    mov al, bh
    and BYTE PTR es:[di], al
    test dh, 8
    jz @dp_NextPlane3
    mov al, bl
    or BYTE PTR es:[di], al
@dp_NextPlane3:

@dp_exit_pixel:
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DrawPixel ENDP

DrawTile PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov si, cx
    mov di, bx

    mov al, dl
    cmp al, 0
    je @dt_color_empty
    cmp al, 1
    je @dt_color_wall
    cmp al, 2
    je @dt_color_floor
    cmp al, 3
    je @dt_color_water
    mov dl, 15
    jmp @dt_start_drawing

@dt_color_empty:
    mov dl, TILE_EMPTY
    jmp @dt_start_drawing

@dt_color_wall:
    mov dl, TILE_WALL
    jmp @dt_start_drawing

@dt_color_floor:
    mov dl, TILE_FLOOR
    jmp @dt_start_drawing

@dt_color_water:
    mov dl, TILE_WATER

@dt_start_drawing:
    mov bp, 0

@dt_row_loop:
    cmp bp, TILE_SIZE
    jae @dt_done
    
    mov cx, si
    add cx, bp
    mov bx, di
    mov ax, 0

@dt_col_loop:
    cmp ax, TILE_SIZE
    jae @dt_next_row
    
    push ax
    push cx
    call DrawPixel
    pop cx
    pop ax
    
    inc bx
    inc ax
    jmp @dt_col_loop

@dt_next_row:
    inc bp
    jmp @dt_row_loop

@dt_done:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DrawTile ENDP

DrawRedLine PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov ax, line_len
    cmp ax, 0
    jz @drl_dr_exit

    mov dx, VIEWPORT_WIDTH - 1
    sub dx, ax
    inc dx
    mov bx, x_pos
    cmp bx, dx
    jbe @drl_dr_clamp_y
    mov bx, dx
    mov x_pos, bx

@drl_dr_clamp_y:
    mov ax, y_pos
    cmp ax, VIEWPORT_HEIGHT - 1
    jbe @drl_dr_setup
    mov ax, VIEWPORT_HEIGHT - 1
    mov y_pos, ax

@drl_dr_setup:
    mov cx, y_pos
    mov si, x_pos
    mov di, line_len

@drl_dr_loop:
    mov bx, si
    mov dl, 15
    call DrawPixel
    inc si
    dec di
    jnz @drl_dr_loop

@drl_dr_exit:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DrawRedLine ENDP

ReadKeyNonBlocking PROC
    push bx
    push cx
    push dx

    mov ah, 01h
    int 16h
    jz @rknb_rknb_none

    mov ah, 00h
    int 16h
    cmp al, 'a'
    jb @rknb_rknb_upper_done
    cmp al, 'z'
    ja @rknb_rknb_upper_done
    sub al, 20h
@rknb_rknb_upper_done:
    xor ah, ah
    pop dx
    pop cx
    pop bx
    ret

@rknb_rknb_none:
    xor ax, ax
    pop dx
    pop cx
    pop bx
    ret
ReadKeyNonBlocking ENDP

DelayTicks PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov bl, cl
    or bl, bl
    jz @dt_dt_exit

    mov ah, 00h
    int 1Ah
    mov si, dx
    mov di, cx

@dt_dt_wait:
    mov ah, 00h
    int 1Ah
    cmp cx, di
    jne @dt_dt_tick
    cmp dx, si
    jne @dt_dt_tick
    jmp @dt_dt_wait

@dt_dt_tick:
    dec bl
    jz @dt_dt_exit
    mov si, dx
    mov di, cx
    jmp @dt_dt_wait

@dt_dt_exit:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DelayTicks ENDP

ClampCameraPosition PROC
    push ax
    push bx

    mov ax, camera_tile_x
    cmp ax, 0
    jge @ccp_check_max_x
    mov ax, 0
    jmp @ccp_store_x

@ccp_check_max_x:
    mov bx, map_width
    sub bx, VIEWPORT_TILES_X
    cmp bx, 0
    jge @ccp_check_x_limit
    mov bx, 0

@ccp_check_x_limit:
    cmp ax, bx
    jle @ccp_store_x
    mov ax, bx

@ccp_store_x:
    mov camera_tile_x, ax

    mov ax, camera_tile_y
    cmp ax, 0
    jge @ccp_check_max_y
    mov ax, 0
    jmp @ccp_store_y

@ccp_check_max_y:
    mov bx, map_height
    sub bx, VIEWPORT_TILES_Y
    cmp bx, 0
    jge @ccp_check_y_limit
    mov bx, 0

@ccp_check_y_limit:
    cmp ax, bx
    jle @ccp_store_y
    mov ax, bx

@ccp_store_y:
    mov camera_tile_y, ax

    pop bx
    pop ax
    ret
ClampCameraPosition ENDP

; ===== RUTINAS DE TILES CORREGIDAS =====

LoadMapFromFile PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov map_loaded, 0

    push ds
    mov dx, OFFSET mapFileName
    call OpenFile
    pop ds
    
    ; FIX: Usar NOT carry flag para evitar salto largo
    jnc LoadMapFromFile_FileOK
    jmp LoadMapFromFile_UseDefault

LoadMapFromFile_FileOK:
    call ReadLine
    call ParseTwoInts
    
    ; FIX: Reorganizar verificaciones para usar saltos cortos
    mov ax, mapW
    cmp ax, 1
    jae LoadMapFromFile_CheckMaxW    ; Salto corto hacia adelante
    jmp LoadMapFromFile_UseDefault   ; Salto largo OK con JMP

LoadMapFromFile_CheckMaxW:
    cmp ax, MAX_MAP_WIDTH
    jbe LoadMapFromFile_CheckMinH    ; Salto corto hacia adelante  
    jmp LoadMapFromFile_UseDefault   ; Salto largo OK con JMP

LoadMapFromFile_CheckMinH:
    mov ax, mapH
    cmp ax, 1
    jae LoadMapFromFile_CheckMaxH    ; Salto corto hacia adelante
    jmp LoadMapFromFile_UseDefault   ; Salto largo OK con JMP

LoadMapFromFile_CheckMaxH:
    cmp ax, MAX_MAP_HEIGHT
    jbe LoadMapFromFile_ValidSize    ; Salto corto hacia adelante
    jmp LoadMapFromFile_UseDefault   ; Salto largo OK con JMP

LoadMapFromFile_ValidSize:
    ; Tamaño válido, continuar
    mov ax, mapW
    mov map_width, ax
    mov ax, mapH
    mov map_height, ax

    call ClearMapData
    mov dx, 0

LoadMapFromFile_RowLoop:
    mov ax, dx
    cmp ax, mapH
    jb LoadMapFromFile_ReadRow
    jmp LoadMapFromFile_Success

LoadMapFromFile_ReadRow:
    call ReadLine

    mov si, OFFSET lineBuffer
    mov al, [si]
    cmp al, 'R'
    jne LoadMapFromFile_StartCols
    jmp LoadMapFromFile_Success

LoadMapFromFile_StartCols:
    mov cx, 0

LoadMapFromFile_ColLoop:
    mov ax, cx
    cmp ax, mapW
    jae LoadMapFromFile_NextRow
    
    call ParseNextInt
    
    push ax
    mov ax, dx
    mul mapW
    add ax, cx
    mov di, OFFSET map_data
    add di, ax
    pop ax
    
    cmp ax, 255
    jbe LoadMapFromFile_StoreValue
    mov BYTE PTR [di], 0
    jmp LoadMapFromFile_NextCol

LoadMapFromFile_StoreValue:
    mov [di], al

LoadMapFromFile_NextCol:
    inc cx
    jmp LoadMapFromFile_ColLoop

LoadMapFromFile_NextRow:
    inc dx
    jmp LoadMapFromFile_RowLoop

LoadMapFromFile_Success:
    mov map_loaded, 1
    call CloseFile
    jmp LoadMapFromFile_Done

LoadMapFromFile_UseDefault:
    call CloseFile
    call CreateDefaultMap

LoadMapFromFile_Done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
LoadMapFromFile ENDP

; ===== CORRECCIÓN DEFINITIVA - BlitBufferToScreen (línea 1160) =====

BlitBufferToScreen PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push ds
    push es

    cld

    mov ax, 0A000h
    mov es, ax
    mov dx, 03C4h

    ; PLANO 0
    mov ax, Plane0Segment
    or  ax, ax
    jz  BlitBufferToScreen_CheckPlane1  ; Salto intermedio corto
    
    mov bx, ax
    mov al, 02h
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    dec dx

    push ds
    mov ds, bx
    xor si, si
    
    mov di, viewport_y_offset
    mov ax, VRAM_BYTES_PER_SCAN
    mul di
    mov di, ax
    mov ax, viewport_x_offset
    shr ax, 3
    add di, ax

    mov ax, VIEWPORT_HEIGHT
BlitBufferToScreen_Row0:
    push ax
    push si
    push di
    
    mov cx, BYTES_PER_SCAN
    rep movsb
    
    pop di
    pop si
    pop ax
    
    add si, BYTES_PER_SCAN
    add di, VRAM_BYTES_PER_SCAN
    
    dec ax
    jnz BlitBufferToScreen_Row0
    pop ds

BlitBufferToScreen_CheckPlane1:
    ; PLANO 1
    mov ax, Plane1Segment
    or  ax, ax
    jz  BlitBufferToScreen_CheckPlane2  ; Salto intermedio corto
    
    mov bx, ax
    mov al, 02h
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    dec dx

    push ds
    mov ds, bx
    xor si, si
    
    mov di, viewport_y_offset
    mov ax, VRAM_BYTES_PER_SCAN
    mul di
    mov di, ax
    mov ax, viewport_x_offset
    shr ax, 3
    add di, ax
    
    mov ax, VIEWPORT_HEIGHT
BlitBufferToScreen_Row1:
    push ax
    push si
    push di
    
    mov cx, BYTES_PER_SCAN
    rep movsb
    
    pop di
    pop si
    pop ax
    
    add si, BYTES_PER_SCAN
    add di, VRAM_BYTES_PER_SCAN
    
    dec ax
    jnz BlitBufferToScreen_Row1
    pop ds

BlitBufferToScreen_CheckPlane2:
    ; PLANO 2
    mov ax, Plane2Segment
    or  ax, ax
    jz  BlitBufferToScreen_CheckPlane3  ; Salto intermedio corto
    
    mov bx, ax
    mov al, 02h
    out dx, al
    inc dx
    mov al, 4
    out dx, al
    dec dx

    push ds
    mov ds, bx
    xor si, si
    
    mov di, viewport_y_offset
    mov ax, VRAM_BYTES_PER_SCAN
    mul di
    mov di, ax
    mov ax, viewport_x_offset
    shr ax, 3
    add di, ax
    
    mov ax, VIEWPORT_HEIGHT
BlitBufferToScreen_Row2:
    push ax
    push si
    push di
    
    mov cx, BYTES_PER_SCAN
    rep movsb
    
    pop di
    pop si
    pop ax
    
    add si, BYTES_PER_SCAN
    add di, VRAM_BYTES_PER_SCAN
    
    dec ax
    jnz BlitBufferToScreen_Row2
    pop ds

BlitBufferToScreen_CheckPlane3:
    ; PLANO 3
    mov ax, Plane3Segment
    or  ax, ax
    jz  BlitBufferToScreen_Finish  ; Salto intermedio corto
    
    mov bx, ax
    mov al, 02h
    out dx, al
    inc dx
    mov al, 8
    out dx, al
    dec dx

    push ds
    mov ds, bx
    xor si, si
    
    mov di, viewport_y_offset
    mov ax, VRAM_BYTES_PER_SCAN
    mul di
    mov di, ax
    mov ax, viewport_x_offset
    shr ax, 3
    add di, ax
    
    mov ax, VIEWPORT_HEIGHT
BlitBufferToScreen_Row3:
    push ax
    push si
    push di
    
    mov cx, BYTES_PER_SCAN
    rep movsb
    
    pop di
    pop si
    pop ax
    
    add si, BYTES_PER_SCAN
    add di, VRAM_BYTES_PER_SCAN
    
    dec ax
    jnz BlitBufferToScreen_Row3
    pop ds

BlitBufferToScreen_Finish:
    mov al, 02h
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al

    pop es
    pop ds
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
BlitBufferToScreen ENDP

END main
