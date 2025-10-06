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
map_loaded        db 0             ; Flag: 1 = mapa cargado correctamente

; Posición de la cámara (en tiles)
camera_tile_x     dw 0            ; Tile X superior izquierdo visible
camera_tile_y     dw 0            ; Tile Y superior izquierdo visible

; ===== CORRECCIÓN: Colores para tipos de tiles (EGA estándar) =====
TILE_EMPTY        EQU 0           ; Tipo 0: Vacío/Muro (negro)
TILE_WALL         EQU 1           ; Tipo 1: Muro (cambiar a tipo 1)
TILE_FLOOR        EQU 2           ; Tipo 2: Piso (verde)
TILE_WATER        EQU 3           ; Tipo 3: Agua (azul)

; ===== Offsets para centrar el viewport dentro de 640x350 =====
viewport_x_offset dw 0      ; Cambiar de 30 a 0 temporalmente  
viewport_y_offset dw 0      ; Cambiar de 125 a 0 temporalmente

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
debug_loading      db 'Cargando mapa...', 13, 10, '$'
debug_file_ok      db 'Archivo abierto OK', 13, 10, '$'
debug_file_error   db 'ERROR: No se pudo abrir mapa.txt', 13, 10, '$'
debug_header_error db 'ERROR: Encabezado invalido', 13, 10, '$'
debug_data_error   db 'ERROR: Datos del mapa invalidos', 13, 10, '$'
debug_success      db 'Mapa cargado exitosamente', 13, 10, '$'
debug_using_default db 'Usando mapa por defecto', 13, 10, '$'
debug_dimensions   db 'Dimensiones: $'
debug_x_sep        db ' x $'    ; Cambiar de ' x', 0 a ' x $'
debug_creating_default db 'Creando mapa por defecto...', 13, 10, '$'
debug_default_created  db 'Mapa por defecto creado (10x6)', 13, 10, '$'
debug_empty_line    db 'ERROR: Línea vacía en mapa.txt', 13, 10, '$'
debug_invalid_dims  db 'ERROR: Dimensiones inválidas en mapa.txt', 13, 10, '$'
debug_buffer_content   db 'DEBUG: Contenido buffer: $'
debug_force_default   db 'DEBUG: Forzando mapa por defecto', 13, 10, '$'

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
    ; Configurar modo gráfico ANTES de todo
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

    ; QUITAR LA PRUEBA DE EMERGENCIA DE AQUÍ
    ; La movemos DESPUÉS de RenderMapViewport

main_game_loop:
    ; CAMBIAR DE CRUZ DE PRUEBA AL SISTEMA DE TILES REAL
    call RenderMapViewport          ; ACTIVAR SISTEMA DE TILES
    
    ; COMENTAR LA PRUEBA DE LA CRUZ:
    ; call ClearOffScreenBuffer
    ; 
    ; ; Línea horizontal (más larga)
    ; mov cx, 10                     ; Y = 10
    ; mov bx, 5                      ; Empezar en X = 5
    ; mov dl, 15                     ; Color blanco brillante
    ; 
    ; mov ax, 0                      ; Contador
    ; draw_horizontal:
    ; cmp ax, 20                     ; Dibujar 20 píxeles
    ; jae draw_vertical_start
    ; 
    ; call DrawPixel
    ; inc bx
    ; inc ax
    ; jmp draw_horizontal
    ; 
    ; draw_vertical_start:
    ; ; Línea vertical
    ; mov bx, 15                     ; X = 15 (centro)
    ; mov cx, 5                      ; Empezar en Y = 5
    ; mov dl, 15                     ; Color blanco
    ; 
    ; mov ax, 0                      ; Contador
    ; draw_vertical:
    ; cmp ax, 20                     ; Dibujar 20 píxeles
    ; jae draw_done
    ; 
    ; call DrawPixel
    ; inc cx
    ; inc ax
    ; jmp draw_vertical
    ; 
    ; draw_done:

    call BlitBufferToScreen

    call ReadKeyNonBlocking
    cmp ax, 0
    je main_no_key

    cmp al, 1Bh             ; ESC para salir
    je main_exit_loop

    ; AGREGAR CONTROLES WASD:
    cmp al, 'W'
    je main_move_up
    cmp al, 'S' 
    je main_move_down
    cmp al, 'A'
    je main_move_left
    cmp al, 'D'
    je main_move_right
    jmp main_no_key

main_move_up:
    dec camera_tile_y
    jmp main_handled
main_move_down:
    inc camera_tile_y
    jmp main_handled
main_move_left:
    dec camera_tile_x
    jmp main_handled
main_move_right:
    inc camera_tile_x
    jmp main_handled

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
    
    ; Forzar modo EGA 640x350 16 colores
    mov ax, 0010h
    int 10h
    
    ; Verificar que se estableció correctamente
    mov ah, 0Fh
    int 10h
    cmp al, 10h
    je @cgm_mode_ok
    
    ; Si falló, intentar modo CGA como respaldo
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

    ; Debug: Mostrar contenido del buffer leído
    mov dx, OFFSET lineBuffer
    mov ah, 09h
    int 21h
    mov dx, OFFSET crlf
    mov ah, 09h
    int 21h

    mov mapW, 0
    mov mapH, 0
    mov si, OFFSET lineBuffer

    ; Verificar que hay contenido
    mov al, [si]
    cmp al, 0
    jne @pti_not_empty
    jmp @pti_error_empty

@pti_not_empty:

@pti_skip_ws1:
    mov al, [si]
    cmp al, 0
    jne @pti_check_ws1
    jmp @pti_error_empty

@pti_check_ws1:
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
    
    ; Verificar que el ancho es válido
    cmp ax, 0
    je @pti_error_invalid

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
    
    ; Verificar que el alto es válido
    cmp ax, 0
    je @pti_error_invalid
    jmp @pti_done_parse

@pti_error_empty:
    ; Debug: Línea vacía
    mov dx, OFFSET debug_empty_line
    mov ah, 09h
    int 21h
    jmp @pti_done_parse

@pti_error_invalid:
    ; Debug: Dimensiones inválidas
    mov dx, OFFSET debug_invalid_dims
    mov ah, 09h
    int 21h

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
    push cx
    push di
    push es

    ; Debug
    mov dx, OFFSET debug_creating_default
    mov ah, 09h
    int 21h

    call ClearMapData

    ; Mapa 10x6 COMPLETAMENTE SIMPLE
    mov ax, 10
    mov map_width, ax
    mov ax, 6  
    mov map_height, ax
    mov map_loaded, 1

    ; Llenar TODO con tipo 1 (rojos)
    mov ax, ds
    mov es, ax
    mov di, OFFSET map_data
    mov al, 1                      ; TODO tipo 1 = rojo
    mov cx, 60                     ; 10 * 6 tiles
    rep stosb

    ; Debug: Confirmar creación
    mov dx, OFFSET debug_default_created
    mov ah, 09h
    int 21h

    pop es
    pop di
    pop cx
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

    call ClearOffScreenBuffer       ; Limpiar buffer cada frame
    call ClampCameraPosition

    ; Dibujar viewport completo (10x6 tiles)
    mov si, 0                       ; SI = fila de tile actual

RMV_RowLoop:
    cmp si, VIEWPORT_TILES_Y        ; 6 filas
    jae RMV_Done
    
    mov di, 0                       ; DI = columna de tile actual

RMV_ColLoop:
    cmp di, VIEWPORT_TILES_X        ; 10 columnas
    jae RMV_NextRow
    
    ; Calcular coordenadas del tile en el mapa
    mov ax, camera_tile_x
    add ax, di                      ; AX = tile_x en mapa
    mov bx, ax
    
    mov ax, camera_tile_y
    add ax, si                      ; AX = tile_y en mapa
    mov cx, ax
    
    ; Obtener tipo de tile
    call GetTileAt                  ; AL = tipo de tile
    
    ; Calcular posición en píxeles
    mov ax, di
    shl ax, 4                       ; AX = columna * 16
    mov bx, ax                      ; BX = pixel_x
    
    mov ax, si
    shl ax, 4                       ; AX = fila * 16  
    mov cx, ax                      ; CX = pixel_y
    
    ; Dibujar tile
    mov dl, al                      ; DL = tipo de tile
    call DrawTile                   ; BX=x, CX=y, DL=tipo
    
    inc di                          ; Siguiente columna
    jmp RMV_ColLoop

RMV_NextRow:
    inc si                          ; Siguiente fila
    jmp RMV_RowLoop

RMV_Done:
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

    ; Verificar límites
    cmp bx, VIEWPORT_WIDTH
    jb @dp_check_y_bound
    jmp @dp_exit_pixel

@dp_check_y_bound:
    cmp cx, VIEWPORT_HEIGHT
    jb @dp_calculate_offset
    jmp @dp_exit_pixel

@dp_calculate_offset:
    ; Calcular offset y máscara
    mov ax, BYTES_PER_SCAN         ; 20
    mul cx                         ; AX = Y * 20
    mov si, ax                     ; SI = offset de línea
    
    mov ax, bx                     ; AX = X
    shr ax, 3                      ; AX = X / 8
    add si, ax                     ; SI = offset final
    
    ; Calcular máscara de bit
    mov ax, bx                     ; AX = X
    and ax, 7                      ; AX = X % 8
    mov cl, 7
    sub cl, al                     ; CL = 7 - (X % 8)
    mov al, 1
    shl al, cl                     ; AL = máscara de bit
    
    ; CORRECCIÓN: Guardar máscara antes de modificar registros
    mov ch, al                     ; CH = máscara de bit
    mov cl, dl                     ; CL = color original
    
    ; Plano 0 (bit 0 del color) - AZUL
    mov dx, Plane0Segment
    or dx, dx
    jz @dp_plane1
    mov es, dx
    test cl, 01h                   ; ¿Bit 0 del color está activo?
    jz @dp_clear_p0
    or BYTE PTR es:[si], ch        ; Activar bit
    jmp @dp_plane1
@dp_clear_p0:
    mov al, ch
    not al
    and BYTE PTR es:[si], al       ; Limpiar bit
    
@dp_plane1:
    ; Plano 1 (bit 1 del color) - VERDE
    mov dx, Plane1Segment
    or dx, dx
    jz @dp_plane2
    mov es, dx
    test cl, 02h                   ; ¿Bit 1 del color está activo?
    jz @dp_clear_p1
    or BYTE PTR es:[si], ch        ; Activar bit
    jmp @dp_plane2
@dp_clear_p1:
    mov al, ch
    not al
    and BYTE PTR es:[si], al       ; Limpiar bit
    
@dp_plane2:
    ; Plano 2 (bit 2 del color) - ROJO
    mov dx, Plane2Segment
    or dx, dx
    jz @dp_plane3
    mov es, dx
    test cl, 04h                   ; ¿Bit 2 del color está activo?
    jz @dp_clear_p2
    or BYTE PTR es:[si], ch        ; Activar bit
    jmp @dp_plane3
@dp_clear_p2:
    mov al, ch
    not al
    and BYTE PTR es:[si], al       ; Limpiar bit
    
@dp_plane3:
    ; Plano 3 (bit 3 del color) - INTENSIDAD
    mov dx, Plane3Segment
    or dx, dx
    jz @dp_exit_pixel
    mov es, dx
    test cl, 08h                   ; ¿Bit 3 del color está activo?
    jz @dp_clear_p3
    or BYTE PTR es:[si], ch        ; Activar bit
    jmp @dp_exit_pixel
@dp_clear_p3:
    mov al, ch
    not al
    and BYTE PTR es:[si], al       ; Limpiar bit

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

; ===== CORRECCIÓN: Mejores colores EGA más visibles =====
DrawTile PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    ; Mapeo de tipos de tiles a colores EGA MÁS CONTRASTANTES
    cmp dl, 0                       ; TILE_EMPTY
    jne @DT_CheckWall
    mov dl, 0                       ; Negro (0000b) - Sin cambios
    jmp @DT_DrawStart
    
@DT_CheckWall:
    cmp dl, 1                       ; TILE_WALL
    jne @DT_CheckFloor
    mov dl, 4                       ; Rojo puro (0100b) - MÁS VISIBLE
    jmp @DT_DrawStart
    
@DT_CheckFloor:
    cmp dl, 2                       ; TILE_FLOOR  
    jne @DT_CheckWater
    mov dl, 2                       ; Verde puro (0010b) - MÁS VISIBLE
    jmp @DT_DrawStart
    
@DT_CheckWater:
    cmp dl, 3                       ; TILE_WATER
    jne @DT_DefaultColor
    mov dl, 1                       ; Azul puro (0001b) - MÁS VISIBLE
    jmp @DT_DrawStart
    
@DT_DefaultColor:
    mov dl, 15                      ; Blanco brillante (1111b)

@DT_DrawStart:
    ; Solo dibujar si no es color negro (optimización)
    cmp dl, 0
    je @dt_done                     ; No dibujar tiles negros
    
    mov si, cx                      ; SI = Y pixel
    mov di, bx                      ; DI = X pixel
    mov bp, 0                       ; BP = fila actual

@dt_row_loop:
    cmp bp, TILE_SIZE
    jae @dt_done
    
    mov cx, si
    add cx, bp                      ; CX = Y actual
    mov bx, di                      ; BX = X inicial
    mov ax, 0                       ; AX = columna actual

@dt_col_loop:
    cmp ax, TILE_SIZE
    jae @dt_next_row
    
    ; Dibujar píxel
    push ax
    push cx
    call DrawPixel                  ; BX=X, CX=Y, DL=color
    pop cx
    pop ax

    inc bx                          ; Siguiente X
    inc ax                          ; Siguiente columna
    jmp @dt_col_loop

@dt_next_row:
    inc bp                          ; Siguiente fila
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

    ; Limitar X de cámara
    mov ax, camera_tile_x
    cmp ax, 0
    jge @ccp_check_max_x
    mov ax, 0
    jmp @ccp_store_x

@ccp_check_max_x:
    mov bx, map_width
    sub bx, VIEWPORT_TILES_X        ; 20 - 10 = máx 10
    cmp bx, 0
    jge @ccp_check_x_limit
    mov bx, 0

@ccp_check_x_limit:
    cmp ax, bx
    jle @ccp_store_x
    mov ax, bx

@ccp_store_x:
    mov camera_tile_x, ax

    ; Limitar Y de cámara  
    mov ax, camera_tile_y
    cmp ax, 0
    jge @ccp_check_max_y
    mov ax, 0
    jmp @ccp_store_y

@ccp_check_max_y:
    mov bx, map_height
    sub bx, VIEWPORT_TILES_Y        ; 15 - 6 = máx 9
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
    
    ; Debug: Forzar mapa por defecto temporalmente
    mov dx, OFFSET debug_force_default
    mov ah, 09h
    int 21h
    
    ; TEMPORAL: Saltar directo al mapa por defecto
    jmp LMFF_UseDefault

    ; (El resto del código permanece igual para futuras correcciones)
    ; Intentar abrir archivo
    mov dx, OFFSET mapFileName
    call OpenFile
    jc LMFF_FileError
    
    ; Debug: Archivo abierto
    mov dx, OFFSET debug_file_ok
    mov ah, 09h
    int 21h
    
    call LoadMapHeader
    jc LMFF_HeaderError
    
    call LoadMapData  
    jc LMFF_DataError
    
    ; Éxito
    mov map_loaded, 1
    mov dx, OFFSET debug_success
    mov ah, 09h
    int 21h
    call CloseFile
    jmp LMFF_Done

LMFF_FileError:
    mov dx, OFFSET debug_file_error
    mov ah, 09h
    int 21h
    jmp LMFF_UseDefault

LMFF_HeaderError:
    mov dx, OFFSET debug_header_error
    mov ah, 09h
    int 21h
    call CloseFile
    jmp LMFF_UseDefault

LMFF_DataError:
    mov dx, OFFSET debug_data_error
    mov ah, 09h
    int 21h
    call CloseFile
    jmp LMFF_UseDefault

LMFF_UseDefault:
    mov dx, OFFSET debug_using_default
    mov ah, 09h
    int 21h
    call CreateDefaultMap

LMFF_Done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
LoadMapFromFile ENDP

; ===== NUEVO: Cargar encabezado del mapa =====
LoadMapHeader PROC
    push ax
    push bx
    
    call ReadLine
    call ParseTwoInts
    
    ; Verificar ancho
    mov ax, mapW
    cmp ax, 1
    jb LMH_Error
    cmp ax, MAX_MAP_WIDTH  
    ja LMH_Error
    
    ; Verificar alto
    mov ax, mapH
    cmp ax, 1
    jb LMH_Error
    cmp ax, MAX_MAP_HEIGHT
    ja LMH_Error
    
    ; Dimensiones válidas
    mov ax, mapW
    mov map_width, ax
    mov ax, mapH
    mov map_height, ax
    
    call PrintMapDimensions        ; Mover debug a procedimiento separado
    call ClearMapData
    clc                           ; Sin error
    jmp LMH_Exit

LMH_Error:
    stc                           ; Con error

LMH_Exit:
    pop bx
    pop ax
    ret
LoadMapHeader ENDP

; ===== NUEVO: Procedimiento separado para debug =====
PrintMapDimensions PROC
    push ax
    push dx
    
    ; Debug: Mostrar dimensiones
    mov dx, OFFSET debug_dimensions
    mov ah, 09h
    int 21h
    mov ax, mapW
    call PrintDecimalAX
    mov dx, OFFSET debug_x_sep
    mov ah, 09h
    int 21h
    mov ax, mapH
    call PrintDecimalAX
    mov dx, OFFSET crlf
    mov ah, 09h
    int 21h
    
    pop dx
    pop ax
    ret
PrintMapDimensions ENDP

; ===== NUEVO: Cargar datos del mapa =====
LoadMapData PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    xor dx, dx                    ; DX = fila actual

LMD_RowLoop:
    mov ax, dx
    cmp ax, mapH
    jb LMD_Continue              ; Cambio: usar jb (salto hacia adelante corto)
    jmp LMD_Success              ; Salto largo directo
    
LMD_Continue:
    call ReadLine
    mov si, OFFSET lineBuffer
    mov al, [si]
    cmp al, 'R'
    je LMD_Success               ; Este salto ya es corto
    
    ; Procesar fila
    push dx
    call ProcessMapRow
    pop dx
    
    inc dx
    jmp LMD_RowLoop

LMD_Success:
    clc                           ; Sin error

LMD_Exit:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
LoadMapData ENDP

; ===== NUEVO: Procesar una fila del mapa =====
ProcessMapRow PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov si, OFFSET lineBuffer
    xor cx, cx                    ; CX = columna actual

PMR_ColLoop:
    mov ax, cx
    cmp ax, mapW
    jb PMR_Continue              ; Cambio: usar jb (salto hacia adelante corto)
    jmp PMR_Done                 ; Salto largo directo

PMR_Continue:
    call ParseNextInt
    call StoreMapTile
    
    inc cx
    jmp PMR_ColLoop

PMR_Done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ProcessMapRow ENDP

; ===== NUEVO: Procedimiento auxiliar para almacenar tile =====
StoreMapTile PROC
    push ax
    push bx
    push di
    
    ; Calcular offset en map_data
    push ax
    mov ax, dx                    ; DX = fila (pasada como parámetro)
    mul map_width
    add ax, cx
    mov di, OFFSET map_data
    add di, ax
    pop ax
    
    ; Validar y almacenar
    cmp ax, 255
    ja SMT_StoreZero
    mov [di], al
    jmp SMT_Done

SMT_StoreZero:
    mov BYTE PTR [di], 0

SMT_Done:
    pop di
    pop bx
    pop ax
    ret
StoreMapTile ENDP

; ===== RUTINAS AUXILIARES PARA DEBUGGING =====

PrintDecimalAX PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov si, 10                     ; Divisor para conversión decimal
    xor cx, cx                     ; Contador de dígitos

@print_decimal_loop:
    xor dx, dx
    div si                         ; DX:AX = AX / 10
    push dx                        ; Guardar dígito en la pila
    inc cx                         ; Aumentar contador de dígitos
    test ax, ax
    jnz @print_decimal_loop

    ; Imprimir dígitos en orden inverso
@print_decimal_pop:
    pop dx
    add dl, '0'                   ; Convertir a carácter ASCII
    mov ah, 02h
    int 21h
    loop @print_decimal_pop

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
PrintDecimalAX ENDP

; ===== NUEVO: Rutina auxiliar para copiar un plano =====
CopyPlaneToVRAM PROC
    ; Entrada: AX = segmento del plano, BL = máscara del plano
    ; Modifica: SI, DI, CX, usa DS temporalmente
    push ds
    push ax
    push bx
    push dx
    
    mov ds, ax                     ; DS = segmento del plano
    xor si, si                     ; SI = 0 (inicio del buffer)
    
    ; Configurar máscara del plano
    mov dx, 03C4h
    mov al, 02h
    out dx, al
    inc dx
    mov al, bl                     ; AL = máscara del plano
    out dx, al
    
    ; Calcular offset inicial en VRAM
    mov ax, viewport_y_offset
    mov dx, VRAM_BYTES_PER_SCAN
    mul dx
    mov di, ax
    add di, viewport_x_offset
    
    ; Copiar VIEWPORT_HEIGHT líneas
    mov bx, VIEWPORT_HEIGHT
    
@cptv_loop:
    push si
    push di
    push bx
    
    mov cx, BYTES_PER_SCAN         ; 20 bytes por línea
    rep movsb                      ; Copiar línea completa
    
    pop bx
    pop di
    pop si
    
    ; Siguiente línea
    add si, BYTES_PER_SCAN         ; Siguiente línea en buffer
    add di, VRAM_BYTES_PER_SCAN    ; Siguiente línea en VRAM
    
    dec bx
    jnz @cptv_loop
    
    pop dx
    pop bx
    pop ax
    pop ds
    ret
CopyPlaneToVRAM ENDP

; ===== CORRECCIÓN: BlitBufferToScreen =====
BlitBufferToScreen PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push ds
    push es

    ; Verificar que los buffers estén inicializados
    mov ax, Plane0Segment
    or ax, ax
    jz @bbts_exit

    ; Configurar segmento de VRAM
    mov ax, 0A000h
    mov es, ax
    cld

    ; Copiar plano 0 (bit 0 del color)
    mov ax, Plane0Segment
    or ax, ax
    jz @bbts_check_p1
    mov bl, 01h                    ; Máscara plano 0
    call CopyPlaneToVRAM

@bbts_check_p1:
    ; Copiar plano 1 (bit 1 del color)  
    mov ax, Plane1Segment
    or ax, ax
    jz @bbts_check_p2
    mov bl, 02h                    ; Máscara plano 1
    call CopyPlaneToVRAM

@bbts_check_p2:
    ; Copiar plano 2 (bit 2 del color)
    mov ax, Plane2Segment
    or ax, ax
    jz @bbts_check_p3
    mov bl, 04h                    ; Máscara plano 2
    call CopyPlaneToVRAM

@bbts_check_p3:
    ; Copiar plano 3 (bit 3 del color)
    mov ax, Plane3Segment
    or ax, ax
    jz @bbts_restore
    mov bl, 08h                    ; Máscara plano 3
    call CopyPlaneToVRAM

@bbts_restore:
    ; Restaurar máscara de todos los planos
    mov dx, 03C4h
    mov al, 02h
    out dx, al
    inc dx
    mov al, 0Fh                    ; Todos los planos
    out dx, al

@bbts_exit:
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
