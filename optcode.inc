; ============================================
; OPTCODE.INC - FASE 1A: MÁSCARAS CORREGIDAS
; Universidad Nacional - Proyecto II Ciclo 2025
; OPTIMIZACIÓN: Dirty tiles + máscaras correctas
; ============================================

; ============================================
; LOOKUP TABLES (Ya funcionan bien)
; ============================================
inicializar_lookup_tables PROC
    push ax
    push bx
    push cx
    push di
    
    ; Tabla: Y * 100 (para mapa 100×100)
    mov di, OFFSET mul100_table
    xor ax, ax
    mov cx, 200
ilt_loop_mul100:
    mov [di], ax
    add di, 2
    add ax, 100
    loop ilt_loop_mul100
    
    ; Tabla: Y * 80 (para video)
    mov di, OFFSET video_offsets
    xor ax, ax
    mov cx, 350
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

; ============================================
; VERIFICACIÓN DE TRANSITABILIDAD (OK)
; ============================================
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
    cmp al, 4           ; TILE_WATER
    je vtt_no_transitable
    cmp al, 5           ; TILE_TREE
    je vtt_no_transitable
    cmp al, 7           ; TILE_ROCK
    je vtt_no_transitable
    cmp al, 10          ; TILE_WALL
    je vtt_no_transitable
    cmp al, 14          ; TILE_LAVA
    je vtt_no_transitable

    pop dx
    pop bx
    pop ax
    stc                 ; Carry = 1 → transitable
    ret

vtt_no_transitable:
    pop dx
    pop bx
    pop ax
    clc                 ; Carry = 0 → no transitable
    ret
verificar_tile_transitable_opt ENDP

; ============================================
; CONVERSIÓN A PLANAR - TILES 16x16 ✅ CORREGIDO
; ============================================
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
    
    ; ✅ CORRECCIÓN: Máscara = OR de todos los planos (1=opaco, 0=transparente)
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    mov [bp], al        ; ✅ SIN NOT - directamente
    
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
    
    ; ✅ CORRECCIÓN: Máscara = OR de todos los planos
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    mov [bp+1], al      ; ✅ SIN NOT
    
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

; ============================================
; CONVERSIÓN A PLANAR - JUGADOR 32x32 ✅ CORREGIDO
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
    
    ; ✅ CORRECCIÓN
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
    
    ; ✅ CORRECCIÓN
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
    
    ; ✅ CORRECCIÓN
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
    
    ; ✅ CORRECCIÓN
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
    push es
    
    mov ax, 0A000h
    mov es, ax
    
    push si                 ; Guardar MASK pointer (SI)
    
    mov ax, dx
    mov bx, 80
    mul bx
    mov bp, ax
    mov ax, cx
    shr ax, 3
    add bp, ax
    add bp, temp_offset
    
    mov bx, di              ; BX = sprite DATA pointer
    pop si                  ; SI = sprite MASK pointer
    
    mov cx, 16

dsp16o_fila:
    push cx
    push bp
    push si
    push bx
    
    mov ah, [si]
    mov al, [si+1]
    push ax
    
    push bp
    mov bp, sp
    
    ; [bp+2]  = máscaras [AH|AL]
    ; [bp+4]  = data pointer (BX)
    ; [bp+6]  = mask pointer (SI)
    ; [bp+8]  = video offset (BP_old)

    ; --- PLANO 0 ---
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 0
    out dx, al
    
    mov ax, [bp+2]
    mov bx, [bp+4]
    mov di, [bp+8]
    
    test ah, ah
    jz dsp16o_p0_b1
    
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx]
    and al, cl
    or al, ch
    mov es:[di], al
    
dsp16o_p0_b1:
    mov ax, [bp+2]
    test al, al
    jz dsp16o_p1
    
    inc di
    mov cl, al
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, al
    mov al, [bx+1]
    and al, cl
    or al, ch
    mov es:[di], al
    
dsp16o_p1:
    ; --- PLANO 1 ---
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    
    mov ax, [bp+2]
    mov bx, [bp+4]
    mov di, [bp+8]
    
    test ah, ah
    jz dsp16o_p1_b1
    
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+32]
    and al, cl
    or al, ch
    mov es:[di], al
    
dsp16o_p1_b1:
    mov ax, [bp+2]
    test al, al
    jz dsp16o_p2
    
    inc di
    mov cl, al
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, al
    mov al, [bx+33]
    and al, cl
    or al, ch
    mov es:[di], al

dsp16o_p2:
    ; --- PLANO 2 ---
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 4
    out dx, al
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 2
    out dx, al

    mov ax, [bp+2]
    mov bx, [bp+4]
    mov di, [bp+8]
    
    test ah, ah
    jz dsp16o_p2_b1
    
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+64]
    and al, cl
    or al, ch
    mov es:[di], al
    
dsp16o_p2_b1:
    mov ax, [bp+2]
    test al, al
    jz dsp16o_p3
    
    inc di
    mov cl, al
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, al
    mov al, [bx+65]
    and al, cl
    or al, ch
    mov es:[di], al
    
dsp16o_p3:
    ; --- PLANO 3 ---
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 8
    out dx, al
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 3
    out dx, al
    
    mov ax, [bp+2]
    mov bx, [bp+4]
    mov di, [bp+8]

    test ah, ah
    jz dsp16o_p3_b1
    
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+96]
    and al, cl
    or al, ch
    mov es:[di], al
    
dsp16o_p3_b1:
    mov ax, [bp+2]
    test al, al
    jz dsp16o_fila_next
    
    inc di
    mov cl, al
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, al
    mov al, [bx+97]
    and al, cl
    or al, ch
    mov es:[di], al
    
dsp16o_fila_next:
    pop bp
    add sp, 2
    
    pop bx
    pop si
    pop bp
    
    add bp, 80
    add si, 2
    add bx, 2
    
    pop cx
    dec cx
    jz dsp16o_fin_loop
    jmp dsp16o_fila
dsp16o_fin_loop:
    
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
    xor al, al
    out dx, al
    
    pop es
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
    push es
    
    mov ax, 0A000h
    mov es, ax
    
    push si
    
    mov ax, dx
    mov bx, 80
    mul bx
    mov bp, ax
    mov ax, cx
    shr ax, 3
    add bp, ax
    add bp, temp_offset
    
    mov bx, di
    pop si
    
    mov cx, 32

dsp32o_fila:
    push cx
    push bp
    push si
    push bx
    
    mov ah, [si]
    mov al, [si+1]
    push ax
    mov ah, [si+2]
    mov al, [si+3]
    push ax
    
    push bp
    mov bp, sp
    
    ; [bp+2]  = máscaras [B2|B3]
    ; [bp+4]  = máscaras [B0|B1]
    ; [bp+6]  = data pointer (BX)
    ; [bp+8]  = mask pointer (SI)
    ; [bp+10] = video offset (BP_old)

    ; --- PLANO 0 ---
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 0
    out dx, al

    mov ax, [bp+2]
    mov dx, [bp+4]
    mov bx, [bp+6]
    mov di, [bp+10]
    
    test dh, dh
    jz dsp32o_p0_b1
    mov cl, dh
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, dh
    mov al, [bx]
    and al, cl
    or al, ch
    mov es:[di], al
dsp32o_p0_b1:
    test dl, dl
    jz dsp32o_p0_b2
    inc di
    mov cl, dl
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, dl
    mov al, [bx+1]
    and al, cl
    or al, ch
    mov es:[di], al
dsp32o_p0_b2:
    test ah, ah
    jz dsp32o_p0_b3
    mov di, [bp+10]
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
dsp32o_p0_b3:
    test al, al
    jz dsp32o_p1
    mov di, [bp+10]
    add di, 3
    mov cl, al
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, al
    mov al, [bx+3]
    and al, cl
    or al, ch
    mov es:[di], al

dsp32o_p1:
    ; --- PLANO 1 ---
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 1
    out dx, al

    mov ax, [bp+2]
    mov dx, [bp+4]
    mov bx, [bp+6]
    mov di, [bp+10]

    test dh, dh
    jz dsp32o_p1_b1
    mov cl, dh
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, dh
    mov al, [bx+128]
    and al, cl
    or al, ch
    mov es:[di], al
dsp32o_p1_b1:
    test dl, dl
    jz dsp32o_p1_b2
    inc di
    mov cl, dl
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, dl
    mov al, [bx+129]
    and al, cl
    or al, ch
    mov es:[di], al
dsp32o_p1_b2:
    test ah, ah
    jz dsp32o_p1_b3
    mov di, [bp+10]
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
dsp32o_p1_b3:
    test al, al
    jz dsp32o_p2
    mov di, [bp+10]
    add di, 3
    mov cl, al
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, al
    mov al, [bx+131]
    and al, cl
    or al, ch
    mov es:[di], al

dsp32o_p2:
    ; --- PLANO 2 ---
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 4
    out dx, al
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    
    mov ax, [bp+2]
    mov dx, [bp+4]
    mov bx, [bp+6]
    mov di, [bp+10]
    
    test dh, dh
    jz dsp32o_p2_b1
    mov cl, dh
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, dh
    mov al, [bx+256]
    and al, cl
    or al, ch
    mov es:[di], al
dsp32o_p2_b1:
    test dl, dl
    jz dsp32o_p2_b2
    inc di
    mov cl, dl
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, dl
    mov al, [bx+257]
    and al, cl
    or al, ch
    mov es:[di], al
dsp32o_p2_b2:
    test ah, ah
    jz dsp32o_p2_b3
    mov di, [bp+10]
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
dsp32o_p2_b3:
    test al, al
    jz dsp32o_p3
    mov di, [bp+10]
    add di, 3
    mov cl, al
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, al
    mov al, [bx+259]
    and al, cl
    or al, ch
    mov es:[di], al

dsp32o_p3:
    ; --- PLANO 3 ---
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 8
    out dx, al
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    mov al, 3
    out dx, al

    mov ax, [bp+2]
    mov dx, [bp+4]
    mov bx, [bp+6]
    mov di, [bp+10]

    test dh, dh
    jz dsp32o_p3_b1
    mov cl, dh
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, dh
    mov al, [bx+384]
    and al, cl
    or al, ch
    mov es:[di], al
dsp32o_p3_b1:
    test dl, dl
    jz dsp32o_p3_b2
    inc di
    mov cl, dl
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, dl
    mov al, [bx+385]
    and al, cl
    or al, ch
    mov es:[di], al
dsp32o_p3_b2:
    test ah, ah
    jz dsp32o_p3_b3
    mov di, [bp+10]
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
dsp32o_p3_b3:
    test al, al
    jz dsp32o_fila_next
    mov di, [bp+10]
    add di, 3
    mov cl, al
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, al
    mov al, [bx+387]
    and al, cl
    or al, ch
    mov es:[di], al

dsp32o_fila_next:
    pop bp
    add sp, 4
    
    pop bx
    pop si
    pop bp
    
    add bp, 80
    add si, 4
    add bx, 4
    
    pop cx
    dec cx
    jz dsp32o_fin_loop
    jmp dsp32o_fila
dsp32o_fin_loop:
    
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
    xor al, al
    out dx, al
    
    pop es
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_sprite_planar_32x32_opt ENDP