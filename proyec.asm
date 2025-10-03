; Programa para modo gráfico EGA 640x350 16 colores
; Ensamblador 8086/8088 - Sintaxis TASM

.MODEL SMALL              ; Usar modelo de memoria small
.STACK 100h               ; Reservar 256 bytes para la pila

.DATA                     ; Segmento de datos
Filler db 0               ; Variable de relleno (no utilizada)

.CODE                     ; Segmento de código
main PROC
    mov ax, @data         ; Inicializar el segmento de datos
    mov ds, ax

    ; Cambiar a modo gráfico EGA 640x350x16 (INT 10h, AH=00h, AL=10h)
    mov ax, 0010h
    int 10h

    ; Limpiar pantalla con color negro usando función de scroll (AH=06h)
    mov ax, 0600h         ; Scroll 0 líneas -> limpiar
    mov bh, 00h           ; Color de relleno: negro
    mov cx, 0000h         ; Coordenada inicial (fila 0, columna 0)
    mov dx, 2A4Fh         ; Coordenada final (fila 42, columna 79)
    int 10h

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
