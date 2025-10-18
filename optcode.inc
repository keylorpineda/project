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
    
    ; Calcular offset de video
    mov ax, dx
    mov bx, 80
    mul bx
    mov si, ax
    mov ax, cx
    shr ax, 3
    add si, ax
    
    ; BX = datos planar, BP = máscaras
    mov bx, di
    push bp
    
    mov cx, 16

dsp16o_fila:
    push cx
    push si
    push bx
    push bp                ; ✅ REPARADO: Guardar BP
    mov bp, sp             ; ✅ REPARADO: BP ahora apunta al marco de la pila
    
    ; Stack: [bp] [bx] [si] [cx] [mask_ptr] ...
    ; bp+2 -> bx
    ; bp+4 -> si
    ; bp+6 -> cx
    ; bp+8 -> mask_ptr (¡este es el que queremos!)
    
    mov di, [bp+8]         ; ✅ REPARADO: Usar [bp+8] en lugar de [sp+8]
    
    ; BYTE 0
    mov ah, [di]
    
    ; Plano 0
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
    pop si
    push si
    mov cl, ah
    not cl
    mov al, es:[si]
    and al, cl
    mov cl, ah
    pop bx
    push bx
    mov ch, [bx]
    and ch, cl
    or al, ch
    pop si
    push si
    mov es:[si], al
    
    ; Plano 1
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
    pop si
    push si
    mov cl, ah
    not cl
    mov al, es:[si]
    and al, cl
    mov cl, ah
    pop bx
    push bx
    mov ch, [bx+32]
    and ch, cl
    or al, ch
    pop si
    push si
    mov es:[si], al
    
    ; Plano 2
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
    pop si
    push si
    mov cl, ah
    not cl
    mov al, es:[si]
    and al, cl
    mov cl, ah
    pop bx
    push bx
    mov ch, [bx+64]
    and ch, cl
    or al, ch
    pop si
    push si
    mov es:[si], al
    
    ; Plano 3
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
    pop si
    push si
    mov cl, ah
    not cl
    mov al, es:[si]
    and al, cl
    mov cl, ah
    pop bx
    push bx
    mov ch, [bx+96]
    and ch, cl
    or al, ch
    pop si
    push si
    mov es:[si], al
    
    ; BYTE 1
    mov di, [bp+8]         ; ✅ REPARADO: Usar [bp+8] en lugar de [sp+8]
    mov ah, [di+1]
    
    ; Plano 0
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
    pop si
    push si
    inc si
    mov cl, ah
    not cl
    mov al, es:[si]
    and al, cl
    mov cl, ah
    pop bx
    push bx
    mov ch, [bx+1]
    and ch, cl
    or al, ch
    mov es:[si], al
    
    ; Plano 1
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
    pop si
    push si
    inc si
    mov cl, ah
    not cl
    mov al, es:[si]
    and al, cl
    mov cl, ah
    pop bx
    push bx
    mov ch, [bx+33]
    and ch, cl
    or al, ch
    mov es:[si], al
    
    ; Plano 2
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
    pop si
    push si
    inc si
    mov cl, ah
    not cl
    mov al, es:[si]
    and al, cl
    mov cl, ah
    pop bx
    push bx
    mov ch, [bx+65]
    and ch, cl
    or al, ch
    mov es:[si], al
    
    ; Plano 3
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
    pop si
    push si
    inc si
    mov cl, ah
    not cl
    mov al, es:[si]
    and al, cl
    mov cl, ah
    pop bx
    push bx
    mov ch, [bx+97]
    and ch, cl
    or al, ch
    mov es:[si], al
    
    ; Siguiente fila
    add WORD PTR [bp+8], 2    ; ✅ REPARADO: Usar [bp+8] en lugar de [sp+6]
    pop bp                    ; ✅ REPARADO: Restaurar BP
    pop bx
    add bx, 2
    pop si
    add si, 80
    pop cx
    ; loop dsp16o_fila        ; <-- Original (Error)
    dec cx                    ; ✅ REPARADO: Reemplazo de LOOP
    jz  dsp16o_fin_loop       ; ✅ Alternativa: evita "out of range"
    jmp NEAR PTR dsp16o_fila  ; ✅ Salto incondicional con desplazamiento de 16 bits
dsp16o_fin_loop:
    
    pop bp
    
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
    
    mov ax, dx
    mov bx, 80
    mul bx
    mov si, ax
    mov ax, cx
    shr ax, 3
    add si, ax
    
    mov bx, di
    push bp
    
    mov cx, 32

dsp32o_fila:
    push cx
    push si
    push bx
    push bp                ; ✅ REPARADO: Guardar BP
    mov bp, sp             ; ✅ REPARADO: BP ahora apunta al marco de la pila
                           ; bp+8 apunta al mask_ptr
    
    mov di, [bp+8]         ; ✅ REPARADO: Usar [bp+8]
    
    ; BYTE 0
    mov ah, [di]
    
    ; Plano 0
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
    pop si
    push si
    mov cl, ah
    not cl
    mov al, es:[si]
    and al, cl
    mov cl, ah
    pop bx
    push bx
    mov ch, [bx]
    and ch, cl
    or al, ch
    pop si
    push si
    mov es:[si], al
    
    ; Plano 1
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
    pop si
    push si
    mov cl, ah
    not cl
    mov al, es:[si]
    and al, cl
    mov cl, ah
    pop bx
    push bx
    mov ch, [bx+128]
    and ch, cl
    or al, ch
    pop si
    push si
    mov es:[si], al
    
    ; Plano 2
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
    pop si
    push si
    mov cl, ah
    not cl
    mov al, es:[si]
    and al, cl
    mov cl, ah
    pop bx
    push bx
    mov ch, [bx+256]
    and ch, cl
    or al, ch
    pop si
    push si
    mov es:[si], al
    
    ; Plano 3
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
    pop si
    push si
    mov cl, ah
    not cl
    mov al, es:[si]
    and al, cl
    mov cl, ah
    pop bx
    push bx
    mov ch, [bx+384]
    and ch, cl
    or al, ch
    pop si
    push si
    mov es:[si], al
    
    ; BYTE 1
    mov di, [bp+8]         ; ✅ REPARADO: Usar [bp+8]
    mov ah, [di+1]
    
    pop si
    push si
    inc si
    
    ; Plano 0
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
    mov cl, ah
    not cl
    mov al, es:[si]
    and al, cl
    mov cl, ah
    pop bx
    push bx
    mov ch, [bx+1]
    and ch, cl
    or al, ch
    mov es:[si], al
    
    ; Plano 1
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
    mov cl, ah
    not cl
    mov al, es:[si]
    and al, cl
    mov cl, ah
    pop bx
    push bx
    mov ch, [bx+129]
    and ch, cl
    or al, ch
    mov es:[si], al
    
    ; Plano 2
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
    mov cl, ah
    not cl
    mov al, es:[si]
    and al, cl
    mov cl, ah
    pop bx
    push bx
    mov ch, [bx+257]
    and ch, cl
    or al, ch
    mov es:[si], al
    
    ; Plano 3
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
    mov cl, ah
    not cl
    mov al, es:[si]
    and al, cl
    mov cl, ah
    pop bx
    push bx
    mov ch, [bx+385]
    and ch, cl
    or al, ch
    mov es:[si], al
    
    ; BYTE 2
    mov di, [bp+8]         ; ✅ REPARADO: Usar [bp+8]
    mov ah, [di+2]
    
    pop si
    push si
    add si, 2
    
    ; Plano 0
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
    mov cl, ah
    not cl
    mov al, es:[si]
    and al, cl
    mov cl, ah
    pop bx
    push bx
    mov ch, [bx+2]
    and ch, cl
    or al, ch
    mov es:[si], al
    
    ; Plano 1
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
    mov cl, ah
    not cl
    mov al, es:[si]
    and al, cl
    mov cl, ah
    pop bx
    push bx
    mov ch, [bx+130]
    and ch, cl
    or al, ch
    mov es:[si], al
    
    ; Plano 2
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
    mov cl, ah
    not cl
    mov al, es:[si]
    and al, cl
    mov cl, ah
    pop bx
    push bx
    mov ch, [bx+258]
    and ch, cl
    or al, ch
    mov es:[si], al
    
    ; Plano 3
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
    mov cl, ah
    not cl
    mov al, es:[si]
    and al, cl
    mov cl, ah
    pop bx
    push bx
    mov ch, [bx+386]
    and ch, cl
    or al, ch
    mov es:[si], al
    
    ; BYTE 3
    mov di, [bp+8]         ; ✅ REPARADO: Usar [bp+8]
    mov ah, [di+3]
    
    pop si
    push si
    add si, 3
    
    ; Plano 0
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
    mov cl, ah
    not cl
    mov al, es:[si]
    and al, cl
    mov cl, ah
    pop bx
    push bx
    mov ch, [bx+3]
    and ch, cl
    or al, ch
    mov es:[si], al
    
    ; Plano 1
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
    mov cl, ah
    not cl
    mov al, es:[si]
    and al, cl
    mov cl, ah
    pop bx
    push bx
    mov ch, [bx+131]
    and ch, cl
    or al, ch
    mov es:[si], al
    
    ; Plano 2
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
    mov cl, ah
    not cl
    mov al, es:[si]
    and al, cl
    mov cl, ah
    pop bx
    push bx
    mov ch, [bx+259]
    and ch, cl
    or al, ch
    mov es:[si], al
    
    ; Plano 3
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
    mov cl, ah
    not cl
    mov al, es:[si]
    and al, cl
    mov cl, ah
    pop bx
    push bx
    mov ch, [bx+387]
    and ch, cl
    or al, ch
    mov es:[si], al
    
    ; Siguiente fila
    add WORD PTR [bp+8], 4    ; ✅ REPARADO: Usar [bp+8]
    pop bp                    ; ✅ REPARADO: Restaurar BP
    pop bx
    add bx, 4
    pop si
    add si, 80
    pop cx
    ; loop dsp32o_fila        ; <-- Original (Error)
    dec cx                    ; ✅ REPARADO: Reemplazo de LOOP largo
    jz dsp32o_fin_loop        ; ✅ REPARADO: Salir si CX=0
    jmp dsp32o_fila           ; ✅ REPARADO: JMP NEAR de vuelta
dsp32o_fin_loop:                ; ✅ REPARADO: Etiqueta de salida del bucle
    
    pop bp
    
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