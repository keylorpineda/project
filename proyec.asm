; Programa para modo gráfico EGA 640x350 16 colores con doble buffer
; Ensamblador 8086/8088 - Sintaxis TASM

.MODEL SMALL                      ; Usar modelo de memoria small (código y datos < 64K)
.STACK 100h                       ; Reservar 256 bytes para la pila

; Constantes generales del modo gráfico
SCREEN_WIDTH      EQU 640         ; Ancho de pantalla en píxeles
SCREEN_HEIGHT     EQU 350         ; Alto de pantalla en píxeles
BYTES_PER_SCAN    EQU SCREEN_WIDTH / 8  ; 640 / 8 = 80 bytes por scanline
PLANE_SIZE        EQU BYTES_PER_SCAN * SCREEN_HEIGHT ; 80 * 350 = 28000 bytes por plano
PLANE_SIZE_WORDS  EQU PLANE_SIZE / 2
PLANE_PARAGRAPHS  EQU (PLANE_SIZE + 15) / 16 ; 1750 párrafos por plano

LINE_LENGTH       EQU 120
LINE_STEP         EQU 4
LINE_COLOR        EQU 4
MAX_PIXEL_X       EQU SCREEN_WIDTH - 1
MAX_PIXEL_Y       EQU SCREEN_HEIGHT - 1
MAX_LINE_X        EQU SCREEN_WIDTH - LINE_LENGTH
MAX_LINE_Y        EQU SCREEN_HEIGHT - 1

.DATA                             ; Segmento de datos
Plane0Segment    dw 0             ; Segmento del plano 0 (bit de peso 1)
Plane1Segment    dw 0             ; Segmento del plano 1 (bit de peso 2)
Plane2Segment    dw 0             ; Segmento del plano 2 (bit de peso 4)
Plane3Segment    dw 0             ; Segmento del plano 3 (bit de peso 8)
psp_seg          dw 0             ; Fix: Para PSP segment
viewport_x_offset dw 0            ; Desfase horizontal nulo para copiar pantalla completa
viewport_y_offset dw 0            ; Desfase vertical nulo para copiar pantalla completa
line_pos_x       dw (SCREEN_WIDTH - LINE_LENGTH) / 2
line_pos_y       dw SCREEN_HEIGHT / 2
msg_err          db 'ERROR: Alloc fallo. Codigo: $'
msg_free         db ' (free block: $'
msg_shrink_fail  db 'Shrink fail',13,10,'$'
crlf             db 13,10,'$'

.CODE                             ; Segmento de código

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
    mov bx, 100                     ; Fix: Shrink programa a 100 paragraphs para liberar mem para alloc
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
    push ax                        ; Guardar registros usados
    push cx
    push di
    push es

    cld

    mov ax, Plane0Segment          ; Borrar plano 0
    or ax, ax
    jz @SkipPlane0
    mov es, ax
    xor di, di
    xor ax, ax
    mov cx, PLANE_SIZE_WORDS
    rep stosw
@SkipPlane0:

    mov ax, Plane1Segment          ; Borrar plano 1
    or ax, ax
    jz @SkipPlane1
    mov es, ax
    xor di, di
    xor ax, ax
    mov cx, PLANE_SIZE_WORDS
    rep stosw
@SkipPlane1:

    mov ax, Plane2Segment          ; Borrar plano 2
    or ax, ax
    jz @SkipPlane2
    mov es, ax
    xor di, di
    xor ax, ax
    mov cx, PLANE_SIZE_WORDS
    rep stosw
@SkipPlane2:

    mov ax, Plane3Segment          ; Borrar plano 3
    or ax, ax
    jz @SkipPlane3
    mov es, ax
    xor di, di
    xor ax, ax
    mov cx, PLANE_SIZE_WORDS
    rep stosw
@SkipPlane3:

    pop es                         ; Restaurar registros
    pop di
    pop cx
    pop ax
    ret
ClearOffScreenBuffer ENDP

; ----------------------------------------------------------------------------
; Rutina: WaitVerticalRetrace
; Sincroniza con el inicio del barrido vertical de la EGA para evitar tearing.
; ----------------------------------------------------------------------------
WaitVerticalRetrace PROC
    push ax
    push dx

    mov dx, 03DAh

@WaitNotRetrace:
    in al, dx
    test al, 08h
    jnz @WaitNotRetrace

@WaitRetrace:
    in al, dx
    test al, 08h
    jz @WaitRetrace

    pop dx
    pop ax
    ret
WaitVerticalRetrace ENDP

; ----------------------------------------------------------------------------
; Rutina: SetPaletteRed
; Ajusta el color 4 de la paleta EGA a rojo brillante (R=63, G=0, B=0).
; Esto mejora la visibilidad de los elementos renderizados en el viewport.
; ----------------------------------------------------------------------------
SetPaletteRed PROC
    push ax                        ; Conservar registros usados
    push dx

    mov dx, 03C8h                  ; Puerto de índice de la DAC
    mov al, 4
    out dx, al                     ; Seleccionar color 4
    inc dx                         ; DX = 03C9h (datos de la DAC)

    mov al, 63
    out dx, al                     ; Fix: EGA 6-bit DAC, 3 bytes/color (R=63 G=0 B=0 para rojo puro)
    mov al, 0
    out dx, al
    mov al, 0
    out dx, al

    pop dx                         ; Restaurar registros
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
    push dx

    mov dx, 03C8h
    mov al, 15
    out dx, al
    inc dx

    mov al, 63
    out dx, al                     ; Test: Blanco full para línea visible
    mov al, 63
    out dx, al
    mov al, 63
    out dx, al

    pop dx
    pop ax
    ret
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
    mov al, 4
    out dx, al
    dec dx

    xor di, di
    mov al, 4
    mov cx, 160
    rep stosb

    xor di, di
    mov cx, 100
@vert:
    mov BYTE PTR es:[di], 4
    add di, 80
    loop @vert

    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    dec dx

    xor di, di
    mov al, 15
    mov cx, 160
    rep stosb

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
    mov cx, PLANE_SIZE           ; 350*80 bytes totales modo 10h
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

    cmp bx, MAX_PIXEL_X
    jbe @CheckYBounds
    jmp NEAR PTR @exit_pixel

@CheckYBounds:
    cmp cx, MAX_PIXEL_Y
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
; Rutina: DrawHorizontalLine
; Dibuja una línea horizontal en el buffer off-screen.
;  Entradas:
;       BX = coordenada X inicial
;       CX = coordenada Y
;       SI = longitud en píxeles
;       DL = color (0..15)
; ----------------------------------------------------------------------------
DrawHorizontalLine PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov di, si
    mov si, bx
    mov ax, cx
    or di, di
    jz @ExitLine

@NextPixel:
    mov bx, si
    mov cx, ax
    call DrawPixel
    inc si
    dec di
    jnz @NextPixel

@ExitLine:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DrawHorizontalLine ENDP

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
    push ds
    push es

    cld

    mov ax, 0A000h                 ; Fix: Cargar segmento de video en ES
    mov es, ax
    mov dx, 03C4h                  ; Fix: Puerto base del sequencer

    mov ax, Plane0Segment          ; Plano 0 ------------------------------------------------
    or ax, ax
    jz @SkipCopy0
    mov bx, ax                     ; Fix: Preservar segmento del plano
    mov al, 02h
    out dx, al
    inc dx
    mov al, 1                      ; Fix: Máscara decimal para plano 0
    out dx, al
    dec dx
    push ds                        ; Fix: Guardar DS antes de cambiarlo al plano
    mov ax, viewport_y_offset      ; Fix: Obtener desplazamiento vertical base
    mov di, ax
    add di, viewport_x_offset      ; Fix: Desplazar viewport centrado
    mov ds, bx                     ; Fix: Usar segmento preservado del plano
    xor si, si
    mov cx, PLANE_SIZE_WORDS
    rep movsw
    pop ds
@SkipCopy0:

    mov ax, Plane1Segment          ; Plano 1 ------------------------------------------------
    or ax, ax
    jz @SkipCopy1
    mov bx, ax                     ; Fix: Preservar segmento del plano
    mov al, 02h
    out dx, al
    inc dx
    mov al, 2                      ; Fix: Máscara decimal para plano 1
    out dx, al
    dec dx
    push ds                        ; Fix: Guardar DS antes de cambiarlo al plano
    mov ax, viewport_y_offset      ; Fix: Obtener desplazamiento vertical base
    mov di, ax
    add di, viewport_x_offset      ; Fix: Desplazar viewport centrado
    mov ds, bx                     ; Fix: Usar segmento preservado del plano
    xor si, si
    mov cx, PLANE_SIZE_WORDS
    rep movsw
    pop ds
@SkipCopy1:

    mov ax, Plane2Segment          ; Plano 2 ------------------------------------------------
    or ax, ax
    jz @SkipCopy2
    mov bx, ax                     ; Fix: Preservar segmento del plano
    mov al, 02h
    out dx, al
    inc dx
    mov al, 4                      ; Fix: Máscara decimal para plano 2
    out dx, al
    dec dx
    push ds                        ; Fix: Guardar DS antes de cambiarlo al plano
    mov ax, viewport_y_offset      ; Fix: Obtener desplazamiento vertical base
    mov di, ax
    add di, viewport_x_offset      ; Fix: Desplazar viewport centrado
    mov ds, bx                     ; Fix: Usar segmento preservado del plano
    xor si, si
    mov cx, PLANE_SIZE_WORDS
    rep movsw
    pop ds
@SkipCopy2:

    mov ax, Plane3Segment          ; Plano 3 ------------------------------------------------
    or ax, ax
    jz @SkipCopy3
    mov bx, ax                     ; Fix: Preservar segmento del plano
    mov al, 02h
    out dx, al
    inc dx
    mov al, 8                      ; Fix: Máscara decimal para plano 3
    out dx, al
    dec dx
    push ds                        ; Fix: Guardar DS antes de cambiarlo al plano
    mov ax, viewport_y_offset      ; Fix: Obtener desplazamiento vertical base
    mov di, ax
    add di, viewport_x_offset      ; Fix: Desplazar viewport centrado
    mov ds, bx                     ; Fix: Usar segmento preservado del plano
    xor si, si
    mov cx, PLANE_SIZE_WORDS
    rep movsw
    pop ds
@SkipCopy3:

    mov al, 02h                    ; Fix: Restaurar índice del registro de máscara
    out dx, al
    inc dx
    mov al, 0Fh                    ; Fix: Habilitar los cuatro planos
    out dx, al

    pop es                         ; Restaurar registros
    pop ds
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

    call ClearScreen              ; Limpiar VRAM y evitar basura previa
    call SetPaletteRed             ; Color 4 = rojo brillante (R=63)

    jmp RenderFrame

MainLoop:
    call WaitVerticalRetrace

    mov ah, 01h
    int 16h
    jz RenderFrame

    mov ah, 00h
    int 16h
    cmp al, 1Bh
    je ExitGraphics

    mov bh, ah
    mov bl, al

    cmp bh, 48h                    ; Flecha arriba
    je MoveLineUp
    cmp bl, 'w'
    je MoveLineUp
    cmp bl, 'W'
    je MoveLineUp

    cmp bh, 50h                    ; Flecha abajo
    je MoveLineDown
    cmp bl, 's'
    je MoveLineDown
    cmp bl, 'S'
    je MoveLineDown

    cmp bh, 4Bh                    ; Flecha izquierda
    je MoveLineLeft
    cmp bl, 'a'
    je MoveLineLeft
    cmp bl, 'A'
    je MoveLineLeft

    cmp bh, 4Dh                    ; Flecha derecha
    je MoveLineRight
    cmp bl, 'd'
    je MoveLineRight
    cmp bl, 'D'
    je MoveLineRight

    jmp RenderFrame

MoveLineUp:
    mov ax, line_pos_y
    cmp ax, LINE_STEP
    jb @ClampTop
    sub ax, LINE_STEP
    jmp @StoreUp
@ClampTop:
    xor ax, ax
@StoreUp:
    mov line_pos_y, ax
    jmp RenderFrame

MoveLineDown:
    mov ax, line_pos_y
    add ax, LINE_STEP
    cmp ax, MAX_LINE_Y
    jbe @StoreDown
    mov ax, MAX_LINE_Y
@StoreDown:
    mov line_pos_y, ax
    jmp RenderFrame

MoveLineLeft:
    mov ax, line_pos_x
    cmp ax, LINE_STEP
    jb @ClampLeft
    sub ax, LINE_STEP
    jmp @StoreLeft
@ClampLeft:
    xor ax, ax
@StoreLeft:
    mov line_pos_x, ax
    jmp RenderFrame

MoveLineRight:
    mov ax, line_pos_x
    add ax, LINE_STEP
    cmp ax, MAX_LINE_X
    jbe @StoreRight
    mov ax, MAX_LINE_X
@StoreRight:
    mov line_pos_x, ax
    jmp RenderFrame

RenderFrame:
    call ClearOffScreenBuffer
    mov bx, line_pos_x
    mov cx, line_pos_y
    mov si, LINE_LENGTH
    mov dl, LINE_COLOR
    call DrawHorizontalLine
    call BlitBufferToScreen
    jmp MainLoop

ExitGraphics:
    mov ax, 0003h                  ; Volver a modo texto 80x25
    int 10h

    call ReleaseOffScreenBuffer    ; Liberar memoria reservada

    mov ax, 4C00h                  ; Terminar programa
    int 21h
main ENDP

END main