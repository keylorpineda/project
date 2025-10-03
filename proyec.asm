; Programa para modo gráfico EGA 640x350 16 colores con doble buffer
; Ensamblador 8086/8088 - Sintaxis TASM

.MODEL SMALL                      ; Usar modelo de memoria small (código y datos < 64K)
.STACK 100h                       ; Reservar 256 bytes para la pila

; Constantes generales del modo gráfico
SCREEN_WIDTH      EQU 640         ; Ancho de pantalla en píxeles
SCREEN_HEIGHT     EQU 350         ; Alto de pantalla en píxeles
BYTES_PER_SCAN    EQU 20          ; Fix: Ajuste a viewport 160x100 (160/8)
PLANE_SIZE        EQU 2000        ; Fix: Tamaño del plano reducido (20 bytes * 100 scans)
PLANE_PARAGRAPHS  EQU (PLANE_SIZE / 16) ; Fix: 2000 bytes = 125 párrafos para INT 21h/48h

.DATA                             ; Segmento de datos
plane0Segment    dw 0             ; Segmento asignado dinámicamente para plano 0
plane1Segment    dw 0             ; Segmento asignado dinámicamente para plano 1
plane2Segment    dw 0             ; Segmento asignado dinámicamente para plano 2
plane3Segment    dw 0             ; Segmento asignado dinámicamente para plano 3
psp_seg          dw 0             ; Fix: Merge viejo working alloc/clear + debug trace crash
viewport_x_offset dw 30           ; Fix: Desfase horizontal (centrado 160 px en 640)
viewport_y_offset dw 10000        ; Fix: Desfase vertical (125 scans * 80 bytes)
msg_err          db 'ERROR: Alloc fallo. Codigo: $'
msg_free         db ' (free block: $'
msg_shrink_fail  db 'Shrink fail',13,10,'$'
crlf             db 13,10,'$'
msg_mode_ok      db 'Mode EGA OK.$'                      ; Fix: Merge viejo working alloc/clear + debug trace crash
msg_alloc_ok     db 'Alloc OK.$'                         ; Fix: Merge viejo working alloc/clear + debug trace crash
msg_draw_ok      db 'Draw OK.$'                          ; Fix: Merge viejo working alloc/clear + debug trace crash
msg_blit_ok      db 'Blit OK.$'                          ; Fix: Merge viejo working alloc/clear + debug trace crash
msg_wait         db 'Wait key.$'                         ; Fix: Merge viejo working alloc/clear + debug trace crash

.CODE                             ; Segmento de código

; -------------------------------------------------------------------------
; Rutina: ShrinkProgramMemory
; Reduce el bloque de memoria asignado al programa antes de reservar
; memoria adicional para los planos. Esto libera memoria "prestada" que el
; cargador asigna al .EXE al iniciarse.
; -------------------------------------------------------------------------
ShrinkProgramMemory PROC
    ; Fix: Merge viejo working alloc/clear + debug trace crash
    push ax
    push bx
    push cx
    push dx
    push es

    mov ax, psp_seg
    or ax, ax
    jnz SHORT @have_psp

    mov ah, 51h
    int 21h
    mov psp_seg, bx

@have_psp:
    mov es, psp_seg
    mov ax, es:[2]
    shr ax, 1

    mov ah, 4Ah
    mov bx, 100
    int 21h
    jc SHORT @shrink_fail

    xor ax, ax
    jmp SHORT @exit

@shrink_fail:
    mov ax, 1

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
    ; Fix: Merge viejo working alloc/clear + debug trace crash
    push bx
    push cx
    push dx
    push di
    push es

    xor ax, ax
    mov plane0Segment, ax
    mov plane1Segment, ax
    mov plane2Segment, ax
    mov plane3Segment, ax

    mov bx, PLANE_PARAGRAPHS
    mov ah, 48h
    int 21h
    jc SHORT @AllocFail
    mov plane0Segment, ax
    mov es, ax
    xor di, di
    xor ax, ax
    mov cx, PLANE_SIZE
    rep stosb

    mov bx, PLANE_PARAGRAPHS
    mov ah, 48h
    int 21h
    jc SHORT @AllocFail
    mov plane1Segment, ax
    mov es, ax
    xor di, di
    xor ax, ax
    mov cx, PLANE_SIZE
    rep stosb

    mov bx, PLANE_PARAGRAPHS
    mov ah, 48h
    int 21h
    jc SHORT @AllocFail
    mov plane2Segment, ax
    mov es, ax
    xor di, di
    xor ax, ax
    mov cx, PLANE_SIZE
    rep stosb

    mov bx, PLANE_PARAGRAPHS
    mov ah, 48h
    int 21h
    jc SHORT @AllocFail
    mov plane3Segment, ax
    mov es, ax
    xor di, di
    xor ax, ax
    mov cx, PLANE_SIZE
    rep stosb

    xor ax, ax
    jmp SHORT @InitExit

@AllocFail:
    push ax
    call ReleaseOffScreenBuffer
    pop ax

@InitExit:
    pop es
    pop di
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
    ; Fix: Merge viejo working alloc/clear + debug trace crash
    push ax
    push es

    mov ax, plane0Segment
    or ax, ax
    jz SHORT @SkipFree0
    mov es, ax
    mov ah, 49h
    int 21h
    mov plane0Segment, 0
@SkipFree0:

    mov ax, plane1Segment
    or ax, ax
    jz SHORT @SkipFree1
    mov es, ax
    mov ah, 49h
    int 21h
    mov plane1Segment, 0
@SkipFree1:

    mov ax, plane2Segment
    or ax, ax
    jz SHORT @SkipFree2
    mov es, ax
    mov ah, 49h
    int 21h
    mov plane2Segment, 0
@SkipFree2:

    mov ax, plane3Segment
    or ax, ax
    jz SHORT @SkipFree3
    mov es, ax
    mov ah, 49h
    int 21h
    mov plane3Segment, 0
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

    mov al, 0

    mov ax, plane0Segment
    or ax, ax
    jz SHORT @skip0                ; Fix: Labels únicos y SHORT jumps para TASM range
    mov es, ax
    xor di, di
    mov cx, PLANE_SIZE
    rep stosb
@skip0:

    mov ax, plane1Segment
    or ax, ax
    jz SHORT @skip1                ; Fix: Labels únicos y SHORT jumps para TASM range
    mov es, ax
    xor di, di
    mov cx, PLANE_SIZE
    rep stosb
@skip1:

    mov ax, plane2Segment
    or ax, ax
    jz SHORT @skip2                ; Fix: Labels únicos y SHORT jumps para TASM range
    mov es, ax
    xor di, di
    mov cx, PLANE_SIZE
    rep stosb
@skip2:

    mov ax, plane3Segment
    or ax, ax
    jz SHORT @skip3                ; Fix: Labels únicos y SHORT jumps para TASM range
    mov es, ax
    xor di, di
    mov cx, PLANE_SIZE
    rep stosb
@skip3:

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

    mov ax, plane0Segment
    or ax, ax
    jz SHORT @plane0_skip          ; Fix: Labels únicos y SHORT jumps para TASM range
    mov es, ax
    mov di, si
    test dh, 1
    jz SHORT @plane0_clear
    mov al, bl
    or BYTE PTR es:[di], al
    jmp SHORT @plane0_next
@plane0_clear:
    mov al, bh
    and BYTE PTR es:[di], al
@plane0_next:
@plane0_skip:

    mov ax, plane1Segment
    or ax, ax
    jz SHORT @plane1_skip          ; Fix: Labels únicos y SHORT jumps para TASM range
    mov es, ax
    mov di, si
    test dh, 2
    jz SHORT @plane1_clear
    mov al, bl
    or BYTE PTR es:[di], al
    jmp SHORT @plane1_next
@plane1_clear:
    mov al, bh
    and BYTE PTR es:[di], al
@plane1_next:
@plane1_skip:

    mov ax, plane2Segment
    or ax, ax
    jz SHORT @plane2_skip          ; Fix: Labels únicos y SHORT jumps para TASM range
    mov es, ax
    mov di, si
    test dh, 4
    jz SHORT @plane2_clear
    mov al, bl
    or BYTE PTR es:[di], al
    jmp SHORT @plane2_next
@plane2_clear:
    mov al, bh
    and BYTE PTR es:[di], al
@plane2_next:
@plane2_skip:

    mov ax, plane3Segment
    or ax, ax
    jz SHORT @plane3_skip          ; Fix: Labels únicos y SHORT jumps para TASM range
    mov es, ax
    mov di, si
    test dh, 8
    jz SHORT @plane3_clear
    mov al, bl
    or BYTE PTR es:[di], al
    jmp SHORT @plane3_next
@plane3_clear:
    mov al, bh
    and BYTE PTR es:[di], al
@plane3_next:
@plane3_skip:

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
; Rutina: BlitBufferToScreen
; Copia el contenido del buffer off-screen a la memoria de video A000h.
; Usa el registro de máscara del mapa (sequencer) para seleccionar cada plano.
; ----------------------------------------------------------------------------
BlitBufferToScreen PROC
    ; Fix: Merge viejo working alloc/clear + debug trace crash
    push ax                        ; Guardar registros usados
    push bx
    push cx
    push dx
    push si
    push di
    push ds
    push es

    mov ax, 0A000h
    mov es, ax                     ; Blit fijo DS=@data to ES top-left
    mov dx, 03C4h

    mov al, 02h
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    dec dx
    mov ax, @data
    mov ds, ax
    mov bx, plane0Segment
    or bx, bx
    jz SHORT @skipcopy0            ; Fix: Labels únicos y SHORT jumps para TASM range
    mov ds, bx
    xor di, di
    xor si, si
    mov cx, PLANE_SIZE
    rep movsb
@skipcopy0:

    mov ax, @data
    mov ds, ax

    mov al, 02h
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    dec dx
    mov bx, plane1Segment
    or bx, bx
    jz SHORT @skipcopy1            ; Fix: Labels únicos y SHORT jumps para TASM range
    mov ds, bx
    xor di, di
    xor si, si
    mov cx, PLANE_SIZE
    rep movsb
@skipcopy1:

    mov ax, @data
    mov ds, ax

    mov al, 02h
    out dx, al
    inc dx
    mov al, 4
    out dx, al
    dec dx
    mov bx, plane2Segment
    or bx, bx
    jz SHORT @skipcopy2            ; Fix: Labels únicos y SHORT jumps para TASM range
    mov ds, bx
    xor di, di
    xor si, si
    mov cx, PLANE_SIZE
    rep movsb
@skipcopy2:

    mov ax, @data
    mov ds, ax

    mov al, 02h
    out dx, al
    inc dx
    mov al, 8
    out dx, al
    dec dx
    mov bx, plane3Segment
    or bx, bx
    jz SHORT @skipcopy3            ; Fix: Labels únicos y SHORT jumps para TASM range
    mov ds, bx
    xor di, di
    xor si, si
    mov cx, PLANE_SIZE
    rep movsb
@skipcopy3:

    mov ax, @data
    mov ds, ax

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
    ; Fix: Merge viejo working alloc/clear + debug trace crash
    mov ax, @data
    mov ds, ax

    call ShrinkProgramMemory

    mov ax, 0010h
    int 10h

    mov dx, OFFSET msg_mode_ok
    mov ah, 09h
    int 21h

    call ClearScreen
    call SetPaletteRed

    call InitOffScreenBuffer
    or ax, ax
    jz SHORT @alloc_ok

    mov si, ax
    mov dx, OFFSET msg_err
    mov ah, 09h
    int 21h
    mov ax, si
    call PrintHexAX
    mov dx, OFFSET msg_free
    mov ah, 09h
    int 21h
    mov ax, bx
    call PrintHexAX
    mov dx, OFFSET crlf
    mov ah, 09h
    int 21h
    mov ax, 4C01h
    int 21h

@alloc_ok:
    mov dx, OFFSET msg_alloc_ok
    mov ah, 09h
    int 21h

    call ClearOffScreenBuffer

    mov cx, 0
    mov bx, 0
    mov dl, 4
@LineLoop:
    call DrawPixel
    inc bx
    cmp bx, 160
    jb SHORT @LineLoop

    mov dx, OFFSET msg_draw_ok
    mov ah, 09h
    int 21h

    mov bx, 0
    mov cx, 0
    mov dl, 4
@VertLoop:
    call DrawPixel
    inc cx
    cmp cx, 100
    jb SHORT @VertLoop

    call BlitBufferToScreen

    mov dx, OFFSET msg_blit_ok
    mov ah, 09h
    int 21h

    mov dx, OFFSET msg_wait
    mov ah, 09h
    int 21h
    xor ah, ah
    int 16h

    call ReleaseOffScreenBuffer

    mov ax, 0003h
    int 10h

    mov ax, 4C00h
    int 21h
main ENDP

END main
