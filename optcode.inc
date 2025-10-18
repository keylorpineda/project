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
; PRE-CALCULAR MÁSCARAS - LLAMAR UNA SOLA VEZ
; ============================================
precalcular_mascaras_tiles PROC
    push si
    push di
    push cx
    push ax
    
    ; Grass
    mov si, OFFSET sprite_grass1
    mov di, OFFSET sprite_grass1_mask
    call calcular_mascara_16x16
    
    ; Path
    mov si, OFFSET sprite_path
    mov di, OFFSET sprite_path_mask
    call calcular_mascara_16x16
    
    ; Water
    mov si, OFFSET sprite_water
    mov di, OFFSET sprite_water_mask
    call calcular_mascara_16x16
    
    ; Tree
    mov si, OFFSET sprite_tree
    mov di, OFFSET sprite_tree_mask
    call calcular_mascara_16x16
    
    ; Sand
    mov si, OFFSET sprite_sand
    mov di, OFFSET sprite_sand_mask
    call calcular_mascara_16x16
    
    ; Rock
    mov si, OFFSET sprite_rock
    mov di, OFFSET sprite_rock_mask
    call calcular_mascara_16x16
    
    ; Snow
    mov si, OFFSET sprite_snow
    mov di, OFFSET sprite_snow_mask
    call calcular_mascara_16x16
    
    ; Ice
    mov si, OFFSET sprite_ice
    mov di, OFFSET sprite_ice_mask
    call calcular_mascara_16x16
    
    ; Wall
    mov si, OFFSET sprite_wall
    mov di, OFFSET sprite_wall_mask
    call calcular_mascara_16x16
    
    ; Dirt
    mov si, OFFSET sprite_dirt
    mov di, OFFSET sprite_dirt_mask
    call calcular_mascara_16x16
    
    ; Lava
    mov si, OFFSET sprite_lava
    mov di, OFFSET sprite_lava_mask
    call calcular_mascara_16x16
    
    ; Bridge
    mov si, OFFSET sprite_bridge
    mov di, OFFSET sprite_bridge_mask
    call calcular_mascara_16x16
    
    pop ax
    pop cx
    pop di
    pop si
    ret
precalcular_mascaras_tiles ENDP

calcular_mascara_16x16 PROC
    push bx
    push cx
    
    mov cx, 16              ; 16 filas
cm16_loop:
    ; Byte 0
    mov al, [si]            ; P0
    or al, [si+32]          ; P1
    or al, [si+64]          ; P2
    or al, [si+96]          ; P3
    mov [di], al
    
    ; Byte 1
    mov al, [si+1]
    or al, [si+33]
    or al, [si+65]
    or al, [si+97]
    mov [di+1], al
    
    add si, 2
    add di, 2
    loop cm16_loop
    
    pop cx
    pop bx
    ret
calcular_mascara_16x16 ENDP

; ============================================
; PRE-CALCULAR MÁSCARAS JUGADOR 32x32
; ============================================
precalcular_mascaras_jugador PROC
    push si
    push di
    
    mov si, OFFSET jugador_up_a
    mov di, OFFSET jugador_up_a_mask
    call calcular_mascara_32x32
    
    mov si, OFFSET jugador_up_b
    mov di, OFFSET jugador_up_b_mask
    call calcular_mascara_32x32
    
    mov si, OFFSET jugador_down_a
    mov di, OFFSET jugador_down_a_mask
    call calcular_mascara_32x32
    
    mov si, OFFSET jugador_down_b
    mov di, OFFSET jugador_down_b_mask
    call calcular_mascara_32x32
    
    mov si, OFFSET jugador_izq_a
    mov di, OFFSET jugador_izq_a_mask
    call calcular_mascara_32x32
    
    mov si, OFFSET jugador_izq_b
    mov di, OFFSET jugador_izq_b_mask
    call calcular_mascara_32x32
    
    mov si, OFFSET jugador_der_a
    mov di, OFFSET jugador_der_a_mask
    call calcular_mascara_32x32
    
    mov si, OFFSET jugador_der_b
    mov di, OFFSET jugador_der_b_mask
    call calcular_mascara_32x32
    
    pop di
    pop si
    ret
precalcular_mascaras_jugador ENDP

calcular_mascara_32x32 PROC
    push bx
    push cx
    
    mov cx, 32              ; 32 filas
cm32_loop:
    ; Byte 0
    mov al, [si]
    or al, [si+128]
    or al, [si+256]
    or al, [si+384]
    mov [di], al
    
    ; Byte 1
    mov al, [si+1]
    or al, [si+129]
    or al, [si+257]
    or al, [si+385]
    mov [di+1], al
    
    ; Byte 2
    mov al, [si+2]
    or al, [si+130]
    or al, [si+258]
    or al, [si+386]
    mov [di+2], al
    
    ; Byte 3
    mov al, [si+3]
    or al, [si+131]
    or al, [si+259]
    or al, [si+387]
    mov [di+3], al
    
    add si, 4
    add di, 4
    loop cm32_loop
    
    pop cx
    pop bx
    ret
calcular_mascara_32x32 ENDP

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
    
    ; Calcular offset de video
    mov ax, dx
    mov bx, 80
    mul bx
    mov bp, ax              ; BP = offset base de fila
    mov ax, cx
    shr ax, 3
    add bp, ax
    add bp, temp_offset
    
    mov bx, di              ; BX = datos planar
    ; SI ya tiene la máscara pre-calculada
    
    mov cx, 16              ; 16 filas

dsp16o_fila:
    push cx
    push bp
    push bx
    push si
    
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
    
    ; Byte 0
    mov ah, [si]            ; Máscara pre-calculada
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov al, [bx]
    and al, ah
    or al, ch
    mov es:[di], al
    inc di
    
    ; Byte 1
    mov ah, [si+1]
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov al, [bx+1]
    and al, ah
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
    
    mov ah, [si]
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov al, [bx+32]
    and al, ah
    or al, ch
    mov es:[di], al
    inc di
    
    mov ah, [si+1]
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov al, [bx+33]
    and al, ah
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
    
    mov ah, [si]
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov al, [bx+64]
    and al, ah
    or al, ch
    mov es:[di], al
    inc di
    
    mov ah, [si+1]
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov al, [bx+65]
    and al, ah
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
    
    mov ah, [si]
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov al, [bx+96]
    and al, ah
    or al, ch
    mov es:[di], al
    inc di
    
    mov ah, [si+1]
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov al, [bx+97]
    and al, ah
    or al, ch
    mov es:[di], al
    
    ; Siguiente fila
    pop si
    add si, 2               ; Siguiente fila de máscara
    pop bx
    add bx, 2               ; Siguiente fila de datos
    pop bp
    add bp, 80              ; Siguiente línea de video
    
    pop cx
    dec cx
    jnz dsp16o_fila
    
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
    
    ; Calcular offset base
    mov ax, dx
    mov bx, 80
    mul bx
    mov bp, ax
    mov ax, cx
    shr ax, 3
    add bp, ax
    add bp, temp_offset
    
    mov bx, di              ; BX = datos planar
    ; SI ya tiene máscara pre-calculada
    
    mov cx, 32              ; 32 filas

dsp32o_fila:
    push cx
    push bp
    push bx
    push si
    
    ; ===== PLANO 0 =====
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
    
    ; Byte 0
    mov ah, [si]
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov al, [bx]
    and al, ah
    or al, ch
    mov es:[di], al
    inc di
    
    ; Byte 1
    mov ah, [si+1]
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov al, [bx+1]
    and al, ah
    or al, ch
    mov es:[di], al
    inc di
    
    ; Byte 2
    mov ah, [si+2]
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov al, [bx+2]
    and al, ah
    or al, ch
    mov es:[di], al
    inc di
    
    ; Byte 3
    mov ah, [si+3]
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov al, [bx+3]
    and al, ah
    or al, ch
    mov es:[di], al
    
    ; ===== PLANO 1 =====
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
    
    mov ah, [si]
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov al, [bx+128]
    and al, ah
    or al, ch
    mov es:[di], al
    inc di
    
    mov ah, [si+1]
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov al, [bx+129]
    and al, ah
    or al, ch
    mov es:[di], al
    inc di
    
    mov ah, [si+2]
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov al, [bx+130]
    and al, ah
    or al, ch
    mov es:[di], al
    inc di
    
    mov ah, [si+3]
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov al, [bx+131]
    and al, ah
    or al, ch
    mov es:[di], al
    
    ; ===== PLANO 2 =====
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
    
    mov ah, [si]
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov al, [bx+256]
    and al, ah
    or al, ch
    mov es:[di], al
    inc di
    
    mov ah, [si+1]
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov al, [bx+257]
    and al, ah
    or al, ch
    mov es:[di], al
    inc di
    
    mov ah, [si+2]
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov al, [bx+258]
    and al, ah
    or al, ch
    mov es:[di], al
    inc di
    
    mov ah, [si+3]
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov al, [bx+259]
    and al, ah
    or al, ch
    mov es:[di], al
    
    ; ===== PLANO 3 =====
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
    
    mov ah, [si]
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov al, [bx+384]
    and al, ah
    or al, ch
    mov es:[di], al
    inc di
    
    mov ah, [si+1]
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov al, [bx+385]
    and al, ah
    or al, ch
    mov es:[di], al
    inc di
    
    mov ah, [si+2]
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov al, [bx+386]
    and al, ah
    or al, ch
    mov es:[di], al
    inc di
    
    mov ah, [si+3]
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov al, [bx+387]
    and al, ah
    or al, ch
    mov es:[di], al
    
    ; Siguiente fila
    pop si
    add si, 4
    pop bx
    add bx, 4
    pop bp
    add bp, 80
    
    pop cx
    dec cx
    jnz dsp32o_fila
    
    ; Restaurar
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