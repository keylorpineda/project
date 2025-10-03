; Programa para modo gráfico EGA 640x350 16 colores con doble buffer
; Ensamblador 8086/8088 - Sintaxis TASM

.MODEL SMALL                      ; Usar modelo de memoria small (código y datos < 64K)
.STACK 100h                       ; Reservar 256 bytes para la pila

; Constantes generales del modo gráfico
SCREEN_WIDTH      EQU 640         ; Ancho de pantalla en píxeles
SCREEN_HEIGHT     EQU 350         ; Alto de pantalla en píxeles
BYTES_PER_SCAN    EQU 20          ; Fix: Ajuste a viewport 160x100 (160/8)
PLANE_SIZE        EQU 2000        ; Fix: Tamaño del plano reducido (20 bytes * 100 scans)

.DATA                             ; Segmento de datos
; Fix: Buffer fijo .DATA para Fase 2 sin bugs DOSBox
plane0           db 2000 dup(0)    ; Buffer fijo planar 2000 bytes/plano
plane1           db 2000 dup(0)
plane2           db 2000 dup(0)
plane3           db 2000 dup(0)
viewport_x_offset dw 30           ; Fix: Desfase horizontal (centrado 160 px en 640)
viewport_y_offset dw 10000        ; Fix: Desfase vertical (125 scans * 80 bytes)
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
    ; Fix: Buffer fijo .DATA para Fase 2 sin bugs DOSBox
    xor ax, ax
    ret
ShrinkProgramMemory ENDP

; -------------------------------------------------------------------------
; Rutina: InitOffScreenBuffer
; Reserva memoria convencional (mediante INT 21h, función 48h) para los
; cuatro planos del buffer off-screen. Devuelve AX=0 si la reserva tuvo
; éxito; en caso contrario, AX contiene el código de error devuelto por DOS.
; -------------------------------------------------------------------------
InitOffScreenBuffer PROC
    ; Fix: Buffer fijo .DATA para Fase 2 sin bugs DOSBox
    xor ax, ax
    ret
InitOffScreenBuffer ENDP

; -------------------------------------------------------------------------
; Rutina: ReleaseOffScreenBuffer
; Libera los bloques de memoria reservados para los planos del buffer
; off-screen (INT 21h, función 49h).
; -------------------------------------------------------------------------
ReleaseOffScreenBuffer PROC
    ; Fix: Buffer fijo .DATA para Fase 2 sin bugs DOSBox
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

    mov ax, @data
    mov es, ax                     ; Clear fijo en ES=@data

    mov di, OFFSET plane0
    mov al, 0
    mov cx, 2000
    rep stosb

    mov di, OFFSET plane1
    mov cx, 2000
    rep stosb

    mov di, OFFSET plane2
    mov cx, 2000
    rep stosb

    mov di, OFFSET plane3
    mov cx, 2000
    rep stosb

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

    mov ax, @data
    mov es, ax

    mov di, si
    test dh, 1
    jz @ClearPlane0
    mov al, bl
    or BYTE PTR es:[OFFSET plane0 + di], al    ; Fix: Buffer fijo .DATA para Fase 2 sin bugs DOSBox
    jmp @NextPlane0
@ClearPlane0:
    mov al, bh
    and BYTE PTR es:[OFFSET plane0 + di], al
@NextPlane0:

    mov di, si
    test dh, 2
    jz @ClearPlane1
    mov al, bl
    or BYTE PTR es:[OFFSET plane1 + di], al
    jmp @NextPlane1
@ClearPlane1:
    mov al, bh
    and BYTE PTR es:[OFFSET plane1 + di], al
@NextPlane1:

    mov di, si
    test dh, 4
    jz @ClearPlane2
    mov al, bl
    or BYTE PTR es:[OFFSET plane2 + di], al
    jmp @NextPlane2
@ClearPlane2:
    mov al, bh
    and BYTE PTR es:[OFFSET plane2 + di], al
@NextPlane2:

    mov di, si
    test dh, 8
    jz @ClearPlane3
    mov al, bl
    or BYTE PTR es:[OFFSET plane3 + di], al
    jmp @NextPlane3
@ClearPlane3:
    mov al, bh
    and BYTE PTR es:[OFFSET plane3 + di], al
@NextPlane3:

@exit_pixel:
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
    push ax                        ; Guardar registros usados
    push bx
    push cx
    push dx
    push si
    push di
    push ds
    push es

    mov ax, @data
    mov ds, ax
    mov ax, 0A000h
    mov es, ax                     ; Blit fijo DS=@data to ES top-left
    mov dx, 03C4h

    mov al, 02h
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    dec dx
    mov si, OFFSET plane0
    xor di, di
    mov cx, 2000
    rep movsb

    mov al, 02h
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    dec dx
    mov si, OFFSET plane1
    xor di, di
    mov cx, 2000
    rep movsb

    mov al, 02h
    out dx, al
    inc dx
    mov al, 4
    out dx, al
    dec dx
    mov si, OFFSET plane2
    xor di, di
    mov cx, 2000
    rep movsb

    mov al, 02h
    out dx, al
    inc dx
    mov al, 8
    out dx, al
    dec dx
    mov si, OFFSET plane3
    xor di, di
    mov cx, 2000
    rep movsb

    mov al, 02h
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    dec dx

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

    mov ax, 0010h                  ; Cambiar a modo gráfico EGA 640x350x16
    int 10h

    ; call SetPaletteRed             ; Fix: Color 4 = rojo brillante (R=63)
    call SetPaletteWhite           ; Test: Paleta blanco puro para referencia en color 15

    call ClearOffScreenBuffer      ; Preparar buffer off-screen

    mov cx, 0                      ; Fix: Línea top-left blanca para test buffer fijo (Y=0)
    mov bx, 0                      ; Fix: Línea top-left blanca para test buffer fijo (X inicial 0)
    mov dl, 15                     ; Fix: Línea top-left blanca para test buffer fijo (color blanco)
LineLoop:
    call DrawPixel
    inc bx
    cmp bx, 160
    jle LineLoop

    mov bx, 0                      ; Fix: Línea top-left blanca para test buffer fijo (X=0)
    mov cx, 0                      ; Fix: Línea top-left blanca para test buffer fijo (Y inicial 0)
    mov dl, 15                     ; Fix: Línea top-left blanca para test buffer fijo (color blanco)
VertLoop:
    call DrawPixel
    inc cx
    cmp cx, 100
    jle VertLoop

    call BlitBufferToScreen        ; Copiar buffer a la pantalla

    xor ah, ah                     ; Esperar tecla
    int 16h

    mov ax, 0003h                  ; Volver a modo texto 80x25
    int 10h

    mov ax, 4C00h                  ; Terminar programa
    int 21h
main ENDP

END main
