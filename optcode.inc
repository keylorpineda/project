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
    
    mov cx, 16          ; 16 filas
    
cspo_fila:
    push cx
    
    ; ===== BYTE IZQUIERDO (pixeles 0-7) =====
    xor bx, bx          ; BH/BL = planos 3/2
    xor dx, dx          ; DH/DL = planos 1/0
    
    mov cx, 8
    
cspo_byte_izq:
    lodsb               ; Leer píxel
    
    ; Rotar LEFT para MSB-first
    rol dl, 1           ; Plano 0
    rol dh, 1           ; Plano 1
    rol bl, 1           ; Plano 2
    rol bh, 1           ; Plano 3
    
    ; Limpiar bits LSB antes de OR
    and dl, 0FEh
    and dh, 0FEh
    and bl, 0FEh
    and bh, 0FEh
    
    ; Extraer bits del color e insertar en LSB
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
    
    ; ===== GENERAR MÁSCARA BYTE IZQUIERDO =====
    ; Si todos los planos = 0, entonces color = 0 = transparente
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    ; AL = 0 si color es 0 (transparente)
    ; AL ≠ 0 si hay algún color (opaco)
    mov ah, al
    xor al, al          ; Asumir opaco (máscara = 0x00)
    test ah, ah
    jnz cspo_masc_izq
    mov al, 0FFh        ; Transparente (máscara = 0xFF)
cspo_masc_izq:
    mov [bp], al
    
    ; ===== BYTE DERECHO (pixeles 8-15) =====
    xor bx, bx
    xor dx, dx
    mov cx, 8
    
cspo_byte_der:
    lodsb
    
    rol dl, 1
    rol dh, 1
    rol bl, 1
    rol bh, 1
    
    and dl, 0FEh
    and dh, 0FEh
    and bl, 0FEh
    and bh, 0FEh
    
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
    
    ; ===== GENERAR MÁSCARA BYTE DERECHO =====
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    mov ah, al
    xor al, al
    test ah, ah
    jnz cspo_masc_der
    mov al, 0FFh
cspo_masc_der:
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
    
    ; ===== BYTE 0 (pixeles 0-7) =====
    xor bx, bx
    xor dx, dx
    mov cx, 8
    
csp32_b0:
    lodsb
    rol dl, 1
    rol dh, 1
    rol bl, 1
    rol bh, 1
    and dl, 0FEh
    and dh, 0FEh
    and bl, 0FEh
    and bh, 0FEh
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
    
    ; Máscara byte 0
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    mov ah, al
    xor al, al
    test ah, ah
    jnz csp32_m0
    mov al, 0FFh
csp32_m0:
    mov [bp], al
    
    ; ===== BYTE 1 (pixeles 8-15) =====
    xor bx, bx
    xor dx, dx
    mov cx, 8
    
csp32_b1:
    lodsb
    rol dl, 1
    rol dh, 1
    rol bl, 1
    rol bh, 1
    and dl, 0FEh
    and dh, 0FEh
    and bl, 0FEh
    and bh, 0FEh
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
    
    ; Máscara byte 1
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    mov ah, al
    xor al, al
    test ah, ah
    jnz csp32_m1
    mov al, 0FFh
csp32_m1:
    mov [bp+1], al
    
    ; ===== BYTE 2 (pixeles 16-23) =====
    xor bx, bx
    xor dx, dx
    mov cx, 8
    
csp32_b2:
    lodsb
    rol dl, 1
    rol dh, 1
    rol bl, 1
    rol bh, 1
    and dl, 0FEh
    and dh, 0FEh
    and bl, 0FEh
    and bh, 0FEh
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
    
    ; Máscara byte 2
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    mov ah, al
    xor al, al
    test ah, ah
    jnz csp32_m2
    mov al, 0FFh
csp32_m2:
    mov [bp+2], al
    
    ; ===== BYTE 3 (pixeles 24-31) =====
    xor bx, bx
    xor dx, dx
    mov cx, 8
    
csp32_b3:
    lodsb
    rol dl, 1
    rol dh, 1
    rol bl, 1
    rol bh, 1
    and dl, 0FEh
    and dh, 0FEh
    and bl, 0FEh
    and bh, 0FEh
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
    
    ; Máscara byte 3
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    mov ah, al
    xor al, al
    test ah, ah
    jnz csp32_m3
    mov al, 0FFh
csp32_m3:
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

dibujar_sprite_planar_16x16_opt PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    ; Calcular offset de video
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
    
    ; ===== BYTE 0 CON MÁSCARA =====
    mov al, [si]        ; Máscara byte 0
    not al              ; 1=dibujar, 0=skip
    test al, al
    jz dsp16_b0_skip
    
    ; Configurar máscara de bits
    mov dx, 3CEh
    mov ah, al
    mov al, 8
    out dx, al
    inc dx
    mov al, ah
    out dx, al
    
    ; Escribir todos los planos a la vez
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    
    mov al, es:[bp]     ; Leer (latch)
    mov bx, di
    mov al, [bx]        ; Dato - EGA mezcla con máscara
    mov es:[bp], al

dsp16_b0_skip:

    ; ===== BYTE 1 CON MÁSCARA =====
    mov al, [si+1]      ; Máscara byte 1
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

    ; Siguiente fila
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
    ; Restaurar registros de EGA
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
    
    ; ===== BYTE 0 CON MÁSCARA =====
    mov al, [si]        ; Máscara byte 0
    not al              ; 1=dibujar, 0=skip
    test al, al
    jz dsp32_b0_skip
    
    ; Configurar máscara de bits
    mov dx, 3CEh
    mov ah, al
    mov al, 8
    out dx, al
    inc dx
    mov al, ah
    out dx, al
    
    ; Escribir todos los planos a la vez
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    
    mov al, es:[bp]     ; Leer (latch)
    mov bx, di
    mov al, [bx]        ; Plano 0 - La EGA mezcla automáticamente
    mov es:[bp], al

dsp32_b0_skip:

    ; ===== BYTE 1 =====
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

    ; ===== BYTE 2 =====
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

    ; ===== BYTE 3 =====
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

    ; Siguiente fila
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
    ; Restaurar registros de EGA
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