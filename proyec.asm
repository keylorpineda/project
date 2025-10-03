; Programa para modo gráfico EGA 640x350 16 colores con doble buffer
; Ensamblador 8086/8088 - Sintaxis TASM
; Recomendado para DOSBox: machine=ega, cycles=3000, [sdl] output=surface

.MODEL SMALL                      ; Usar modelo de memoria small (código y datos < 64K)
.STACK 100h                       ; Reservar 256 bytes para la pila

; Constantes generales del modo gráfico
SCREEN_WIDTH      EQU 640         ; Ancho de pantalla en píxeles
SCREEN_HEIGHT     EQU 350         ; Alto de pantalla en píxeles
SCREEN_BYTES_PER_SCAN EQU 80      ; Bytes por scanline en VRAM (640/8)
SCREEN_TOTAL_BYTES EQU (SCREEN_BYTES_PER_SCAN * SCREEN_HEIGHT)
VIEWPORT_WIDTH    EQU 160         ; Ancho del viewport en píxeles
VIEWPORT_HEIGHT   EQU 100         ; Alto del viewport en píxeles
BYTES_PER_SCAN    EQU 20          ; Bytes por scanline en el viewport (160/8)
VIEWPORT_LINE_SKIP EQU (SCREEN_BYTES_PER_SCAN - BYTES_PER_SCAN)
VIEWPORT_MAX_X    EQU (VIEWPORT_WIDTH - 1)
VIEWPORT_MAX_Y    EQU (VIEWPORT_HEIGHT - 1)
PLANE_SIZE        EQU (BYTES_PER_SCAN * VIEWPORT_HEIGHT)
PLANE_PARAGRAPHS  EQU 128         ; 128 párrafos (2048 bytes) por plano
PLANE_TOTAL_PARAGRAPHS EQU (PLANE_PARAGRAPHS * 4)
HEAP_GUARD_PARAGRAPHS  EQU 16      ; Margen para otras rutinas
REQUIRED_FREE_PARAGRAPHS EQU (PLANE_TOTAL_PARAGRAPHS + HEAP_GUARD_PARAGRAPHS)
PLAYER_LINE_LENGTH EQU 20         ; Longitud de la línea del jugador en píxeles
PLAYER_MAX_X      EQU (VIEWPORT_WIDTH - PLAYER_LINE_LENGTH)

.DATA                             ; Segmento de datos
Plane0Segment    dw 0             ; Segmento del plano 0 (bit de peso 1)
Plane1Segment    dw 0             ; Segmento del plano 1 (bit de peso 2)
Plane2Segment    dw 0             ; Segmento del plano 2 (bit de peso 4)
Plane3Segment    dw 0             ; Segmento del plano 3 (bit de peso 8)
psp_seg          dw 0             ; Segmento del PSP (cacheado tras primera consulta)
viewport_x_pixels dw 0            ; Desfase horizontal en píxeles (debug: 0 = esquina superior izquierda)
viewport_y_pixels dw 0            ; Desfase vertical en píxeles (debug: 0 = esquina superior izquierda)
viewport_start_offset dw 0        ; Offset inicial en bytes dentro de VRAM para el blit
msg_err          db 'ERROR: Alloc fallo. Codigo: $'
msg_free         db ' (free block: $'
msg_shrink_fail  db 'Shrink fail',13,10,'$'
crlf             db 13,10,'$'
player_x        dw 0             ; Posición X inicial (esquina superior izquierda)
player_y        dw 50            ; Posición Y inicial de la línea del jugador
largest_block   dw 0             ; Último tamaño de bloque libre reportado por DOS
HeapEnd LABEL BYTE               ; Marca fin de datos para cálculo del shrink

.CODE                             ; Segmento de código

; -------------------------------------------------------------------------
; Rutina: ShrinkProgramMemory
; Reduce el bloque de memoria asignado al programa antes de reservar
; memoria adicional para los planos. Esto libera memoria "prestada" que el
; cargador asigna al .EXE al iniciarse.
; -------------------------------------------------------------------------
ShrinkProgramMemory PROC
    push ax                         ; Conservar registros utilizados
    push bx
    push cx
    push dx
    push si
    push es

    mov ax, psp_seg                 ; ¿Ya tenemos el PSP cacheado?
    or ax, ax
    jnz Shrink_have_psp

    mov ah, 51h                     ; DOS 2+: obtener segmento del PSP
    int 21h
    mov psp_seg, bx

Shrink_have_psp:
    mov es, psp_seg                 ; ES -> PSP
    mov si, es:[2]                  ; SI = tamaño actual del bloque en párrafos

    mov bx, seg HeapEnd             ; Diferencia en párrafos entre PSP y DGROUP
    sub bx, psp_seg

    mov ax, OFFSET HeapEnd          ; Convertir offset a párrafos (redondeo hacia arriba)
    mov dx, ax
    and dx, 0Fh
    mov cl, 4
    shr ax, cl
    cmp dx, 0
    je Shrink_NoExtraParagraph
    inc ax
Shrink_NoExtraParagraph:
    add bx, ax                      ; BX = párrafos necesarios para el programa

    mov ax, si
    sub ax, bx                      ; ¿Cuántos párrafos quedarían libres?
    jc Shrink_cannot_shrink         ; No hay espacio extra
    cmp ax, REQUIRED_FREE_PARAGRAPHS
    jb Shrink_cannot_shrink         ; No es suficiente para los buffers

    mov ah, 4Ah                     ; Intentar encoger el bloque
    int 21h
    jc Shrink_cannot_shrink

    xor ax, ax                      ; AX=0 -> shrink exitoso
    jmp Shrink_exit

Shrink_cannot_shrink:
    mov ax, 1                       ; AX=1 -> se mantiene el tamaño original

Shrink_exit:
    pop es
    pop si
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
    mov bx, PLANE_PARAGRAPHS
    int 21h
    jc @AllocationFailed
    mov Plane1Segment, ax

    mov ah, 48h                    ; Reservar memoria para el plano 2
    mov bx, PLANE_PARAGRAPHS
    int 21h
    jc @AllocationFailed
    mov Plane2Segment, ax

    mov ah, 48h                    ; Reservar memoria para el plano 3
    mov bx, PLANE_PARAGRAPHS
    int 21h
    jc @AllocationFailed
    mov Plane3Segment, ax

    mov largest_block, 0           ; Limpiar dato de error previo
    xor ax, ax                     ; AX=0 indica éxito
    jmp @InitExit

@AllocationFailed:
    push bx                        ; Guardar tamaño máximo libre reportado
    push ax                        ; Guardar código de error original
    call ReleaseOffScreenBuffer    ; Liberar cualquier bloque ya reservado
    pop ax                         ; AX = código de error
    pop bx                         ; BX = bloque libre reportado por DOS
    mov largest_block, bx

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
    push ax                        ; Guardar registros usados
    push cx
    push di
    push es

    cld                            ; Asegurar dirección hacia adelante para stosb

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

; ----------------------------------------------------------------------------
; Rutina: SetPaletteRed
; Ajusta el color 4 de la paleta EGA a rojo brillante (R=63, G=0, B=0).
; Esto mejora la visibilidad de los elementos renderizados en el viewport.
; ----------------------------------------------------------------------------
SetPaletteRed PROC
    push ax                        ; Conservar registros usados
    push bx
    push dx

    mov dx, 03C8h                  ; Puerto VGA DAC: seleccionar índice
    mov al, 4                      ; Color 4 -> rojo
    out dx, al

    mov dx, 03C9h                  ; Puerto de datos del DAC
    mov al, 63                     ; R = 63 (máximo brillo)
    out dx, al
    xor al, al                     ; G = 0
    out dx, al
    out dx, al                     ; B = 0

    pop dx                         ; Restaurar registros
    pop bx
    pop ax
    ret
SetPaletteRed ENDP

; ----------------------------------------------------------------------------
; Rutina: SetPaletteWhite
; Ajusta el color 15 de la paleta EGA a blanco completo (R=63, G=63, B=63)
; para mejorar la visibilidad de los elementos de prueba.
; ----------------------------------------------------------------------------
SetPaletteWhite PROC
    push ax
    push bx
    push dx

    mov dx, 03C8h                  ; Seleccionar índice del DAC
    mov al, 15                     ; Color 15 -> blanco
    out dx, al

    mov dx, 03C9h                  ; Escribir valores RGB (6 bits)
    mov al, 63                     ; R = 63
    out dx, al
    mov al, 63                     ; G = 63
    out dx, al
    mov al, 63                     ; B = 63
    out dx, al

    pop dx
    pop bx
    pop ax
    ret
SetPaletteWhite ENDP

; Fix: Limpia full A000h para eliminar garbage de modo anterior
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

    cld                            ; Asegurar dirección correcta antes de stosb

    xor di, di
    xor ax, ax
    mov cx, SCREEN_TOTAL_BYTES
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
; Rutina: DirectPixelTest
; Escribe un píxel rojo en la posición (0,0) directamente en VRAM para
; confirmar que el modo gráfico está activo y que la paleta responde.
; ----------------------------------------------------------------------------
DirectPixelTest PROC
    push ax
    push dx
    push di
    push es

    mov dx, 03C4h                  ; Registro de máscara del mapa
    mov al, 02h
    out dx, al
    inc dx
    mov al, 04h                    ; Habilitar únicamente el plano 2 (bit de color 4)
    out dx, al
    dec dx

    mov ax, 0A000h                 ; Acceder a VRAM
    mov es, ax
    xor di, di
    mov al, 80h                    ; Bit más significativo del primer byte (x=0)
    mov es:[di], al

    mov al, 02h                    ; Restaurar máscara -> habilitar 4 planos
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    dec dx

    pop es
    pop di
    pop dx
    pop ax
    ret
DirectPixelTest ENDP

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

    cmp bx, VIEWPORT_MAX_X         ; Limitar al ancho del viewport
    jbe @CheckYBounds
    jmp @exit_pixel

@CheckYBounds:
    cmp cx, VIEWPORT_MAX_Y         ; Limitar al alto del viewport
    jbe @PixelWithinBounds
    jmp @exit_pixel

@PixelWithinBounds:

    mov dh, dl                     ; Conservar el color completo en DH

    mov si, bx                     ; Guardar X original
    mov di, cx                     ; DI = Y
    shl di, 1
    shl di, 1
    shl di, 1
    shl di, 1                      ; DI = Y * 16
    mov ax, cx
    shl ax, 1
    shl ax, 1                      ; AX = Y * 4
    add di, ax                     ; DI = Y * 20

    mov ax, si
    shr ax, 1
    shr ax, 1
    shr ax, 1                      ; AX = X / 8
    add di, ax                     ; Offset final dentro del plano

    cmp di, PLANE_SIZE             ; Prevenir accesos fuera del buffer
    jb @pixel_in_range
    jmp @exit_pixel

@pixel_in_range:
    mov ax, si
    and ax, 7                      ; AX = X mod 8
    mov cl, 7
    sub cl, al                     ; CL = 7 - (X mod 8)
    mov al, 1
    shl al, cl                     ; AL = máscara del bit del píxel
    mov bl, al                     ; BL = máscara directa
    mov bh, bl
    not bh                         ; BH = máscara invertida para limpiar el bit

    mov si, di                     ; Guardar offset para cada plano

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

; Fase 3: Input movimiento línea
; Dibuja la línea roja del jugador reutilizando DrawPixel.
; Dibuja línea player horizontal desde player_x en player_y
DrawPlayerLine PROC
    push bx
    push cx
    push dx
    push si

    mov bx, player_x
    mov cx, player_y
    mov dl, 4
    mov si, PLAYER_LINE_LENGTH

@loop_player:
    call DrawPixel
    inc bx
    dec si
    jnz @loop_player

    pop si
    pop dx
    pop cx
    pop bx
    ret
DrawPlayerLine ENDP

; ----------------------------------------------------------------------------
; Rutina: RedrawViewport
; Limpia el buffer off-screen, dibuja la línea roja y la transfiere a VRAM.
; ----------------------------------------------------------------------------
RedrawViewport PROC
    call ClearOffScreenBuffer
    call DrawPlayerLine
    call BlitBufferToScreen
    ret
RedrawViewport ENDP

; Fase 3: Input movimiento línea - Lee tecla, mueve player, redraw loop
HandleInput PROC
    push ax
    push bx
    push cx
    push dx

    call RedrawViewport            ; Dibujar estado inicial

@frame_loop:
    mov ah, 01h                    ; Comprobar si hay tecla disponible (no bloqueante)
    int 16h
    jnz @key_available             ; Continuar si hay una tecla lista
    jmp @frame_loop                ; Reintentar hasta que se presione algo

@key_available:

    mov ah, 00h                    ; Leer tecla (ASCII en AL, scan en AH)
    int 16h

    cmp al, 27                     ; ESC (ASCII 27)
    jne @not_escape
    jmp @exit_input

@not_escape:

    mov bh, ah                     ; Scan code
    mov bl, al                     ; ASCII
    xor dl, dl                     ; DL = 0 -> sin movimiento todavía

    cmp bh, 48h                    ; Flecha arriba
    je @move_up
    cmp bh, 50h                    ; Flecha abajo
    je @move_down
    cmp bh, 4Bh                    ; Flecha izquierda
    je @move_left
    cmp bh, 4Dh                    ; Flecha derecha
    je @move_right

    cmp bl, 'w'                    ; WASD
    je @move_up
    cmp bl, 'W'
    je @move_up
    cmp bl, 's'
    je @move_down
    cmp bl, 'S'
    je @move_down
    cmp bl, 'a'
    je @move_left
    cmp bl, 'A'
    je @move_left
    cmp bl, 'd'
    je @move_right
    cmp bl, 'D'
    je @move_right

    jmp @frame_loop                ; Tecla ignorada

@move_up:
    mov ax, player_y
    or ax, ax
    jnz @move_up_adjust
    jmp @after_move
@move_up_adjust:
    dec ax
    mov player_y, ax
    mov dl, 1
    jmp @after_move

@move_down:
    mov ax, player_y
    cmp ax, VIEWPORT_MAX_Y
    jb @move_down_adjust
    jmp @after_move
@move_down_adjust:
    inc ax
    mov player_y, ax
    mov dl, 1
    jmp @after_move

@move_left:
    mov ax, player_x
    or ax, ax
    jnz @move_left_adjust
    jmp @after_move
@move_left_adjust:
    dec ax
    mov player_x, ax
    mov dl, 1
    jmp @after_move

@move_right:
    mov ax, player_x
    cmp ax, PLAYER_MAX_X
    jb @move_right_adjust
    jmp @after_move
@move_right_adjust:
    inc ax
    mov player_x, ax
    mov dl, 1

@after_move:
    mov ax, player_x               ; Clamp X inferior
    cmp ax, 0
    jge @clamp_x_high
    xor ax, ax
    mov player_x, ax

@clamp_x_high:
    cmp ax, PLAYER_MAX_X
    jbe @clamp_y_low
    mov ax, PLAYER_MAX_X
    mov player_x, ax

@clamp_y_low:
    mov ax, player_y
    cmp ax, 0
    jge @clamp_y_high
    xor ax, ax
    mov player_y, ax

@clamp_y_high:
    cmp ax, VIEWPORT_MAX_Y
    jbe @maybe_redraw
    mov ax, VIEWPORT_MAX_Y
    mov player_y, ax

@maybe_redraw:
    or dl, dl                      ; ¿Hubo movimiento real?
    jnz @do_redraw
    jmp @frame_loop

@do_redraw:
    call RedrawViewport            ; Actualizar pantalla solo tras mover
    jmp @frame_loop

@exit_input:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
HandleInput ENDP

; ----------------------------------------------------------------------------
; Rutina: BlitBufferToScreen
; Copia el contenido del buffer off-screen a la memoria de video A000h.
; Usa el registro de máscara del mapa (sequencer) para seleccionar cada plano.
; ----------------------------------------------------------------------------
BlitBufferToScreen PROC
    push ax                        ; Guardar registros usados
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push ds
    push es

    mov ax, 0A000h                 ; Fix: Cargar segmento de video en ES
    mov es, ax
    mov dx, 03C4h                  ; Fix: Puerto base del sequencer

    mov al, 02h                    ; Preparar máscara a los cuatro planos
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    dec dx

    cld                            ; Asegurar copias hacia adelante en los rep movsb

    mov ax, Plane0Segment          ; Plano 0 ------------------------------------------------
    or ax, ax
    jz @SkipCopy0
    mov bx, ax                     ; Preservar segmento del plano
    mov al, 02h
    out dx, al
    inc dx
    mov al, 1                      ; Máscara para plano 0
    out dx, al
    dec dx
    push ds                        ; Guardar DS antes de cambiarlo al plano
    mov ax, viewport_start_offset  ; Offset base en VRAM para el viewport
    mov di, ax
    mov ds, bx                     ; DS = plano actual
    xor si, si
    mov bp, VIEWPORT_HEIGHT
@CopyPlane0:
    mov cx, BYTES_PER_SCAN
    rep movsb
    add di, VIEWPORT_LINE_SKIP
    dec bp
    jnz @CopyPlane0
    pop ds
@SkipCopy0:

    mov ax, Plane1Segment          ; Plano 1 ------------------------------------------------
    or ax, ax
    jz @SkipCopy1
    mov bx, ax                     ; Preservar segmento del plano
    mov al, 02h
    out dx, al
    inc dx
    mov al, 2                      ; Máscara para plano 1
    out dx, al
    dec dx
    push ds                        ; Guardar DS antes de cambiarlo al plano
    mov ax, viewport_start_offset
    mov di, ax
    mov ds, bx
    xor si, si
    mov bp, VIEWPORT_HEIGHT
@CopyPlane1:
    mov cx, BYTES_PER_SCAN
    rep movsb
    add di, VIEWPORT_LINE_SKIP
    dec bp
    jnz @CopyPlane1
    pop ds
@SkipCopy1:

    mov ax, Plane2Segment          ; Plano 2 ------------------------------------------------
    or ax, ax
    jz @SkipCopy2
    mov bx, ax                     ; Preservar segmento del plano
    mov al, 02h
    out dx, al
    inc dx
    mov al, 4                      ; Máscara para plano 2
    out dx, al
    dec dx
    push ds                        ; Guardar DS antes de cambiarlo al plano
    mov ax, viewport_start_offset
    mov di, ax
    mov ds, bx
    xor si, si
    mov bp, VIEWPORT_HEIGHT
@CopyPlane2:
    mov cx, BYTES_PER_SCAN
    rep movsb
    add di, VIEWPORT_LINE_SKIP
    dec bp
    jnz @CopyPlane2
    pop ds
@SkipCopy2:

    mov ax, Plane3Segment          ; Plano 3 ------------------------------------------------
    or ax, ax
    jz @SkipCopy3
    mov bx, ax                     ; Preservar segmento del plano
    mov al, 02h
    out dx, al
    inc dx
    mov al, 8                      ; Máscara para plano 3
    out dx, al
    dec dx
    push ds                        ; Guardar DS antes de cambiarlo al plano
    mov ax, viewport_start_offset
    mov di, ax
    mov ds, bx
    xor si, si
    mov bp, VIEWPORT_HEIGHT
@CopyPlane3:
    mov cx, BYTES_PER_SCAN
    rep movsb
    add di, VIEWPORT_LINE_SKIP
    dec bp
    jnz @CopyPlane3
    pop ds
@SkipCopy3:

    mov al, 02h                    ; Fix: Restaurar índice del registro de máscara
    out dx, al
    inc dx
    mov al, 0Fh                    ; Fix: Habilitar los cuatro planos
    out dx, al

    pop es                         ; Restaurar registros
    pop ds
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
BlitBufferToScreen ENDP

PrintHexAX PROC
    push ax
    push bx
    push cx
    push dx
    push si

    mov bx, ax                     ; Copiar valor original
    mov si, 4                      ; Contador de nibbles
    mov cl, 12

@PrintLoop:
    mov dx, bx
    shr dx, cl
    and dl, 0Fh
    cmp dl, 9
    jbe @digit
    add dl, 'A' - 10
    jmp @emit

@digit:
    add dl, '0'

@emit:
    mov ah, 02h
    int 21h

    shl bx, 1
    shl bx, 1
    shl bx, 1
    shl bx, 1

    dec si
    jnz @PrintLoop

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
PrintHexAX ENDP

main PROC
    mov ax, @data                  ; Inicializar el segmento de datos
    mov ds, ax
    cld                            ; Asegurar DF=0 para operaciones con cadenas

    call ShrinkProgramMemory       ; Fix: Liberar memoria prestada antes de reservar planos

    call InitOffScreenBuffer       ; Reservar memoria para el buffer off-screen
    cmp ax, 0
    je @ok_print

    mov si, ax                     ; Código de error devuelto por DOS
    mov dx, offset msg_err         ; Mensaje de error
    mov ah, 09h
    int 21h
    mov ax, si
    call PrintHexAX
    mov dx, offset msg_free        ; Mostrar bloque libre más grande
    mov ah, 09h
    int 21h
    mov ax, largest_block
    call PrintHexAX
    mov dx, offset crlf
    mov ah, 09h
    int 21h
    mov ah, 4Ch                    ; Fix: Salir con código de error genérico 8
    mov al, 8
    int 21h

@ok_print:
@BuffersReady:

    ; Calcular el offset base del viewport dentro de VRAM (160x100 -> esquina superior izquierda)
    mov ax, viewport_y_pixels
    mov bx, ax
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1                       ; AX = y * 16
    shl bx, 1
    shl bx, 1                       ; BX = y * 4
    add ax, bx                      ; AX = y * 20
    mov bx, viewport_x_pixels
    shr bx, 1
    shr bx, 1
    shr bx, 1                       ; BX = x / 8
    add ax, bx
    mov viewport_start_offset, ax

    mov ax, 0010h                  ; Cambiar a modo gráfico EGA 640x350x16
    int 10h

    xor bh, bh                     ; Asegurar que la página activa es la 0
    mov ah, 05h
    int 10h

    call ClearScreen              ; Fix: Limpiar VRAM y evitar basura previa
    call SetPaletteRed             ; Ajustar color 4 a rojo brillante
    call SetPaletteWhite           ; Ajustar color 15 a blanco
    call DirectPixelTest           ; Verificación rápida de escritura directa

    call HandleInput               ; Fase 3: Input movimiento línea - control interactivo

    mov ax, 0003h                  ; Volver a modo texto 80x25
    int 10h

    call ReleaseOffScreenBuffer    ; Liberar memoria reservada

    mov ax, 4C00h                  ; Terminar programa
    int 21h
main ENDP

END main
