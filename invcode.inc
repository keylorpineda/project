HUD_HEART_MARGIN  EQU 8
HUD_HEART_X       EQU HUD_HEART_MARGIN
HUD_HEART_Y       EQU HUD_HEART_MARGIN
HUD_HEART_SPACING EQU 20
HUD_HOTBAR_SLOTS  EQU 8
HUD_HOTBAR_X      EQU 128
HUD_HOTBAR_Y      EQU 302

verificar_colision_recursos PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov ax, jugador_px
    sub ax, 16
    mov player_left_temp, ax
    
    mov ax, jugador_px
    add ax, 15
    mov player_right_temp, ax

    mov ax, jugador_py
    sub ax, 16
    mov player_top_temp, ax

    mov ax, jugador_py
    add ax, 15
    mov player_bottom_temp, ax

    xor si, si
    mov bx, 1

vcr_loop:
    mov al, num_recursos_cargados
    cbw
    cmp si, ax
    jae vcr_fin

    test recursos_recogidos, bx
    jnz vcr_next

    mov ax, si
    mov dx, 3
    mul dx
    mov di, ax

    mov al, [recursos_mapa + di]
    xor ah, ah
    shl ax, 4
    mov cx, ax

    mov al, [recursos_mapa + di + 1]
    xor ah, ah
    shl ax, 4
    mov dx, ax
    
    mov ax, cx
    add ax, 15
    mov bp, ax

    mov ax, dx
    add ax, 15
    push ax

    mov ax, player_right_temp
    cmp ax, cx
    jl vcr_no_colision

    mov ax, player_left_temp
    cmp ax, bp
    jg vcr_no_colision

    mov ax, player_bottom_temp
    cmp ax, dx
    jl vcr_no_colision

    mov ax, player_top_temp
    pop dx
    cmp ax, dx
    jg vcr_next
    
    call recoger_recurso
    jmp vcr_next

vcr_no_colision:
    pop ax

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
    mov requiere_redibujar, 2
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
    cmp bl, 3
    jne rr_actualizar
    inc recursos_tipo3
    jmp rr_actualizar


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

    mov dl, al
    mov cx, MAX_ITEMS
    mov si, OFFSET inventario_slots
    mov di, OFFSET inventario_cantidades

ais_loop:
    test cx, cx
    jz ais_fin

    mov al, [si]
    test al, al
    jz ais_asignar
    
    jmp ais_next_slot

ais_next_slot:
    inc si
    inc di
    dec cx
    jmp ais_loop

ais_asignar:
    mov [si], dl
    mov byte ptr [di], 1
    jmp ais_fin

ais_fin:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
actualizar_inventario_slots ENDP

dibujar_recursos_en_mapa PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    xor si, si
    mov bx, 1

drm_loop:
    mov al, num_recursos_cargados
    mov ah, 0
    cmp si, ax
    jb drm_loop_continue
    jmp drm_fin

drm_loop_continue:
    push bx
    mov ax, recursos_recogidos
    and ax, bx
    pop bx
    jz drm_procesar
    jmp drm_next

drm_procesar:
    push bx
    push si

    mov ax, si
    mov bx, 3
    mul bx
    mov di, ax

    mov al, [recursos_mapa + di]
    xor ah, ah
    mov cx, ax
    shl cx, 1
    shl cx, 1
    shl cx, 1
    shl cx, 1

    mov bx, inicio_tile_x
    shl bx, 1
    shl bx, 1
    shl bx, 1
    shl bx, 1

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
    mov al, [recursos_mapa + di + 1]
    xor ah, ah
    mov dx, ax
    shl dx, 1
    shl dx, 1
    shl dx, 1
    shl dx, 1

    mov ax, inicio_tile_y
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    mov bx, ax

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

    mov al, [recursos_mapa + di + 2]

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

dibujar_inventario PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    cmp inventario_abierto, 0
    je di_fin

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
    call dibujar_texto_buffer

    call dibujar_jugador_inventario
    call dibujar_slots_items
    call dibujar_estadisticas

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

    call obtener_sprite_jugador

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
    push si
    mov ax, ITEM_SIZE
    mov bx, ITEM_SIZE
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

    mov bh, al

    push cx
    push dx

    add cx, ITEM_ICON_OFFSET
    add dx, ITEM_ICON_OFFSET

    mov al, bh
    cmp al, 1
    jne dsi_tipo2
    mov di, OFFSET sprite_cristal
    push si
    mov si, OFFSET sprite_cristal_mask
    jmp dsi_dibujar

dsi_tipo2:
    cmp al, 2
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
    
    ; --- Dibujar cantidad ---
    mov bx, OFFSET inventario_cantidades
    add bx, si
    mov al, [bx]
    cmp al, 1  ; No dibujar '1'
    jbe dsi_next 
    
    xor ah, ah
    push si
    
    mov cx, ax ; Guardar Coordenada X del slot
    mov dx, ax ; Guardar Coordenada Y del slot
    
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
    
    add cx, ITEM_COUNT_OFFSET_X
    add dx, ITEM_COUNT_OFFSET_Y
    
    mov bx, OFFSET inventario_cantidades
    add bx, si
    mov al, [bx]
    xor ah, ah
    
    call dibujar_numero
    
    pop si
    ; --- Fin dibujar cantidad ---

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

    mov bp, ZONA_ITEMS_Y
    add bp, (ITEM_TOTAL * 2)
    add bp, 10

    mov cx, ZONA_ITEMS_X
    sub cx, 24
    mov dx, bp
    mov si, OFFSET msg_cristales
    mov al, COLOR_TEXTO
    call dibujar_texto_buffer

    mov cx, ZONA_ITEMS_X
    add cx, STAT_VAL_OFFSET
    mov dx, bp
    mov al, recursos_tipo1
    xor ah, ah
    call dibujar_numero

    mov cx, ZONA_ITEMS_X
    sub cx, 24
    mov dx, bp
    add dx, 12
    mov si, OFFSET msg_gemas
    mov al, COLOR_TEXTO
    call dibujar_texto_buffer

    mov cx, ZONA_ITEMS_X
    add cx, STAT_VAL_OFFSET
    mov dx, bp
    add dx, 12
    mov al, recursos_tipo2
    xor ah, ah
    call dibujar_numero

    mov cx, ZONA_ITEMS_X
    sub cx, 24
    mov dx, bp
    add dx, 24
    mov si, OFFSET msg_monedas
    mov al, COLOR_TEXTO
    call dibujar_texto_buffer

    mov cx, ZONA_ITEMS_X
    add cx, STAT_VAL_OFFSET
    mov dx, bp
    add dx, 24
    mov al, recursos_tipo3
    xor ah, ah
    call dibujar_numero

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

    mov si, ax
    mov di, bx

    push cx
    push dx
    mov ax, 80
    mov bx, 8
    push si
    mov si, COLOR_BARRA_VACIA
    call dibujar_rectangulo_lleno
    pop si
    pop dx
    pop cx

    cmp di, 0
    je dbp_fin

    mov ax, si
    mov bx, 80
    mul bx
    xor dx, dx
    div di

    cmp ax, 80
    jbe dbp_width_ok
    mov ax, 80

dbp_width_ok:
    test ax, ax
    jz dbp_fin

    mov bx, 8
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

dibujar_rectangulo_lleno PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    push bp

    mov bp, ax
    mov di, bx

    mov ax, VIDEO_SEG
    mov es, ax

drl_fila:
    test di, di
    jz drl_fin

    push cx
    push dx

    mov bx, dx
    shl bx, 1
    mov ax, [video_offsets + bx]
    mov bx, cx
    shr bx, 1
    shr bx, 1
    shr bx, 1
    add ax, bx
    add ax, temp_offset
    mov bx, ax

    mov ax, si
    and ax, 0FFh

    mov dx, 3C4h
    push ax
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    pop ax

    mov cx, bp
    
    add cx, 7
    shr cx, 3

drl_pixel:
    mov es:[bx], al
    inc bx
    loop drl_pixel

    pop dx
    pop cx

    inc dx
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

dibujar_rectangulo_vacio PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov di, ax
    mov bp, bx

    push cx
    push dx
    mov ax, di
    mov bx, 1
    call dibujar_rectangulo_lleno
    pop dx
    pop cx

    push cx
    push dx
    add dx, bp
    dec dx
    mov ax, di
    mov bx, 1
    call dibujar_rectangulo_lleno
    pop dx
    pop cx

    push cx
    push dx
    mov ax, 8
    mov bx, bp
    call dibujar_rectangulo_lleno
    pop dx
    pop cx

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

dibujar_texto_buffer PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    mov texto_color_actual, al

    mov ax, VIDEO_SEG
    mov es, ax

dtb_loop:
    lodsb
    test al, al
    jz dtb_fin

    cmp al, ' '
    je dtb_space

    push cx
    push dx
    push si
    call dibujar_caracter_buffer_8x8
    pop si
    pop dx
    pop cx

dtb_space:
    add cx, 8
    jmp dtb_loop

dtb_fin:
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_texto_buffer ENDP

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

dcb_color db 0
dcb_glyph_ptr dw 0

dibujar_caracter_buffer_8x8 PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push es

    call obtener_ptr_glifo
    jnc dcb_continue
    jmp dcb_exit

dcb_continue:
    mov ax, VIDEO_SEG
    mov es, ax

    mov bx, dx
    shl bx, 1
    mov bp, [video_offsets + bx]
    mov ax, cx
    shr ax, 3
    add bp, ax
    add bp, temp_offset

    mov word ptr [dcb_glyph_ptr], si

    mov al, texto_color_actual
    and al, 0Fh
    mov byte ptr [dcb_color], al


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

    mov cx, 8
    mov di, bp

dcb_p0:
    mov ah, [si]
    mov al, ah
    not al
    and al, es:[di]

    mov dl, byte ptr [dcb_color]
    test dl, 1
    jz dcb_p0_skip
    and ah, 0FFh
    or al, ah
dcb_p0_skip:
    mov es:[di], al
    add di, 80
    inc si
    loop dcb_p0

    mov si, word ptr [dcb_glyph_ptr]


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

    mov cx, 8
    mov di, bp

dcb_p1:
    mov ah, [si]
    mov al, ah
    not al
    and al, es:[di]

    mov dl, byte ptr [dcb_color]
    test dl, 2
    jz dcb_p1_skip
    and ah, 0FFh
    or al, ah
dcb_p1_skip:
    mov es:[di], al
    add di, 80
    inc si
    loop dcb_p1

    mov si, word ptr [dcb_glyph_ptr]


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

    mov cx, 8
    mov di, bp

dcb_p2:
    mov ah, [si]
    mov al, ah
    not al
    and al, es:[di]

    mov dl, byte ptr [dcb_color]
    test dl, 4
    jz dcb_p2_skip
    and ah, 0FFh
    or al, ah
dcb_p2_skip:
    mov es:[di], al
    add di, 80
    inc si
    loop dcb_p2

    mov si, word ptr [dcb_glyph_ptr]


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
    mov di, bp

dcb_p3:
    mov ah, [si]
    mov al, ah
    not al
    and al, es:[di]

    mov dl, byte ptr [dcb_color]
    test dl, 8
    jz dcb_p3_skip
    and ah, 0FFh
    or al, ah
dcb_p3_skip:
    mov es:[di], al
    add di, 80
    inc si
    loop dcb_p3


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

dcb_exit:
    pop es
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

dibujar_caracter_buffer_8x8 ENDP

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
    push bp
    mov bp, sp
    sub sp, 2
    push bx
    push cx
    push dx
    push si
    push di

    mov [bp-2], ax
    mov bx, 10
    lea di, numero_buffer + 5
    mov byte ptr [di], 0

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
    mov cx, [bp-6]
    mov dx, [bp-8]

    mov si, di
    mov al, COLOR_TEXTO
    call dibujar_texto_buffer

    mov ax, [bp-2]
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    add sp, 2
    pop bp
    ret
dibujar_numero ENDP

actualizar_animacion_recoger PROC
    push ax

    cmp anim_recoger_activa, 0
    je aar_fin

    inc anim_recoger_frame
    sub anim_recoger_y, 2

    cmp anim_recoger_frame, 15
    jb aar_fin

    mov anim_recoger_activa, 0

aar_fin:
    pop ax
    ret
actualizar_animacion_recoger ENDP

dibujar_animacion_recoger PROC
    push ax
    push cx
    push dx

    cmp anim_recoger_activa, 0
    je dar_fin

    mov ax, anim_recoger_x
    sub ax, camara_px
    add ax, viewport_x
    mov cx, ax

    mov ax, anim_recoger_y
    sub ax, camara_py
    add ax, viewport_y
    mov dx, ax

    cmp cx, -16
    jl dar_fin
    cmp cx, 336
    jg dar_fin
    cmp dx, -16
    jl dar_fin
    cmp dx, 208
    jg dar_fin

dar_fin:
    pop dx
    pop cx
    pop ax
    ret
dibujar_animacion_recoger ENDP

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

    stc
    jmp vv_fin

vv_no_gano:
    clc

vv_fin:
    pop ax
    ret
verificar_victoria ENDP

dibujar_hud PROC
    push ax

    call dibujar_hud_vida

    cmp inventario_abierto, 1
    je dh_fin

    call dibujar_hud_progreso
    call dibujar_hud_hotbar

dh_fin:
    pop ax
    ret
dibujar_hud ENDP

dibujar_hud_progreso PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov dx, 35

    mov cx, 530
    mov si, OFFSET msg_objetivo
    mov al, COLOR_TEXTO
    call dibujar_texto_buffer
    add dx, 12

    mov di, OFFSET sprite_cristal
  
    mov si, OFFSET sprite_cristal_mask
    mov cx, 530
    call dibujar_sprite_planar_16x16_opt

    mov cx, 550
    add dx, 4
    mov al, recursos_tipo1
    xor ah, ah
    call dibujar_numero

    
    mov cx, 562
    mov si, OFFSET msg_slash
    mov al, COLOR_TEXTO
    call dibujar_texto_buffer

    mov cx, 574
    mov al, META_POR_TIPO
    xor ah, ah
    call dibujar_numero
    
    sub dx, 4

    add dx, 20
    mov di, OFFSET sprite_gema
    mov si, OFFSET sprite_gema_mask
    mov cx, 530
    call dibujar_sprite_planar_16x16_opt

    mov cx, 550
    add dx, 4
    mov al, recursos_tipo2
    xor ah, ah
    call dibujar_numero

    mov cx, 562
    mov si, OFFSET msg_slash
    mov al, COLOR_TEXTO
    call dibujar_texto_buffer

    mov cx, 574
    mov al, META_POR_TIPO
  
    xor ah, ah
    call dibujar_numero
    sub dx, 4

    add dx, 20
    mov di, OFFSET sprite_moneda
    mov si, OFFSET sprite_moneda_mask
    mov cx, 530
    call dibujar_sprite_planar_16x16_opt

    mov cx, 550
    add dx, 4
    mov al, recursos_tipo3
    xor ah, ah
    call dibujar_numero

    mov cx, 562
    mov si, OFFSET msg_slash
    mov al, COLOR_TEXTO
    call dibujar_texto_buffer

 
    mov cx, 574
    mov al, META_POR_TIPO
    xor ah, ah
    call dibujar_numero

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_hud_progreso ENDP

dibujar_hud_hotbar PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    xor si, si

dhh_loop_slots:
 
    cmp si, MAX_ITEMS
    jb dhh_continue
    jmp dhh_fin

dhh_continue:
    mov ax, si
    mov bx, ITEM_TOTAL
    mul bx
    add ax, HUD_HOTBAR_X
    mov cx, ax

    mov dx, HUD_HOTBAR_Y

    mov ax, ITEM_SIZE
    mov bx, ITEM_SIZE
    push si
    mov si, COLOR_ITEM_SLOT
    call dibujar_rectangulo_vacio
    pop si

    mov cx, si
    cmp cl, hud_slot_seleccionado
    jne dhh_no_select

    mov ax, si
    mov bx, ITEM_TOTAL
    mul bx
    add ax, HUD_HOTBAR_X
    mov cx, ax
    mov dx, HUD_HOTBAR_Y
    mov ax, ITEM_SIZE
    mov bx, ITEM_SIZE
    push si
    mov si, COLOR_TEXTO
    call dibujar_rectangulo_vacio
    pop si

dhh_no_select:
    mov bx, si

    mov al, [inventario_slots + bx]
    test al, al
    jz dhh_next

    push ax

  
    mov ax, si
    mov bx, ITEM_TOTAL
    mul bx
    add ax, HUD_HOTBAR_X
    add ax, ITEM_ICON_OFFSET
    add ax, 4
    mov cx, ax

    mov dx, HUD_HOTBAR_Y
    add dx, ITEM_ICON_OFFSET

    pop ax

    cmp al, 1
    jne dhh_tipo2
    mov di, OFFSET sprite_cristal
    push si
    mov si, OFFSET sprite_cristal_mask
    jmp dhh_dibujar

dhh_tipo2:
    cmp al, 2
   
    jne dhh_tipo3
    mov di, OFFSET sprite_gema
    push si
    mov si, OFFSET sprite_gema_mask
    jmp dhh_dibujar

dhh_tipo3:
    mov di, OFFSET sprite_moneda
    push si
    mov si, OFFSET sprite_moneda_mask

dhh_dibujar:
    call dibujar_sprite_planar_16x16_opt
    pop si

dhh_next:
    inc si
    jmp dhh_loop_slots

dhh_fin:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_hud_hotbar ENDP

reproducir_sonido_victoria PROC
    push ax
    push cx
    mov     ax, 4560
    call    PlayNote
    call    SoundDurationDelay
    call    SoundDurationDelay
    mov     ax, 3620
    call    PlayNote
    call    SoundDurationDelay
    call    SoundDurationDelay
    mov     ax, 3044
    call    PlayNote
    call    SoundDurationDelay
    call    SoundDurationDelay
    call    SoundDurationDelay
    call    SoundDurationDelay
    call    SpeakerOff
    call    SoundDurationDelay
    call    SoundDurationDelay
    mov     ax, 1710
    call    PlayNote
    call    SoundDurationDelay
    call    SoundDurationDelay
    mov     ax, 1810
    call    PlayNote
    call    SoundDurationDelay
    call    SoundDurationDelay
    mov     ax, 1522
    call    PlayNote
    call    SoundDurationDelay
    call    SoundDurationDelay
    call    SpeakerOff
    call    SoundDurationDelay
    mov     ax, 2280
    call    PlayNote
    call    SoundDurationDelay
    call    SoundDurationDelay
    call    SoundDurationDelay
    call    SoundDurationDelay
    call    SoundDurationDelay
    call    SoundDurationDelay
    call    SoundDurationDelay
    call    SoundDurationDelay
    call    SpeakerOff
    pop cx
    pop ax
    ret
reproducir_sonido_victoria ENDP

dibujar_caracter_zoom_2x_buffer PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push es

    mov ax, VIDEO_SEG
    mov es, ax

    call obtener_ptr_glifo
    jnc dcz_continue
    jmp dcz_exit

dcz_continue:
    mov bp, si
    xor di, di

dcz_row_loop:
    cmp di, 8
    jae dcz_exit

    mov al, [bp + di]
    mov font_row_mask, al
    
    mov si, 8
    xor bx, bx

dcz_bit_loop:
    test si, si
    jz dcz_next_row

    mov al, font_row_mask
    test al, 80h
    jz dcz_skip_pixel

    push bp
    push si
    push di
    push bx
    
    mov ah, 0Ch
    mov al, [texto_color_actual]
    mov bh, 0
    
    mov bp, bx
    shl bp, 1
    add bp, cx
    
    mov si, di
    shl si, 1
    add si, dx
    
    push cx
    push dx
    
    mov cx, bp
    mov dx, si
    int 10h
    
    inc cx
    int 10h
    
    inc dx
    int 10h

    dec cx
    int 10h
    
    pop dx
    pop cx
    
    pop bx
    pop di
    pop si
    pop bp

dcz_skip_pixel:
    mov al, font_row_mask
    shl al, 1
    mov font_row_mask, al
    inc bx
    dec si
    jmp dcz_bit_loop

dcz_next_row:
    inc di
    jmp dcz_row_loop

dcz_exit:
    pop es
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_caracter_zoom_2x_buffer ENDP

dibujar_texto_zoom_2x_buffer PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov texto_color_actual, al

dtzb_loop:
    lodsb
    test al, al
    jz dtzb_fin

    cmp al, ' '
    je dtzb_space

    push cx
    push dx
    push si
    call dibujar_caracter_zoom_2x_buffer
    pop si
    pop dx
    pop cx

dtzb_space:
    add cx, 16
    jmp dtzb_loop

dtzb_fin:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_texto_zoom_2x_buffer ENDP

dibujar_caracter_buffer_2x PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push es

    call obtener_ptr_glifo
    jnc dcb2x_continue
    jmp dcb2x_exit

dcb2x_continue:
    mov ax, VIDEO_SEG
    mov es, ax

    mov bx, dx
    shl bx, 1
    mov bp, [video_offsets + bx]
    mov ax, cx
    shr ax, 3
    add bp, ax
    add bp, temp_offset

    mov word ptr [dcb_glyph_ptr], si

    mov al, texto_color_actual
    and al, 0Fh
    mov byte ptr [dcb_color], al

    mov bx, OFFSET zoom_lookup_table

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

    mov cx, 8
dcb2x_p0:
    push cx
    call dcb2x_p0_iter
    pop cx
    loop dcb2x_p0

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

    mov cx, 8
dcb2x_p1:
    push cx
    call dcb2x_p1_iter
    pop cx
    loop dcb2x_p1

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

    mov cx, 8
dcb2x_p2:
    push cx
    call dcb2x_p2_iter
    pop cx
    loop dcb2x_p2

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
dcb2x_p3:
    push cx
    call dcb2x_p3_iter
    pop cx
    loop dcb2x_p3

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

dcb2x_exit:
    pop es
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
  dibujar_caracter_buffer_2x ENDP

dcb2x_p0_iter PROC NEAR
    mov ax, 8
    sub al, cl

    mov di, ax
    mov dx, ax
    shl di, 7
    shl dx, 5
    add di, dx
    add di, bp

    mov si, word ptr [dcb_glyph_ptr]
    add si, ax
    mov ah, [si]

    mov al, ah
    shr al, 4
    and ah, 0Fh

    push ax
    xlat
    mov dh, al
    pop ax

    mov al, ah
    xlat
    mov dl, al

    mov ah, dh
    mov al, ah
    not al
    and al, es:[di]
    mov ch, byte ptr [dcb_color]
    test ch, 1
    jz dcb2x_p0_s1
    and ah, 0FFh
    or al, ah
dcb2x_p0_s1:
    mov es:[di], al
    mov es:[di+80], al

    mov ah, dl
    mov al, ah
    not al
    and al, es:[di + 1]
    mov ch, byte ptr [dcb_color]
    test ch, 1
    jz dcb2x_p0_s2
    and ah, 0FFh
    or al, ah
dcb2x_p0_s2:
    mov es:[di + 1], al
    mov es:[di + 81], al

    ret
dcb2x_p0_iter ENDP

dcb2x_p1_iter PROC NEAR
    mov ax, 8
    sub al, cl

    mov di, ax
    mov dx, ax
    shl di, 7
    shl dx, 5
    add di, dx
    add di, bp

    mov si, word ptr [dcb_glyph_ptr]
    add si, ax
    mov ah, [si]

    mov al, ah
    shr al, 4
    and ah, 0Fh

    push ax
    xlat
    mov dh, al
    pop ax

    mov al, ah
    xlat
    mov dl, al

    mov ah, dh
    mov al, ah
    not al
    and al, es:[di]
    mov ch, byte ptr [dcb_color]
    test ch, 2
    jz dcb2x_p1_s1
    and ah, 0FFh
    or al, ah
dcb2x_p1_s1:
    mov es:[di], al
    mov es:[di+80], al

    mov ah, dl
    mov al, ah
    not al
    and al, es:[di + 1]
    mov ch, byte ptr [dcb_color]
    test ch, 2
    jz dcb2x_p1_s2
    and ah, 0FFh
    or al, ah
dcb2x_p1_s2:
    mov es:[di + 1], al
    mov es:[di + 81], al

    ret
dcb2x_p1_iter ENDP

dcb2x_p2_iter PROC NEAR
    mov ax, 8
    sub al, cl

    mov di, ax
    mov dx, ax
    shl di, 7
    shl dx, 5
    add di, dx
    add di, bp

    mov si, word ptr [dcb_glyph_ptr]
    add si, ax
    mov ah, [si]

    mov al, ah
    shr al, 4
    and ah, 0Fh

    push ax
    xlat
    mov dh, al
    pop ax

    mov al, ah
    xlat
    mov dl, al

    mov ah, dh
    mov al, ah
    not al
    and al, es:[di]
    mov ch, byte ptr [dcb_color]
    test ch, 4
    jz dcb2x_p2_s1
    and ah, 0FFh
    or al, ah
dcb2x_p2_s1:
    mov es:[di], al
    mov es:[di+80], al

    mov ah, dl
    mov al, ah
    not al
    and al, es:[di + 1]
    mov ch, byte ptr [dcb_color]
    test ch, 4
    jz dcb2x_p2_s2
    and ah, 0FFh
    or al, ah
dcb2x_p2_s2:
    mov es:[di + 1], al
    mov es:[di + 81], al

    ret
dcb2x_p2_iter ENDP

dcb2x_p3_iter PROC NEAR
    mov ax, 8
    sub al, cl

    mov di, ax
    mov dx, ax
    shl di, 7
    shl dx, 5
    add di, dx
    add di, bp

    mov si, word ptr [dcb_glyph_ptr]
    add si, ax
    mov ah, [si]

    mov al, ah
    shr al, 4
    and ah, 0Fh

    push ax
    xlat
    mov dh, al
    pop ax

    mov al, ah
    xlat
    mov dl, al

    mov ah, dh
    mov al, ah
    not al
    and al, es:[di]
    mov ch, byte ptr [dcb_color]
    test ch, 8
    jz dcb2x_p3_s1
    and ah, 0FFh
    or al, ah
dcb2x_p3_s1:
    mov es:[di], al
    mov es:[di+80], al

    mov ah, dl
    mov al, ah
    not al
    and al, es:[di + 1]
    mov ch, byte ptr [dcb_color]
    test ch, 8
    jz dcb2x_p3_s2
    and ah, 0FFh
    or al, ah
dcb2x_p3_s2:
    mov es:[di + 1], al
    mov es:[di + 81], al

    ret
dcb2x_p3_iter ENDP

  dibujar_texto_buffer_2x PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    mov texto_color_actual, al

    mov ax, VIDEO_SEG
    mov es, ax

dtb2x_loop:
    lodsb
    test al, al
    jz dtb2x_fin

    cmp al, ' '
    je dtb2x_space

    push cx
    push dx
    push si
    call dibujar_caracter_buffer_2x
    pop si
    pop dx
    pop cx

dtb2x_space:
    add cx, 16
    jmp dtb2x_loop

dtb2x_fin:
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_texto_buffer_2x ENDP

pantalla_victoria PROC
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov al, pagina_dibujo
    test al, 1
    jz pv_render_p0
    mov temp_offset, 8000h
    jmp pv_limpiar

pv_render_p0:
    mov temp_offset, 0

pv_limpiar:
    call limpiar_pagina_actual
    call reproducir_sonido_victoria
    
    mov cx, 160
    mov dx, 120
    mov ax, 320
    mov bx, 110
    mov si, COLOR_MARCO
    call dibujar_rectangulo_vacio
    
    mov cx, 248
    mov dx, 160
    mov si, OFFSET msg_victoria
    mov al, COLOR_TEXTO
    call dibujar_texto_buffer_2x

    mov cx, 260
    mov dx, 200
    mov si, OFFSET msg_victoria_sub
    mov al, COLOR_TEXTO
    call dibujar_texto_buffer

    mov ah, 5
    mov al, pagina_dibujo
    int 10h
    
pv_clear_buffer:
    mov ah, 1
    int 16h
    jz pv_wait_key
    mov ah, 0
    int 16h
    jmp pv_clear_buffer

pv_wait_key:
    mov ah, 1
    int 16h
    jz pv_wait_key

    mov ah, 0
    int 16h
    
    cmp ah, 01h
    jne pv_wait_key
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
pantalla_victoria ENDP

dibujar_hud_vida PROC
	push ax
	push bx
	push cx
	push dx
	push si
	push di

	mov cx, 8
	mov dx, 10
	mov si, OFFSET msg_vida
	mov al, COLOR_TEXTO
	call dibujar_texto_buffer

	mov ax, [jugador_vida]
	mov bx, 100
	mul bx
	mov bx, [jugador_vida_maxima]
	div bx
	
	mov bx, ax

	mov cx, 48
	mov dx, 10
	push bx
	mov ax, 100
	mov bx, 8
	mov si, COLOR_BARRA_VACIA
	call dibujar_rectangulo_lleno
	
	pop bx
	mov cx, 48
	mov dx, 10
	mov ax, bx
	mov bx, 8
	mov si, COLOR_BARRA_LLENA
	call dibujar_rectangulo_lleno

	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
dibujar_hud_vida ENDP

reproducir_sonido_daño PROC
	push ax
	push bx
	push cx
	push dx
	
	mov al, 0B6h
	out 43h, al
	
	mov ax, 3030
	out 42h, al
	mov al, ah
	out 42h, al
	
	in al, 61h
	mov bl, al
	or al, 3
	out 61h, al
	
	mov cx, 1500
rsd_delay:
	loop rsd_delay
	
	mov al, bl
	out 61h, al
	
	pop dx
	pop cx
	pop bx
	pop ax
	ret
reproducir_sonido_daño ENDP

aplicar_daño PROC
	push ax
	push bx

	cmp jugador_vida, 0
	je ad_fin
	
	mov bx, ax
	mov ax, jugador_vida
	sub ax, bx
	
	jge ad_no_muerto
	xor ax, ax
	mov jugador_muerto, 1
	
ad_no_muerto:
	mov jugador_vida, ax
	mov requiere_redibujar, 2
	call reproducir_sonido_daño

ad_fin:
	pop bx
	pop ax
	ret
aplicar_daño ENDP

actualizar_estado_jugador PROC
	push ax
	push bx

	cmp jugador_muerto, 1
	je aej_fin
	
	cmp jugador_invencible_timer, 0
	jne aej_dec_inv
	jmp aej_check_poison
aej_dec_inv:
	dec jugador_invencible_timer
	
aej_check_poison:
	cmp jugador_veneno_timer, 0
	jne aej_dec_poison
	jmp aej_check_tile
aej_dec_poison:
	dec jugador_veneno_timer
	
	cmp jugador_invencible_timer, 0
	jne aej_check_tile
	
	mov ax, jugador_veneno_timer
	mov bl, 18
	xor dx, dx
	div bl
	cmp dx, 0
	jne aej_check_tile
	
	mov ax, VENENO_DAÑO
	call aplicar_daño
	mov jugador_invencible_timer, 10
	
aej_check_tile:
	call get_tile_under_player
	
	cmp al, TILE_LAVA
	je aej_lava
	
	cmp al, TILE_LODO
	je aej_lodo
	
	jmp aej_fin
	
aej_lava:
	cmp jugador_invencible_timer, 0
	jne aej_fin
	
	mov ax, LAVA_DAÑO
	call aplicar_daño
	mov jugador_invencible_timer, INVENCIBLE_DURACION
	jmp aej_fin

aej_lodo:
	mov jugador_veneno_timer, VENENO_DURACION
	
aej_fin:
	pop bx
	pop ax
	ret
actualizar_estado_jugador ENDP

pantalla_muerte PROC
    push ax
    push bx
    push cx
    push dx
    push si
	
	mov al, pagina_dibujo
	test al, 1
	jz pm_render_p0
	mov temp_offset, 8000h
	jmp pm_limpiar

pm_render_p0:
	mov temp_offset, 0

pm_limpiar:
	call limpiar_pagina_actual
	
	mov cx, 240
	mov dx, 175
	mov si, OFFSET msg_muerto
	mov al, COLOR_TEXTO
	call dibujar_texto_buffer
	
	mov ah, 5
	mov al, pagina_dibujo
	int 10h

pm_clear_buffer:
    mov ah, 1
    int 16h
    jz pm_wait_key
    mov ah, 0
    int 16h
    jmp pm_clear_buffer

pm_wait_key:
	mov ah, 0
	int 16h
	
    cmp ah, 01h
    je pm_exit
	
	jmp pm_wait_key

pm_exit:
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	jmp fin_juego
pantalla_muerte ENDP