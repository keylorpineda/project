; ============================================
; OPTCODE.INC - Motor grafico optimizado
; Universidad Nacional - Proyecto II Ciclo 2025
; ============================================

; Inicializar todas las tablas de optimizacion
inicializar_lookup_tables PROC
    call calcular_video_offsets
    call calcular_mul100_table
    call inicializar_walkable
    ret
inicializar_lookup_tables ENDP

; Calcular tabla de offsets de video (Y x 80)
calcular_video_offsets PROC
    push ax
    push cx
    push si
    
    xor ax, ax      ; Offset inicial = 0
    xor si, si      ; Indice en tabla = 0
    mov cx, 350     ; 350 filas
    
cvo_loop:
    mov [video_offsets + si], ax
    add ax, 80      ; Siguiente fila (+80 bytes)
    add si, 2       ; Siguiente entrada (word = 2 bytes)
    loop cvo_loop
    
    pop si
    pop cx
    pop ax
    ret
calcular_video_offsets ENDP

; Calcular tabla de multiplicacion por 100 (Y x 100)
calcular_mul100_table PROC
    push ax
    push cx
    push si
    
    xor ax, ax      ; Resultado inicial = 0
    xor si, si      ; Indice en tabla = 0
    mov cx, 100     ; 100 entradas
    
cm100_loop:
    mov [mul100_table + si], ax
    add ax, 100     ; Siguiente multiplo de 100
    add si, 2       ; Siguiente entrada (word = 2 bytes)
    loop cm100_loop
    
    pop si
    pop cx
    pop ax
    ret
calcular_mul100_table ENDP

; Inicializar tabla de transitabilidad
inicializar_walkable PROC
    push ax
    
    ; Por defecto todos son transitables (ya inicializado a 1)
    ; Solo marcar los NO transitables como 0
    mov byte ptr [tile_walkable + TILE_WATER], 0
    mov byte ptr [tile_walkable + TILE_TREE], 0
    mov byte ptr [tile_walkable + TILE_ROCK], 0
    mov byte ptr [tile_walkable + TILE_WALL], 0
    mov byte ptr [tile_walkable + TILE_LAVA], 0
    
    pop ax
    ret
inicializar_walkable ENDP

; ============================================
; FUNCIONES DE DIRTY RECTANGLES
; ============================================

; Marcar un tile como "sucio" (necesita redibujo)
; IN: CX = tile X, DX = tile Y
marcar_tile_sucio PROC
    push ax
    push bx
    
    ; Verificar limites
    cmp cx, 100
    jae mts_fin
    cmp dx, 100
    jae mts_fin
    
    ; Calcular indice: Y x 100 + X
    mov bx, dx
    shl bx, 1
    mov ax, [mul100_table + bx]
    add ax, cx
    mov bx, ax
    
    ; Marcar con numero de frame actual
    mov al, frame_counter
    mov [dirty_tiles + bx], al
    
mts_fin:
    pop bx
    pop ax
    ret
marcar_tile_sucio ENDP

; Marcar area alrededor del jugador como sucia
; Marca el tile del jugador + vecinos (9 tiles en total)
marcar_area_jugador_sucia PROC
    push ax
    push cx
    push dx
    
    ; Obtener tile del jugador
    mov ax, jugador_px
    shr ax, 4           ; Dividir por 16
    mov cx, ax          ; tile_x
    
    mov ax, jugador_py
    shr ax, 4
    mov dx, ax          ; tile_y
    
    ; Marcar tile central
    call marcar_tile_sucio
    
    ; Marcar vecinos (8 tiles alrededor)
    push cx
    push dx
    
    ; Arriba-izquierda
    dec cx
    dec dx
    call marcar_tile_sucio
    
    ; Arriba
    inc cx
    call marcar_tile_sucio
    
    ; Arriba-derecha
    inc cx
    call marcar_tile_sucio
    
    ; Derecha
    inc dx
    call marcar_tile_sucio
    
    ; Abajo-derecha
    inc dx
    call marcar_tile_sucio
    
    ; Abajo
    dec cx
    call marcar_tile_sucio
    
    ; Abajo-izquierda
    dec cx
    call marcar_tile_sucio
    
    ; Izquierda
    dec dx
    call marcar_tile_sucio
    
    pop dx
    pop cx
    
    pop dx
    pop cx
    pop ax
    ret
marcar_area_jugador_sucia ENDP

; Incrementar contador de frames (llamar al inicio de cada frame)
incrementar_frame_counter PROC
    inc frame_counter
    ret
incrementar_frame_counter ENDP

; ============================================
; VERIFICACION DE COLISIONES OPTIMIZADA
; ============================================

verificar_tile_transitable_opt PROC
    push ax
    push bx
    push dx
    
    ; Verificar limites del mapa
    cmp cx, 100
    jae vtt_no_transitable
    cmp dx, 100
    jae vtt_no_transitable
    
    ; Usar lookup table en lugar de MUL
    mov bx, dx
    shl bx, 1
    mov ax, [mul100_table + bx]
    add ax, cx
    mov bx, ax
    
    ; Obtener tipo de tile
    mov al, [mapa_datos + bx]
    
    ; Usar lookup table en lugar de comparaciones
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
    push cx             ; Solo guardar el contador
    
    ; ===== BYTE IZQUIERDO (pixeles 0-7) =====
    xor bx, bx
    xor dx, dx
    mov cx, 8
    
cspo_byte_izq:
    lodsb               ; SI se auto-incrementa
    shl dl, 1
    shl dh, 1
    shl bl, 1
    shl bh, 1
    
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
    
    ; Guardar byte izquierdo en los 4 planos
    mov [di], dl        ; Plano 0
    mov [di+32], dh     ; Plano 1
    mov [di+64], bl     ; Plano 2
    mov [di+96], bh     ; Plano 3
    
    ; Calcular máscara para este byte
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
    lodsb               ; SI se auto-incrementa
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
    mov [di+1], dl      ; Plano 0
    mov [di+33], dh     ; Plano 1
    mov [di+65], bl     ; Plano 2
    mov [di+97], bh     ; Plano 3
    
    ; Calcular máscara para este byte
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    mov [bp+1], al
    
    ; Avanzar punteros para la siguiente fila
    add di, 2           ; Siguiente fila planar (2 bytes)
    add bp, 2           ; Siguiente fila de máscaras (2 bytes)
    
    pop cx              ; Recuperar contador de filas
    dec cx              ; ✅ CAMBIO: Decrementar manualmente
    jz cspo_fin         ; ✅ CAMBIO: Terminar cuando CX llegue a cero
    jmp cspo_fila       ; ✅ CAMBIO: Continuar procesando filas restantes

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
; CONVERSION CON PRE-MASCARAS (32x32)
; ============================================

; Convertir sprite 32x32 a planar Y generar mascaras
; IN: SI = fuente (datos lineales), DI = destino (planar), BP = destino mascaras
convertir_sprite_32x32_a_planar_opt PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    mov cx, 32          ; 32 filas
    
csp32o_fila:
    push cx
    
    ; ===== BYTE 0 (pixeles 0-7) =====
    push bp
    xor bx, bx
    xor dx, dx
    mov cx, 8
    
csp32o_byte0:
    lodsb
    shl dl, 1
    shl dh, 1
    shl bl, 1
    shl bh, 1
    test al, 01h
    jz csp32o_b0_p0
    or dl, 1
csp32o_b0_p0:
    test al, 02h
    jz csp32o_b0_p1
    or dh, 1
csp32o_b0_p1:
    test al, 04h
    jz csp32o_b0_p2
    or bl, 1
csp32o_b0_p2:
    test al, 08h
    jz csp32o_b0_p3
    or bh, 1
csp32o_b0_p3:
    loop csp32o_byte0
    
    mov [di], dl
    mov [di+128], dh
    mov [di+256], bl
    mov [di+384], bh
    
    ; Calcular mascara
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    pop bp
    mov [bp], al
    inc bp
    push bp
    inc di
    
    ; ===== BYTE 1 (pixeles 8-15) =====
    xor bx, bx
    xor dx, dx
    mov cx, 8
    
csp32o_byte1:
    lodsb
    shl dl, 1
    shl dh, 1
    shl bl, 1
    shl bh, 1
    test al, 01h
    jz csp32o_b1_p0
    or dl, 1
csp32o_b1_p0:
    test al, 02h
    jz csp32o_b1_p1
    or dh, 1
csp32o_b1_p1:
    test al, 04h
    jz csp32o_b1_p2
    or bl, 1
csp32o_b1_p2:
    test al, 08h
    jz csp32o_b1_p3
    or bh, 1
csp32o_b1_p3:
    loop csp32o_byte1
    
    mov [di], dl
    mov [di+128], dh
    mov [di+256], bl
    mov [di+384], bh
    
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    pop bp
    mov [bp], al
    inc bp
    push bp
    inc di
    
    ; ===== BYTE 2 (pixeles 16-23) =====
    xor bx, bx
    xor dx, dx
    mov cx, 8
    
csp32o_byte2:
    lodsb
    shl dl, 1
    shl dh, 1
    shl bl, 1
    shl bh, 1
    test al, 01h
    jz csp32o_b2_p0
    or dl, 1
csp32o_b2_p0:
    test al, 02h
    jz csp32o_b2_p1
    or dh, 1
csp32o_b2_p1:
    test al, 04h
    jz csp32o_b2_p2
    or bl, 1
csp32o_b2_p2:
    test al, 08h
    jz csp32o_b2_p3
    or bh, 1
csp32o_b2_p3:
    loop csp32o_byte2
    
    mov [di], dl
    mov [di+128], dh
    mov [di+256], bl
    mov [di+384], bh
    
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    pop bp
    mov [bp], al
    inc bp
    push bp
    inc di
    
    ; ===== BYTE 3 (pixeles 24-31) =====
    xor bx, bx
    xor dx, dx
    mov cx, 8
    
csp32o_byte3:
    lodsb
    shl dl, 1
    shl dh, 1
    shl bl, 1
    shl bh, 1
    test al, 01h
    jz csp32o_b3_p0
    or dl, 1
csp32o_b3_p0:
    test al, 02h
    jz csp32o_b3_p1
    or dh, 1
csp32o_b3_p1:
    test al, 04h
    jz csp32o_b3_p2
    or bl, 1
csp32o_b3_p2:
    test al, 08h
    jz csp32o_b3_p3
    or bh, 1
csp32o_b3_p3:
    loop csp32o_byte3
    
    mov [di], dl
    mov [di+128], dh
    mov [di+256], bl
    mov [di+384], bh
    
    mov al, dl
    or al, dh
    or al, bl
    or al, bh
    pop bp
    mov [bp], al
    inc bp
    inc di
    
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
    
    ; Guardar coordenadas originales
    push cx             ; ← NUEVO: guardar X
    push dx             ; ← NUEVO: guardar Y
    
    ; Calcular offset usando lookup table
    mov bx, dx
    shl bx, 1
    mov ax, [video_offsets + bx]
    add ax, temp_offset
    mov bp, ax
    
    mov ax, cx
    shr ax, 3
    add bp, ax
    
    ; Restaurar coordenadas
    pop dx              ; ← NUEVO: restaurar Y
    pop cx              ; ← NUEVO: restaurar X
    
    mov cx, 16          ; 16 filas

dsp16o_loop_fila:
    push cx
    push di
    push si
    push bp
    
    mov bx, di 
    
    ; Leer mascaras pre-calculadas
    mov ah, [si]        ; Mascara byte 0
    mov al, [si+1]      ; Mascara byte 1
    
    push ax             ; Guardar ambas máscaras
    
    ; ========================================
    ; BYTE 0 - PLANO 0
    ; ========================================
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
    
    pop ax
    push ax
    
    mov di, bp
    
    mov cl, ah          ; Máscara byte 0
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx]        ; P0, byte 0
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; ========================================
    ; BYTE 0 - PLANO 1
    ; ========================================
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
    
    pop ax
    push ax
    
    mov di, bp
    
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+32]     ; P1, byte 0
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; ========================================
    ; BYTE 0 - PLANO 2
    ; ========================================
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
    
    pop ax
    push ax
    
    mov di, bp
    
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+64]     ; P2, byte 0
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; ========================================
    ; BYTE 0 - PLANO 3 (¡FALTABA!)
    ; ========================================
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
    
    pop ax
    push ax
    
    mov di, bp
    
    mov cl, ah
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, ah
    mov al, [bx+96]     ; ✅ P3, byte 0 (FALTABA)
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; ========================================
    ; BYTE 1 - PLANO 0
    ; ========================================
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
    
    pop ax
    push ax
    
    mov di, bp
    inc di
    
    mov cl, al          ; Máscara byte 1
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, al
    mov al, [bx+1]      ; P0, byte 1
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; ========================================
    ; BYTE 1 - PLANO 1
    ; ========================================
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
    
    pop ax
    push ax
    
    mov di, bp
    inc di
    
    mov cl, al
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, al
    mov al, [bx+33]     ; P1, byte 1
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; ========================================
    ; BYTE 1 - PLANO 2
    ; ========================================
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
    
    pop ax
    push ax
    
    mov di, bp
    inc di
    
    mov cl, al
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, al
    mov al, [bx+65]     ; P2, byte 1
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; ========================================
    ; BYTE 1 - PLANO 3
    ; ========================================
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
    
    pop ax              ; ✅ Recuperar máscaras
    
    mov di, bp
    inc di
    
    mov cl, al          ; AL = máscara byte 1
    not cl
    mov ch, es:[di]
    and ch, cl
    mov cl, al
    mov al, [bx+97]     ; P3, byte 1
    and al, cl
    or al, ch
    mov es:[di], al
    
    ; ========================================
    ; Siguiente fila
    ; ========================================
    pop bp
    add bp, 80
    pop si
    add si, 2
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

; ============================================
; RENDERIZADO OPTIMIZADO (32x32) - COMPLETO
; ============================================
; Dibujar sprite 32x32 con mascaras pre-calculadas
; IN: DI = sprite data, SI = sprite masks, CX = X, DX = Y
; ============================================

dibujar_sprite_planar_32x32_opt PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    ; Calcular offset usando lookup table
    mov bx, dx
    shl bx, 1
    mov ax, [video_offsets + bx]
    add ax, temp_offset
    mov bp, ax
    
    mov ax, cx
    shr ax, 3
    add bp, ax
    
    mov cx, 32          ; 32 filas

dsp32o_loop_fila:
    push cx
    push di
    push si
    push bp
    
    mov bx, di
    
    ; =========================================
    ; BYTE 0 (pixeles 0-7)
    ; =========================================
    mov ah, [si]        ; Leer mascara pre-calculada
    
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
    
    ; =========================================
    ; BYTE 1 (pixeles 8-15)
    ; =========================================
    pop si
    push si
    mov ah, [si+1]      ; Leer mascara pre-calculada
    
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
    
    ; =========================================
    ; BYTE 2 (pixeles 16-23)
    ; =========================================
    pop si
    push si
    mov ah, [si+2]      ; Leer mascara pre-calculada
    
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
    
    ; =========================================
    ; BYTE 3 (pixeles 24-31)
    ; =========================================
    pop si
    push si
    mov ah, [si+3]      ; Leer mascara pre-calculada
    
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
    
    ; =========================================
    ; Siguiente fila
    ; =========================================
    pop bp
    add bp, 80
    pop si
    add si, 4           ; 4 mascaras por fila
    pop di
    add di, 4           ; 4 bytes de datos por fila
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