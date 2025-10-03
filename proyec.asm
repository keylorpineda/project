; Programa para modo gráfico EGA 640x350 16 colores con doble buffer
; Ensamblador 8086/8088 - Sintaxis TASM

.MODEL SMALL                      ; Usar modelo de memoria small (código y datos < 64K)
.STACK 100h                       ; Reservar 256 bytes para la pila

; Constantes generales del modo gráfico
SCREEN_WIDTH      EQU 640         ; Ancho de pantalla en píxeles
SCREEN_HEIGHT     EQU 350         ; Alto de pantalla en píxeles
BYTES_PER_SCAN    EQU (SCREEN_WIDTH / 8) ; Bytes por línea en cada plano (640/8 = 80)
PLANE_SIZE        EQU (BYTES_PER_SCAN * SCREEN_HEIGHT) ; Bytes por plano (80*350 = 28000)
PLANE_PARAGRAPHS  EQU ((PLANE_SIZE + 15) / 16) ; Párrafos necesarios para cada plano (28000/16 = 1750)

.DATA                             ; Segmento de datos
Plane0Segment    dw 0             ; Segmento del plano 0 (bit de peso 1)
Plane1Segment    dw 0             ; Segmento del plano 1 (bit de peso 2)
Plane2Segment    dw 0             ; Segmento del plano 2 (bit de peso 4)
Plane3Segment    dw 0             ; Segmento del plano 3 (bit de peso 8)

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

    mov bx, PLANE_PARAGRAPHS       ; Número de párrafos a reservar por plano

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

.CODE                             ; Segmento de código

; ----------------------------------------------------------------------------
; Rutina: ClearOffScreenBuffer
; Borra los cuatro planos del buffer off-screen llenándolos con cero.
; ----------------------------------------------------------------------------
ClearOffScreenBuffer PROC
    push ax                        ; Guardar registros usados
    push cx
    push di
    push es

    mov al, 0                      ; Valor de llenado: cero

    mov ax, Plane0Segment          ; Borrar plano 0
    or ax, ax
    jz @SkipPlane0
    mov es, ax
    xor di, di
    mov cx, PLANE_SIZE
    rep stosb
@SkipPlane0:

    mov ax, Plane1Segment          ; Borrar plano 1
    or ax, ax
    jz @SkipPlane1
    mov es, ax
    xor di, di
    mov cx, PLANE_SIZE
    rep stosb
@SkipPlane1:

    mov ax, Plane2Segment          ; Borrar plano 2
    or ax, ax
    jz @SkipPlane2
    mov es, ax
    xor di, di
    mov cx, PLANE_SIZE
    rep stosb
@SkipPlane2:

    mov ax, Plane3Segment          ; Borrar plano 3
    or ax, ax
    jz @SkipPlane3
    mov es, ax
    xor di, di
    mov cx, PLANE_SIZE
    rep stosb
@SkipPlane3:

    pop es                         ; Restaurar registros
    pop di
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
    push di
    push es

    mov ah, al                     ; Guardar el color completo en AH

    ; Calcular desplazamiento dentro del plano: offset = Y * 80 + (X / 8)
    mov ax, BYTES_PER_SCAN         ; AX = 80 bytes por línea
    mul dx                         ; DX:AX = Y * 80 (DX queda en 0 porque 350*80 < 65536)
    mov di, ax                     ; DI = Y * 80

    mov bx, cx                     ; BX = X
    mov dl, bl                     ; DL = parte baja de X (para obtener X mod 8)
    shr bx, 3                      ; BX = X / 8 (índice de byte dentro de la línea)
    add di, bx                     ; DI = offset final dentro del plano

    and dl, 7                      ; DL = X mod 8
    mov cl, 7                      ; Preparar desplazamiento para invertir el bit
    sub cl, dl                     ; CL = 7 - (X mod 8)
    mov al, 1
    shl al, cl                     ; AL = máscara con el bit correspondiente al píxel
    mov bl, al                     ; BL = máscara de píxel
    mov bh, bl                     ; BH = copia de la máscara
    not bh                         ; BH = máscara invertida (para limpiar el bit)

    ; Actualizar cada plano con el bit correspondiente del color

    ; Plano 0 (bit 0)
    mov ax, Plane0Segment
    or ax, ax
    jz @NextPlane0
    mov es, ax
    mov al, ah                     ; AL = color
    test al, 1                     ; ¿Está activo el bit 0 del color?
    jz @ClearPlane0
    or es:[di], bl                 ; Establecer el bit en el buffer
    jmp @NextPlane0
@ClearPlane0:
    and es:[di], bh                ; Limpiar el bit si el plano no participa
@NextPlane0:

    ; Plano 1 (bit 1)
    mov ax, Plane1Segment
    or ax, ax
    jz @NextPlane1
    mov es, ax
    mov al, ah
    test al, 2
    jz @ClearPlane1
    or es:[di], bl
    jmp @NextPlane1
@ClearPlane1:
    and es:[di], bh
@NextPlane1:

    ; Plano 2 (bit 2)
    mov ax, Plane2Segment
    or ax, ax
    jz @NextPlane2
    mov es, ax
    mov al, ah
    test al, 4
    jz @ClearPlane2
    or es:[di], bl
    jmp @NextPlane2
@ClearPlane2:
    and es:[di], bh
@NextPlane2:

    ; Plano 3 (bit 3)
    mov ax, Plane3Segment
    or ax, ax
    jz @NextPlane3
    mov es, ax
    mov al, ah
    test al, 8
    jz @ClearPlane3
    or es:[di], bl
    jmp @NextPlane3
@ClearPlane3:
    and es:[di], bh
@NextPlane3:

    pop es                         ; Restaurar registros
    pop di
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
    mov bx, Plane0Segment
    or bx, bx
    jz @SkipCopy0
    push ds
    mov ds, bx
    xor si, si
    xor di, di
    mov cx, PLANE_SIZE             ; CX = número de bytes del plano
    rep movsb                      ; Copiar plano completo
    pop ds
@SkipCopy0:

    ; Plano 1 --------------------------------------------------------------
    mov al, 02h
    out dx, al
    inc dx
    mov al, 0002b                  ; Activar plano 1
    out dx, al
    dec dx
    mov bx, Plane1Segment
    or bx, bx
    jz @SkipCopy1
    push ds
    mov ds, bx
    xor si, si
    xor di, di
    mov cx, PLANE_SIZE
    rep movsb
    pop ds
@SkipCopy1:

    ; Plano 2 --------------------------------------------------------------
    mov al, 02h
    out dx, al
    inc dx
    mov al, 0004b                  ; Activar plano 2
    out dx, al
    dec dx
    mov bx, Plane2Segment
    or bx, bx
    jz @SkipCopy2
    push ds
    mov ds, bx
    xor si, si
    xor di, di
    mov cx, PLANE_SIZE
    rep movsb
    pop ds
@SkipCopy2:

    ; Plano 3 --------------------------------------------------------------
    mov al, 02h
    out dx, al
    inc dx
    mov al, 0008b                  ; Activar plano 3
    out dx, al
    dec dx
    mov bx, Plane3Segment
    or bx, bx
    jz @SkipCopy3
    push ds
    mov ds, bx
    xor si, si
    xor di, di
    mov cx, PLANE_SIZE
    rep movsb
    pop ds
@SkipCopy3:

    ; Restaurar la máscara para habilitar todos los planos (valor por defecto 0Fh)
    mov al, 02h
    out dx, al
    inc dx
    mov al, 0Fh
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

main PROC
    mov ax, @data                  ; Inicializar el segmento de datos
    mov ds, ax

    call InitOffScreenBuffer       ; Reservar memoria para el buffer off-screen
    cmp ax, 0
    je @BuffersReady

    mov dl, al                     ; Guardar código de error
    mov ah, 4Ch                    ; Error en la reserva -> finalizar con código en AL
    mov al, dl
    int 21h

@BuffersReady:

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

    call ReleaseOffScreenBuffer    ; Liberar memoria reservada

    ; Terminar el programa regresando a DOS
    mov ax, 4C00h
    int 21h
main ENDP

END main
