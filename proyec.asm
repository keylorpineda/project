; Programa para modo gráfico EGA 640x350 16 colores con doble buffer
; Ensamblador 8086/8088 - Sintaxis TASM

.MODEL SMALL                      ; Usar modelo de memoria small (código y datos < 64K)
.STACK 100h                       ; Reservar 256 bytes para la pila

; Constantes generales del modo gráfico
SCREEN_WIDTH      EQU 640         ; Ancho de pantalla en píxeles
SCREEN_HEIGHT     EQU 350         ; Alto de pantalla en píxeles
BYTES_PER_SCAN    EQU 20          ; Fix: Ajuste a viewport 160x100 (160/8)
PLANE_SIZE        EQU 2000        ; Fix: Tamaño del plano reducido (20 bytes * 100 scans)
PLANE_PARAGRAPHS  EQU 128         ; Fix: 128 párrafos (8 KB) para reserva segura
VIEWPORT_WIDTH    EQU 160         ; Ancho del viewport en píxeles
VIEWPORT_HEIGHT   EQU 100         ; Alto del viewport en píxeles
VIEWPORT_PIXELS   EQU VIEWPORT_WIDTH * VIEWPORT_HEIGHT
VIEWPORT_BYTES    EQU PLANE_SIZE  ; 20 bytes * 100 filas para el viewport
LINE_BUFFER_SIZE  EQU 128         ; Tamaño del buffer temporal para lectura

.DATA                             ; Segmento de datos
Plane0Segment    dw 0             ; Segmento del plano 0 (bit de peso 1)
Plane1Segment    dw 0             ; Segmento del plano 1 (bit de peso 2)
Plane2Segment    dw 0             ; Segmento del plano 2 (bit de peso 4)
Plane3Segment    dw 0             ; Segmento del plano 3 (bit de peso 8)
psp_seg          dw 0             ; Fix: Para PSP segment
viewport_x_offset dw 30           ; Fix: Desfase horizontal (centrado 160 px en 640)
viewport_y_offset dw 10000        ; 125 * 80 bytes → centra 100 filas en 350 (modo 10h)
msg_err          db 'ERROR: Alloc fallo. Codigo: $'
msg_free         db ' (free block: $'
msg_shrink_fail  db 'Shrink fail',13,10,'$'
crlf             db 13,10,'$'
mapHandle       dw 0FFFFh        ; Handle actual del archivo del mapa o -1
mapW            dw 0             ; Ancho del mapa en tiles
mapH            dw 0             ; Alto del mapa en tiles
mapFileName     db 'mapa.txt',0  ; Nombre del archivo de mapa (ASCIIZ)
lineBuffer      db LINE_BUFFER_SIZE dup (0) ; Buffer para lectura de líneas
readChar        db 0             ; Byte temporal de lectura
x_pos           dw 20            ; Posición inicial X de la línea roja
y_pos           dw 20            ; Posición inicial Y de la línea roja
line_len        dw 80            ; Longitud de la línea roja
speed_dx        dw 1             ; Velocidad horizontal (1 píxel)
speed_dy        dw 1             ; Velocidad vertical (1 píxel)

.CODE                             ; Segmento de código

; FIX: Nueva rutina para verificar si el modo gráfico se estableció correctamente
CheckGraphicsMode PROC
    push ax
    push bx
    
    mov ah, 0Fh                   ; Obtener modo de video actual
    int 10h
    cmp al, 10h                   ; ¿Es modo 10h (640x350x16)?
    je @mode_ok
    
    ; Si no es modo 10h, intentar modo alternativo
    mov ax, 000Eh                 ; Intentar modo 0Eh (640x200x16)
    int 10h
    mov ah, 0Fh
    int 10h
    cmp al, 0Eh
    je @mode_ok
    
    ; Si tampoco funciona, usar modo básico
    mov ax, 0004h                 ; Modo CGA 320x200x4
    int 10h
    
@mode_ok:
    pop bx
    pop ax
    ret
CheckGraphicsMode ENDP

; -------------------------------------------------------------------------
; Rutina: ShrinkProgramMemory
; Reduce el bloque de memoria asignado al programa antes de reservar
; memoria adicional para los planos. Esto libera memoria "prestada" que el
; cargador asigna al .EXE al iniciarse.
; -------------------------------------------------------------------------
ShrinkProgramMemory PROC
    push ax
    push bx
    push cx
    push dx
    push es

    mov ax, psp_seg
    or ax, ax
    jnz @have_psp

    mov ah, 51h                     ; Fix: Obtener segmento del PSP actual
    int 21h
    mov psp_seg, bx

@have_psp:
    mov es, psp_seg                 ; PSP segment para INT 21h/4Ah
    mov ax, es:[2]                  ; AX = párrafos originales
    shr ax, 1                       ; Fix: Estimar tamaño de código propio

    mov ah, 4Ah                     ; Función DOS para encoger bloque
    mov bx, 200                     ; FIX: Aumentar de 100 a 200 paragraphs
    int 21h
    jc @shrink_fail

    xor ax, ax                      ; Fix: AX=0 indica shrink exitoso
    jmp @exit

@shrink_fail:
    ; Fix: Quitar mensaje shrink para evitar basura en salida
    ; mov dx, offset msg_shrink_fail
    ; mov ah, 09h
    ; int 21h
    mov ax, 1                       ; Fix: AX=1 indica shrink no disponible

@exit:
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ShrinkProgramMemory ENDP

; -------------------------------------------------------------------------
; Rutina: InitOffScreenBuffer
; Reserva memoria convencional (mediante INT 21h, función 48h) para los
; cuatro planos del buffer off-screen. Devuelve AX=0 si la reserva tuvo
; éxito; en caso contrario, AX contiene el código de error devuelto por DOS.
; -------------------------------------------------------------------------
InitOffScreenBuffer PROC
    push bx
    push cx
    push dx
    push es

    ; Asegurarse de que los segmentos están en cero antes de reservar.
    mov Plane0Segment, 0
    mov Plane1Segment, 0
    mov Plane2Segment, 0
    mov Plane3Segment, 0

    mov bx, PLANE_PARAGRAPHS      ; Fix: Reserva 8 KB por plano reducido

    mov ah, 48h                    ; Reservar memoria para el plano 0
    int 21h
    jc @AllocationFailed
    mov Plane0Segment, ax

    mov ah, 48h                    ; Reservar memoria para el plano 1
    mov bx, PLANE_PARAGRAPHS      ; Fix: Reaplicar tamaño reducido
    int 21h
    jc @AllocationFailed
    mov Plane1Segment, ax

    mov ah, 48h                    ; Reservar memoria para el plano 2
    mov bx, PLANE_PARAGRAPHS      ; Fix: Reaplicar tamaño reducido
    int 21h
    jc @AllocationFailed
    mov Plane2Segment, ax

    mov ah, 48h                    ; Reservar memoria para el plano 3
    mov bx, PLANE_PARAGRAPHS      ; Fix: Reaplicar tamaño reducido
    int 21h
    jc @AllocationFailed
    mov Plane3Segment, ax

    xor ax, ax                     ; AX=0 indica éxito
    jmp @InitExit

@AllocationFailed:
    push ax                        ; Guardar código de error
    call ReleaseOffScreenBuffer    ; Liberar cualquier bloque ya reservado
    pop ax                         ; Recuperar el código de error original

@InitExit:
    pop es
    pop dx
    pop cx
    pop bx
    ret
InitOffScreenBuffer ENDP

; -------------------------------------------------------------------------
; Rutina: ReleaseOffScreenBuffer
; Libera los bloques de memoria reservados para los planos del buffer
; off-screen (INT 21h, función 49h).
; -------------------------------------------------------------------------
ReleaseOffScreenBuffer PROC
    push ax
    push es

    mov ax, Plane0Segment
    or ax, ax
    jz @SkipFree0
    mov es, ax
    mov ah, 49h
    int 21h
    mov Plane0Segment, 0
@SkipFree0:

    mov ax, Plane1Segment
    or ax, ax
    jz @SkipFree1
    mov es, ax
    mov ah, 49h
    int 21h
    mov Plane1Segment, 0
@SkipFree1:

    mov ax, Plane2Segment
    or ax, ax
    jz @SkipFree2
    mov es, ax
    mov ah, 49h
    int 21h
    mov Plane2Segment, 0
@SkipFree2:

    mov ax, Plane3Segment
    or ax, ax
    jz @SkipFree3
    mov es, ax
    mov ah, 49h
    int 21h
    mov Plane3Segment, 0
@SkipFree3:

    pop es
    pop ax
    ret
ReleaseOffScreenBuffer ENDP

; ----------------------------------------------------------------------------
; Rutina: ClearOffScreenBuffer
; Borra los cuatro planos del buffer off-screen llenándolos con cero.
; ----------------------------------------------------------------------------
ClearOffScreenBuffer PROC
    cld
    push ax                        ; Guardar registros usados
    push cx
    push di
    push es

    mov ax, Plane0Segment          ; Borrar plano 0
    or ax, ax
    jz @SkipPlane0
    mov es, ax
    xor ax, ax                     ; Fix: AL=0 para stosb
    xor di, di
    mov cx, PLANE_SIZE            ; Fix: Conteo ajustado al viewport reducido
    rep stosb
@SkipPlane0:

    mov ax, Plane1Segment          ; Borrar plano 1
    or ax, ax
    jz @SkipPlane1
    mov es, ax
    xor ax, ax                     ; Fix: AL=0 para stosb
    xor di, di
    mov cx, PLANE_SIZE            ; Fix: Conteo ajustado al viewport reducido
    rep stosb
@SkipPlane1:

    mov ax, Plane2Segment          ; Borrar plano 2
    or ax, ax
    jz @SkipPlane2
    mov es, ax
    xor ax, ax                     ; Fix: AL=0 para stosb
    xor di, di
    mov cx, PLANE_SIZE            ; Fix: Conteo ajustado al viewport reducido
    rep stosb
@SkipPlane2:

    mov ax, Plane3Segment          ; Borrar plano 3
    or ax, ax
    jz @SkipPlane3
    mov es, ax
    xor ax, ax                     ; Fix: AL=0 para stosb
    xor di, di
    mov cx, PLANE_SIZE            ; Fix: Conteo ajustado al viewport reducido
    rep stosb
@SkipPlane3:

    pop es                         ; Restaurar registros
    pop di
    pop cx
    pop ax
    ret
ClearOffScreenBuffer ENDP

; ...existing code...

; FIX: Rutina de prueba simple para verificar que el hardware funciona
SimpleDrawTest PROC
    push ax
    push cx
    push dx
    push di
    push es
    
    mov ax, 0A000h
    mov es, ax
    
    ; Configurar sequencer para escribir en todos los planos
    mov dx, 03C4h
    mov al, 02h
    out dx, al
    inc dx
    mov al, 0Fh                   ; Escribir en todos los planos
    out dx, al
    
    ; Dibujar algunas líneas de prueba
    xor di, di
    mov al, 15                    ; Color blanco
    mov cx, 160                   ; Primera línea horizontal
    rep stosb
    
    ; Saltar a línea 50
    mov di, 4000                  ; 50 * 80 bytes
    mov al, 4                     ; Color rojo
    mov cx, 160
    rep stosb
    
    ; Saltar a línea 100
    mov di, 8000                  ; 100 * 80 bytes
    mov al, 2                     ; Color verde
    mov cx, 160
    rep stosb
    
    pop es
    pop di
    pop dx
    pop cx
    pop ax
    ret
SimpleDrawTest ENDP

; ----------------------------------------------------------------------------
; Rutinas de manejo de archivo ASCII (lectura de mapa)
; ----------------------------------------------------------------------------
OpenFile PROC
    push dx
    mov ah, 3Dh                   ; Abrir archivo en modo solo lectura
    xor al, al
    int 21h
    jc @open_error
    mov mapHandle, ax             ; Guardar handle válido
    clc
    pop dx
    ret

@open_error:
    mov mapHandle, 0FFFFh         ; Indicar handle inválido
    stc
    pop dx
    ret
OpenFile ENDP

CloseFile PROC
    push ax
    push bx
    mov ax, mapHandle
    cmp ax, 0FFFFh
    je @close_done                ; Nada que cerrar
    mov bx, ax
    mov ah, 3Eh                   ; Cerrar archivo
    int 21h
    mov mapHandle, 0FFFFh
@close_done:
    pop bx
    pop ax
    ret
CloseFile ENDP

ReadLine PROC
    cld
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    mov ax, ds                    ; Espejo DS en ES para limpiar buffer
    mov es, ax
    mov di, OFFSET lineBuffer
    mov cx, LINE_BUFFER_SIZE
    xor al, al
    rep stosb

    mov bx, mapHandle
    cmp bx, 0FFFFh
    je @rl_done                   ; Handle inválido, salir

    mov di, OFFSET lineBuffer

@rl_next:
    mov ah, 3Fh                   ; Leer 1 byte
    mov cx, 1
    mov dx, OFFSET readChar
    int 21h
    jc @rl_done
    cmp ax, 0
    je @rl_done                   ; Fin de archivo

    mov al, readChar
    cmp al, 0Dh
    je @rl_next                   ; Ignorar CR
    cmp al, 0Ah
    je @rl_done                   ; Fin de línea

    cmp di, OFFSET lineBuffer + LINE_BUFFER_SIZE - 1
    jae @rl_next                  ; Evitar desbordar, continuar lectura

    mov [di], al
    inc di
    jmp @rl_next

@rl_done:
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

; --- Primer entero (ancho) ---
@skip_ws1:
    mov al, [si]
    cmp al, 0
    je @store_width
    cmp al, ' '
    je @adv_ws1
    cmp al, 9
    je @adv_ws1
    jmp @parse_width
@adv_ws1:
    inc si
    jmp @skip_ws1

@parse_width:
    xor ax, ax
@width_loop:
    mov al, [si]
    cmp al, '0'
    jb @store_width
    cmp al, '9'
    ja @store_width
    mov dl, [si]
    sub dl, '0'
    xor dh, dh
    mov cx, ax
    shl ax, 1
    shl cx, 3
    add ax, cx
    add ax, dx
    inc si
    jmp @width_loop

@store_width:
    mov mapW, ax

; --- Segundo entero (alto) ---
@skip_ws2:
    mov al, [si]
    cmp al, 0
    je @done_parse
    cmp al, ' '
    je @adv_ws2
    cmp al, 9
    je @adv_ws2
    jmp @parse_height
@adv_ws2:
    inc si
    jmp @skip_ws2

@parse_height:
    xor ax, ax
@height_loop:
    mov al, [si]
    cmp al, '0'
    jb @store_height
    cmp al, '9'
    ja @store_height
    mov dl, [si]
    sub dl, '0'
    xor dh, dh
    mov cx, ax
    shl ax, 1
    shl cx, 3
    add ax, cx
    add ax, dx
    inc si
    jmp @height_loop

@store_height:
    mov mapH, ax

@done_parse:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ParseTwoInts ENDP

; ----------------------------------------------------------------------------
; Render del mapa simplificado: todo el viewport en verde (color 2)
; ----------------------------------------------------------------------------
RenderMapGreenViewport PROC
    cld
    push ax
    push cx
    push di
    push es

    mov ax, Plane0Segment          ; Plano 0 = 0 (bit 0)
    or ax, ax
    jz @skip_plane0
    mov es, ax
    xor di, di
    xor al, al
    mov cx, VIEWPORT_BYTES
    rep stosb
@skip_plane0:

    mov ax, Plane2Segment          ; Plano 2 = 0 (bit 2)
    or ax, ax
    jz @skip_plane2
    mov es, ax
    xor di, di
    xor al, al
    mov cx, VIEWPORT_BYTES
    rep stosb
@skip_plane2:

    mov ax, Plane3Segment          ; Plano 3 = 0 (bit 3)
    or ax, ax
    jz @skip_plane3
    mov es, ax
    xor di, di
    xor al, al
    mov cx, VIEWPORT_BYTES
    rep stosb
@skip_plane3:

    mov ax, Plane1Segment          ; Plano 1 = FFh (color 2)
    or ax, ax
    jz @rm_exit
    mov es, ax
    xor di, di
    mov al, 0FFh
    mov cx, VIEWPORT_BYTES
    rep stosb

@rm_exit:
    pop es
    pop di
    pop cx
    pop ax
    ret
RenderMapGreenViewport ENDP

; ----------------------------------------------------------------------------
; Rutina: SetPaletteRed
; Ajusta el color 4 de la paleta EGA a rojo brillante (R=63, G=0, B=0).
; Esto mejora la visibilidad de los elementos renderizados en el viewport.
; ----------------------------------------------------------------------------
SetPaletteRed PROC
    ret                             ; Stub: mantener compatibilidad sin tocar DAC VGA
SetPaletteRed ENDP

; ----------------------------------------------------------------------------
; Rutina: SetPaletteWhite
; Ajusta el color 15 de la paleta EGA a blanco completo (R=63, G=63, B=63)
; para mejorar la visibilidad de los elementos de prueba.
; ----------------------------------------------------------------------------
SetPaletteWhite PROC
    ret                             ; Stub: sin cambios de paleta para EGA pura
SetPaletteWhite ENDP

; Test: Direct draw cruz blanca/roja top-left sin buffer
DirectDrawTest PROC
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
    mov al, 0Fh                   ; FIX: Escribir en todos los planos
    out dx, al
    dec dx

    xor di, di
    mov al, 15                    ; FIX: Color blanco brillante
    mov cx, 160
    rep stosb

    xor di, di
    mov cx, 100
@vert:
    mov BYTE PTR es:[di], 15      ; FIX: Color blanco brillante
    add di, 80
    loop @vert

    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DirectDrawTest ENDP

; Fix: Limpia full A000h para eliminar garbage de modo anterior
ClearScreen PROC
    cld
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
    mov cx, 28000                ; Fix: 350*80 bytes totales modo 10h
    rep stosb

    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ClearScreen ENDP

; ----------------------------------------------------------------------------
; Rutina: DrawPixel
; Dibuja un píxel en el buffer off-screen usando coordenadas (X,Y) y color C.
;  Entradas:
;       BX = coordenada X (0..639)
;       CX = coordenada Y (0..349)
;       DL = color (0..15, 4 bits -> planos 0..3)
; ----------------------------------------------------------------------------
DrawPixel PROC
    push ax                        ; Guardar registros modificados
    push bx
    push cx
    push dx
    push si
    push di
    push es

    cmp bx, 159                    ; Fix: Limit viewport 160x100
    jbe @CheckYBounds
    jmp NEAR PTR @exit_pixel

@CheckYBounds:
    cmp cx, 99                     ; Fix: Limit viewport 160x100
    jbe @PixelWithinBounds
    jmp NEAR PTR @exit_pixel

@PixelWithinBounds:

    mov dh, dl                     ; Fix: Conservar el color completo en DH

    mov ax, BYTES_PER_SCAN         ; Fix: AX=20 para multiplicar Y en viewport
    mul cx                         ; DX:AX = Y * 20 (sin overflow para 100 líneas)
    mov di, ax                     ; DI = Y * 20

    mov si, bx                     ; Fix: Guardar X original en SI
    mov ax, si
    shr ax, 3                      ; AX = X / 8 (índice de byte)
    add di, ax                     ; DI = offset final dentro del plano

    mov ax, si
    and ax, 7                      ; AX = X mod 8
    mov cl, 7
    sub cl, al                     ; CL = 7 - (X mod 8)
    mov al, 1
    shl al, cl                     ; AL = máscara del bit del píxel
    mov bl, al                     ; BL = máscara directa
    mov bh, bl                     ; Fix: Copia de la máscara
    not bh                         ; Fix: Máscara invertida para limpiar el bit

    mov si, di                     ; Fix: Guardar offset para reutilizar en cada plano

    mov ax, Plane0Segment          ; Plano 0 (bit 0)
    or ax, ax
    jz @NextPlane0
    mov es, ax
    mov di, si
    test dh, 1
    jz @ClearPlane0
    mov al, bl
    or BYTE PTR es:[di], al        ; Fix: Especificar tamaño byte al establecer
    jmp @NextPlane0
@ClearPlane0:
    mov al, bh
    and BYTE PTR es:[di], al       ; Fix: Especificar tamaño byte al limpiar
@NextPlane0:

    mov ax, Plane1Segment          ; Plano 1 (bit 1)
    or ax, ax
    jz @NextPlane1
    mov es, ax
    mov di, si
    test dh, 2
    jz @ClearPlane1
    mov al, bl
    or BYTE PTR es:[di], al        ; Fix: Especificar tamaño byte al establecer
    jmp @NextPlane1
@ClearPlane1:
    mov al, bh
    and BYTE PTR es:[di], al       ; Fix: Especificar tamaño byte al limpiar
@NextPlane1:

    mov ax, Plane2Segment          ; Plano 2 (bit 2)
    or ax, ax
    jz @NextPlane2
    mov es, ax
    mov di, si
    test dh, 4
    jz @ClearPlane2
    mov al, bl
    or BYTE PTR es:[di], al        ; Fix: Especificar tamaño byte al establecer
    jmp @NextPlane2
@ClearPlane2:
    mov al, bh
    and BYTE PTR es:[di], al       ; Fix: Especificar tamaño byte al limpiar
@NextPlane2:

    mov ax, Plane3Segment          ; Plano 3 (bit 3)
    or ax, ax
    jz @NextPlane3
    mov es, ax
    mov di, si
    test dh, 8
    jz @ClearPlane3
    mov al, bl
    or BYTE PTR es:[di], al        ; Fix: Especificar tamaño byte al establecer
    jmp @NextPlane3
@ClearPlane3:
    mov al, bh
    and BYTE PTR es:[di], al       ; Fix: Especificar tamaño byte al limpiar
@NextPlane3:

@exit_pixel:
    pop es                         ; Restaurar registros
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DrawPixel ENDP

; ----------------------------------------------------------------------------
; Rutina: BlitBufferToScreen
; Copia el contenido del buffer off-screen a la memoria de video A000h.
; Usa el registro de máscara del mapa (sequencer) para seleccionar cada plano.
; ----------------------------------------------------------------------------
BlitBufferToScreen PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push ds
    push es

    cld                             ; copiar hacia adelante

    mov ax, 0A000h
    mov es, ax
    mov dx, 03C4h                   ; Sequencer base

    ; ========= PLANO 0 =========
    mov ax, Plane0Segment
    or  ax, ax
    jz  @Skip0
    mov bx, ax                      ; BX = seg del plano 0
    mov al, 02h
    out dx, al
    inc dx
    mov al, 1                       ; Map Mask = 0001b
    out dx, al
    dec dx

    push ds
    mov ds, bx
    xor si, si
    mov di, viewport_y_offset
    add di, viewport_x_offset

    mov cx, VIEWPORT_HEIGHT         ; 100 filas
@Row0:
    push cx
    mov cx, BYTES_PER_SCAN          ; 20 bytes por fila
    rep movsb                       ; copia DS:SI -> ES:DI (20 bytes)
    add di, (80 - BYTES_PER_SCAN)   ; saltar 60 bytes hasta inicio de la próxima fila en VRAM
    pop cx
    loop @Row0
    pop ds
@Skip0:

    ; ========= PLANO 1 =========
    mov ax, Plane1Segment
    or  ax, ax
    jz  @Skip1
    mov bx, ax
    mov al, 02h
    out dx, al
    inc dx
    mov al, 2                       ; Map Mask = 0010b
    out dx, al
    dec dx

    push ds
    mov ds, bx
    xor si, si
    mov di, viewport_y_offset
    add di, viewport_x_offset
    mov cx, VIEWPORT_HEIGHT
@Row1:
    push cx
    mov cx, BYTES_PER_SCAN
    rep movsb
    add di, (80 - BYTES_PER_SCAN)
    pop cx
    loop @Row1
    pop ds
@Skip1:

    ; ========= PLANO 2 =========
    mov ax, Plane2Segment
    or  ax, ax
    jz  @Skip2
    mov bx, ax
    mov al, 02h
    out dx, al
    inc dx
    mov al, 4                       ; Map Mask = 0100b
    out dx, al
    dec dx

    push ds
    mov ds, bx
    xor si, si
    mov di, viewport_y_offset
    add di, viewport_x_offset
    mov cx, VIEWPORT_HEIGHT
@Row2:
    push cx
    mov cx, BYTES_PER_SCAN
    rep movsb
    add di, (80 - BYTES_PER_SCAN)
    pop cx
    loop @Row2
    pop ds
@Skip2:

    ; ========= PLANO 3 =========
    mov ax, Plane3Segment
    or  ax, ax
    jz  @Skip3
    mov bx, ax
    mov al, 02h
    out dx, al
    inc dx
    mov al, 8                       ; Map Mask = 1000b
    out dx, al
    dec dx

    push ds
    mov ds, bx
    xor si, si
    mov di, viewport_y_offset
    add di, viewport_x_offset
    mov cx, VIEWPORT_HEIGHT
@Row3:
    push cx
    mov cx, BYTES_PER_SCAN
    rep movsb
    add di, (80 - BYTES_PER_SCAN)
    pop cx
    loop @Row3
    pop ds
@Skip3:

    ; Restaurar: habilitar los cuatro planos
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

DrawRedLine PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov ax, line_len
    cmp ax, 0
    jz @dr_exit                  ; Nada que dibujar si longitud es cero

    mov dx, VIEWPORT_WIDTH - 1
    sub dx, ax
    inc dx                       ; DX = 159 - line_len + 1
    mov bx, x_pos
    cmp bx, dx
    jbe @dr_clamp_y
    mov bx, dx
    mov x_pos, bx                ; Clamp horizontal máximo

@dr_clamp_y:
    mov ax, y_pos
    cmp ax, VIEWPORT_HEIGHT - 1
    jbe @dr_setup
    mov ax, VIEWPORT_HEIGHT - 1
    mov y_pos, ax                ; Clamp vertical máximo

@dr_setup:
    mov cx, y_pos
    mov si, x_pos
    mov di, line_len

@dr_loop:
    mov bx, si
    mov dl, 12                   ; 1100b = rojo brillante (mejor contraste)
    call DrawPixel               ; Usa rutina existente (planar seguro)
    inc si
    dec di
    jnz @dr_loop

@dr_exit:
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

    mov ah, 01h                  ; ¿Hay tecla disponible?
    int 16h
    jz @rknb_none

    mov ah, 00h                  ; Leer tecla
    int 16h
    cmp al, 'a'
    jb @rknb_upper_done
    cmp al, 'z'
    ja @rknb_upper_done
    sub al, 20h                  ; Normalizar a mayúscula
@rknb_upper_done:
    xor ah, ah
    pop dx
    pop cx
    pop bx
    ret

@rknb_none:
    xor ax, ax                   ; Sin tecla → AX=0
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

    mov bl, cl                   ; Guardar número de ticks a esperar
    or bl, bl
    jz @dt_exit

    mov ah, 00h
    int 1Ah                      ; Leer contador actual
    mov si, dx                   ; Guardar DX (parte baja)
    mov di, cx                   ; Guardar CX (parte alta)

@dt_wait:
    mov ah, 00h
    int 1Ah
    cmp cx, di
    jne @dt_tick
    cmp dx, si
    jne @dt_tick
    jmp @dt_wait

@dt_tick:
    dec bl
    jz @dt_exit
    mov si, dx
    mov di, cx
    jmp @dt_wait

@dt_exit:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DelayTicks ENDP

MainLoop PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

@frame_loop:
    call ClearOffScreenBuffer
    call RenderMapGreenViewport
    call DrawRedLine
    call BlitBufferToScreen

    call ReadKeyNonBlocking
    cmp ax, 0
    je @no_key

    cmp al, 1Bh                  ; ESC → salir
    je @exit_loop

    cmp al, 'W'
    jne @check_s
    mov bx, speed_dy
    mov ax, y_pos
    cmp ax, bx
    jb @handled
    sub ax, bx
    mov y_pos, ax
    jmp @handled

@check_s:
    cmp al, 'S'
    jne @check_a
    mov bx, speed_dy
    mov ax, y_pos
    mov dx, VIEWPORT_HEIGHT - 1
    sub dx, bx
    cmp ax, dx
    ja @handled
    add ax, bx
    mov y_pos, ax
    jmp @handled

@check_a:
    cmp al, 'A'
    jne @check_d
    mov bx, speed_dx
    mov ax, x_pos
    cmp ax, bx
    jb @handled
    sub ax, bx
    mov x_pos, ax
    jmp @handled

@check_d:
    cmp al, 'D'
    jne @handled
    mov bx, speed_dx
    mov ax, x_pos
    add ax, bx
    mov dx, VIEWPORT_WIDTH - 1
    mov si, line_len
    sub dx, si
    inc dx
    cmp ax, dx
    jbe @store_x
    mov ax, dx
@store_x:
    mov x_pos, ax

@handled:
@no_key:
    mov cl, 1
    call DelayTicks              ; Pequeña pausa por frame
    jmp @frame_loop

@exit_loop:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
MainLoop ENDP

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
@loop:
    mov ax, dx
    shr ax, cl
    and al, 0Fh
    mov dl, '0'
    cmp al, 9
    jbe @num
    mov dl, 'A'
    add dl, al
    sub dl, 10
    jmp @print
@num:
    add dl, al
@print:
    mov ah, 02h
    int 21h
    shl dx, 1
    shl dx, 1
    shl dx, 1
    shl dx, 1
    shr bx, 4                       ; Fix: Avanzar siguiente nibble desde MSB
    dec si
    jnz @loop
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
PrintHexAX ENDP                     ; Fix: Hex correcto, MSB first, A-F

main PROC
    mov ax, @data                  ; Inicializar el segmento de datos
    mov ds, ax

    call ShrinkProgramMemory       ; Fix: Liberar memoria prestada antes de reservar planos

    call InitOffScreenBuffer       ; Reservar memoria para el buffer off-screen
    cmp ax, 0
    je @ok_print

    mov si, ax                     ; Fix: Preservar código de error
    mov dx, offset msg_err         ; Fix: Mensaje de error
    mov ah, 09h
    int 21h
    mov ax, si
    push ax                        ; Fix: Guardar error para depuración
    call PrintHexAX
    mov dx, offset msg_free        ; Fix: Mostrar bloque libre más grande
    mov ah, 09h
    int 21h
    pop ax                         ; Fix: Limpiar pila tras imprimir error
    mov ax, bx
    call PrintHexAX
    mov dx, offset crlf
    mov ah, 09h
    int 21h
    mov ah, 4Ch                    ; Fix: Salir con código de error genérico 8
    mov al, 8
    int 21h

@ok_print:
@BuffersReady:

    mov ax, 0010h                  ; Cambiar a modo gráfico EGA 640x350x16
    int 10h

    call ClearScreen              ; Fix: Limpiar VRAM y evitar basura previa

    call SetPaletteRed             ; Stub EGA-safe (sin DAC)
    call SetPaletteWhite           ; Stub EGA-safe (sin DAC)

    push ds
    mov dx, OFFSET mapFileName     ; DS:DX -> nombre del mapa
    call OpenFile                  ; Abrir "mapa.txt"
    pop ds
    jc @skip_map_read              ; Si falla, continuar con dimensiones por defecto
    call ReadLine                  ; Leer primera línea
    call ParseTwoInts              ; Guardar mapW/mapH
@skip_map_read:
    call CloseFile                 ; Cerrar archivo si estaba abierto

    call MainLoop                  ; Bucle principal de render/interacción

    mov ax, 0003h                  ; Volver a modo texto 80x25
    int 10h

    call ReleaseOffScreenBuffer    ; Liberar memoria reservada

    mov ax, 4C00h                  ; Terminar programa
    int 21h
main ENDP

END main