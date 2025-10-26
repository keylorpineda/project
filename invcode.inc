; ============================================
; INVCODE.INC - Sistema de Inventario
; Universidad Nacional - Proyecto II Ciclo 2025
; ============================================

; ============================================
; VERIFICAR COLISIÓN CON RECURSOS
; ============================================
verificar_colision_recursos PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov ax, jugador_px
    mov player_left_temp, ax
    add ax, 31
    mov player_right_temp, ax

    mov ax, jugador_py
    mov player_top_temp, ax
    add ax, 31
    mov player_bottom_temp, ax

    xor si, si                  ; Índice de recurso
    mov bx, 1                   ; Máscara de bit

vcr_loop:
    mov al, num_recursos_cargados
    cbw
    cmp si, ax
    jae vcr_fin

    mov ax, recursos_recogidos
    and ax, bx
    jnz vcr_next                ; Ya recogido, saltar

    mov ax, si
    shl ax, 1
    add ax, si
    mov di, ax

    mov al, [recursos_mapa + di]
    xor ah, ah
    mov cx, ax
    shl cx, 1
    shl cx, 1
    shl cx, 1
    shl cx, 1

    mov al, [recursos_mapa + di + 1]
    xor ah, ah
    mov dx, ax
    shl dx, 1
    shl dx, 1
    shl dx, 1
    shl dx, 1

    mov ax, cx
    add ax, 15
    mov bp, ax                  ; Derecha del recurso

    mov ax, dx
    add ax, 15
    mov di, ax                  ; Parte inferior del recurso

    mov ax, player_right_temp
    cmp ax, cx
    jl vcr_next

    mov ax, player_left_temp
    cmp ax, bp
    jg vcr_next

    mov ax, player_bottom_temp
    cmp ax, dx
    jl vcr_next

    mov ax, player_top_temp
    cmp ax, di
    jg vcr_next

    call recoger_recurso

vcr_next:
    shl bx, 1
    inc si
    jmp vcr_loop

vcr_fin:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
verificar_colision_recursos ENDP

recoger_recurso PROC
    push ax
    push bx
    push di

    or recursos_recogidos, bx
    mov requiere_redibujar, 2    ; ✅ SIEMPRE forzar redibujado

    mov ax, si
    mov bx, 3
    mul bx
    mov di, ax

    mov al, [recursos_mapa + di + 2]
    mov bl, al

    cmp bl, 1
    jne rr_tipo2
    inc recursos_tipo1
    jmp rr_actualizar

rr_tipo2:
    cmp bl, 2
    jne rr_tipo3
    inc recursos_tipo2
    jmp rr_actualizar

rr_tipo3:
    inc recursos_tipo3

rr_actualizar:
    mov al, bl
    call actualizar_inventario_slots

    mov anim_recoger_activa, 1
    mov anim_recoger_frame, 0
    mov ax, jugador_px
    mov anim_recoger_x, ax
    mov ax, jugador_py
    sub ax, 32
    mov anim_recoger_y, ax

    call reproducir_sonido_recoleccion

    pop di
    pop bx
    pop ax
    ret
recoger_recurso ENDP

actualizar_inventario_slots PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov dl, al                  ; Tipo de recurso
    mov cx, MAX_ITEMS
    mov si, OFFSET inventario_slots
    mov di, OFFSET inventario_cantidades

ais_loop:
    test cx, cx
    jz ais_fin

    mov al, [si]
    cmp al, dl
    je ais_incrementar
    test al, al
    jz ais_asignar

    inc si
    inc di
    dec cx
    jmp ais_loop

ais_incrementar:
    inc byte ptr [di]
    jmp ais_fin

ais_asignar:
    mov [si], dl
    mov byte ptr [di], 1

ais_fin:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
actualizar_inventario_slots ENDP

; ============================================
; DIBUJAR RECURSOS EN EL MAPA
; ============================================
dibujar_recursos_en_mapa PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    xor si, si                  ; Índice de recurso
    mov bx, 1                   ; Máscara de bit
    
drm_loop:
    mov al, num_recursos_cargados
    mov ah, 0
    cmp si, ax
    jb drm_loop_continue
    jmp drm_fin

drm_loop_continue:
    
    ; Verificar si ya fue recogido
    push bx
    mov ax, recursos_recogidos
    and ax, bx
    pop bx
    jz drm_procesar
    jmp drm_next

drm_procesar:
    
    ; Obtener posición del recurso
    push bx
    push si
    
    mov ax, si
    mov bx, 3
    mul bx
    mov di, ax

    mov al, [recursos_mapa + di]                 ; X (en tiles)
    xor ah, ah
    mov cx, ax
    shl cx, 1
    shl cx, 1
    shl cx, 1
    shl cx, 1

    ; Calcular cámara alineada a tile para eje X
    mov bx, inicio_tile_x
    shl bx, 1
    shl bx, 1
    shl bx, 1
    shl bx, 1

    ; Verificar si está visible en viewport (X)
    mov ax, cx
    sub ax, bx
    cmp ax, -15
    jge drm_visible_x_min_ok
    jmp drm_next_pop

drm_visible_x_min_ok:
    cmp ax, 319
    jle drm_visible_x_max_ok
    jmp drm_next_pop

drm_visible_x_max_ok:

    mov al, [recursos_mapa + di + 1]             ; Y (en tiles)
    xor ah, ah
    mov dx, ax
    shl dx, 1
    shl dx, 1
    shl dx, 1
    shl dx, 1

    ; Calcular cámara alineada a tile para eje Y
    mov ax, inicio_tile_y
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    mov bx, ax

    ; Verificar si está visible en viewport (Y)
    mov ax, dx
    sub ax, bx
    cmp ax, -15
    jge drm_visible_y_min_ok
    jmp drm_next_pop

drm_visible_y_min_ok:
    cmp ax, 191
    jle drm_visible_y_max_ok
    jmp drm_next_pop

drm_visible_y_max_ok:

    ; Calcular posición en pantalla usando cámara alineada a tile
    mov ax, inicio_tile_x
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    sub cx, ax
    add cx, viewport_x

    mov ax, inicio_tile_y
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    sub dx, ax
    add dx, viewport_y
    
    ; Obtener sprite según tipo
    mov al, [recursos_mapa + di + 2]            ; Tipo

    cmp al, 1
    jne drm_tipo2
    mov di, OFFSET sprite_cristal
    push si
    mov si, OFFSET sprite_cristal_mask
    jmp drm_dibujar
    
drm_tipo2:
    cmp al, 2
    jne drm_tipo3
    mov di, OFFSET sprite_gema
    push si
    mov si, OFFSET sprite_gema_mask
    jmp drm_dibujar
    
drm_tipo3:
    mov di, OFFSET sprite_moneda
    push si
    mov si, OFFSET sprite_moneda_mask
    
drm_dibujar:
    call dibujar_sprite_planar_16x16_opt
    pop si
    
drm_next_pop:
    pop si
    pop bx
    
drm_next:
    shl bx, 1
    inc si
    jmp drm_loop
    
drm_fin:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_recursos_en_mapa ENDP

; ============================================
; DIBUJAR PANEL DE INVENTARIO
; ============================================
dibujar_inventario PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    cmp inventario_abierto, 0
    je di_fin                   ; <-- Si está cerrado, no hacer NADA
    
    ; --- DIBUJAR INVENTARIO (SI ESTÁ ABIERTO) ---
    mov cx, INV_X
    mov dx, INV_Y
    mov ax, INV_WIDTH
    mov bx, INV_HEIGHT
    mov si, COLOR_FONDO
    call dibujar_rectangulo_lleno

    mov cx, INV_X
    mov dx, INV_Y
    mov ax, INV_WIDTH
    mov bx, INV_HEIGHT
    mov si, COLOR_MARCO
    call dibujar_rectangulo_vacio

    mov cx, INV_X
    add cx, 12
    mov dx, INV_Y
    add dx, 12
    mov si, OFFSET msg_inventario
    mov al, COLOR_TEXTO
    call dibujar_texto_simple

    call dibujar_jugador_inventario
    
    call dibujar_slots_items
    
    call dibujar_estadisticas  ; <-- Asegúrate que esté DESCOMENTADO
    
di_fin:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_inventario ENDP

dibujar_jugador_inventario PROC
    push cx
    push dx
    push si
    push di
    
    ; Obtener sprite actual del jugador
    call obtener_sprite_jugador
    
    ; Dibujar en posición fija
    mov cx, ZONA_PLAYER_X
    mov dx, ZONA_PLAYER_Y
    
    call dibujar_sprite_planar_32x32_opt
    
    pop di
    pop si
    pop dx
    pop cx
    ret
dibujar_jugador_inventario ENDP

dibujar_slots_items PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    xor si, si

dsi_loop:
    cmp si, MAX_ITEMS
    jb dsi_continuar
    jmp dsi_fin

dsi_continuar:

    mov ax, si
    xor dx, dx
    mov bx, 4
    div bx
    mov bp, ax

    mov ax, dx
    mov bx, ITEM_TOTAL
    mul bx
    add ax, ZONA_ITEMS_X
    mov cx, ax

    mov ax, bp
    mov bx, ITEM_TOTAL
    mul bx
    add ax, ZONA_ITEMS_Y
    mov dx, ax

    push cx
    push dx
    mov ax, ITEM_SIZE
    mov bx, ITEM_SIZE
    push si
    mov si, COLOR_ITEM_SLOT
    call dibujar_rectangulo_vacio
    pop si
    pop dx
    pop cx

    mov bx, OFFSET inventario_slots
    add bx, si
    mov al, [bx]
    test al, al
    jz dsi_next

    mov dl, al
    push cx
    push dx

    mov ax, cx
    add ax, ITEM_ICON_OFFSET
    mov cx, ax

    mov ax, dx
    add ax, ITEM_ICON_OFFSET
    mov dx, ax

    cmp dl, 1
    jne dsi_tipo2
    mov di, OFFSET sprite_cristal
    push si
    mov si, OFFSET sprite_cristal_mask
    jmp dsi_dibujar

dsi_tipo2:
    cmp dl, 2
    jne dsi_tipo3
    mov di, OFFSET sprite_gema
    push si
    mov si, OFFSET sprite_gema_mask
    jmp dsi_dibujar

dsi_tipo3:
    mov di, OFFSET sprite_moneda
    push si
    mov si, OFFSET sprite_moneda_mask

dsi_dibujar:
    call dibujar_sprite_planar_16x16_opt
    pop si

    pop dx
    pop cx

    mov bx, OFFSET inventario_cantidades
    add bx, si
    mov al, [bx]
    xor ah, ah
    push ax

    mov ax, cx
    add ax, ITEM_COUNT_OFFSET_X
    mov cx, ax

    mov ax, dx
    add ax, ITEM_COUNT_OFFSET_Y
    mov dx, ax

    pop ax
    call dibujar_numero

dsi_next:
    inc si
    jmp dsi_loop

dsi_fin:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_slots_items ENDP

dibujar_estadisticas PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    ; --- Calcular Base Y (Debajo de los slots) ---
    mov bp, ZONA_ITEMS_Y
    add bp, (ITEM_TOTAL * 2)
    add bp, 10

    ; --- Dibujar Cristales ---
    mov cx, ZONA_ITEMS_X
    sub cx, 24                ; X-Texto = 180 - 24 = 156
    mov dx, bp
    mov si, OFFSET msg_cristales
    mov al, COLOR_TEXTO
    call dibujar_texto_simple ; Dibuja "CRISTALES:"

    mov cx, ZONA_ITEMS_X
    add cx, STAT_VAL_OFFSET   ; X-Número = 180 + 88 = 268
    mov dx, bp
    mov al, recursos_tipo1
    xor ah, ah
    call dibujar_numero     ; Dibuja el número

    ; --- Dibujar Gemas ---
    mov cx, ZONA_ITEMS_X
    sub cx, 24                ; X-Texto = 156 (RECALCULADO)
    mov dx, bp
    add dx, 12
    mov si, OFFSET msg_gemas
    mov al, COLOR_TEXTO
    call dibujar_texto_simple ; Dibuja "GEMAS:"

    mov cx, ZONA_ITEMS_X
    add cx, STAT_VAL_OFFSET   ; X-Número = 268
    mov dx, bp
    add dx, 12
    mov al, recursos_tipo2
    xor ah, ah
    call dibujar_numero     ; Dibuja el número

    ; --- Dibujar Monedas ---
    mov cx, ZONA_ITEMS_X
    sub cx, 24                ; X-Texto = 156 (RECALCULADO)
    mov dx, bp
    add dx, 24
    mov si, OFFSET msg_monedas
    mov al, COLOR_TEXTO
    call dibujar_texto_simple ; Dibuja "MONEDAS:"

    mov cx, ZONA_ITEMS_X
    add cx, STAT_VAL_OFFSET   ; X-Número = 268
    mov dx, bp
    add dx, 24
    mov al, recursos_tipo3
    xor ah, ah
    call dibujar_numero     ; Dibuja el número
    
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_estadisticas ENDP

dibujar_barra_progreso PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov si, ax                  ; Guardar valor actual
    mov di, bx                  ; Guardar valor máximo
    
    ; Dibujar fondo de la barra (vacía)
    push cx
    push dx
    mov ax, 80                  ; Ancho de la barra
    mov bx, 8                   ; Alto de la barra
    push si
    mov si, COLOR_BARRA_VACIA
    call dibujar_rectangulo_lleno
    pop si
    pop dx
    pop cx
    
    ; Calcular ancho de la barra llena
    cmp di, 0
    je dbp_fin

    mov ax, si                  ; Valor actual
    mov bx, 80                  ; Ancho total
    mul bx
    xor dx, dx
    div di                      ; Dividir por valor máximo

    cmp ax, 80
    jbe dbp_width_ok
    mov ax, 80

dbp_width_ok:
    
    ; Si es 0, no dibujar nada
    test ax, ax
    jz dbp_fin
    
    ; Dibujar barra llena
    mov bx, 8                   ; Alto
    push si
    mov si, COLOR_BARRA_LLENA
    call dibujar_rectangulo_lleno
    pop si
    
dbp_fin:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_barra_progreso ENDP

; ============================================
; DIBUJAR RECTÁNGULO LLENO
; Entrada: CX = X, DX = Y, AX = ancho, BX = alto, SI = color (0-15)
; ============================================
dibujar_rectangulo_lleno PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    push bp
    
    mov bp, ax                  ; BP = ancho
    mov di, bx                  ; DI = alto

    mov ax, VIDEO_SEG
    mov es, ax

drl_fila:
    test di, di
    jz drl_fin

    push cx
    push dx

    ; Calcular offset de video
    mov bx, dx
    shl bx, 1
    mov ax, [video_offsets + bx]
    mov bx, cx
    shr bx, 1
    shr bx, 1
    shr bx, 1
    add ax, bx
    add ax, temp_offset
    mov bx, ax                  ; BX = offset de video

    ; Dibujar línea horizontal
    mov ax, si
    and ax, 0FFh

    ; Configurar para escribir en todos los planos
    mov dx, 3C4h
    push ax
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    pop ax
    
    ; Dibujar píxeles
    mov cx, bp                  ; Ancho en píxeles
    shr cx, 1
    shr cx, 1
    shr cx, 1
    
drl_pixel:
    mov es:[bx], al
    inc bx
    loop drl_pixel

    pop dx
    pop cx

    inc dx                      ; Siguiente fila
    dec di
    jmp drl_fila

drl_fin:
    pop bp
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_rectangulo_lleno ENDP

; ============================================
; DIBUJAR RECTÁNGULO VACÍO (solo marco)
; Entrada: CX = X, DX = Y, AX = ancho, BX = alto, SI = color (0-15)
dibujar_rectangulo_vacio PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov di, ax                  ; Guardar ancho
    mov bp, bx                  ; Guardar alto

    ; Línea superior
    push cx
    push dx
    mov ax, di
    mov bx, 1
    call dibujar_rectangulo_lleno
    pop dx
    pop cx

    ; Línea inferior
    push cx
    push dx
    add dx, bp
    dec dx
    mov ax, di
    mov bx, 1
    call dibujar_rectangulo_lleno
    pop dx
    pop cx

    ; Línea izquierda
    push cx
    push dx
    mov ax, 8
    mov bx, bp
    call dibujar_rectangulo_lleno
    pop dx
    pop cx

    ; Línea derecha
    push cx
    push dx
    add cx, di
    sub cx, 8
    mov ax, 8
    mov bx, bp
    call dibujar_rectangulo_lleno
    pop dx
    pop cx

    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_rectangulo_vacio ENDP

; ============================================
; DIBUJAR TEXTO SIMPLE (solo mayúsculas y números)
; Entrada: CX = X, DX = Y, SI = puntero a string terminado en 0, AL = color
; ============================================
FONT_LETTER_OFFSET EQU 10
FONT_COLON_INDEX   EQU 36
FONT_SLASH_INDEX   EQU 37
FONT_EXCLAM_INDEX  EQU 38

dibujar_texto_simple PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov texto_color_actual, al

dts_loop:
    lodsb
    test al, al
    jz dts_fin

    cmp al, ' '
    je dts_space

    push cx
    push dx
    call dibujar_caracter_8x8
    pop dx
    pop cx

dts_space:
    add cx, 8
    jmp dts_loop

dts_fin:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_texto_simple ENDP

dibujar_caracter_8x8 PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov font_base_x_temp, cx
    mov font_base_y_temp, dx

    call obtener_ptr_glifo
    jc dce_exit

    xor di, di

dce_row_loop:
    cmp di, 8
    jae dce_exit

    mov al, [si]
    mov font_row_mask, al
    mov bx, font_base_x_temp
    mov bp, 8

dce_bit_loop:
    mov al, font_row_mask
    test al, 80h
    jz dce_skip_pixel

    mov ah, 0Ch
    mov al, texto_color_actual
    mov bh, 0
    mov cx, bx
    mov dx, font_base_y_temp
    add dx, di
    int 10h

dce_skip_pixel:
    mov al, font_row_mask
    shl al, 1
    mov font_row_mask, al
    inc bx
    dec bp
    jnz dce_bit_loop

    inc si
    inc di
    jmp dce_row_loop

dce_exit:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_caracter_8x8 ENDP

obtener_ptr_glifo PROC
    push bx
    push dx

    mov si, OFFSET font_8x8

    cmp al, '0'
    jb og_check_letter
    cmp al, '9'
    ja og_check_letter
    sub al, '0'
    xor ah, ah
    mov bx, ax
    shl bx, 1
    shl bx, 1
    shl bx, 1
    add si, bx
    clc
    jmp og_exit

og_check_letter:
    cmp al, 'A'
    jb og_check_colon
    cmp al, 'Z'
    ja og_check_colon
    sub al, 'A'
    add al, FONT_LETTER_OFFSET
    xor ah, ah
    mov bx, ax
    shl bx, 1
    shl bx, 1
    shl bx, 1
    add si, bx
    clc
    jmp og_exit

og_check_colon:
    cmp al, ':'
    je og_from_colon
    cmp al, '/'
    je og_from_slash
    cmp al, '!'
    je og_from_excl
    stc
    jmp og_exit

og_from_colon:
    mov bx, FONT_COLON_INDEX
    jmp og_from_index

og_from_slash:
    mov bx, FONT_SLASH_INDEX
    jmp og_from_index

og_from_excl:
    mov bx, FONT_EXCLAM_INDEX

og_from_index:
    xor ah, ah
    mov ax, bx
    shl ax, 1
    shl ax, 1
    shl ax, 1
    add si, ax
    clc

og_exit:
    pop dx
    pop bx
    ret
obtener_ptr_glifo ENDP

dibujar_numero PROC
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov bp, ax                  ; Guardar valor original
    mov bx, 10
    lea di, numero_buffer + 5
    mov byte ptr [di], 0

    mov ax, bp
    cmp ax, 0
    jne dn_loop_start
    dec di
    mov byte ptr [di], '0'
    jmp dn_ready

dn_loop_start:
dn_loop:
    xor dx, dx
    div bx
    dec di
    add dl, '0'
    mov [di], dl
    test ax, ax
    jnz dn_loop

dn_ready:
    
    ; ====================== INICIO DE LA CORRECCIÓN ======================
    ; Copiar SP a un registro base legal (BX)
    mov bx, sp
    
    ; Cargar las coordenadas usando el indexado legal [BX+offset]
    ; [BX+0] = bp, [BX+2] = di, [BX+4] = si, [BX+6] = dx, [BX+8] = cx
    mov cx, [bx+8]  ; Restaurar CX (coordenada X)
    mov dx, [bx+6]  ; Restaurar DX (coordenada Y)
    ; ===================================================================
    
    mov si, di
    mov al, COLOR_TEXTO
    call dibujar_texto_simple

    mov ax, bp
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret
dibujar_numero ENDP

; ============================================
; ACTUALIZAR ANIMACIÓN DE RECOLECCIÓN
; ============================================
actualizar_animacion_recoger PROC
    push ax
    
    cmp anim_recoger_activa, 0
    je aar_fin
    
    ; Incrementar frame
    inc anim_recoger_frame
    
    ; Mover hacia arriba
    sub anim_recoger_y, 2
    
    ; Terminar animación después de 15 frames
    cmp anim_recoger_frame, 15
    jb aar_fin
    
    mov anim_recoger_activa, 0
    
aar_fin:
    pop ax
    ret
actualizar_animacion_recoger ENDP

; ============================================
; DIBUJAR ANIMACIÓN DE RECOLECCIÓN
; ============================================
dibujar_animacion_recoger PROC
    push ax
    push cx
    push dx
    
    cmp anim_recoger_activa, 0
    je dar_fin
    
    ; Calcular posición en pantalla
    mov ax, anim_recoger_x
    sub ax, camara_px
    add ax, viewport_x
    mov cx, ax
    
    mov ax, anim_recoger_y
    sub ax, camara_py
    add ax, viewport_y
    mov dx, ax
    
    ; Verificar si está visible
    cmp cx, -16
    jl dar_fin
    cmp cx, 336
    jg dar_fin
    cmp dx, -16
    jl dar_fin
    cmp dx, 208
    jg dar_fin
    
    ; Dibujar símbolo "+" o similar
    ; TODO: Implementar sprite de "+1" o animación más elaborada
    ; Por ahora, solo un marcador simple
    
dar_fin:
    pop dx
    pop cx
    pop ax
    ret
dibujar_animacion_recoger ENDP

; ============================================
; VERIFICAR VICTORIA
; Retorna: Carry set si ganó, Carry clear si no
; ============================================
verificar_victoria PROC
    push ax
    
    mov al, recursos_tipo1
    cmp al, META_POR_TIPO
    jb vv_no_gano
    
    mov al, recursos_tipo2
    cmp al, META_POR_TIPO
    jb vv_no_gano
    
    mov al, recursos_tipo3
    cmp al, META_POR_TIPO
    jb vv_no_gano
    
    ; ¡Victoria!
    stc
    jmp vv_fin
    
vv_no_gano:
    clc
    
vv_fin:
    pop ax
    ret
verificar_victoria ENDP