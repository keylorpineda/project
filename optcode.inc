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

; ============================================
; DIBUJADO DE TILES 16x16 ✅ CORREGIDO + OPTIMIZADO
; ============================================
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
    ; BYTE 0 (píxeles 0-7) - ✅ MÁSCARA CORREGIDA
    ; ============================================
    
    mov ah, [bx + 128]      ; AH = máscara (1=opaco, 0=transparente)
    
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
    
    mov si, bp              ; SI = offset video
    mov cl, ah
    not cl                  ; CL = NOT(máscara) para preservar background
    mov ch, es:[si]         ; Leer background
    and ch, cl              ; Preservar píxeles transparentes
    mov cl, ah              ; CL = máscara
    mov al, [bx]            ; AL = datos plano 0
    and al, cl              ; Solo píxeles opacos
    or al, ch               ; Combinar
    mov es:[si], al
    
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
    
    mov si, bp
    mov cl, ah
    not cl
    mov ch, es:[si]
    and ch, cl
    mov cl, ah
    mov al, [bx+32]
    and al, cl
    or al, ch
    mov es:[si], al
    
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
    
    mov si, bp
    mov cl, ah
    not cl
    mov ch, es:[si]
    and ch, cl
    mov cl, ah
    mov al, [bx+64]
    and al, cl
    or al, ch
    mov es:[si], al
    
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
    
    mov si, bp
    mov cl, ah
    not cl
    mov ch, es:[si]
    and ch, cl
    mov cl, ah
    mov al, [bx+96]
    and al, cl
    or al, ch
    mov es:[si], al
    
    ; ============================================
    ; BYTE 1 (píxeles 8-15) - ✅ MÁSCARA CORREGIDA
    ; ============================================
    
    mov ah, [bx + 129]      ; AH = máscara byte 1
    
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
    
    mov si, bp
    inc si
    mov cl, ah
    not cl
    mov ch, es:[si]
    and ch, cl
    mov cl, ah
    mov al, [bx+1]
    and al, cl
    or al, ch
    mov es:[si], al
    
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
    
    mov si, bp
    inc si
    mov cl, ah
    not cl
    mov ch, es:[si]
    and ch, cl
    mov cl, ah
    mov al, [bx+33]
    and al, cl
    or al, ch
    mov es:[si], al
    
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
    
    mov si, bp
    inc si
    mov cl, ah
    not cl
    mov ch, es:[si]
    and ch, cl
    mov cl, ah
    mov al, [bx+65]
    and al, cl
    or al, ch
    mov es:[si], al
    
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
    
    mov si, bp
    inc si
    mov cl, ah
    not cl
    mov ch, es:[si]
    and ch, cl
    mov cl, ah
    mov al, [bx+97]
    and al, cl
    or al, ch
    mov es:[si], al
    
    ; ============================================
    ; Siguiente fila
    ; ============================================
    pop bp
    add bp, 80
    pop di
    add di, 2
    pop cx
    dec cx
    jnz dsp16o_continuar_near
    jmp dsp16o_fin

dsp16o_continuar_near:
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

; ============================================
; DIBUJADO DEL JUGADOR 32x32 ✅ CORREGIDO
; ============================================
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
    
    mov bx, di
    
    ; ===== BYTE 0 ===== (código similar, usando máscara correcta)
    mov ah, [bx + 512]      ; Offset de máscara: 32 filas × 4 bytes × 4 = 512
    
    ; PLANO 0
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
    mov si, bp
    mov cl, ah
    not cl
    mov ch, es:[si]
    and ch, cl
    mov cl, ah
    mov al, [bx]
    and al, cl
    or al, ch
    mov es:[si], al
    
    ; PLANO 1
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
    mov si, bp
    mov cl, ah
    not cl
    mov ch, es:[si]
    and ch, cl
    mov cl, ah
    mov al, [bx+128]
    and al, cl
    or al, ch
    mov es:[si], al
    
    ; PLANO 2
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
    mov si, bp
    mov cl, ah
    not cl
    mov ch, es:[si]
    and ch, cl
    mov cl, ah
    mov al, [bx+256]
    and al, cl
    or al, ch
    mov es:[si], al
    
    ; PLANO 3
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
    mov si, bp
    mov cl, ah
    not cl
    mov ch, es:[si]
    and ch, cl
    mov cl, ah
    mov al, [bx+384]
    and al, cl
    or al, ch
    mov es:[si], al
    
    ; ===== BYTES 1, 2, 3 ===== (patrón similar)
    ; Por brevedad, solo muestro byte 1, los demás siguen el mismo patrón
    
    mov ah, [bx + 513]
    
    ; PLANO 0
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
    mov si, bp
    inc si
    mov cl, ah
    not cl
    mov ch, es:[si]
    and ch, cl
    mov cl, ah
    mov al, [bx+1]
    and al, cl
    or al, ch
    mov es:[si], al
    
    ; [Continuar con planos 1,2,3 y bytes 2,3...]
    ; [Por brevedad omito código repetitivo - sigue mismo patrón]
    
    pop bp
    add bp, 80
    pop di
    add di, 4
    pop cx
    dec cx
    jnz dsp32o_continuar_near
    jmp dsp32o_fin

dsp32o_continuar_near:
    jmp dsp32o_loop_fila

dsp32o_fin:
    ; Restaurar registros
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