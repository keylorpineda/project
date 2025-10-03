; Programa para modo gráfico VGA 320x200x256 con buffer packed
; Ensamblador 8086/8088 - Sintaxis TASM

.MODEL SMALL                      ; Usar modelo de memoria small (código y datos < 64K)
.STACK 100h                       ; Reservar 256 bytes para la pila

; Constantes generales del modo gráfico
SCREEN_WIDTH      EQU 320         ; Fix: VGA 13h packed para Fase 2 visible DOSBox
SCREEN_HEIGHT     EQU 200         ; Fix: VGA 13h packed para Fase 2 visible DOSBox
BYTES_PER_SCAN    EQU 320         ; Fix: VGA 13h packed para Fase 2 visible DOSBox
PLANE_SIZE        EQU 32000       ; Fix: VGA 13h packed para Fase 2 visible DOSBox (320*100)

.DATA                             ; Segmento de datos
; Fix: VGA 13h packed para Fase 2 visible DOSBox
buffer           db 32000 dup(0)  ; Buffer fijo packed 320x100

.CODE                             ; Segmento de código

; -------------------------------------------------------------------------
; Rutina: ShrinkProgramMemory
; Fix: VGA 13h packed para Fase 2 visible DOSBox
; -------------------------------------------------------------------------
ShrinkProgramMemory PROC
    xor ax, ax
    ret
ShrinkProgramMemory ENDP

; -------------------------------------------------------------------------
; Rutina: InitOffScreenBuffer
; Fix: VGA 13h packed para Fase 2 visible DOSBox
; -------------------------------------------------------------------------
InitOffScreenBuffer PROC
    xor ax, ax
    ret
InitOffScreenBuffer ENDP

; -------------------------------------------------------------------------
; Rutina: ReleaseOffScreenBuffer
; Fix: VGA 13h packed para Fase 2 visible DOSBox
; -------------------------------------------------------------------------
ReleaseOffScreenBuffer PROC
    ret
ReleaseOffScreenBuffer ENDP

; ----------------------------------------------------------------------------
; Rutina: ClearOffScreenBuffer
; Borra el buffer packed llenándolo con cero.
; ----------------------------------------------------------------------------
ClearOffScreenBuffer PROC
    push ax
    push cx
    push di
    push es

    mov ax, @data
    mov es, ax

    mov di, OFFSET buffer
    xor al, al
    mov cx, 32000
    rep stosb

    pop es
    pop di
    pop cx
    pop ax
    ret
ClearOffScreenBuffer ENDP

; ----------------------------------------------------------------------------
; Rutina: SetPaletteRed
; Ajusta el color 4 de la paleta VGA a rojo brillante (R=63, G=0, B=0).
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
; Rutina: ClearScreen
; Limpia toda la memoria de video del modo 13h.
; ----------------------------------------------------------------------------
ClearScreen PROC
    push ax
    push cx
    push di
    push es

    mov ax, 0A000h
    mov es, ax

    xor di, di
    xor al, al
    mov cx, 64000                   ; Fix: VGA 13h packed para Fase 2 visible DOSBox
    rep stosb

    pop es
    pop di
    pop cx
    pop ax
    ret
ClearScreen ENDP

; ----------------------------------------------------------------------------
; Rutina: DrawPixel
; Dibuja un píxel en el buffer packed usando coordenadas (X,Y) y color DL.
; ----------------------------------------------------------------------------
DrawPixel PROC
    push ax
    push bx
    push cx
    push dx
    push di
    push es

    cmp bx, 319
    ja @exit_pixel
    cmp cx, 99
    ja @exit_pixel

    mov ax, cx
    mov dx, BYTES_PER_SCAN
    mul dx
    add ax, bx

    mov di, OFFSET buffer
    add di, ax

    mov ax, @data
    mov es, ax
    mov al, dl
    mov es:[di], al

@exit_pixel:
    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DrawPixel ENDP

; ----------------------------------------------------------------------------
; Rutina: BlitBufferToScreen
; Copia el contenido del buffer packed a la memoria de video A000h.
; ----------------------------------------------------------------------------
BlitBufferToScreen PROC
    push ax
    push cx
    push si
    push di
    push ds
    push es

    mov ax, @data
    mov ds, ax
    mov si, OFFSET buffer

    mov ax, 0A000h
    mov es, ax
    xor di, di

    mov cx, 32000                   ; Fix: VGA 13h packed para Fase 2 visible DOSBox
    rep movsb                       ; Blit packed directo top-left

    pop es
    pop ds
    pop di
    pop si
    pop cx
    pop ax
    ret
BlitBufferToScreen ENDP

; -------------------------------------------------------------------------
; Programa principal
; -------------------------------------------------------------------------
main PROC
    mov ax, @data
    mov ds, ax

    mov ax, 0013h
    int 10h

    call ClearScreen
    call SetPaletteRed
    call ClearOffScreenBuffer

    mov cx, 50
    mov bx, 0
    mov dl, 4
LineLoop:
    call DrawPixel
    inc bx
    cmp bx, SCREEN_WIDTH
    jb LineLoop

    mov bx, 160
    mov cx, 0
    mov dl, 4
VertLoop:
    call DrawPixel
    inc cx
    cmp cx, SCREEN_HEIGHT
    jb VertLoop

    call BlitBufferToScreen

    xor ah, ah
    int 16h

    mov ax, 0003h
    int 10h

    mov ax, 4C00h
    int 21h
main ENDP

END main
