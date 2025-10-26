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

    ; Recursos                        ; ← AGREGAR ESTO
    mov si, OFFSET sprite_cristal
    mov di, OFFSET sprite_cristal_mask
    call calcular_mascara_16x16
    
    mov si, OFFSET sprite_gema
    mov di, OFFSET sprite_gema_mask
    call calcular_mascara_16x16
    
    mov si, OFFSET sprite_moneda
    mov di, OFFSET sprite_moneda_mask
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

; ============================================
; AJUSTAR COORDENADAS PARA SCROLL SUAVE
; ============================================
ajustar_coords_scroll PROC
    ; Entrada: CX = X, DX = Y
    ; Salida: CX, DX ajustados
    push ax
    
    mov ax, scroll_offset_x
    sub cx, ax              ; Desplazar X
    
    mov ax, scroll_offset_y
    sub dx, ax              ; Desplazar Y
    
    pop ax
    ret
ajustar_coords_scroll ENDP

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
    
    mov bx, dx
    shl bx, 1
    mov bp, [video_offsets + bx]
    mov ax, cx
    shr ax, 3
    add bp, ax
    add bp, temp_offset
    
    mov bx, di
    
    ; ===== PLANO 0 =====
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    xor al, al
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    
    push bp
    push bx
    push si
    
    mov cx, 4
    
dsp16_p0:
    mov di, bp
    
    mov ah, [si]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+1]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+1]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    add di, 80
    mov ah, [si+2]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+2]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+3]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+3]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    add di, 80
    mov ah, [si+4]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+4]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+5]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+5]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    add di, 80
    mov ah, [si+6]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+6]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+7]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+7]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    add bp, 320
    add si, 8
    add bx, 8
    dec cx
    jz dsp16_p0_done
    jmp dsp16_p0

dsp16_p0_done:
    
    pop si
    pop bx
    pop bp
    
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
    
    push bp
    push bx
    push si
    
    mov cx, 4
    
dsp16_p1:
    mov di, bp
    
    mov ah, [si]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+32]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+1]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+33]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    add di, 80
    mov ah, [si+2]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+34]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+3]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+35]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    add di, 80
    mov ah, [si+4]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+36]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+5]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+37]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    add di, 80
    mov ah, [si+6]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+38]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+7]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+39]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    add bp, 320
    add si, 8
    add bx, 8
    dec cx
    jz dsp16_p1_done
    jmp dsp16_p1

dsp16_p1_done:
    
    pop si
    pop bx
    pop bp
    
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
    
    push bp
    push bx
    push si
    
    mov cx, 4
    
dsp16_p2:
    mov di, bp
    
    mov ah, [si]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+64]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+1]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+65]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    add di, 80
    mov ah, [si+2]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+66]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+3]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+67]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    add di, 80
    mov ah, [si+4]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+68]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+5]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+69]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    add di, 80
    mov ah, [si+6]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+70]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+7]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+71]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    add bp, 320
    add si, 8
    add bx, 8
    dec cx
    jz dsp16_p2_done
    jmp dsp16_p2

dsp16_p2_done:
    
    pop si
    pop bx
    pop bp
    
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

    ; =================== INICIO DE LA CORRECCIÓN ===================
    push bp
    push bx
    push si
    ; ===============================================================
    
    mov cx, 4
    
dsp16_p3:
    mov di, bp
    
    mov ah, [si]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+96]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+1]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+97]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    add di, 80
    mov ah, [si+2]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+98]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+3]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+99]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    add di, 80
    mov ah, [si+4]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+100]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+5]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+101]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    add di, 80
    mov ah, [si+6]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+102]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+7]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+103]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    add bp, 320
    add si, 8
    add bx, 8
    dec cx
    jz dsp16_p3_done
    jmp dsp16_p3

dsp16_p3_done:

    ; =================== INICIO DE LA CORRECCIÓN ===================
    pop si
    pop bx
    pop bp
    ; ===============================================================
    
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
    
    ; ✅ OPTIMIZACIÓN: Usar tabla video_offsets
    mov bx, dx
    shl bx, 1
    mov bp, [video_offsets + bx]
    mov ax, cx
    shr ax, 3
    add bp, ax
    add bp, temp_offset
    
    mov bx, di              ; BX = datos
    ; SI = máscara
    
    ; ===== PLANO 0 =====
    mov dx, 3CEh
    mov al, 4
    out dx, al
    inc dx
    xor al, al
    out dx, al
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    
    push bp
    push bx
    push si
    
    ; ✅ Desenrollar: 4 filas por iteración (32/4 = 8 iteraciones)
    mov cx, 8
    
dsp32_p0_loop:
    mov di, bp
    
    ; Fila 1 - 4 bytes
    mov ah, [si]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+1]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+1]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    mov ah, [si+2]
    mov al, ah
    not al
    and al, es:[di+2]
    mov dl, [bx+2]
    and dl, ah
    or al, dl
    mov es:[di+2], al
    
    mov ah, [si+3]
    mov al, ah
    not al
    and al, es:[di+3]
    mov dl, [bx+3]
    and dl, ah
    or al, dl
    mov es:[di+3], al
    
    ; Fila 2 - 4 bytes
    add di, 80
    mov ah, [si+4]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+4]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+5]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+5]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    mov ah, [si+6]
    mov al, ah
    not al
    and al, es:[di+2]
    mov dl, [bx+6]
    and dl, ah
    or al, dl
    mov es:[di+2], al
    
    mov ah, [si+7]
    mov al, ah
    not al
    and al, es:[di+3]
    mov dl, [bx+7]
    and dl, ah
    or al, dl
    mov es:[di+3], al
    
    ; Fila 3 - 4 bytes
    add di, 80
    mov ah, [si+8]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+8]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+9]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+9]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    mov ah, [si+10]
    mov al, ah
    not al
    and al, es:[di+2]
    mov dl, [bx+10]
    and dl, ah
    or al, dl
    mov es:[di+2], al
    
    mov ah, [si+11]
    mov al, ah
    not al
    and al, es:[di+3]
    mov dl, [bx+11]
    and dl, ah
    or al, dl
    mov es:[di+3], al
    
    ; Fila 4 - 4 bytes
    add di, 80
    mov ah, [si+12]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+12]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+13]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+13]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    mov ah, [si+14]
    mov al, ah
    not al
    and al, es:[di+2]
    mov dl, [bx+14]
    and dl, ah
    or al, dl
    mov es:[di+2], al
    
    mov ah, [si+15]
    mov al, ah
    not al
    and al, es:[di+3]
    mov dl, [bx+15]
    and dl, ah
    or al, dl
    mov es:[di+3], al
    
    add bp, 320             ; 80 * 4 filas
    add si, 16              ; 4 bytes * 4 filas
    add bx, 16
    dec cx
    jz dsp32_p0_done
    jmp dsp32_p0_loop

dsp32_p0_done:
    pop si
    pop bx
    pop bp
    
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
    
    push bp
    push bx
    push si
    mov cx, 8
    
dsp32_p1_loop:
    mov di, bp
    
    ; Fila 1
    mov ah, [si]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+128]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+1]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+129]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    mov ah, [si+2]
    mov al, ah
    not al
    and al, es:[di+2]
    mov dl, [bx+130]
    and dl, ah
    or al, dl
    mov es:[di+2], al
    
    mov ah, [si+3]
    mov al, ah
    not al
    and al, es:[di+3]
    mov dl, [bx+131]
    and dl, ah
    or al, dl
    mov es:[di+3], al
    
    ; Fila 2
    add di, 80
    mov ah, [si+4]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+132]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+5]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+133]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    mov ah, [si+6]
    mov al, ah
    not al
    and al, es:[di+2]
    mov dl, [bx+134]
    and dl, ah
    or al, dl
    mov es:[di+2], al
    
    mov ah, [si+7]
    mov al, ah
    not al
    and al, es:[di+3]
    mov dl, [bx+135]
    and dl, ah
    or al, dl
    mov es:[di+3], al
    
    ; Fila 3
    add di, 80
    mov ah, [si+8]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+136]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+9]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+137]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    mov ah, [si+10]
    mov al, ah
    not al
    and al, es:[di+2]
    mov dl, [bx+138]
    and dl, ah
    or al, dl
    mov es:[di+2], al
    
    mov ah, [si+11]
    mov al, ah
    not al
    and al, es:[di+3]
    mov dl, [bx+139]
    and dl, ah
    or al, dl
    mov es:[di+3], al
    
    ; Fila 4
    add di, 80
    mov ah, [si+12]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+140]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+13]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+141]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    mov ah, [si+14]
    mov al, ah
    not al
    and al, es:[di+2]
    mov dl, [bx+142]
    and dl, ah
    or al, dl
    mov es:[di+2], al
    
    mov ah, [si+15]
    mov al, ah
    not al
    and al, es:[di+3]
    mov dl, [bx+143]
    and dl, ah
    or al, dl
    mov es:[di+3], al
    
    add bp, 320
    add si, 16
    add bx, 16
    dec cx
    jz dsp32_p1_done
    jmp dsp32_p1_loop

dsp32_p1_done:
    pop si
    pop bx
    pop bp
    
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
    
    push bp
    push bx
    push si
    mov cx, 8
    
dsp32_p2_loop:
    mov di, bp
    
    ; Fila 1
    mov ah, [si]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+256]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+1]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+257]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    mov ah, [si+2]
    mov al, ah
    not al
    and al, es:[di+2]
    mov dl, [bx+258]
    and dl, ah
    or al, dl
    mov es:[di+2], al
    
    mov ah, [si+3]
    mov al, ah
    not al
    and al, es:[di+3]
    mov dl, [bx+259]
    and dl, ah
    or al, dl
    mov es:[di+3], al
    
    ; Fila 2
    add di, 80
    mov ah, [si+4]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+260]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+5]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+261]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    mov ah, [si+6]
    mov al, ah
    not al
    and al, es:[di+2]
    mov dl, [bx+262]
    and dl, ah
    or al, dl
    mov es:[di+2], al
    
    mov ah, [si+7]
    mov al, ah
    not al
    and al, es:[di+3]
    mov dl, [bx+263]
    and dl, ah
    or al, dl
    mov es:[di+3], al
    
    ; Fila 3
    add di, 80
    mov ah, [si+8]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+264]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+9]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+265]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    mov ah, [si+10]
    mov al, ah
    not al
    and al, es:[di+2]
    mov dl, [bx+266]
    and dl, ah
    or al, dl
    mov es:[di+2], al
    
    mov ah, [si+11]
    mov al, ah
    not al
    and al, es:[di+3]
    mov dl, [bx+267]
    and dl, ah
    or al, dl
    mov es:[di+3], al
    
    ; Fila 4
    add di, 80
    mov ah, [si+12]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+268]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+13]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+269]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    mov ah, [si+14]
    mov al, ah
    not al
    and al, es:[di+2]
    mov dl, [bx+270]
    and dl, ah
    or al, dl
    mov es:[di+2], al
    
    mov ah, [si+15]
    mov al, ah
    not al
    and al, es:[di+3]
    mov dl, [bx+271]
    and dl, ah
    or al, dl
    mov es:[di+3], al
    
    add bp, 320
    add si, 16
    add bx, 16
    dec cx
    jz dsp32_p2_done
    jmp dsp32_p2_loop

dsp32_p2_done:
    pop si
    pop bx
    pop bp
    
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
    
    mov cx, 8
    
dsp32_p3_loop:
    mov di, bp
    
    ; Fila 1
    mov ah, [si]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+384]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+1]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+385]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    mov ah, [si+2]
    mov al, ah
    not al
    and al, es:[di+2]
    mov dl, [bx+386]
    and dl, ah
    or al, dl
    mov es:[di+2], al
    
    mov ah, [si+3]
    mov al, ah
    not al
    and al, es:[di+3]
    mov dl, [bx+387]
    and dl, ah
    or al, dl
    mov es:[di+3], al
    
    ; Fila 2
    add di, 80
    mov ah, [si+4]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+388]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+5]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+389]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    mov ah, [si+6]
    mov al, ah
    not al
    and al, es:[di+2]
    mov dl, [bx+390]
    and dl, ah
    or al, dl
    mov es:[di+2], al
    
    mov ah, [si+7]
    mov al, ah
    not al
    and al, es:[di+3]
    mov dl, [bx+391]
    and dl, ah
    or al, dl
    mov es:[di+3], al
    
    ; Fila 3
    add di, 80
    mov ah, [si+8]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+392]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+9]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+393]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    mov ah, [si+10]
    mov al, ah
    not al
    and al, es:[di+2]
    mov dl, [bx+394]
    and dl, ah
    or al, dl
    mov es:[di+2], al
    
    mov ah, [si+11]
    mov al, ah
    not al
    and al, es:[di+3]
    mov dl, [bx+395]
    and dl, ah
    or al, dl
    mov es:[di+3], al
    
    ; Fila 4
    add di, 80
    mov ah, [si+12]
    mov al, ah
    not al
    and al, es:[di]
    mov dl, [bx+396]
    and dl, ah
    or al, dl
    mov es:[di], al
    
    mov ah, [si+13]
    mov al, ah
    not al
    and al, es:[di+1]
    mov dl, [bx+397]
    and dl, ah
    or al, dl
    mov es:[di+1], al
    
    mov ah, [si+14]
    mov al, ah
    not al
    and al, es:[di+2]
    mov dl, [bx+398]
    and dl, ah
    or al, dl
    mov es:[di+2], al
    
    mov ah, [si+15]
    mov al, ah
    not al
    and al, es:[di+3]
    mov dl, [bx+399]
    and dl, ah
    or al, dl
    mov es:[di+3], al
    
    add bp, 320
    add si, 16
    add bx, 16
    dec cx
    jz dsp32_p3_done
    jmp dsp32_p3_loop

dsp32_p3_done:
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

; ============================================
; SCROLL SUAVE - AJUSTE DE PÍXELES
; ============================================
aplicar_scroll_hardware PROC
    push ax
    push dx
    
    ; Calcular offset de scroll en píxeles
    mov ax, camara_px
    and ax, 15              ; Solo los últimos 4 bits (0-15 píxeles)
    mov scroll_offset_x, ax
    
    mov ax, camara_py
    and ax, 15
    mov scroll_offset_y, ax
    
    ; ✅ NOTA: EGA no tiene scroll por píxel en hardware
    ; Se implementa ajustando las coordenadas de dibujo
    
    pop dx
    pop ax
    ret
aplicar_scroll_hardware ENDP

; ============================================
; CENTRAR CÁMARA CON SCROLL SUAVE
; ============================================
centrar_camara_suave PROC
    push ax
    push bx
    
    ; NO alinear a múltiplos de 16 para scroll suave
    mov ax, jugador_px
    sub ax, 160
    jge ccs_x_pos
    xor ax, ax
ccs_x_pos:
    cmp ax, 1280
    jle ccs_x_ok
    mov ax, 1280
ccs_x_ok:
    mov camara_px, ax
    
    mov ax, jugador_py
    sub ax, 96
    jge ccs_y_pos
    xor ax, ax
ccs_y_pos:
    cmp ax, 1408
    jle ccs_y_ok
    mov ax, 1408
ccs_y_ok:
    mov camara_py, ax
    
    ; Calcular offsets de sub-píxel
    call aplicar_scroll_hardware
    
    pop bx
    pop ax
    ret
centrar_camara_suave ENDP

pantalla_victoria PROC
    push ax
    push dx
    push si
    
    ; Limpiar pantalla
    mov ax, VIDEO_SEG
    mov es, ax
    xor di, di
    mov cx, 28000
    xor ax, ax
    rep stosw
    
    ; Dibujar mensaje de victoria centrado
    mov cx, 240
    mov dx, 150
    
    ; Dibujar rectángulo de fondo
    mov ax, 160
    mov bx, 50
    mov si, COLOR_BARRA_LLENA
    call dibujar_rectangulo_lleno
    
    ; TODO: Dibujar texto "¡FELICIDADES!"
    ; (Por ahora solo el fondo)
    
    ; Esperar tecla
    mov ah, 0
    int 16h
    
    pop si
    pop dx
    pop ax
    ret
pantalla_victoria ENDP