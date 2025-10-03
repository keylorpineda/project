; Programa para modo gráfico EGA 640x350 16 colores con doble buffer
; Ensamblador 8086/8088 - Sintaxis TASM

.MODEL SMALL                      ; Usar modelo de memoria small (código y datos < 64K)
.STACK 100h                       ; Reservar 256 bytes para la pila

; Constantes generales del modo gráfico
SCREEN_WIDTH      EQU 640         ; Ancho de pantalla en píxeles
SCREEN_HEIGHT     EQU 350         ; Alto de pantalla en píxeles
BYTES_PER_SCAN    EQU (SCREEN_WIDTH / 8) ; Bytes por línea en cada plano (640/8 = 80)
PLANE_SIZE        EQU (BYTES_PER_SCAN * SCREEN_HEIGHT) ; Bytes por plano (80*350 = 28000)
BUFFER_TOTAL_SIZE EQU (PLANE_SIZE * 4) ; 4 planos (112000 bytes)

.DATA                             ; Segmento de datos
OffScreenBuffer  LABEL BYTE       ; Etiqueta base del buffer off-screen (organizado por planos)
Plane0Buffer     db PLANE_SIZE dup (0) ; Plano 0 (bit de peso 1)
Plane1Buffer     db PLANE_SIZE dup (0) ; Plano 1 (bit de peso 2)
Plane2Buffer     db PLANE_SIZE dup (0) ; Plano 2 (bit de peso 4)
Plane3Buffer     db PLANE_SIZE dup (0) ; Plano 3 (bit de peso 8)

.CODE                             ; Segmento de código

; ----------------------------------------------------------------------------
; Rutina: ClearOffScreenBuffer
; Borra los cuatro planos del buffer off-screen llenándolos con cero.
; ----------------------------------------------------------------------------
ClearOffScreenBuffer PROC
    push ax                        ; Guardar registros usados
    push cx
    push di

    mov al, 0                      ; Valor de llenado: cero

    lea di, Plane0Buffer           ; Borrar plano 0
    mov cx, PLANE_SIZE
    rep stosb

    lea di, Plane1Buffer           ; Borrar plano 1
    mov cx, PLANE_SIZE
    rep stosb

    lea di, Plane2Buffer           ; Borrar plano 2
    mov cx, PLANE_SIZE
    rep stosb

    lea di, Plane3Buffer           ; Borrar plano 3
    mov cx, PLANE_SIZE
    rep stosb

    pop di                         ; Restaurar registros
    pop cx
    pop ax
    ret
ClearOffScreenBuffer ENDP

; ----------------------------------------------------------------------------
; Rutina: DrawPixel
; Dibuja un píxel en el buffer off-screen usando coordenadas (X,Y) y color C.
;  Entradas:
;       CX = coordenada X (0..639)
;       DX = coordenada Y (0..349)
;       AL = color (0..15, 4 bits -> planos 0..3)
;  Salidas:
;       Ninguna. El buffer se actualiza en memoria de datos.
; ----------------------------------------------------------------------------
DrawPixel PROC
    push ax                        ; Guardar registros modificados
    push bx
    push cx
    push dx
    push si
    push di

    mov ah, al                     ; Guardar el color completo en AH

    ; Calcular desplazamiento dentro del plano: offset = Y * 80 + (X / 8)
    mov ax, BYTES_PER_SCAN         ; AX = 80 bytes por línea
    mul dx                         ; DX:AX = Y * 80 (DX queda en 0 porque 350*80 < 65536)
    mov di, ax                     ; DI = Y * 80

    mov bx, cx                     ; BX = X
    mov si, bx                     ; SI = X
    shr bx, 3                      ; BX = X / 8 (índice de byte dentro de la línea)
    add di, bx                     ; DI = offset final dentro del plano

    ; Preparar máscara de bit para seleccionar el píxel dentro del byte
    and si, 7                      ; SI = X mod 8
    mov bl, 7                      ; BL = 7 para invertir el índice (bit más significativo = píxel más a la izquierda)
    sub bl, byte ptr si            ; BL = 7 - (X mod 8)
    mov al, 1                      ; AL = 0000 0001b
    mov cl, bl                     ; CL = número de desplazamientos
    shl al, cl                     ; AL = máscara con el bit correspondiente al píxel
    mov bl, al                     ; BL = máscara de píxel
    mov bh, bl                     ; BH = copia de la máscara
    not bh                         ; BH = máscara invertida (para limpiar el bit)

    ; Actualizar cada plano con el bit correspondiente del color

    ; Plano 0 (bit 0)
    lea si, Plane0Buffer           ; SI -> inicio del plano 0
    add si, di                     ; SI -> byte específico dentro del plano
    mov al, ah                     ; AL = color
    test al, 1                     ; ¿Está activo el bit 0 del color?
    jz @ClearPlane0
    or byte ptr [si], bl           ; Establecer el bit en el buffer
    jmp @NextPlane0
@ClearPlane0:
    and byte ptr [si], bh          ; Limpiar el bit si el plano no participa
@NextPlane0:

    ; Plano 1 (bit 1)
    lea si, Plane1Buffer
    add si, di
    mov al, ah
    test al, 2
    jz @ClearPlane1
    or byte ptr [si], bl
    jmp @NextPlane1
@ClearPlane1:
    and byte ptr [si], bh
@NextPlane1:

    ; Plano 2 (bit 2)
    lea si, Plane2Buffer
    add si, di
    mov al, ah
    test al, 4
    jz @ClearPlane2
    or byte ptr [si], bl
    jmp @NextPlane2
@ClearPlane2:
    and byte ptr [si], bh
@NextPlane2:

    ; Plano 3 (bit 3)
    lea si, Plane3Buffer
    add si, di
    mov al, ah
    test al, 8
    jz @ClearPlane3
    or byte ptr [si], bl
    jmp @NextPlane3
@ClearPlane3:
    and byte ptr [si], bh
@NextPlane3:

    pop di                         ; Restaurar registros
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
    push es

    mov ax, 0A000h                 ; ES = segmento de memoria de video
    mov es, ax

    ; Copiar cada plano al video usando la máscara correspondiente

    ; Plano 0 --------------------------------------------------------------
    mov dx, 03C4h                  ; Puerto del sequencer
    mov al, 02h                    ; Índice del registro Map Mask
    out dx, al
    inc dx                         ; DX = 03C5h (registro de datos)
    mov al, 0001b                  ; Activar únicamente el plano 0
    out dx, al
    dec dx                         ; DX = 03C4h (restaurar índice)
    lea si, Plane0Buffer           ; SI -> datos del plano 0
    xor di, di                     ; DI -> comienzo de la memoria de video
    mov cx, PLANE_SIZE             ; CX = número de bytes del plano
    rep movsb                      ; Copiar plano completo

    ; Plano 1 --------------------------------------------------------------
    mov al, 02h
    out dx, al
    inc dx
    mov al, 0002b                  ; Activar plano 1
    out dx, al
    dec dx
    lea si, Plane1Buffer
    xor di, di
    mov cx, PLANE_SIZE
    rep movsb

    ; Plano 2 --------------------------------------------------------------
    mov al, 02h
    out dx, al
    inc dx
    mov al, 0004b                  ; Activar plano 2
    out dx, al
    dec dx
    lea si, Plane2Buffer
    xor di, di
    mov cx, PLANE_SIZE
    rep movsb

    ; Plano 3 --------------------------------------------------------------
    mov al, 02h
    out dx, al
    inc dx
    mov al, 0008b                  ; Activar plano 3
    out dx, al
    dec dx
    lea si, Plane3Buffer
    xor di, di
    mov cx, PLANE_SIZE
    rep movsb

    ; Restaurar la máscara para habilitar todos los planos (valor por defecto 0Fh)
    mov al, 02h
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al

    pop es                         ; Restaurar registros
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
BlitBufferToScreen ENDP

main PROC
    mov ax, @data                  ; Inicializar el segmento de datos
    mov ds, ax

    ; Cambiar a modo gráfico EGA 640x350x16 (INT 10h, AH=00h, AL=10h)
    mov ax, 0010h
    int 10h

    ; Limpiar el buffer off-screen antes de dibujar
    call ClearOffScreenBuffer

    ; Dibujar una línea horizontal de color rojo (4) desde X=0 hasta X=100 en Y=100
    mov bx, 0                      ; BX = X inicial
LineLoop:
    mov cx, bx                     ; CX = X actual
    mov dx, 100                    ; DX = Y fijo
    mov al, 4                      ; AL = color rojo (bit 2 activado)
    call DrawPixel                 ; Dibujar píxel en el buffer

    inc bx                         ; Siguiente X
    cmp bx, 101                    ; ¿Llegamos al final (X = 100)?
    jle LineLoop                   ; Repetir mientras BX <= 101

    ; Copiar el buffer a la pantalla (doble buffer -> se muestra todo a la vez)
    call BlitBufferToScreen

    ; Esperar a que se presione una tecla (INT 16h, AH=00h)
    xor ah, ah
    int 16h

    ; Volver a modo texto 80x25 (INT 10h, AH=00h, AL=03h)
    mov ax, 0003h
    int 10h

    ; Terminar el programa regresando a DOS
    mov ax, 4C00h
    int 21h
main ENDP

END main
