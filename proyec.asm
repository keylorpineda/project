; JUEGO DE EXPLORACIÓN - VERSION DEBUG Y CORREGIDA
; Universidad Nacional - Proyecto II Ciclo 2025

.MODEL SMALL
.STACK 4096

; === CONSTANTES CORREGIDAS ===
TILE_GRASS  EQU 0
TILE_WALL   EQU 1
TILE_PATH   EQU 2
TILE_WATER  EQU 3
TILE_TREE   EQU 4

TILE_SIZE   EQU 16
SCREEN_W    EQU 640
SCREEN_H    EQU 350
VIEWPORT_W  EQU 20      ; *** CORREGIDO: era 40, ahora 20 ***
VIEWPORT_H  EQU 12      ; *** CORREGIDO: era 21, ahora 12 ***

.DATA
; === ARCHIVOS ===
archivo_mapa    db 'MAPA.TXT',0

; === MAPA ===
mapa_ancho  dw 20
mapa_alto   dw 12
mapa_datos  db 2000 dup(0)

; === SPRITES (16x16 píxeles) ===
sprite_grass   db 256 dup(2)
sprite_wall    db 256 dup(6)
sprite_path    db 256 dup(7)
sprite_water   db 256 dup(1)
sprite_tree    db 256 dup(10)
sprite_player  db 64 dup(14)

; === JUGADOR ===
jugador_x   dw 1
jugador_y   dw 1
jugador_x_ant dw 1
jugador_y_ant dw 1

; === CÁMARA ===
camara_x    dw 0
camara_y    dw 0

; === BUFFER ARCHIVO ===
buffer_archivo db 2048 dup(0)
handle_arch dw 0
bytes_leidos dw 0

; === PÁGINAS ===
pagina_activa db 0
pagina_trabajo db 1

; === MENSAJES DEBUG ===
msg_inicio  db 'JUEGO DE EXPLORACION - DEBUG VERSION',13,10
           db '=====================================',13,10,'$'
msg_cargando db 'Intentando cargar MAPA.TXT...',13,10,'$'
msg_archivo_ok db '[OK] Archivo abierto',13,10,'$'
msg_no_existe db '[AVISO] Archivo no encontrado',13,10,'$'
msg_usando_default db '[INFO] Usando mapa por defecto (20x12)',13,10,'$'
msg_bytes db 'Bytes leidos: $'
msg_dimensiones db 'Dimensiones: $'
msg_x db ' x $'
msg_tiles db ' tiles',13,10,'$'
msg_viewport db 'Viewport configurado: $'
msg_listo  db 13,10,'[LISTO] Sistema inicializado',13,10
           db 'Controles: Flechas/WASD para mover, ESC para salir',13,10
           db 'Presiona cualquier tecla...$'

.CODE
inicio:
    mov ax, @data
    mov ds, ax
    mov es, ax

    mov dx, OFFSET msg_inicio
    mov ah, 9
    int 21h

    call cargar_recursos
    
    ; Mostrar config del viewport
    mov dx, OFFSET msg_viewport
    mov ah, 9
    int 21h
    mov ax, VIEWPORT_W
    call imprimir_numero
    mov dx, OFFSET msg_x
    mov ah, 9
    int 21h
    mov ax, VIEWPORT_H
    call imprimir_numero
    mov dl, 13
    mov ah, 2
    int 21h
    mov dl, 10
    mov ah, 2
    int 21h
    
    mov dx, OFFSET msg_listo
    mov ah, 9
    int 21h

    mov ah, 0
    int 16h

    mov ax, 10h
    int 10h
    
    mov pagina_activa, 0
    mov pagina_trabajo, 1

    call actualizar_camara
    call renderizar_completo

bucle_principal:
    mov ah, 1
    int 16h
    jz bucle_principal

    mov ah, 0
    int 16h

    cmp al, 27
    je fin_programa

    call procesar_movimiento
    call renderizar_completo
    
    jmp bucle_principal

fin_programa:
    mov ax, 3
    int 10h
    mov ax, 4C00h
    int 21h

; === IMPRIMIR NÚMERO (DEBUG) ===
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

; === CARGAR RECURSOS ===
cargar_recursos PROC
    push ax
    push dx
    
    mov dx, OFFSET msg_cargando
    mov ah, 9
    int 21h
    
    call cargar_mapa_archivo
    call inicializar_sprites_default
    
    pop dx
    pop ax
    ret
cargar_recursos ENDP

; === CARGAR MAPA DESDE ARCHIVO ===
cargar_mapa_archivo PROC
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
    jc usar_mapa_default
    
    ; DEBUG: Archivo abierto
    push ax
    mov dx, OFFSET msg_archivo_ok
    mov ah, 9
    int 21h
    pop ax
    
    mov handle_arch, ax
    
    ; Leer archivo
    mov bx, ax
    mov cx, 2000
    mov dx, OFFSET buffer_archivo
    mov ah, 3Fh
    int 21h
    jc cerrar_y_default
    
    ; DEBUG: Mostrar bytes leídos
    mov bytes_leidos, ax
    push ax
    mov dx, OFFSET msg_bytes
    mov ah, 9
    int 21h
    pop ax
    call imprimir_numero
    mov dl, 13
    mov ah, 2
    int 21h
    mov dl, 10
    mov ah, 2
    int 21h
    
    ; Parsear dimensiones
    mov si, OFFSET buffer_archivo
    call parsear_numero
    mov mapa_ancho, ax
    push ax
    call parsear_numero
    mov mapa_alto, ax
    
    ; DEBUG: Mostrar dimensiones
    mov dx, OFFSET msg_dimensiones
    mov ah, 9
    int 21h
    pop ax
    push ax
    call imprimir_numero
    mov dx, OFFSET msg_x
    mov ah, 9
    int 21h
    mov ax, mapa_alto
    call imprimir_numero
    mov dx, OFFSET msg_tiles
    mov ah, 9
    int 21h
    pop ax
    
    ; Leer tiles
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
    
    jmp fin_carga_mapa

cerrar_y_default:
    mov bx, handle_arch
    mov ah, 3Eh
    int 21h
    
usar_mapa_default:
    mov dx, OFFSET msg_no_existe
    mov ah, 9
    int 21h
    mov dx, OFFSET msg_usando_default
    mov ah, 9
    int 21h
    call cargar_mapa_default
    
fin_carga_mapa:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
cargar_mapa_archivo ENDP

; === PARSEAR NÚMERO ===
parsear_numero PROC
    push bx
    push cx
    push dx
    
    xor ax, ax
    xor bx, bx
    
pn_espacio:
    mov bl, [si]
    inc si
    cmp bl, ' '
    je pn_espacio
    cmp bl, 13
    je pn_espacio
    cmp bl, 10
    je pn_espacio
    cmp bl, 9
    je pn_espacio
    
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

; === MAPA POR DEFECTO ===
cargar_mapa_default PROC
    push ax
    push cx
    push si
    push di
    
    mov mapa_ancho, 20
    mov mapa_alto, 12
    
    mov si, OFFSET datos_mapa_default
    mov di, OFFSET mapa_datos
    mov cx, 240
    rep movsb
    
    pop di
    pop si
    pop cx
    pop ax
    ret
    
datos_mapa_default:
    db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
    db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
    db 1,0,2,2,2,2,2,2,0,0,0,0,2,2,2,2,2,2,0,1
    db 1,0,2,0,0,0,0,2,0,4,4,0,2,0,0,0,0,2,0,1
    db 1,0,2,0,3,3,0,2,0,4,4,0,2,0,3,3,0,2,0,1
    db 1,0,2,0,3,3,0,2,0,0,0,0,2,0,3,3,0,2,0,1
    db 1,0,2,0,0,0,0,2,0,0,0,0,2,0,0,0,0,2,0,1
    db 1,0,2,2,2,2,2,2,0,0,0,0,2,2,2,2,2,2,0,1
    db 1,0,0,0,0,0,0,0,0,4,4,0,0,0,0,0,0,0,0,1
    db 1,0,4,4,0,0,0,0,0,4,4,0,0,0,0,0,0,4,4,1
    db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
    db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
cargar_mapa_default ENDP

; === SPRITES ===
inicializar_sprites_default PROC
    push ax
    push cx
    push di
    
    mov di, OFFSET sprite_grass
    mov al, 2
    mov cx, 256
    rep stosb
    
    mov di, OFFSET sprite_wall
    mov al, 6
    mov cx, 256
    rep stosb
    
    mov di, OFFSET sprite_path
    mov al, 7
    mov cx, 256
    rep stosb
    
    mov di, OFFSET sprite_water
    mov cx, 256
isw_loop:
    mov al, 1
    test cx, 8
    jz isw_dark
    mov al, 9
isw_dark:
    stosb
    loop isw_loop
    
    mov di, OFFSET sprite_tree
    mov al, 10
    mov cx, 256
    rep stosb
    
    mov di, OFFSET sprite_player
    mov al, 14
    mov cx, 64
    rep stosb
    
    pop di
    pop cx
    pop ax
    ret
inicializar_sprites_default ENDP

; === MOVIMIENTO ===
procesar_movimiento PROC
    push ax
    push bx
    
    mov ax, jugador_x
    mov jugador_x_ant, ax
    mov ax, jugador_y
    mov jugador_y_ant, ax
    
    cmp ah, 48h
    je pm_arriba
    cmp al, 'w'
    je pm_arriba
    cmp al, 'W'
    je pm_arriba
    
    cmp ah, 50h
    je pm_abajo
    cmp al, 's'
    je pm_abajo
    cmp al, 'S'
    je pm_abajo
    
    cmp ah, 4Bh
    je pm_izquierda
    cmp al, 'a'
    je pm_izquierda
    cmp al, 'A'
    je pm_izquierda
    
    cmp ah, 4Dh
    je pm_derecha
    cmp al, 'd'
    je pm_derecha
    cmp al, 'D'
    je pm_derecha
    
    jmp pm_fin
    
pm_arriba:
    cmp jugador_y, 0
    je pm_fin
    dec jugador_y
    jmp pm_verificar
    
pm_abajo:
    mov ax, jugador_y
    inc ax
    cmp ax, mapa_alto
    jae pm_fin
    mov jugador_y, ax
    jmp pm_verificar
    
pm_izquierda:
    cmp jugador_x, 0
    je pm_fin
    dec jugador_x
    jmp pm_verificar
    
pm_derecha:
    mov ax, jugador_x
    inc ax
    cmp ax, mapa_ancho
    jae pm_fin
    mov jugador_x, ax
    jmp pm_verificar
    
pm_verificar:
    call verificar_colision
    jc pm_restaurar
    call actualizar_camara
    jmp pm_fin
    
pm_restaurar:
    mov ax, jugador_x_ant
    mov jugador_x, ax
    mov ax, jugador_y_ant
    mov jugador_y, ax
    
pm_fin:
    pop bx
    pop ax
    ret
procesar_movimiento ENDP

; === COLISIÓN ===
verificar_colision PROC
    push ax
    push bx
    push si
    
    mov ax, jugador_y
    mov bx, mapa_ancho
    mul bx
    add ax, jugador_x
    
    mov si, OFFSET mapa_datos
    add si, ax
    mov al, [si]
    
    cmp al, TILE_GRASS
    je vc_ok
    cmp al, TILE_PATH
    je vc_ok
    
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

; === CÁMARA ===
actualizar_camara PROC
    push ax
    push bx
    
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

; === RENDERIZADO ===
renderizar_completo PROC
    push ax
    push bx
    
    mov al, pagina_trabajo
    mov ah, 05h
    int 10h
    
    call limpiar_pantalla
    call dibujar_viewport
    call dibujar_jugador
    
    mov dx, 03DAh
rc_wait1:
    in al, dx
    test al, 8
    jnz rc_wait1
rc_wait2:
    in al, dx
    test al, 8
    jz rc_wait2
    
    mov al, pagina_trabajo
    mov ah, pagina_activa
    mov pagina_activa, al
    mov pagina_trabajo, ah
    
    mov al, pagina_activa
    mov ah, 05h
    int 10h
    
    pop bx
    pop ax
    ret
renderizar_completo ENDP

limpiar_pantalla PROC
    push ax
    push bx
    push cx
    push dx
    
    mov ax, 0600h
    mov bh, 0
    mov cx, 0
    mov dx, 184Fh
    int 10h
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
limpiar_pantalla ENDP

; === DIBUJAR VIEWPORT ===
dibujar_viewport PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    xor di, di
dv_loop_y:
    cmp di, VIEWPORT_H
    jae dv_fin
    
    xor si, si
dv_loop_x:
    cmp si, VIEWPORT_W
    jae dv_next_y
    
    mov ax, camara_y
    add ax, di
    cmp ax, mapa_alto
    jae dv_next_x
    
    mov bx, mapa_ancho
    mul bx
    mov bx, camara_x
    add bx, si
    cmp bx, mapa_ancho
    jae dv_next_x
    add ax, bx
    
    push si
    push di
    mov si, OFFSET mapa_datos
    add si, ax
    mov al, [si]
    
    mov bx, OFFSET sprite_grass
    cmp al, TILE_WALL
    jne dv_check2
    mov bx, OFFSET sprite_wall
    jmp dv_draw
dv_check2:
    cmp al, TILE_PATH
    jne dv_check3
    mov bx, OFFSET sprite_path
    jmp dv_draw
dv_check3:
    cmp al, TILE_WATER
    jne dv_check4
    mov bx, OFFSET sprite_water
    jmp dv_draw
dv_check4:
    cmp al, TILE_TREE
    jne dv_draw
    mov bx, OFFSET sprite_tree
    
dv_draw:
    pop di
    pop si
    
    push si
    push di
    mov ax, si
    mov cx, TILE_SIZE
    mul cx
    mov cx, ax
    
    mov ax, di
    mov dx, TILE_SIZE
    mul dx
    mov dx, ax
    
    call dibujar_sprite
    
    pop di
    pop si
    
dv_next_x:
    inc si
    jmp dv_loop_x
    
dv_next_y:
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

; === DIBUJAR SPRITE ===
dibujar_sprite PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov si, bx
    mov di, dx
    
    mov ax, di
    add ax, TILE_SIZE
    push ax
    
    mov ax, cx
    add ax, TILE_SIZE
    push ax
    
ds_loop_y:
    pop ax
    push ax
    mov bx, ax
    
    pop ax
    push ax
    sub ax, TILE_SIZE
    mov cx, ax
    
ds_loop_x:
    cmp cx, bx
    jae ds_next_y
    cmp cx, SCREEN_W
    jae ds_skip_pixel
    cmp di, SCREEN_H
    jae ds_skip_pixel
    
    mov al, [si]
    
    push bx
    mov ah, 0Ch
    mov bh, pagina_trabajo
    mov dx, di
    int 10h
    pop bx
    
ds_skip_pixel:
    inc si
    inc cx
    jmp ds_loop_x
    
ds_next_y:
    inc di
    pop ax
    pop bx
    push bx
    push ax
    cmp di, bx
    jb ds_loop_y
    
    pop ax
    pop ax
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_sprite ENDP

; === DIBUJAR JUGADOR ===
dibujar_jugador PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
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
    
    mov cx, TILE_SIZE
    mul cx
    add ax, 4
    mov cx, ax
    
    mov ax, bx
    mov dx, TILE_SIZE
    mul dx
    add ax, 4
    mov dx, ax
    
    mov si, OFFSET sprite_player
    mov di, 8
    
dj_loop_y:
    push cx
    push di
    mov di, 8
    
dj_loop_x:
    cmp cx, SCREEN_W
    jae dj_skip
    cmp dx, SCREEN_H
    jae dj_skip
    
    mov al, [si]
    
    push di
    mov ah, 0Ch
    mov bh, pagina_trabajo
    int 10h
    pop di
    
dj_skip:
    inc si
    inc cx
    dec di
    jnz dj_loop_x
    
    pop di
    pop cx
    inc dx
    dec di
    jnz dj_loop_y
    
dj_fin:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_jugador ENDP

END inicio