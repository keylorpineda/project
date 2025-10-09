; JUEGO DE EXPLORACIÓN - MODO EGA 0Dh (320x200x16)
; Universidad Nacional - Proyecto II Ciclo 2025
; Con DOBLE BUFFER REAL funcionando

.MODEL SMALL
.STACK 4096

; === CONSTANTES ===
TILE_GRASS  EQU 0
TILE_WALL   EQU 1
TILE_PATH   EQU 2
TILE_WATER  EQU 3
TILE_TREE   EQU 4

TILE_SIZE   EQU 16
SCREEN_W    EQU 320
SCREEN_H    EQU 200
VIEWPORT_W  EQU 20      ; 320/16 = 20 tiles
VIEWPORT_H  EQU 12      ; 192/16 = 12 tiles (usa 192 píxeles)

.DATA
; === ARCHIVOS ===
archivo_mapa    db 'MAPA.TXT',0

; === MAPA (100x100) ===
mapa_ancho  dw 100
mapa_alto   dw 100
mapa_datos  db 10000 dup(0)

; === JUGADOR ===
jugador_x   dw 50
jugador_y   dw 50
jugador_x_ant dw 50
jugador_y_ant dw 50

; === CÁMARA ===
camara_x    dw 0
camara_y    dw 0

; === DOBLE BUFFER ===
pagina_visible db 0     ; Página que se muestra
pagina_dibujo  db 1     ; Página donde se dibuja

; === BUFFER ARCHIVO ===
buffer_archivo db 20000 dup(0)
handle_arch dw 0

; === MENSAJES ===
msg_inicio  db 'JUEGO EXPLORACION - MODO 0Dh (320x200x16)',13,10
           db '==========================================',13,10,'$'
msg_cargando db 'Cargando MAPA.TXT...$'
msg_ok db 'OK',13,10,'$'
msg_generando db 'Generando mapa procedural 100x100...$'
msg_dimensiones db 'Dimensiones: $'
msg_x db 'x$'
msg_listo  db 13,10,'Sistema listo!',13,10
           db 'Flechas o WASD = Mover',13,10
           db 'ESC = Salir',13,10
           db 13,10,'Presiona tecla para comenzar...$'

.CODE
inicio:
    mov ax, @data
    mov ds, ax

    ; Mensajes iniciales
    mov dx, OFFSET msg_inicio
    mov ah, 9
    int 21h

    mov dx, OFFSET msg_cargando
    mov ah, 9
    int 21h
    
    call cargar_mapa
    
    mov dx, OFFSET msg_listo
    mov ah, 9
    int 21h

    ; Esperar tecla
    mov ah, 0
    int 16h

    ; *** MODO GRAFICO 0Dh - 320x200x16 ***
    mov ax, 0Dh
    int 10h
    
    ; Inicializar doble buffer
    mov pagina_visible, 0
    mov pagina_dibujo, 1
    
    ; Mostrar página 0
    mov al, 0
    mov ah, 05h
    int 10h
    
    ; Renderizar frame inicial
    call actualizar_camara
    call renderizar_completo

bucle_principal:
    ; Verificar si hay tecla
    mov ah, 1
    int 16h
    jz bucle_principal

    ; Leer tecla
    mov ah, 0
    int 16h

    ; ESC = salir
    cmp al, 27
    je salir

    ; Procesar movimiento
    call mover_jugador
    
    ; Renderizar nuevo frame
    call renderizar_completo
    
    jmp bucle_principal

salir:
    ; Volver a modo texto
    mov ax, 3
    int 10h
    
    ; Salir al DOS
    mov ax, 4C00h
    int 21h

; ========================================
; CARGAR MAPA
; ========================================
cargar_mapa PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Intentar abrir archivo
    mov dx, OFFSET archivo_mapa
    mov ax, 3D00h
    int 21h
    jc generar_procedural
    
    mov handle_arch, ax
    mov bx, ax
    
    ; Leer archivo
    mov cx, 20000
    mov dx, OFFSET buffer_archivo
    mov ah, 3Fh
    int 21h
    jc cerrar_y_generar
    
    ; Parsear dimensiones
    mov si, OFFSET buffer_archivo
    call parsear_numero
    mov mapa_ancho, ax
    push ax
    call parsear_numero
    mov mapa_alto, ax
    
    ; Mostrar dimensiones
    mov dx, OFFSET msg_dimensiones
    mov ah, 9
    int 21h
    pop ax
    push ax
    call imprimir_numero
    mov dl, 'x'
    mov ah, 2
    int 21h
    mov ax, mapa_alto
    call imprimir_numero
    mov dl, 13
    mov ah, 2
    int 21h
    mov dl, 10
    int 21h
    pop ax
    
    ; Leer tiles del mapa
    mov di, OFFSET mapa_datos
    mov ax, mapa_alto
    mov bx, mapa_ancho
    mul bx
    mov cx, ax
    
leer_tiles:
    call parsear_numero
    mov [di], al
    inc di
    loop leer_tiles
    
    ; Cerrar archivo
    mov bx, handle_arch
    mov ah, 3Eh
    int 21h
    
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
    jmp fin_cargar_mapa

cerrar_y_generar:
    mov bx, handle_arch
    mov ah, 3Eh
    int 21h
    
generar_procedural:
    mov dx, OFFSET msg_generando
    mov ah, 9
    int 21h
    call generar_mapa_procedural
    mov dx, OFFSET msg_ok
    mov ah, 9
    int 21h
    
fin_cargar_mapa:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
cargar_mapa ENDP

; ========================================
; PARSEAR NÚMERO
; ========================================
parsear_numero PROC
    push bx
    push cx
    push dx
    
    xor ax, ax
    xor bx, bx
    
pn_saltar:
    mov bl, [si]
    inc si
    cmp bl, ' '
    je pn_saltar
    cmp bl, 13
    je pn_saltar
    cmp bl, 10
    je pn_saltar
    cmp bl, 9
    je pn_saltar
    
pn_digitos:
    cmp bl, '0'
    jb pn_fin
    cmp bl, '9'
    ja pn_fin
    
    sub bl, '0'
    mov cx, 10
    mul cx
    add ax, bx
    
    mov bl, [si]
    inc si
    jmp pn_digitos
    
pn_fin:
    pop dx
    pop cx
    pop bx
    ret
parsear_numero ENDP

; ========================================
; IMPRIMIR NÚMERO
; ========================================
imprimir_numero PROC
    push ax
    push bx
    push cx
    push dx
    
    mov cx, 0
    mov bx, 10
    
    cmp ax, 0
    jne in_dividir
    push ax
    inc cx
    jmp in_imprimir
    
in_dividir:
    xor dx, dx
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne in_dividir
    
in_imprimir:
    pop dx
    add dl, '0'
    mov ah, 2
    int 21h
    loop in_imprimir
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
imprimir_numero ENDP

; ========================================
; GENERAR MAPA PROCEDURAL
; ========================================
generar_mapa_procedural PROC
    push ax
    push bx
    push cx
    push dx
    push di
    
    mov mapa_ancho, 100
    mov mapa_alto, 100
    
    mov di, OFFSET mapa_datos
    mov cx, 10000
    xor bx, bx
    
gmp_loop:
    ; Verificar bordes
    cmp bx, 100
    jb gmp_muro
    
    mov ax, bx
    xor dx, dx
    mov si, 100
    div si
    
    cmp ax, 99
    je gmp_muro
    cmp dx, 0
    je gmp_muro
    cmp dx, 99
    je gmp_muro
    
    ; Zona de inicio (48-52, 48-52)
    cmp ax, 48
    jb gmp_terreno
    cmp ax, 52
    ja gmp_terreno
    cmp dx, 48
    jb gmp_terreno
    cmp dx, 52
    ja gmp_terreno
    mov al, TILE_GRASS
    jmp gmp_guardar
    
gmp_terreno:
    ; Terreno pseudo-aleatorio
    mov ax, bx
    and ax, 1Fh
    
    cmp ax, 2
    jb gmp_agua
    cmp ax, 6
    jb gmp_arbol
    cmp ax, 10
    jb gmp_camino
    mov al, TILE_GRASS
    jmp gmp_guardar
    
gmp_muro:
    mov al, TILE_WALL
    jmp gmp_guardar
    
gmp_agua:
    mov al, TILE_WATER
    jmp gmp_guardar
    
gmp_arbol:
    mov al, TILE_TREE
    jmp gmp_guardar
    
gmp_camino:
    mov al, TILE_PATH
    
gmp_guardar:
    mov [di], al
    inc di
    inc bx
    loop gmp_loop
    
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
generar_mapa_procedural ENDP

; ========================================
; MOVER JUGADOR
; ========================================
mover_jugador PROC
    push ax
    push bx
    
    ; Guardar posición anterior
    mov ax, jugador_x
    mov jugador_x_ant, ax
    mov ax, jugador_y
    mov jugador_y_ant, ax
    
    ; Verificar tecla presionada
    cmp ah, 48h         ; Flecha arriba
    je mj_arriba
    cmp al, 'w'
    je mj_arriba
    cmp al, 'W'
    je mj_arriba
    
    cmp ah, 50h         ; Flecha abajo
    je mj_abajo
    cmp al, 's'
    je mj_abajo
    cmp al, 'S'
    je mj_abajo
    
    cmp ah, 4Bh         ; Flecha izquierda
    je mj_izquierda
    cmp al, 'a'
    je mj_izquierda
    cmp al, 'A'
    je mj_izquierda
    
    cmp ah, 4Dh         ; Flecha derecha
    je mj_derecha
    cmp al, 'd'
    je mj_derecha
    cmp al, 'D'
    je mj_derecha
    
    jmp mj_fin
    
mj_arriba:
    cmp jugador_y, 0
    je mj_fin
    dec jugador_y
    jmp mj_verificar
    
mj_abajo:
    mov ax, jugador_y
    inc ax
    cmp ax, mapa_alto
    jae mj_fin
    mov jugador_y, ax
    jmp mj_verificar
    
mj_izquierda:
    cmp jugador_x, 0
    je mj_fin
    dec jugador_x
    jmp mj_verificar
    
mj_derecha:
    mov ax, jugador_x
    inc ax
    cmp ax, mapa_ancho
    jae mj_fin
    mov jugador_x, ax
    jmp mj_verificar
    
mj_verificar:
    call verificar_colision
    jc mj_restaurar
    call actualizar_camara
    jmp mj_fin
    
mj_restaurar:
    mov ax, jugador_x_ant
    mov jugador_x, ax
    mov ax, jugador_y_ant
    mov jugador_y, ax
    
mj_fin:
    pop bx
    pop ax
    ret
mover_jugador ENDP

; ========================================
; VERIFICAR COLISIÓN
; ========================================
verificar_colision PROC
    push ax
    push bx
    push si
    
    ; Calcular índice en mapa
    mov ax, jugador_y
    mov bx, mapa_ancho
    mul bx
    add ax, jugador_x
    
    ; Obtener tipo de tile
    mov si, OFFSET mapa_datos
    add si, ax
    mov al, [si]
    
    ; Verificar si es transitable
    cmp al, TILE_GRASS
    je vc_ok
    cmp al, TILE_PATH
    je vc_ok
    
    ; Colisión detectada
    stc
    jmp vc_fin
    
vc_ok:
    clc
    
vc_fin:
    pop si
    pop bx
    pop ax
    ret
verificar_colision ENDP

; ========================================
; ACTUALIZAR CÁMARA
; ========================================
actualizar_camara PROC
    push ax
    push bx
    
    ; Centrar en X
    mov ax, jugador_x
    sub ax, VIEWPORT_W/2
    cmp ax, 0
    jge ac_x1
    xor ax, ax
ac_x1:
    mov bx, mapa_ancho
    sub bx, VIEWPORT_W
    jle ac_x2
    cmp ax, bx
    jle ac_x3
    mov ax, bx
    jmp ac_x3
ac_x2:
    xor ax, ax
ac_x3:
    mov camara_x, ax
    
    ; Centrar en Y
    mov ax, jugador_y
    sub ax, VIEWPORT_H/2
    cmp ax, 0
    jge ac_y1
    xor ax, ax
ac_y1:
    mov bx, mapa_alto
    sub bx, VIEWPORT_H
    jle ac_y2
    cmp ax, bx
    jle ac_y3
    mov ax, bx
    jmp ac_y3
ac_y2:
    xor ax, ax
ac_y3:
    mov camara_y, ax
    
    pop bx
    pop ax
    ret
actualizar_camara ENDP

; ========================================
; RENDERIZAR COMPLETO (DOBLE BUFFER)
; ========================================
renderizar_completo PROC
    push ax
    
    ; Seleccionar página de dibujo (oculta)
    mov al, pagina_dibujo
    mov ah, 05h
    int 10h
    
    ; Dibujar viewport
    call dibujar_viewport
    
    ; Dibujar jugador
    call dibujar_jugador
    
    ; Intercambiar páginas
    mov al, pagina_dibujo
    mov bl, pagina_visible
    mov pagina_visible, al
    mov pagina_dibujo, bl
    
    ; Mostrar página recién dibujada
    mov al, pagina_visible
    mov ah, 05h
    int 10h
    
    pop ax
    ret
renderizar_completo ENDP

; ========================================
; DIBUJAR VIEWPORT
; ========================================
dibujar_viewport PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    xor di, di          ; Y del viewport
    
dv_loop_y:
    cmp di, VIEWPORT_H
    jae dv_fin
    
    xor si, si          ; X del viewport
    
dv_loop_x:
    cmp si, VIEWPORT_W
    jae dv_siguiente_y
    
    ; Calcular posición en mapa
    mov ax, camara_y
    add ax, di
    cmp ax, mapa_alto
    jae dv_siguiente_x
    
    mov bx, mapa_ancho
    mul bx
    mov bx, camara_x
    add bx, si
    cmp bx, mapa_ancho
    jae dv_siguiente_x
    add ax, bx
    
    ; Obtener tile
    push si
    push di
    mov si, OFFSET mapa_datos
    add si, ax
    mov al, [si]
    pop di
    pop si
    
    ; Obtener color según tile
    mov ah, 2           ; Default: verde (grass)
    cmp al, TILE_GRASS
    je dv_dibujar
    mov ah, 6           ; Marrón (wall)
    cmp al, TILE_WALL
    je dv_dibujar
    mov ah, 7           ; Gris (path)
    cmp al, TILE_PATH
    je dv_dibujar
    mov ah, 1           ; Azul (water)
    cmp al, TILE_WATER
    je dv_dibujar
    mov ah, 10          ; Verde claro (tree)
    
dv_dibujar:
    ; Dibujar tile 16x16
    push si
    push di
    
    ; CX = X en píxeles, DX = Y en píxeles
    mov ax, si
    shl ax, 4           ; * 16
    mov cx, ax
    
    mov ax, di
    shl ax, 4           ; * 16
    mov dx, ax
    
    mov al, ah          ; Color en AL
    call dibujar_tile
    
    pop di
    pop si
    
dv_siguiente_x:
    inc si
    jmp dv_loop_x
    
dv_siguiente_y:
    inc di
    jmp dv_loop_y
    
dv_fin:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_viewport ENDP

 Map Mask
    mov cl, 1           ; Máscara de plano
    
dtr_planos:
    out dx, ax
    test ah, cl
    jz dtr_skip_plano
    
    mov byte ptr es:[di], 0FFh
    inc di
    mov byte ptr es:[di], 0FFh
    dec di
    
dtr_skip_plano:
    shl cl, 1
    cmp cl, 10h
    jb dtr_planos
    
    pop dx
    pop cx
    pop ax
    
    inc si
    jmp dtr_y_loop
    
dtr_fin:
    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_tile_rapido ENDP

; ========================================
; DIBUJAR JUGADOR
; ========================================
dibujar_jugador PROC
    push ax
    push bx
    push cx
    push dx
    
    ; Verificar si está en viewport
    mov ax, jugador_x
    sub ax, camara_x
    js dj_fin
    cmp ax, VIEWPORT_W
    jae dj_fin
    
    mov bx, jugador_y
    sub bx, camara_y
    js dj_fin
    cmp bx, VIEWPORT_H
    jae dj_fin
    
    ; Convertir a píxeles y centrar (8x8 dentro de tile 16x16)
    shl ax, 4           ; * 16
    add ax, 4           ; Centrar
    mov cx, ax
    
    mov ax, bx
    shl ax, 4
    add ax, 4
    mov dx, ax
    
    ; Dibujar cuadrado 8x8 amarillo
    mov al, 14          ; Color amarillo
    call dibujar_jugador_sprite
    
dj_fin:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_jugador ENDP

; ========================================
; DIBUJAR JUGADOR SPRITE (8x8)
; AL = color, CX = x, DX = y
; ========================================
dibujar_jugador_sprite PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov bl, al          ; Guardar color
    mov si, dx          ; Y inicial
    add dx, 8           ; Y final
    
djs_y_loop:
    cmp si, SCREEN_H
    jae djs_fin
    
    push cx
    mov di, cx          ; X inicial
    add cx, 8           ; X final
    
djs_x_loop:
    cmp di, SCREEN_W
    jae djs_next_y
    
    ; Dibujar píxel
    push bx
    push cx
    push dx
    
    mov ah, 0Ch
    mov al, bl
    mov bh, pagina_dibujo
    mov cx, di
    mov dx, si
    int 10h
    
    pop dx
    pop cx
    pop bx
    
    inc di
    cmp di, cx
    jb djs_x_loop
    
djs_next_y:
    pop cx
    inc si
    cmp si, dx
    jb djs_y_loop
    
djs_fin:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_jugador_sprite ENDP

END inicio