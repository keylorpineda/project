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
PLANE_SIZE        EQU 2000        ; FIX: 20 * 100 = 2000 bytes por plano (NO 8000)
PLANE_PARAGRAPHS  EQU 128 
VIEWPORT_PIXELS   EQU VIEWPORT_WIDTH * VIEWPORT_HEIGHT
VIEWPORT_BYTES    EQU PLANE_SIZE  ; 2000 bytes para el viewport
LINE_BUFFER_SIZE  EQU 128   

.DATA                             ; Segmento de datos
Plane0Segment    dw 0             ; Segmento del plano 0 (bit de peso 1)
Plane1Segment    dw 0             ; Segmento del plano 1 (bit de peso 2)
Plane2Segment    dw 0             ; Segmento del plano 2 (bit de peso 4)
Plane3Segment    dw 0             ; Segmento del plano 3 (bit de peso 8)
psp_seg          dw 0             ; Fix: Para PSP segment

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
viewport_x_offset dw 30          ; FIX: Reducir offset horizontal
viewport_y_offset dw 1000        ; FIX: Reducir offset vertical

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

.CODE                             ; Segmento de código

main PROC
    mov ax, @data
    mov ds, ax

    call ShrinkProgramMemory
    call InitOffScreenBuffer
    cmp ax, 0
    je @ok_print

    ; Imprimir código de error y salir
    call PrintHexAX
    mov dx, OFFSET msg_err
    mov ah, 09h
    int 21h
    mov ah, 4Ch
    mov al, 8
    int 21h

@ok_print:
    mov ax, 0010h
    int 10h
    
    call CheckGraphicsMode
    call ClearScreen
    call SimpleDrawTest
    
    mov ah, 00h
    int 16h
    
    call SetPaletteRed
    call SetPaletteWhite

    ; FIX: Cargar mapa de tiles desde archivo
    call LoadMapFromFile

    ; FIX: Inicializar posición de cámara
    mov camera_tile_x, 0
    mov camera_tile_y, 0

    call MainLoop

    mov ax, 0003h
    int 10h
    call ReleaseOffScreenBuffer
    mov ax, 4C00h
    int 21h
main ENDP

; ===== RUTINAS BÁSICAS PRIMERO =====

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

    mov ax, psp_seg
    or ax, ax
    jnz @spm_have_psp

    mov ah, 51h
    int 21h
    mov psp_seg, bx

@spm_have_psp:
    mov es, psp_seg
    mov ax, es:[2]
    shr ax, 1

    mov ah, 4Ah
    mov bx, 200
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

SimpleDrawTest PROC
    push ax
    push cx
    push dx
    push di
    push es
    
    mov ax, 0A000h
    mov es, ax
    
    mov dx, 03C4h
    mov al, 02h
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    
    xor di, di
    mov al, 15
    mov cx, 160
    rep stosb
    
    mov di, 4000
    mov al, 4
    mov cx, 160
    rep stosb
    
    mov di, 8000
    mov al, 2
    mov cx, 160
    rep stosb
    
    pop es
    pop di
    pop dx
    pop cx
    pop ax
    ret
SimpleDrawTest ENDP

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

SetPaletteRed PROC
    ret
SetPaletteRed ENDP

SetPaletteWhite PROC
    ret
SetPaletteWhite ENDP

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
    push dx

@pni_skip_non_digit:
    mov al, [si]
    cmp al, 0
    je @pni_return_zero
    cmp al, '0'
    jb @pni_advance
    cmp al, '9'
    jbe @pni_start_parse
@pni_advance:
    inc si
    jmp @pni_skip_non_digit

@pni_start_parse:
    xor ax, ax

@pni_digit_loop:
    mov al, [si]
    cmp al, '0'
    jb @pni_digits_done
    cmp al, '9'
    ja @pni_digits_done
    mov dl, al
    sub dl, '0'
    xor dh, dh
    mov bx, ax
    shl ax, 1
    shl bx, 3
    add ax, bx
    add ax, dx
    inc si
    jmp @pni_digit_loop

@pni_digits_done:
@pni_skip_delimiters:
    mov al, [si]
    cmp al, 0
    je @pni_done
    cmp al, '0'
    jb @pni_check_space
    cmp al, '9'
    jbe @pni_done
@pni_check_space:
    cmp al, ' '
    je @pni_consume
    cmp al, 9
    je @pni_consume
    cmp al, ','
    je @pni_consume
    cmp al, 0Dh
    je @pni_consume
    cmp al, 0Ah
    je @pni_consume
    jmp @pni_done

@pni_consume:
    inc si
    jmp @pni_skip_delimiters

@pni_return_zero:
    xor ax, ax

@pni_done:
    pop dx
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
    push es

    call ClearMapData

    mov ax, 10
    mov map_width, ax
    mov ax, 6
    mov map_height, ax

    mov map_loaded, 1

    mov dx, map_height
    xor si, si

@cdm_row_loop:
    cmp si, dx
    jae @cdm_done

    mov ax, si
    mul map_width
    mov di, OFFSET map_data
    add di, ax

    mov cx, map_width
    xor bx, bx

@cdm_col_loop:
    mov al, TILE_FLOOR
    cmp si, 0
    je @cdm_use_wall
    mov ax, map_height
    dec ax
    cmp si, ax
    je @cdm_use_wall
    cmp bx, 0
    je @cdm_use_wall
    mov ax, map_width
    dec ax
    cmp bx, ax
    jne @cdm_store

@cdm_use_wall:
    mov al, TILE_WALL

@cdm_store:
    mov [di], al
    inc di
    inc bx
    loop @cdm_col_loop

    inc si
    jmp @cdm_row_loop

@cdm_done:
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
CreateDefaultMap ENDP

; ===== RUTINAS DE DIBUJADO CORTAS =====

GetTileAt PROC
    push dx
    push si
    push di

    mov ax, map_width
    cmp bx, ax
    jae @gta_out_of_bounds

    mov ax, map_height
    cmp cx, ax
    jae @gta_out_of_bounds

    mov ax, cx
    mul map_width
    add ax, bx
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

DrawPixel PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    cmp bx, 159
    jbe @dp_check_y
    jmp @dp_exit_pixel

@dp_check_y:
    cmp cx, 99
    jbe @dp_prepare_pixel
    jmp @dp_exit_pixel

@dp_prepare_pixel:
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
    jmp @dt_color_ready

@dt_color_empty:
    mov dl, TILE_EMPTY
    jmp @dt_color_ready

@dt_color_wall:
    mov dl, TILE_WALL
    jmp @dt_color_ready

@dt_color_floor:
    mov dl, TILE_FLOOR
    jmp @dt_color_ready

@dt_color_water:
    mov dl, TILE_WATER

@dt_color_ready:
    xor ax, ax

@dt_row_loop:
    cmp ax, TILE_SIZE
    jae @dt_done
    mov cx, si
    add cx, ax
    mov bx, di
    xor bp, bp

@dt_col_loop:
    cmp bp, TILE_SIZE
    jae @dt_next_row
    call DrawPixel
    inc bx
    inc bp
    jmp @dt_col_loop

@dt_next_row:
    inc ax
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

; ===== RUTINAS DE TILES =====

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
    jc @lmff_load_default_map

    call ReadLine
    call ParseTwoInts
    
    mov ax, mapW
    cmp ax, 1
    jb @lmff_load_default_map
    cmp ax, MAX_MAP_WIDTH
    ja @lmff_load_default_map
    
    mov ax, mapH
    cmp ax, 1
    jb @lmff_load_default_map
    cmp ax, MAX_MAP_HEIGHT
    ja @lmff_load_default_map

    mov ax, mapW
    mov map_width, ax
    mov ax, mapH
    mov map_height, ax

    call ClearMapData

    mov cx, mapH
    mov di, 0

@lmff_read_matrix_row:
    push cx
    push di
    
    call ReadLine
    
    mov si, OFFSET lineBuffer
    mov cx, mapW
    
@lmff_parse_tile_in_row:
    push cx
    push di
    
    call ParseNextInt
    cmp ax, 255
    ja @lmff_invalid_tile
    
    mov bx, OFFSET map_data
    add bx, di
    mov [bx], al
    
    pop di
    inc di
    pop cx
    dec cx                        ; FIX: Cambiar loop por dec cx + jnz
    jnz @lmff_parse_tile_in_row
    
    pop di
    add di, mapW
    pop cx
    dec cx                        ; FIX: Cambiar loop por dec cx + jnz
    jnz @lmff_read_matrix_row

    mov map_loaded, 1
    call CloseFile
    jmp @lmff_load_success

@lmff_invalid_tile:
    pop di
    pop cx
    pop cx
    call CloseFile
    jmp @lmff_load_default_map

@lmff_load_default_map:
    call CreateDefaultMap

@lmff_load_success:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
LoadMapFromFile ENDP

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

RenderMapViewport PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    cmp map_loaded, 0
    je @rmv_render_default

    call ClearOffScreenBuffer
    call ClampCameraPosition

    mov si, camera_tile_y
    mov ax, 0

@rmv_render_tile_row:
    cmp si, map_height
    jae @rmv_next_tile_row
    cmp ax, VIEWPORT_HEIGHT
    jae @rmv_exit_render

    push ax
    push si
    
    mov di, camera_tile_x
    mov bx, 0
    
@rmv_render_tile_column:
    cmp di, map_width
    jae @rmv_next_tile_column
    cmp bx, VIEWPORT_WIDTH
    jae @rmv_end_tile_row

    push ax
    push bx
    push cx
    mov bx, di
    mov cx, si
    call GetTileAt
    mov dl, al
    pop cx
    pop bx
    pop ax

    push ax
    push bx
    push cx
    mov cx, ax
    call DrawTile
    pop cx
    pop bx
    pop ax

@rmv_next_tile_column:
    add bx, TILE_SIZE
    inc di
    jmp @rmv_render_tile_column

@rmv_end_tile_row:
    pop si
    pop ax
    
@rmv_next_tile_row:
    add ax, TILE_SIZE
    inc si
    jmp @rmv_render_tile_row

@rmv_render_default:
    call ClearOffScreenBuffer

@rmv_exit_render:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
RenderMapViewport ENDP

MainLoop PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

@ml_frame_loop:
    call RenderMapViewport
    call DrawRedLine
    call BlitBufferToScreen

    call ReadKeyNonBlocking
    cmp ax, 0
    je @ml_no_key

    cmp al, 1Bh
    je @ml_exit_loop

    cmp al, 'W'
    jne @ml_check_s
    mov ax, camera_tile_y
    cmp ax, 0
    je @ml_handled
    dec ax
    mov camera_tile_y, ax
    jmp @ml_handled

@ml_check_s:
    cmp al, 'S'
    jne @ml_check_a
    mov ax, camera_tile_y
    mov bx, map_height
    sub bx, VIEWPORT_TILES_Y
    cmp bx, 0
    jge @ml_check_s_limit
    mov bx, 0
@ml_check_s_limit:
    cmp ax, bx
    jae @ml_handled
    inc ax
    mov camera_tile_y, ax
    jmp @ml_handled

@ml_check_a:
    cmp al, 'A'
    jne @ml_check_d
    mov ax, camera_tile_x
    cmp ax, 0
    je @ml_handled
    dec ax
    mov camera_tile_x, ax
    jmp @ml_handled

@ml_check_d:
    cmp al, 'D'
    jne @ml_handled
    mov ax, camera_tile_x
    mov bx, map_width
    sub bx, VIEWPORT_TILES_X
    cmp bx, 0
    jge @ml_check_d_limit
    mov bx, 0
@ml_check_d_limit:
    cmp ax, bx
    jae @ml_handled
    inc ax
    mov camera_tile_x, ax

@ml_handled:
@ml_no_key:
    mov cl, 2
    call DelayTicks
    jmp @ml_frame_loop

@ml_exit_loop:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
MainLoop ENDP

; ===== RUTINA MÁS LARGA AL FINAL =====

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
    jz  @bbts_Skip0
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
    add di, viewport_x_offset

    mov ax, VIEWPORT_HEIGHT
@bbts_Row0:
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
    jnz @bbts_Row0
    pop ds
@bbts_Skip0:

    ; PLANO 1
    mov ax, Plane1Segment
    or  ax, ax
    jz  @bbts_Skip1
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
    add di, viewport_x_offset
    
    mov ax, VIEWPORT_HEIGHT
@bbts_Row1:
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
    jnz @bbts_Row1
    pop ds
@bbts_Skip1:

    ; PLANO 2
    mov ax, Plane2Segment
    or  ax, ax
    jz  @bbts_Skip2
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
    add di, viewport_x_offset
    
    mov ax, VIEWPORT_HEIGHT
@bbts_Row2:
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
    jnz @bbts_Row2
    pop ds
@bbts_Skip2:

    ; PLANO 3
    mov ax, Plane3Segment
    or  ax, ax
    jz  @bbts_Skip3
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
    add di, viewport_x_offset
    
    mov ax, VIEWPORT_HEIGHT
@bbts_Row3:
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
    jnz @bbts_Row3
    pop ds
@bbts_Skip3:

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
