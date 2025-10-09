; =====================================================
; JUEGO EGA - VERSIÓN FUNCIONAL Y RÁPIDA
; Escribe DIRECTO a memoria de video
; =====================================================

.MODEL SMALL
.STACK 2048

TILE_SIZE EQU 16
VIEWPORT_W EQU 10
VIEWPORT_H EQU 8

VIDEO_SEG EQU 0A000h
SC_INDEX EQU 3C4h
GC_INDEX EQU 3CEh

.DATA
archivo_mapa db 'MAPA.TXT',0
archivo_grass db 'GRASS.TXT',0
archivo_wall db 'WALL.TXT',0
archivo_path db 'PATH.TXT',0
archivo_water db 'WATER.TXT',0
archivo_tree db 'TREE.TXT',0
archivo_player db 'PLAYER.TXT',0

mapa_datos db 2500 dup(0)
sprite_grass db 256 dup(0)
sprite_wall db 256 dup(0)
sprite_path db 256 dup(0)
sprite_water db 256 dup(0)
sprite_tree db 256 dup(0)
sprite_player db 64 dup(0)
buffer_temp db 300 dup(0)

jugador_x dw 25
jugador_y dw 25
camara_x dw 0
camara_y dw 0

msg_titulo db 'JUEGO EGA - Modo Rapido',13,10,'$'
msg_cargando db 'Cargando...',13,10,'$'
msg_ok db 'OK',13,10,'$'
msg_error db 'ERROR',13,10,'$'
msg_controles db 'WASD/Flechas=Mover ESC=Salir',13,10,'Presiona tecla...$'

.CODE
inicio:
    mov ax, @data
    mov ds, ax
    
    mov dx, OFFSET msg_titulo
    mov ah, 9
    int 21h
    
    mov dx, OFFSET msg_cargando
    mov ah, 9
    int 21h
    
    call cargar_mapa
    jc error
    call cargar_sprites
    jc error
    
    mov dx, OFFSET msg_controles
    mov ah, 9
    int 21h
    mov ah, 0
    int 16h
    
    mov ax, 10h
    int 10h
    
    call config_ega
    call actualizar_camara
    call renderizar

bucle:
    mov ah, 1
    int 16h
    jz bucle
    
    mov ah, 0
    int 16h
    
    cmp al, 27
    je fin
    
    call mover
    call actualizar_camara
    call renderizar
    jmp bucle

error:
    mov dx, OFFSET msg_error
    mov ah, 9
    int 21h
    mov ah, 0
    int 16h

fin:
    mov ax, 3
    int 10h
    mov ax, 4C00h
    int 21h

; =====================================================
; CONFIGURAR EGA
; =====================================================
config_ega PROC
    push ax
    push dx
    
    mov dx, SC_INDEX
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    
    mov dx, GC_INDEX
    mov al, 5
    out dx, al
    inc dx
    mov al, 0
    out dx, al
    
    pop dx
    pop ax
    ret
config_ega ENDP

; =====================================================
; RENDERIZAR (RÁPIDO)
; =====================================================
renderizar PROC
    push ax
    push es
    
    mov ax, VIDEO_SEG
    mov es, ax
    
    call dibujar_mapa_rapido
    call dibujar_jugador_rapido
    
    pop es
    pop ax
    ret
renderizar ENDP

; =====================================================
; DIBUJAR MAPA RÁPIDO
; =====================================================
dibujar_mapa_rapido PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    xor bp, bp
    
dmr_fila:
    cmp bp, VIEWPORT_H
    jb  dmr_fila_cont
    jmp dmr_fin

dmr_fila_cont:
    
    xor si, si
    
dmr_col:
    cmp si, VIEWPORT_W
    jb  dmr_col_cont
    jmp dmr_nf

dmr_col_cont:
    
    mov ax, camara_y
    add ax, bp
    cmp ax, 50
    jb  dmr_y_ok
    jmp dmr_nc

dmr_y_ok:
    
    mov bx, camara_x
    add bx, si
    cmp bx, 50
    jb  dmr_x_ok
    jmp dmr_nc

dmr_x_ok:
    
    push dx
    mov dx, 50
    mul dx
    add ax, bx
    pop dx
    
    cmp ax, 2500
    jb  dmr_idx_ok
    jmp dmr_nc

dmr_idx_ok:
    
    push si
    push di
    push bx
    mov bx, OFFSET mapa_datos
    add bx, ax
    mov al, [bx]
    pop bx
    pop di
    pop si
    
    push si
    push bp
    
    cmp al, 0
    jne dmr_t1
    mov di, OFFSET sprite_grass
    jmp dmr_draw
dmr_t1:
    cmp al, 1
    jne dmr_t2
    mov di, OFFSET sprite_wall
    jmp dmr_draw
dmr_t2:
    cmp al, 2
    jne dmr_t3
    mov di, OFFSET sprite_path
    jmp dmr_draw
dmr_t3:
    cmp al, 3
    jne dmr_t4
    mov di, OFFSET sprite_water
    jmp dmr_draw
dmr_t4:
    cmp al, 4
    jne dmr_t5
    mov di, OFFSET sprite_tree
    jmp dmr_draw
dmr_t5:
    mov di, OFFSET sprite_grass
    
dmr_draw:
    pop bp
    pop si
    
    mov ax, si
    shl ax, 4
    add ax, 240
    mov cx, ax
    
    mov ax, bp
    shl ax, 4
    add ax, 111
    mov dx, ax
    
    call draw_tile_fast
    
dmr_nc:
    inc si
    jmp dmr_col
    
dmr_nf:
    inc bp
    jmp dmr_fila
    
dmr_fin:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_mapa_rapido ENDP

; =====================================================
; DIBUJAR TILE RÁPIDO (16x16)
; CX=X, DX=Y, DI=sprite
; =====================================================
draw_tile_fast PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push bp
    
    mov si, di
    mov bp, 16
    
dtf_row:
    mov ax, dx
    mov bx, 80
    mul bx
    mov bx, cx
    shr bx, 3
    add ax, bx
    mov di, ax
    
    mov bx, cx
    and bx, 7
    mov cl, bl
    
    push bp
    mov bp, 16
    
dtf_col:
    lodsb
    cmp al, 0
    je dtf_skip
    
    push bx
    push cx
    push dx
    
    ; Configurar planos según color
    mov ah, al
    mov dx, SC_INDEX
    mov al, 2
    out dx, al
    inc dx
    
    mov al, 1
    test ah, 1
    jz dtf_p0
    out dx, al
dtf_p0:
    mov al, 2
    test ah, 2
    jz dtf_p1
    out dx, al
dtf_p1:
    mov al, 4
    test ah, 4
    jz dtf_p2
    out dx, al
dtf_p2:
    mov al, 8
    test ah, 8
    jz dtf_p3
    out dx, al
dtf_p3:
    
    ; Escribir píxel
    mov al, 80h
    shr al, cl
    or es:[di], al
    
    pop dx
    pop cx
    pop bx
    
dtf_skip:
    inc cl
    and cl, 7
    jnz dtf_same_byte
    inc di
dtf_same_byte:
    
    dec bp
    jnz dtf_col
    
    pop bp
    inc dx
    dec bp
    jnz dtf_row
    
    pop bp
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_tile_fast ENDP

; =====================================================
; DIBUJAR JUGADOR RÁPIDO
; =====================================================
dibujar_jugador_rapido PROC
    push ax
    push bx
    push cx
    push dx
    
    mov ax, jugador_x
    sub ax, camara_x
    js djr_fin
    cmp ax, VIEWPORT_W
    jae djr_fin
    
    mov bx, jugador_y
    sub bx, camara_y
    js djr_fin
    cmp bx, VIEWPORT_H
    jae djr_fin
    
    shl ax, 4
    add ax, 244
    mov cx, ax
    
    shl bx, 4
    add bx, 115
    mov dx, bx
    
    ; Dibujar cuadrado 8x8 color 14 (amarillo)
    mov bp, 8
djr_y:
    mov ax, dx
    mov bx, 80
    mul bx
    mov bx, cx
    shr bx, 3
    add ax, bx
    mov di, ax
    
    push bp
    mov bp, 8
djr_x:
    ; Color 14 = planos 1,2,3 activos
    mov al, 0Eh
    push dx
    mov dx, SC_INDEX
    mov ah, 2
    out dx, al
    inc dx
    mov al, 0Eh
    out dx, al
    pop dx
    
    push cx
    mov bx, cx
    and bx, 7
    mov al, 80h
    mov cl, bl
    shr al, cl
    pop cx
    or es:[di], al
    
    inc cx
    and cl, 7
    jnz djr_sb
    inc di
djr_sb:
    dec bp
    jnz djr_x
    
    pop bp
    sub cx, 8
    inc dx
    dec bp
    jnz djr_y
    
djr_fin:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_jugador_rapido ENDP

; =====================================================
; MOVER
; =====================================================
mover PROC
    push ax
    
    cmp ah, 48h
    je m_arr
    cmp al, 'w'
    je m_arr
    cmp al, 'W'
    je m_arr
    
    cmp ah, 50h
    je m_aba
    cmp al, 's'
    je m_aba
    cmp al, 'S'
    je m_aba
    
    cmp ah, 4Bh
    je m_izq
    cmp al, 'a'
    je m_izq
    cmp al, 'A'
    je m_izq
    
    cmp ah, 4Dh
    je m_der
    cmp al, 'd'
    je m_der
    cmp al, 'D'
    je m_der
    
    jmp m_fin

m_arr:
    cmp jugador_y, 1
    jbe m_fin
    dec jugador_y
    call verificar_col
    jnc m_fin
    inc jugador_y
    jmp m_fin

m_aba:
    cmp jugador_y, 48
    jae m_fin
    inc jugador_y
    call verificar_col
    jnc m_fin
    dec jugador_y
    jmp m_fin

m_izq:
    cmp jugador_x, 1
    jbe m_fin
    dec jugador_x
    call verificar_col
    jnc m_fin
    inc jugador_x
    jmp m_fin

m_der:
    cmp jugador_x, 48
    jae m_fin
    inc jugador_x
    call verificar_col
    jnc m_fin
    dec jugador_x

m_fin:
    pop ax
    ret
mover ENDP

; =====================================================
; VERIFICAR COLISIÓN
; =====================================================
verificar_col PROC
    push ax
    push bx
    push si
    
    mov ax, jugador_y
    mov bx, 50
    mul bx
    add ax, jugador_x
    
    cmp ax, 2500
    jae vc_col
    
    mov si, OFFSET mapa_datos
    add si, ax
    mov al, [si]
    
    cmp al, 0
    je vc_ok
    cmp al, 2
    je vc_ok
    
vc_col:
    stc
    jmp vc_fin
    
vc_ok:
    clc
    
vc_fin:
    pop si
    pop bx
    pop ax
    ret
verificar_col ENDP

; =====================================================
; ACTUALIZAR CÁMARA
; =====================================================
actualizar_camara PROC
    push ax
    push bx
    
    mov ax, jugador_x
    sub ax, 5
    jge ac_x1
    xor ax, ax
ac_x1:
    mov bx, 40
    cmp ax, bx
    jle ac_x2
    mov ax, bx
ac_x2:
    mov camara_x, ax
    
    mov ax, jugador_y
    sub ax, 4
    jge ac_y1
    xor ax, ax
ac_y1:
    mov bx, 42
    cmp ax, bx
    jle ac_y2
    mov ax, bx
ac_y2:
    mov camara_y, ax
    
    pop bx
    pop ax
    ret
actualizar_camara ENDP

; =====================================================
; CARGAR MAPA
; =====================================================
cargar_mapa PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    mov ax, 3D00h
    mov dx, OFFSET archivo_mapa
    int 21h
    jc cm_err
    
    mov bx, ax
    mov ah, 3Fh
    mov cx, 20
    mov dx, OFFSET buffer_temp
    int 21h
    
    mov di, OFFSET mapa_datos
    xor bp, bp
    
cm_read:
    mov ah, 3Fh
    mov cx, 200
    mov dx, OFFSET buffer_temp
    int 21h
    
    cmp ax, 0
    je cm_close
    
    mov cx, ax
    xor si, si

cm_proc:
    cmp si, cx
    jae cm_read

    mov al, [buffer_temp + si]
    inc si
    
    cmp al, ' '
    je cm_proc
    cmp al, 13
    je cm_proc
    cmp al, 10
    je cm_proc
    cmp al, 9
    je cm_proc
    cmp al, '0'
    jb cm_proc
    cmp al, '9'
    ja cm_proc
    
    sub al, '0'
    mov [di], al
    inc di
    inc bp

    cmp bp, 2500
    jb cm_proc
    
cm_close:
    mov ah, 3Eh
    int 21h
    clc
    jmp cm_fin
    
cm_err:
    stc
    
cm_fin:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
cargar_mapa ENDP

; =====================================================
; CARGAR SPRITES
; =====================================================
cargar_sprites PROC
    push dx
    push di
    
    mov dx, OFFSET archivo_grass
    mov di, OFFSET sprite_grass
    call load_spr16
    jc cs_err
    
    mov dx, OFFSET archivo_wall
    mov di, OFFSET sprite_wall
    call load_spr16
    jc cs_err
    
    mov dx, OFFSET archivo_path
    mov di, OFFSET sprite_path
    call load_spr16
    jc cs_err
    
    mov dx, OFFSET archivo_water
    mov di, OFFSET sprite_water
    call load_spr16
    jc cs_err
    
    mov dx, OFFSET archivo_tree
    mov di, OFFSET sprite_tree
    call load_spr16
    jc cs_err
    
    mov dx, OFFSET archivo_player
    mov di, OFFSET sprite_player
    call load_spr8
    jc cs_err
    
    clc
    jmp cs_fin

cs_err:
    stc

cs_fin:
    pop di
    pop dx
    ret
cargar_sprites ENDP

load_spr16 PROC
    push ax
    push bx
    push cx
    push si
    push bp
    
    mov ax, 3D00h
    int 21h
    jc ls16_err
    
    mov bx, ax
    mov ah, 3Fh
    mov cx, 20
    push dx
    mov dx, OFFSET buffer_temp
    int 21h
    pop dx
    
    xor bp, bp
    
ls16_read:
    mov ah, 3Fh
    mov cx, 200
    push dx
    mov dx, OFFSET buffer_temp
    int 21h
    pop dx
    
    cmp ax, 0
    je ls16_close
    
    mov cx, ax
    xor si, si

ls16_proc:
    cmp si, cx
    jae ls16_read

    mov al, [buffer_temp + si]
    inc si
    
    cmp al, ' '
    je ls16_proc
    cmp al, 13
    je ls16_proc
    cmp al, 10
    je ls16_proc
    cmp al, 9
    je ls16_proc
    cmp al, '0'
    jb ls16_proc
    cmp al, '9'
    ja ls16_proc
    
    sub al, '0'
    mov [di], al
    inc di
    inc bp

    cmp bp, 256
    jb ls16_proc
    
ls16_close:
    mov ah, 3Eh
    int 21h
    clc
    jmp ls16_fin
    
ls16_err:
    stc
    
ls16_fin:
    pop bp
    pop si
    pop cx
    pop bx
    pop ax
    ret
load_spr16 ENDP

load_spr8 PROC
    push ax
    push bx
    push cx
    push si
    push bp
    
    mov ax, 3D00h
    int 21h
    jc ls8_err
    
    mov bx, ax
    mov ah, 3Fh
    mov cx, 20
    push dx
    mov dx, OFFSET buffer_temp
    int 21h
    pop dx
    
    xor bp, bp
    
ls8_read:
    mov ah, 3Fh
    mov cx, 100
    push dx
    mov dx, OFFSET buffer_temp
    int 21h
    pop dx
    
    cmp ax, 0
    je ls8_close
    
    mov cx, ax
    xor si, si

ls8_proc:
    cmp si, cx
    jae ls8_read

    mov al, [buffer_temp + si]
    inc si
    
    cmp al, ' '
    je ls8_proc
    cmp al, 13
    je ls8_proc
    cmp al, 10
    je ls8_proc
    cmp al, 9
    je ls8_proc
    cmp al, '0'
    jb ls8_proc
    cmp al, '9'
    ja ls8_proc
    
    sub al, '0'
    mov [di], al
    inc di
    inc bp

    cmp bp, 64
    jb ls8_proc
    
ls8_close:
    mov ah, 3Eh
    int 21h
    clc
    jmp ls8_fin
    
ls8_err:
    stc
    
ls8_fin:
    pop bp
    pop si
    pop cx
    pop bx
    pop ax
    ret
load_spr8 ENDP

END inicio