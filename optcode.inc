; ============================================
; OPTCODE.INC - SISTEMA PLANAR **CORREGIDO**
; Universidad Nacional - Proyecto II Ciclo 2025
; ============================================

inicializar_lookup_tables PROC
    call calcular_video_offsets
    call calcular_mul100_table
    call inicializar_walkable
    ret
inicializar_lookup_tables ENDP

calcular_video_offsets PROC
    push ax
    push cx
    push si
    
    xor ax, ax
    xor si, si
    mov cx, 350
    
cvo_loop:
    mov [video_offsets + si], ax
    add ax, 80
    add si, 2
    loop cvo_loop
    
    pop si
    pop cx
    pop ax
    ret
calcular_video_offsets ENDP

calcular_mul100_table PROC
    push ax
    push cx
    push si
    
    xor ax, ax
    xor si, si
    mov cx, 100
    
cm100_loop:
    mov [mul100_table + si], ax
    add ax, 100
    add si, 2
    loop cm100_loop
    
    pop si
    pop cx
    pop ax
    ret
calcular_mul100_table ENDP

inicializar_walkable PROC
    push ax
    
    mov byte ptr [tile_walkable + 4], 0
    mov byte ptr [tile_walkable + 5], 0
    mov byte ptr [tile_walkable + 7], 0
    mov byte ptr [tile_walkable + 10], 0
    mov byte ptr [tile_walkable + 14], 0
    
    pop ax
    ret
inicializar_walkable ENDP

marcar_tile_sucio PROC
    ret
marcar_tile_sucio ENDP

marcar_area_jugador_sucia PROC
    ret
marcar_area_jugador_sucia ENDP

incrementar_frame_counter PROC
    inc frame_counter
    ret
incrementar_frame_counter ENDP

verificar_tile_transitable_opt PROC
    push ax
    push bx
    push dx
    
    cmp cx, 100
    jae vtt_no_transitable
    cmp dx, 100
    jae vtt_no_transitable
    
    mov bx, dx
    shl bx, 1
    mov ax, [mul100_table + bx]
    add ax, cx
    mov bx, ax
    
    mov al, [mapa_datos + bx]
    
    mov bl, al
    xor bh, bh
    test byte ptr [tile_walkable + bx], 1
    jnz vtt_transitable

vtt_no_transitable:
    pop dx
    pop bx
    pop ax
    clc
    ret

vtt_transitable:
    pop dx
    pop bx
    pop ax
    stc
    ret
verificar_tile_transitable_opt ENDP

; ============================================
; CONVERSIÓN PLANAR CORREGIDA - 16x16
; ============================================
convertir_sprite_a_planar_opt PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    mov cx, 16
    
cspo_fila:
    push cx
    
    ; ===== BYTE IZQUIERDO (píxeles 0-7) =====
    xor bx, bx
    xor dx, dx
    mov cx, 8
    
cspo_byte_izq:
    lodsb
    
    shl dl, 1
    test al, 01h
    jz cspo_i0
    or dl, 1
cspo_i0:
    shl dh, 1
    test al, 02h
    jz cspo_i1
    or dh, 1
cspo_i1:
    shl bl, 1
    test al, 04h
    jz cspo_i2
    or bl, 1
cspo_i2:
    shl bh, 1
    test al, 08h
    jz cspo_i3
    or bh, 1
cspo_i3:
    loop cspo_byte_izq
    
    mov [di], dl
    mov [di+32], dh
    mov [di+64], bl
    mov [di+96], bh
    
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    not al
    mov [bp], al
    
    ; ===== BYTE DERECHO (píxeles 8-15) =====
    xor bx, bx
    xor dx, dx
    mov cx, 8
    
cspo_byte_der:
    lodsb
    
    shl dl, 1
    test al, 01h
    jz cspo_d0
    or dl, 1
cspo_d0:
    shl dh, 1
    test al, 02h
    jz cspo_d1
    or dh, 1
cspo_d1:
    shl bl, 1
    test al, 04h
    jz cspo_d2
    or bl, 1
cspo_d2:
    shl bh, 1
    test al, 08h
    jz cspo_d3
    or bh, 1
cspo_d3:
    loop cspo_byte_der
    
    mov [di+1], dl
    mov [di+33], dh
    mov [di+65], bl
    mov [di+97], bh
    
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    not al
    mov [bp+1], al
    
    add di, 2
    add bp, 2
    
    pop cx
    dec cx
    jz cspo_fin
    jmp cspo_fila

cspo_fin:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
convertir_sprite_a_planar_opt ENDP

; ============================================
; CONVERSIÓN PLANAR CORREGIDA - 32x32
; ============================================
convertir_sprite_32x32_a_planar_opt PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    mov cx, 32
    
csp32_fila:
    push cx
    
    ; ===== BYTE 0 =====
    xor bx, bx
    xor dx, dx
    mov cx, 8
csp32_b0:
    lodsb
    shl dl, 1
    test al, 01h
    jz csp32_b0_0
    or dl, 1
csp32_b0_0:
    shl dh, 1
    test al, 02h
    jz csp32_b0_1
    or dh, 1
csp32_b0_1:
    shl bl, 1
    test al, 04h
    jz csp32_b0_2
    or bl, 1
csp32_b0_2:
    shl bh, 1
    test al, 08h
    jz csp32_b0_3
    or bh, 1
csp32_b0_3:
    loop csp32_b0
    
    mov [di], dl
    mov [di+128], dh
    mov [di+256], bl
    mov [di+384], bh
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    not al
    mov [bp], al
    
    ; ===== BYTE 1 =====
    xor bx, bx
    xor dx, dx
    mov cx, 8
csp32_b1:
    lodsb
    shl dl, 1
    test al, 01h
    jz csp32_b1_0
    or dl, 1
csp32_b1_0:
    shl dh, 1
    test al, 02h
    jz csp32_b1_1
    or dh, 1
csp32_b1_1:
    shl bl, 1
    test al, 04h
    jz csp32_b1_2
    or bl, 1
csp32_b1_2:
    shl bh, 1
    test al, 08h
    jz csp32_b1_3
    or bh, 1
csp32_b1_3:
    loop csp32_b1
    
    mov [di+1], dl
    mov [di+129], dh
    mov [di+257], bl
    mov [di+385], bh
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    not al
    mov [bp+1], al
    
    ; ===== BYTE 2 =====
    xor bx, bx
    xor dx, dx
    mov cx, 8
csp32_b2:
    lodsb
    shl dl, 1
    test al, 01h
    jz csp32_b2_0
    or dl, 1
csp32_b2_0:
    shl dh, 1
    test al, 02h
    jz csp32_b2_1
    or dh, 1
csp32_b2_1:
    shl bl, 1
    test al, 04h
    jz csp32_b2_2
    or bl, 1
csp32_b2_2:
    shl bh, 1
    test al, 08h
    jz csp32_b2_3
    or bh, 1
csp32_b2_3:
    loop csp32_b2
    
    mov [di+2], dl
    mov [di+130], dh
    mov [di+258], bl
    mov [di+386], bh
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    not al
    mov [bp+2], al
    
    ; ===== BYTE 3 =====
    xor bx, bx
    xor dx, dx
    mov cx, 8
csp32_b3:
    lodsb
    shl dl, 1
    test al, 01h
    jz csp32_b3_0
    or dl, 1
csp32_b3_0:
    shl dh, 1
    test al, 02h
    jz csp32_b3_1
    or dh, 1
csp32_b3_1:
    shl bl, 1
    test al, 04h
    jz csp32_b3_2
    or bl, 1
csp32_b3_2:
    shl bh, 1
    test al, 08h
    jz csp32_b3_3
    or bh, 1
csp32_b3_3:
    loop csp32_b3
    
    mov [di+3], dl
    mov [di+131], dh
    mov [di+259], bl
    mov [di+387], bh
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    not al
    mov [bp+3], al
    
    add di, 4
    add bp, 4
    
    pop cx
    dec cx
    jz csp32_fin
    jmp csp32_fila

csp32_fin:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
convertir_sprite_32x32_a_planar_opt ENDP

; ============================================
; DIBUJADO CON TRANSPARENCIA - 16x16
; ============================================
dibujar_sprite_planar_16x16_opt PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    mov bx, dx
    shl bx, 1
    mov ax, [video_offsets + bx]
    add ax, temp_offset
    mov bp, ax
    
    mov ax, cx
    shr ax, 3
    add bp, ax
    
    mov cx, 16

dsp16_fila:
    push cx
    push di
    push si
    push bp
    
    ; BYTE 0
    mov al, [si]
    not al
    test al, al
    jz dsp16_b0_skip
    
    mov dx, 3CEh
    mov ah, al
    mov al, 8
    out dx, al
    inc dx
    mov al, ah
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    
    mov al, es:[bp]
    mov bx, di
    mov al, [bx]
    mov es:[bp], al

dsp16_b0_skip:
    ; BYTE 1
    mov al, [si+1]
    not al
    test al, al
    jz dsp16_b1_skip
    
    mov dx, 3CEh
    mov ah, al
    mov al, 8
    out dx, al
    inc dx
    mov al, ah
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    
    mov al, es:[bp+1]
    mov bx, di
    mov al, [bx+1]
    mov es:[bp+1], al

dsp16_b1_skip:
    pop bp
    add bp, 80
    pop si
    add si, 2
    pop di
    add di, 2
    pop cx
    dec cx
    jz dsp16_salir
    jmp dsp16_fila

dsp16_salir:
    mov dx, 3CEh
    mov al, 8
    out dx, al
    inc dx
    mov al, 0FFh
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_sprite_planar_16x16_opt ENDP

; ============================================
; DIBUJADO CON TRANSPARENCIA - 32x32
; ============================================
dibujar_sprite_planar_32x32_opt PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    mov bx, dx
    shl bx, 1
    mov ax, [video_offsets + bx]
    add ax, temp_offset
    mov bp, ax
    
    mov ax, cx
    shr ax, 3
    add bp, ax
    
    mov cx, 32

dsp32_fila:
    push cx
    push di
    push si
    push bp
    
    ; BYTE 0
    mov al, [si]
    not al
    test al, al
    jz dsp32_b0_skip
    
    mov dx, 3CEh
    mov ah, al
    mov al, 8
    out dx, al
    inc dx
    mov al, ah
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    
    mov al, es:[bp]
    mov bx, di
    mov al, [bx]
    mov es:[bp], al

dsp32_b0_skip:
    ; BYTE 1
    mov al, [si+1]
    not al
    test al, al
    jz dsp32_b1_skip
    
    mov dx, 3CEh
    mov ah, al
    mov al, 8
    out dx, al
    inc dx
    mov al, ah
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    
    mov al, es:[bp+1]
    mov bx, di
    mov al, [bx+1]
    mov es:[bp+1], al

dsp32_b1_skip:
    ; BYTE 2
    mov al, [si+2]
    not al
    test al, al
    jz dsp32_b2_skip
    
    mov dx, 3CEh
    mov ah, al
    mov al, 8
    out dx, al
    inc dx
    mov al, ah
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    
    mov al, es:[bp+2]
    mov bx, di
    mov al, [bx+2]
    mov es:[bp+2], al

dsp32_b2_skip:
    ; BYTE 3
    mov al, [si+3]
    not al
    test al, al
    jz dsp32_b3_skip
    
    mov dx, 3CEh
    mov ah, al
    mov al, 8
    out dx, al
    inc dx
    mov al, ah
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    
    mov al, es:[bp+3]
    mov bx, di
    mov al, [bx+3]
    mov es:[bp+3], al

dsp32_b3_skip:
    pop bp
    add bp, 80
    pop si
    add si, 4
    pop di
    add di, 4
    pop cx
    dec cx
    jz dsp32_salir
    jmp dsp32_fila

dsp32_salir:
    mov dx, 3CEh
    mov al, 8
    out dx, al
    inc dx
    mov al, 0FFh
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_sprite_planar_32x32_opt ENDP