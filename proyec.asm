; Programa para modo gráfico EGA 640x350 16 colores con doble buffer
; Ensamblador 8086/8088 - Sintaxis TASM

.MODEL SMALL                      ; Usar modelo de memoria small (código y datos < 64K)
.STACK 100h                       ; Reservar 256 bytes para la pila

STACK_SIZE            EQU 100h
STACK_PARAGRAPHS      EQU (STACK_SIZE + 15) / 16
SHRINK_MARGIN_PARAS   EQU 16

; Constantes generales del modo gráfico
SCREEN_WIDTH          EQU 640
SCREEN_HEIGHT         EQU 350
SCREEN_BYTES_PER_SCAN EQU SCREEN_WIDTH / 8            ; 80 bytes por scanline
VRAM_SIZE             EQU SCREEN_BYTES_PER_SCAN * SCREEN_HEIGHT

; Constantes del viewport 160x100 centrado en pantalla
VIEWPORT_WIDTH        EQU 160
VIEWPORT_HEIGHT       EQU 100
BYTES_PER_SCAN        EQU VIEWPORT_WIDTH / 8          ; 160 / 8 = 20 bytes por scanline
PLANE_SIZE            EQU BYTES_PER_SCAN * VIEWPORT_HEIGHT
PLANE_PARAGRAPHS      EQU 128                         ; 8 KB por plano para reserva segura
ROW_STRIDE_DIFF       EQU SCREEN_BYTES_PER_SCAN - BYTES_PER_SCAN
VIEWPORT_MARGIN_X     EQU (SCREEN_WIDTH - VIEWPORT_WIDTH) / 2
VIEWPORT_MARGIN_Y     EQU (SCREEN_HEIGHT - VIEWPORT_HEIGHT) / 2
VIEWPORT_X_OFFSET     EQU VIEWPORT_MARGIN_X / 8
VIEWPORT_Y_OFFSET     EQU VIEWPORT_MARGIN_Y * SCREEN_BYTES_PER_SCAN

; Constantes de la línea controlable
LINE_LENGTH           EQU 120
LINE_STEP             EQU 4
LINE_COLOR            EQU 4
MAX_PIXEL_X           EQU VIEWPORT_WIDTH - 1
MAX_PIXEL_Y           EQU VIEWPORT_HEIGHT - 1
MAX_LINE_X            EQU VIEWPORT_WIDTH - LINE_LENGTH
MAX_LINE_Y            EQU VIEWPORT_HEIGHT - 1

.DATA                             ; Segmento de datos
Plane0Segment        dw 0         ; Segmento del plano 0 (bit de peso 1)
Plane1Segment        dw 0         ; Segmento del plano 1 (bit de peso 2)
Plane2Segment        dw 0         ; Segmento del plano 2 (bit de peso 4)
Plane3Segment        dw 0         ; Segmento del plano 3 (bit de peso 8)
psp_seg              dw 0         ; Segmento del PSP para shrink
viewport_x_offset    dw VIEWPORT_X_OFFSET
viewport_y_offset    dw VIEWPORT_Y_OFFSET
line_pos_x           dw (VIEWPORT_WIDTH - LINE_LENGTH) / 2
line_pos_y           dw VIEWPORT_HEIGHT / 2
msg_err              db 'ERROR: Alloc fallo. Codigo: $'
msg_free             db ' (free block: $'
msg_shrink_fail      db 'Shrink fail',13,10,'$'
crlf                 db 13,10,'$'
DataEnd              LABEL BYTE

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
    push si
    push di
    push bp
    push es

    mov ax, psp_seg
    or ax, ax
    jnz @have_psp

    mov ah, 51h                     ; Obtener segmento del PSP actual
    int 21h
    mov psp_seg, bx

@have_psp:
    mov ax, psp_seg
    mov es, ax
    mov dx, es:[2]                  ; Tamaño actual del bloque en párrafos

    mov ax, cs
    sub ax, psp_seg
    mov bx, ax
    mov ax, OFFSET CodeEnd
    add ax, 15
    shr ax, 4
    add bx, ax
    mov si, bx                      ; Párrafos necesarios para el código

    mov ax, ds
    sub ax, psp_seg
    mov bx, ax
    mov ax, OFFSET DataEnd
    add ax, 15
    shr ax, 4
    add bx, ax
    mov di, bx                      ; Párrafos necesarios para datos

    mov ax, ss
    sub ax, psp_seg
    mov bx, ax
    mov ax, STACK_PARAGRAPHS
    add bx, ax
    mov bp, bx                      ; Párrafos necesarios para la pila

    mov ax, si
    cmp di, ax
    jbe @check_stack
    mov ax, di
@check_stack:
    cmp bp, ax
    jbe @add_margin
    mov ax, bp
@add_margin:
    add ax, SHRINK_MARGIN_PARAS
    cmp ax, dx
    jbe @have_size
    mov ax, dx
@have_size:
    mov bx, ax
    mov ah, 4Ah                     ; Función DOS para encoger bloque
    mov ax, psp_seg
    mov es, ax
    int 21h
    jc @shrink_fail

    xor ax, ax                      ; AX=0 indica shrink exitoso
    jmp @exit

@shrink_fail:
    mov ax, 1                       ; AX=1 indica shrink no disponible

@exit:
    pop es
    pop bp
    pop di
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

    mov Plane0Segment, 0
    mov Plane1Segment, 0
    mov Plane2Segment, 0
    mov Plane3Segment, 0

    mov bx, PLANE_PARAGRAPHS

    mov ah, 48h
    int 21h
    jc @AllocationFailed
    mov Plane0Segment, ax

    mov ah, 48h
    mov bx, PLANE_PARAGRAPHS
    int 21h
    jc @AllocationFailed
    mov Plane1Segment, ax

    mov ah, 48h
    mov bx, PLANE_PARAGRAPHS
    int 21h
    jc @AllocationFailed
    mov Plane2Segment, ax

    mov ah, 48h
    mov bx, PLANE_PARAGRAPHS
    int 21h
    jc @AllocationFailed
    mov Plane3Segment, ax

    xor ax, ax
    jmp @InitExit

@AllocationFailed:
    push ax
    call ReleaseOffScreenBuffer
    pop ax

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
    push ax
    push cx
    push di
    push es

    cld

    mov ax, Plane0Segment
    or ax, ax
    jz @SkipPlane0
    mov es, ax
    xor di, di
    xor ax, ax
    mov cx, PLANE_SIZE
    rep stosb
@SkipPlane0:

    mov ax, Plane1Segment
    or ax, ax
    jz @SkipPlane1
    mov es, ax
    xor di, di
    xor ax, ax
    mov cx, PLANE_SIZE
    rep stosb
@SkipPlane1:

    mov ax, Plane2Segment
    or ax, ax
    jz @SkipPlane2
    mov es, ax
    xor di, di
    xor ax, ax
    mov cx, PLANE_SIZE
    rep stosb
@SkipPlane2:

    mov ax, Plane3Segment
    or ax, ax
    jz @SkipPlane3
    mov es, ax
    xor di, di
    xor ax, ax
    mov cx, PLANE_SIZE
    rep stosb
@SkipPlane3:

    pop es
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
; ----------------------------------------------------------------------------
SetPaletteRed PROC
    push ax
    push dx

    mov dx, 03C8h
    mov al, 4
    out dx, al
    inc dx

    mov al, 63
    out dx, al
    mov al, 0
    out dx, al
    mov al, 0
    out dx, al

    pop dx
    pop ax
    ret
SetPaletteRed ENDP

; ----------------------------------------------------------------------------
; Rutina: SetPaletteWhite
; Ajusta el color 15 de la paleta EGA a blanco completo (R=63, G=63, B=63).
; ----------------------------------------------------------------------------
SetPaletteWhite PROC
    push ax
    push dx

    mov dx, 03C8h
    mov al, 15
    out dx, al
    inc dx

    mov al, 63
    out dx, al
    mov al, 63
    out dx, al
    mov al, 63
    out dx, al

    pop dx
    pop ax
    ret
SetPaletteWhite ENDP

; ----------------------------------------------------------------------------
; Rutina: ClearScreen
; Limpia toda la memoria de video del modo 10h.
; ----------------------------------------------------------------------------
ClearScreen PROC
    push ax
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

    cld
    xor di, di
    xor ax, ax
    mov cx, VRAM_SIZE
    rep stosb

    pop es
    pop di
    pop dx
    pop cx
    pop ax
    ret
ClearScreen ENDP

; ----------------------------------------------------------------------------
; Rutina: DrawPixel
; Dibuja un píxel en el buffer off-screen usando coordenadas (X,Y) y color C.
; Entradas:
;   BX = coordenada X (0..VIEWPORT_WIDTH-1)
;   CX = coordenada Y (0..VIEWPORT_HEIGHT-1)
;   DL = color (0..15)
; ----------------------------------------------------------------------------
DrawPixel PROC
    push ax
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
    jz @NextPlane0
    mov es, ax
    mov di, si
    test dh, 1
    jz @ClearPlane0
    mov al, bl
    or BYTE PTR es:[di], al
    jmp @NextPlane0
@ClearPlane0:
    mov al, bh
    and BYTE PTR es:[di], al
@NextPlane0:

    mov ax, Plane1Segment
    or ax, ax
    jz @NextPlane1
    mov es, ax
    mov di, si
    test dh, 2
    jz @ClearPlane1
    mov al, bl
    or BYTE PTR es:[di], al
    jmp @NextPlane1
@ClearPlane1:
    mov al, bh
    and BYTE PTR es:[di], al
@NextPlane1:

    mov ax, Plane2Segment
    or ax, ax
    jz @NextPlane2
    mov es, ax
    mov di, si
    test dh, 4
    jz @ClearPlane2
    mov al, bl
    or BYTE PTR es:[di], al
    jmp @NextPlane2
@ClearPlane2:
    mov al, bh
    and BYTE PTR es:[di], al
@NextPlane2:

    mov ax, Plane3Segment
    or ax, ax
    jz @NextPlane3
    mov es, ax
    mov di, si
    test dh, 8
    jz @ClearPlane3
    mov al, bl
    or BYTE PTR es:[di], al
    jmp @NextPlane3
@ClearPlane3:
    mov al, bh
    and BYTE PTR es:[di], al
@NextPlane3:

@exit_pixel:
    pop es
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
; Entradas:
;   BX = coordenada X inicial
;   CX = coordenada Y
;   SI = longitud en píxeles
;   DL = color (0..15)
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
; El viewport es de 160x100 y se centra en la pantalla 640x350.
; ----------------------------------------------------------------------------
BlitBufferToScreen PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push ds
    push es

    cld

    mov ax, 0A000h
    mov es, ax
    mov dx, 03C4h

    mov ax, Plane0Segment
    or ax, ax
    jz @SkipCopy0
    mov bx, ax
    mov al, 02h
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    dec dx
    push ds
    mov ax, viewport_y_offset
    mov di, ax
    mov ax, viewport_x_offset
    add di, ax
    mov ds, bx
    xor si, si
    mov bp, VIEWPORT_HEIGHT
@RowCopy0:
    mov cx, BYTES_PER_SCAN
@RowCopy0Bytes:
    mov al, ds:[si]
    mov es:[di], al
    inc si
    inc di
    loop @RowCopy0Bytes
    add di, ROW_STRIDE_DIFF
    dec bp
    jnz @RowCopy0
    pop ds
@SkipCopy0:

    mov ax, Plane1Segment
    or ax, ax
    jz @SkipCopy1
    mov bx, ax
    mov al, 02h
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    dec dx
    push ds
    mov ax, viewport_y_offset
    mov di, ax
    mov ax, viewport_x_offset
    add di, ax
    mov ds, bx
    xor si, si
    mov bp, VIEWPORT_HEIGHT
@RowCopy1:
    mov cx, BYTES_PER_SCAN
@RowCopy1Bytes:
    mov al, ds:[si]
    mov es:[di], al
    inc si
    inc di
    loop @RowCopy1Bytes
    add di, ROW_STRIDE_DIFF
    dec bp
    jnz @RowCopy1
    pop ds
@SkipCopy1:

    mov ax, Plane2Segment
    or ax, ax
    jz @SkipCopy2
    mov bx, ax
    mov al, 02h
    out dx, al
    inc dx
    mov al, 4
    out dx, al
    dec dx
    push ds
    mov ax, viewport_y_offset
    mov di, ax
    mov ax, viewport_x_offset
    add di, ax
    mov ds, bx
    xor si, si
    mov bp, VIEWPORT_HEIGHT
@RowCopy2:
    mov cx, BYTES_PER_SCAN
@RowCopy2Bytes:
    mov al, ds:[si]
    mov es:[di], al
    inc si
    inc di
    loop @RowCopy2Bytes
    add di, ROW_STRIDE_DIFF
    dec bp
    jnz @RowCopy2
    pop ds
@SkipCopy2:

    mov ax, Plane3Segment
    or ax, ax
    jz @SkipCopy3
    mov bx, ax
    mov al, 02h
    out dx, al
    inc dx
    mov al, 8
    out dx, al
    dec dx
    push ds
    mov ax, viewport_y_offset
    mov di, ax
    mov ax, viewport_x_offset
    add di, ax
    mov ds, bx
    xor si, si
    mov bp, VIEWPORT_HEIGHT
@RowCopy3:
    mov cx, BYTES_PER_SCAN
@RowCopy3Bytes:
    mov al, ds:[si]
    mov es:[di], al
    inc si
    inc di
    loop @RowCopy3Bytes
    add di, ROW_STRIDE_DIFF
    dec bp
    jnz @RowCopy3
    pop ds
@SkipCopy3:

    mov al, 02h
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al

    pop es
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
    shr bx, 4
    dec si
    jnz @loop
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
PrintHexAX ENDP

main PROC
    mov ax, @data
    mov ds, ax

    call ShrinkProgramMemory

    call InitOffScreenBuffer
    cmp ax, 0
    je @BuffersReady

    mov si, ax
    mov dx, offset msg_err
    mov ah, 09h
    int 21h
    mov ax, si
    push ax
    call PrintHexAX
    mov dx, offset msg_free
    mov ah, 09h
    int 21h
    pop ax
    mov ax, bx
    call PrintHexAX
    mov dx, offset crlf
    mov ah, 09h
    int 21h
    mov ah, 4Ch
    mov al, 8
    int 21h

@BuffersReady:
    mov ax, 0010h
    int 10h

    call ClearScreen
    call SetPaletteRed
    call SetPaletteWhite

    jmp RenderFrame

MainLoop:
    call WaitVerticalRetrace

    mov ah, 01h
    int 16h
    jnz @KeyPressed
    jmp RenderFrame

@KeyPressed:
    mov ah, 00h
    int 16h
    cmp al, 1Bh
    je ExitGraphics
    cmp ah, 01h
    je ExitGraphics

@NotEscape:
    mov bh, ah
    mov bl, al

    cmp bh, 48h
    jne @CheckKeyWLower
    jmp MoveLineUp

@CheckKeyWLower:
    cmp bl, 'w'
    jne @CheckKeyWUpper
    jmp MoveLineUp

@CheckKeyWUpper:
    cmp bl, 'W'
    jne @CheckKeyDownArrow
    jmp MoveLineUp

@CheckKeyDownArrow:
    cmp bh, 50h
    jne @CheckKeySLower
    jmp MoveLineDown

@CheckKeySLower:
    cmp bl, 's'
    jne @CheckKeySUpper
    jmp MoveLineDown

@CheckKeySUpper:
    cmp bl, 'S'
    jne @CheckKeyLeftArrow
    jmp MoveLineDown

@CheckKeyLeftArrow:
    cmp bh, 4Bh
    jne @CheckKeyALower
    jmp MoveLineLeft

@CheckKeyALower:
    cmp bl, 'a'
    jne @CheckKeyAUpper
    jmp MoveLineLeft

@CheckKeyAUpper:
    cmp bl, 'A'
    jne @CheckKeyRightArrow
    jmp MoveLineLeft

@CheckKeyRightArrow:
    cmp bh, 4Dh
    jne @CheckKeyDLower
    jmp MoveLineRight

@CheckKeyDLower:
    cmp bl, 'd'
    jne @CheckKeyDUpper
    jmp MoveLineRight

@CheckKeyDUpper:
    cmp bl, 'D'
    jne @NoMovementKey
    jmp MoveLineRight

@NoMovementKey:

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
    mov ax, 0003h
    int 10h

    call ReleaseOffScreenBuffer

    mov ax, 4C00h
    int 21h
main ENDP

CodeEnd LABEL BYTE

END main
