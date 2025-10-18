; ============================================
; OPTCODE.INC - SISTEMA PLANAR REPARADO
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
; CONVERSIÓN PLANAR REPARADA - 16x16
; ============================================
convertir_sprite_a_planar_opt PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    mov cx, 16          ; 16 filas
    
cspo_fila:
    push cx
    
    ; Limpiar acumuladores
    xor bx, bx          ; BH/BL = planos 3/2
    xor dx, dx          ; DH/DL = planos 1/0
    
    ; ===== BYTE IZQUIERDO (pixeles 0-7) =====
    mov cx, 8
    
cspo_byte_izq:
    lodsb               ; Leer píxel
    
    ; Construir bits MSB-first
    shl dl, 1           ; Plano 0
    shl dh, 1           ; Plano 1
    shl bl, 1           ; Plano 2
    shl bh, 1           ; Plano 3
    
    ; Extraer bits del color
    test al, 01h
    jz cspo_izq_b1
    or dl, 1
cspo_izq_b1:
    test al, 02h
    jz cspo_izq_b2
    or dh, 1
cspo_izq_b2:
    test al, 04h
    jz cspo_izq_b3
    or bl, 1
cspo_izq_b3:
    test al, 08h
    jz cspo_izq_next
    or bh, 1
cspo_izq_next:
    loop cspo_byte_izq
    
    ; Guardar byte izquierdo
    mov [di], dl        ; Plano 0
    mov [di+32], dh     ; Plano 1
    mov [di+64], bl     ; Plano 2
    mov [di+96], bh     ; Plano 3
    
    ; Generar máscara (1 donde hay píxel, 0 transparente)
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    mov [bp], al
    
    ; ===== BYTE DERECHO (pixeles 8-15) =====
    xor bx, bx
    xor dx, dx
    mov cx, 8
    
cspo_byte_der:
    lodsb
    
    shl dl, 1
    shl dh, 1
    shl bl, 1
    shl bh, 1
    
    test al, 01h
    jz cspo_der_b1
    or dl, 1
cspo_der_b1:
    test al, 02h
    jz cspo_der_b2
    or dh, 1
cspo_der_b2:
    test al, 04h
    jz cspo_der_b3
    or bl, 1
cspo_der_b3:
    test al, 08h
    jz cspo_der_next
    or bh, 1
cspo_der_next:
    loop cspo_byte_der
    
    ; Guardar byte derecho
    mov [di+1], dl
    mov [di+33], dh
    mov [di+65], bl
    mov [di+97], bh
    
    ; Generar máscara
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

; ============================================
; CONVERSIÓN PLANAR REPARADA - 32x32
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
    
    ; ===== BYTE 0 (pixeles 0-7) =====
    xor bx, bx
    xor dx, dx
    mov cx, 8
    
csp32_b0:
    lodsb
    shl dl, 1
    shl dh, 1
    shl bl, 1
    shl bh, 1
    test al, 01h
    jz csp32_b0_1
    or dl, 1
csp32_b0_1:
    test al, 02h
    jz csp32_b0_2
    or dh, 1
csp32_b0_2:
    test al, 04h
    jz csp32_b0_3
    or bl, 1
csp32_b0_3:
    test al, 08h
    jz csp32_b0_next
    or bh, 1
csp32_b0_next:
    loop csp32_b0
    
    mov [di], dl
    mov [di+128], dh
    mov [di+256], bl
    mov [di+384], bh
    
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    mov [bp], al
    
    ; ===== BYTE 1 (pixeles 8-15) =====
    xor bx, bx
    xor dx, dx
    mov cx, 8
    
csp32_b1:
    lodsb
    shl dl, 1
    shl dh, 1
    shl bl, 1
    shl bh, 1
    test al, 01h
    jz csp32_b1_1
    or dl, 1
csp32_b1_1:
    test al, 02h
    jz csp32_b1_2
    or dh, 1
csp32_b1_2:
    test al, 04h
    jz csp32_b1_3
    or bl, 1
csp32_b1_3:
    test al, 08h
    jz csp32_b1_next
    or bh, 1
csp32_b1_next:
    loop csp32_b1
    
    mov [di+1], dl
    mov [di+129], dh
    mov [di+257], bl
    mov [di+385], bh
    
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    mov [bp+1], al
    
    ; ===== BYTE 2 (pixeles 16-23) =====
    xor bx, bx
    xor dx, dx
    mov cx, 8
    
csp32_b2:
    lodsb
    shl dl, 1
    shl dh, 1
    shl bl, 1
    shl bh, 1
    test al, 01h
    jz csp32_b2_1
    or dl, 1
csp32_b2_1:
    test al, 02h
    jz csp32_b2_2
    or dh, 1
csp32_b2_2:
    test al, 04h
    jz csp32_b2_3
    or bl, 1
csp32_b2_3:
    test al, 08h
    jz csp32_b2_next
    or bh, 1
csp32_b2_next:
    loop csp32_b2
    
    mov [di+2], dl
    mov [di+130], dh
    mov [di+258], bl
    mov [di+386], bh
    
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    mov [bp+2], al
    
    ; ===== BYTE 3 (pixeles 24-31) =====
    xor bx, bx
    xor dx, dx
    mov cx, 8
    
csp32_b3:
    lodsb
    shl dl, 1
    shl dh, 1
    shl bl, 1
    shl bh, 1
    test al, 01h
    jz csp32_b3_1
    or dl, 1
csp32_b3_1:
    test al, 02h
    jz csp32_b3_2
    or dh, 1
csp32_b3_2:
    test al, 04h
    jz csp32_b3_3
    or bl, 1
csp32_b3_3:
    test al, 08h
    jz csp32_b3_next
    or bh, 1
csp32_b3_next:
    loop csp32_b3
    
    mov [di+3], dl
    mov [di+131], dh
    mov [di+259], bl
    mov [di+387], bh
    
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    mov [bp+3], al
    
    ; Siguiente fila
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
; DIBUJADO CON MÁSCARAS - 16x16
; ============================================
dibujar_sprite_planar_16x16_opt PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    ; Calcular offset
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
    
    mov bx, di          ; BX = datos planares
    
    ; ===== BYTE 0 - Todos los planos =====
    ; Plano 0
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    
    mov al, [si]        ; Máscara
    test al, al
    jz dsp16_byte0_p1
    
    mov al, [bx]        ; Datos
    mov es:[bp], al
    
dsp16_byte0_p1:
    ; Plano 1
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    
    mov al, [si]
    test al, al
    jz dsp16_byte0_p2
    
    mov al, [bx+32]
    mov es:[bp], al
    
dsp16_byte0_p2:
    ; Plano 2
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 4
    out dx, al
    
    mov al, [si]
    test al, al
    jz dsp16_byte0_p3
    
    mov al, [bx+64]
    mov es:[bp], al
    
dsp16_byte0_p3:
    ; Plano 3
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 8
    out dx, al
    
    mov al, [si]
    test al, al
    jz dsp16_byte1
    
    mov al, [bx+96]
    mov es:[bp], al
    
    ; ===== BYTE 1 - Todos los planos =====
dsp16_byte1:
    ; Plano 0
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    
    mov al, [si+1]
    test al, al
    jz dsp16_byte1_p1
    
    mov al, [bx+1]
    mov es:[bp+1], al
    
dsp16_byte1_p1:
    ; Plano 1
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    
    mov al, [si+1]
    test al, al
    jz dsp16_byte1_p2
    
    mov al, [bx+33]
    mov es:[bp+1], al
    
dsp16_byte1_p2:
    ; Plano 2
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 4
    out dx, al
    
    mov al, [si+1]
    test al, al
    jz dsp16_byte1_p3
    
    mov al, [bx+65]
    mov es:[bp+1], al
    
dsp16_byte1_p3:
    ; Plano 3
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 8
    out dx, al
    
    mov al, [si+1]
    test al, al
    jz dsp16_next_fila
    
    mov al, [bx+97]
    mov es:[bp+1], al
    
dsp16_next_fila:
    pop bp
    add bp, 80
    pop si
    add si, 2
    pop di
    add di, 2
    pop cx
    dec cx
    jz dsp16_end
    jmp dsp16_fila

dsp16_end:
    
    ; Restaurar
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
; DIBUJADO CON MÁSCARAS - 32x32
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
    
    mov bx, di
    
    ; ===== BYTE 0 =====
    ; Plano 0
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    
    mov al, [si]
    test al, al
    jz dsp32_b0_p1
    mov al, [bx]
    mov es:[bp], al
    
dsp32_b0_p1:
    ; Plano 1
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    
    mov al, [si]
    test al, al
    jz dsp32_b0_p2
    mov al, [bx+128]
    mov es:[bp], al
    
dsp32_b0_p2:
    ; Plano 2
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 4
    out dx, al
    
    mov al, [si]
    test al, al
    jz dsp32_b0_p3
    mov al, [bx+256]
    mov es:[bp], al
    
dsp32_b0_p3:
    ; Plano 3
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 8
    out dx, al
    
    mov al, [si]
    test al, al
    jz dsp32_b1
    mov al, [bx+384]
    mov es:[bp], al
    
    ; ===== BYTE 1 =====
dsp32_b1:
    ; Plano 0
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    
    mov al, [si+1]
    test al, al
    jz dsp32_b1_p1
    mov al, [bx+1]
    mov es:[bp+1], al
    
dsp32_b1_p1:
    ; Plano 1
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    
    mov al, [si+1]
    test al, al
    jz dsp32_b1_p2
    mov al, [bx+129]
    mov es:[bp+1], al
    
dsp32_b1_p2:
    ; Plano 2
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 4
    out dx, al
    
    mov al, [si+1]
    test al, al
    jz dsp32_b1_p3
    mov al, [bx+257]
    mov es:[bp+1], al
    
dsp32_b1_p3:
    ; Plano 3
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 8
    out dx, al
    
    mov al, [si+1]
    test al, al
    jz dsp32_b2
    mov al, [bx+385]
    mov es:[bp+1], al
    
    ; ===== BYTE 2 =====
dsp32_b2:
    ; Plano 0
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    
    mov al, [si+2]
    test al, al
    jz dsp32_b2_p1
    mov al, [bx+2]
    mov es:[bp+2], al
    
dsp32_b2_p1:
    ; Plano 1
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    
    mov al, [si+2]
    test al, al
    jz dsp32_b2_p2
    mov al, [bx+130]
    mov es:[bp+2], al
    
dsp32_b2_p2:
    ; Plano 2
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 4
    out dx, al
    
    mov al, [si+2]
    test al, al
    jz dsp32_b2_p3
    mov al, [bx+258]
    mov es:[bp+2], al
    
dsp32_b2_p3:
    ; Plano 3
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 8
    out dx, al
    
    mov al, [si+2]
    test al, al
    jz dsp32_b3
    mov al, [bx+386]
    mov es:[bp+2], al
    
    ; ===== BYTE 3 =====
dsp32_b3:
    ; Plano 0
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 1
    out dx, al
    
    mov al, [si+3]
    test al, al
    jz dsp32_b3_p1
    mov al, [bx+3]
    mov es:[bp+3], al
    
dsp32_b3_p1:
    ; Plano 1
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 2
    out dx, al
    
    mov al, [si+3]
    test al, al
    jz dsp32_b3_p2
    mov al, [bx+131]
    mov es:[bp+3], al
    
dsp32_b3_p2:
    ; Plano 2
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 4
    out dx, al
    
    mov al, [si+3]
    test al, al
    jz dsp32_b3_p3
    mov al, [bx+259]
    mov es:[bp+3], al
    
dsp32_b3_p3:
    ; Plano 3
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 8
    out dx, al
    
    mov al, [si+3]
    test al, al
    jz dsp32_next_fila
    mov al, [bx+387]
    mov es:[bp+3], al
    
dsp32_next_fila:
    pop bp
    add bp, 80
    pop si
    add si, 4
    pop di
    add di, 4
    pop cx
    dec cx
    jz dsp32_end
    jmp dsp32_fila

dsp32_end:
    
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