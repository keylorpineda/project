; ============================================
; OPTCODE.INC - SISTEMA PLANAR **CORREGIDO**
; Universidad Nacional - Proyecto II Ciclo 2025
; ============================================

inicializar_lookup_tables PROC
    push ax
    push bx
    push cx
    push di
    
    ; ===== TABLA: Y * 100 (para mapa 100×100) =====
    mov di, OFFSET mul100_table
    xor ax, ax
    mov cx, 200             ; 200 entradas (0-199)
    
ilt_loop_mul100:
    mov [di], ax
    add di, 2
    add ax, 100
    loop ilt_loop_mul100
    
    ; ===== TABLA: Y * 80 (para video) =====
    mov di, OFFSET video_offsets
    xor ax, ax
    mov cx, 350             ; 350 líneas
    
ilt_loop_video:
    mov [di], ax
    add di, 2
    add ax, 80
    loop ilt_loop_video
    
    pop di
    pop cx
    pop bx
    pop ax
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
    
    ; Verificar límites
    cmp cx, 100
    jae vtt_no_transitable
    cmp dx, 100
    jae vtt_no_transitable
    
    ; Calcular índice: dx * 100 + cx
    mov ax, dx
    mov bx, cx
    push bx
    mov bx, ax
    shl bx, 1
    mov ax, [mul100_table + bx]
    pop bx
    add ax, bx
    mov bx, ax
    
    ; Obtener tipo de tile
    mov al, [mapa_datos + bx]
    
    ; Verificar si es transitable
    cmp al, TILE_WATER
    je vtt_no_transitable
    cmp al, TILE_TREE
    je vtt_no_transitable
    cmp al, TILE_ROCK
    je vtt_no_transitable
    cmp al, TILE_WALL
    je vtt_no_transitable
    cmp al, TILE_LAVA
    je vtt_no_transitable

    pop dx
    pop bx
    pop ax
    stc                     ; Carry = 1 → transitable
    ret

vtt_no_transitable:
    pop dx
    pop bx
    pop ax
    clc                     ; Carry = 0 → no transitable
    ret
verificar_tile_transitable_opt ENDP

convertir_sprite_a_planar_opt PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    mov cx, 16              ; 16 filas
    
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
    
    ; Guardar planos
    mov [di], dl
    mov [di+32], dh
    mov [di+64], bl
    mov [di+96], bh
    
    ; Calcular máscara (SIN NOT)
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
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
    
    ; Guardar planos
    mov [di+1], dl
    mov [di+33], dh
    mov [di+65], bl
    mov [di+97], bh
    
    ; Calcular máscara (SIN NOT)
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    mov [bp+1], al
    
    ; Siguiente fila
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
convertir_sprite_32x32_a_planar_opt PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    mov cx, 32
    
csp32o_fila:
    push cx
    
    ; ===== BYTE 0 (píxeles 0-7) =====
    xor bx, bx
    xor dx, dx
    mov cx, 8
    
csp32o_byte0:
    lodsb
    shl dl, 1
    test al, 01h
    jz csp32o_b0_0
    or dl, 1
csp32o_b0_0:
    shl dh, 1
    test al, 02h
    jz csp32o_b0_1
    or dh, 1
csp32o_b0_1:
    shl bl, 1
    test al, 04h
    jz csp32o_b0_2
    or bl, 1
csp32o_b0_2:
    shl bh, 1
    test al, 08h
    jz csp32o_b0_3
    or bh, 1
csp32o_b0_3:
    loop csp32o_byte0
    
    mov [di], dl
    mov [di+128], dh
    mov [di+256], bl
    mov [di+384], bh
    
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    mov [bp], al
    
    inc di
    inc bp
    
    ; ===== BYTE 1 (píxeles 8-15) =====
    xor bx, bx
    xor dx, dx
    mov cx, 8
    
csp32o_byte1:
    lodsb
    shl dl, 1
    test al, 01h
    jz csp32o_b1_0
    or dl, 1
csp32o_b1_0:
    shl dh, 1
    test al, 02h
    jz csp32o_b1_1
    or dh, 1
csp32o_b1_1:
    shl bl, 1
    test al, 04h
    jz csp32o_b1_2
    or bl, 1
csp32o_b1_2:
    shl bh, 1
    test al, 08h
    jz csp32o_b1_3
    or bh, 1
csp32o_b1_3:
    loop csp32o_byte1
    
    mov [di], dl
    mov [di+128], dh
    mov [di+256], bl
    mov [di+384], bh
    
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    mov [bp], al
    
    inc di
    inc bp
    
    ; ===== BYTE 2 (píxeles 16-23) =====
    xor bx, bx
    xor dx, dx
    mov cx, 8
    
csp32o_byte2:
    lodsb
    shl dl, 1
    test al, 01h
    jz csp32o_b2_0
    or dl, 1
csp32o_b2_0:
    shl dh, 1
    test al, 02h
    jz csp32o_b2_1
    or dh, 1
csp32o_b2_1:
    shl bl, 1
    test al, 04h
    jz csp32o_b2_2
    or bl, 1
csp32o_b2_2:
    shl bh, 1
    test al, 08h
    jz csp32o_b2_3
    or bh, 1
csp32o_b2_3:
    loop csp32o_byte2
    
    mov [di], dl
    mov [di+128], dh
    mov [di+256], bl
    mov [di+384], bh
    
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    mov [bp], al
    
    inc di
    inc bp
    
    ; ===== BYTE 3 (píxeles 24-31) =====
    xor bx, bx
    xor dx, dx
    mov cx, 8
    
csp32o_byte3:
    lodsb
    shl dl, 1
    test al, 01h
    jz csp32o_b3_0
    or dl, 1
csp32o_b3_0:
    shl dh, 1
    test al, 02h
    jz csp32o_b3_1
    or dh, 1
csp32o_b3_1:
    shl bl, 1
    test al, 04h
    jz csp32o_b3_2
    or bl, 1
csp32o_b3_2:
    shl bh, 1
    test al, 08h
    jz csp32o_b3_3
    or bh, 1
csp32o_b3_3:
    loop csp32o_byte3
    
    mov [di], dl
    mov [di+128], dh
    mov [di+256], bl
    mov [di+384], bh
    
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    mov [bp], al
    
    inc di
    inc bp
    
    ; Siguiente fila
    pop cx
    dec cx
    jz csp32o_fin
    jmp csp32o_fila

csp32o_fin:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
convertir_sprite_32x32_a_planar_opt ENDP

dibujar_sprite_planar_16x16_opt PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    ; Calcular offset de video
    mov ax, dx
    mov bx, 80
    mul bx
    add ax, temp_offset
    mov bp, ax
    
    mov ax, cx
    shr ax, 3
    add bp, ax
    
    mov cx, 16              ; 16 filas

dsp16o_loop_fila:
    push cx
    push di
    push bp
    
    mov bx, di              ; BX = puntero a datos planar
    
    ; ============================================
    ; BYTE 0 (píxeles 0-7) - BYTE IZQUIERDO
    ; ============================================
    
    ; Calcular máscara: plano0 AND NOT(plano1) AND plano2 AND plano3, luego NOT
    mov al, [bx]            ; plano 0
    mov dl, [bx+32]         ; plano 1
    not dl
    and al, dl
    and al, [bx+64]         ; plano 2
    and al, [bx+96]         ; plano 3
    not al
    mov ah, al              ; AH = máscara byte 0
    
    ; --- PLANO 0 ---
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 0
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    
    mov di, bp
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx]
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; --- PLANO 1 ---
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    
    mov di, bp
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+32]
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; --- PLANO 2 ---
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 4
    out dx, al
    
    mov di, bp
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+64]
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; --- PLANO 3 ---
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 3
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 8
    out dx, al
    
    mov di, bp
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+96]
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; ============================================
    ; BYTE 1 (píxeles 8-15) - BYTE DERECHO
    ; ============================================
    
    mov al, [bx+1]
    mov dl, [bx+33]
    not dl
    and al, dl
    and al, [bx+65]
    and al, [bx+97]
    not al
    mov ah, al              ; AH = máscara byte 1
    
    ; --- PLANO 0 ---
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 0
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    
    mov di, bp
    inc di
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+1]
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; --- PLANO 1 ---
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    
    mov di, bp
    inc di
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+33]
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; --- PLANO 2 ---
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 4
    out dx, al
    
    mov di, bp
    inc di
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+65]
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; --- PLANO 3 ---
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 3
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 8
    out dx, al
    
    mov di, bp
    inc di
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+97]
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; ============================================
    ; Siguiente fila
    ; ============================================
    pop bp
    add bp, 80
    pop di
    add di, 2
    pop cx
    dec cx
    jnz dsp16o_continuar
    jmp dsp16o_fin

dsp16o_continuar:
    jmp dsp16o_loop_fila

dsp16o_fin:
    ; Restaurar registros EGA
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 0
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

dibujar_sprite_planar_32x32_opt PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    ; Calcular offset de video
    mov ax, dx
    mov bx, 80
    mul bx
    add ax, temp_offset
    mov bp, ax
    
    mov ax, cx
    shr ax, 3
    add bp, ax
    
    mov cx, 32              ; 32 filas

dsp32o_loop_fila:
    push cx
    push di
    push bp
    
    mov bx, di              ; BX = puntero a datos planar
    
    ; ============================================
    ; BYTE 0 (píxeles 0-7)
    ; ============================================
    
    ; Calcular máscara: OR de todos los planos (color 0 = transparente)
    mov al, [bx]            ; plano 0
    or al, [bx+128]         ; OR plano 1
    or al, [bx+256]         ; OR plano 2
    or al, [bx+384]         ; OR plano 3
    mov ah, al              ; AH = máscara byte 0 (1=opaco, 0=transparente)
    
    ; --- PLANO 0 ---
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 0
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    
    mov di, bp
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx]
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; --- PLANO 1 ---
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    
    mov di, bp
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+128]
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; --- PLANO 2 ---
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 4
    out dx, al
    
    mov di, bp
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+256]
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; --- PLANO 3 ---
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 3
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 8
    out dx, al
    
    mov di, bp
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+384]
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; ============================================
    ; BYTE 1 (píxeles 8-15)
    ; ============================================
    
    mov al, [bx+1]
    or al, [bx+129]
    or al, [bx+257]
    or al, [bx+385]
    mov ah, al              ; AH = máscara byte 1
    
    ; --- PLANO 0 ---
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 0
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    
    mov di, bp
    inc di
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+1]
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; --- PLANO 1 ---
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    
    mov di, bp
    inc di
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+129]
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; --- PLANO 2 ---
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 4
    out dx, al
    
    mov di, bp
    inc di
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+257]
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; --- PLANO 3 ---
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 3
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 8
    out dx, al
    
    mov di, bp
    inc di
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+385]
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; ============================================
    ; BYTE 2 (píxeles 16-23)
    ; ============================================
    
    mov al, [bx+2]
    or al, [bx+130]
    or al, [bx+258]
    or al, [bx+386]
    mov ah, al              ; AH = máscara byte 2
    
    ; --- PLANO 0 ---
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 0
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    
    mov di, bp
    add di, 2
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+2]
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; --- PLANO 1 ---
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    
    mov di, bp
    add di, 2
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+130]
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; --- PLANO 2 ---
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 4
    out dx, al
    
    mov di, bp
    add di, 2
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+258]
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; --- PLANO 3 ---
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 3
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 8
    out dx, al
    
    mov di, bp
    add di, 2
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+386]
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; ============================================
    ; BYTE 3 (píxeles 24-31)
    ; ============================================
    
    mov al, [bx+3]
    or al, [bx+131]
    or al, [bx+259]
    or al, [bx+387]
    mov ah, al              ; AH = máscara byte 3
    
    ; --- PLANO 0 ---
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 0
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    
    mov di, bp
    add di, 3
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+3]
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; --- PLANO 1 ---
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    
    mov di, bp
    add di, 3
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+131]
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; --- PLANO 2 ---
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 4
    out dx, al
    
    mov di, bp
    add di, 3
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+259]
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; --- PLANO 3 ---
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 3
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 8
    out dx, al
    
    mov di, bp
    add di, 3
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+387]
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; ============================================
    ; Siguiente fila
    ; ============================================
    pop bp
    add bp, 80
    pop di
    add di, 4
    pop cx
    dec cx
    jnz dsp32o_continuar
    jmp dsp32o_fin

dsp32o_continuar:
    jmp dsp32o_loop_fila

dsp32o_fin:
    ; Restaurar registros EGA
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 0
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