; ============================================
; OPTSYS.INC - CORREGIDO FINAL
; ============================================

inicializar_sistema_opt PROC
    push ax
    push bx
    push cx
    push di
    
    call init_sprite_table
    
    ; Limpiar dirty map
    mov di, OFFSET dirty_map
    xor al, al
    mov cx, 273
iso_clear:
    mov [di], al
    inc di
    loop iso_clear
    
    ; ✅ CRÍTICO: Empezar con frame_counter en 1 (no 0)
    mov frame_counter_opt, 1
    mov force_full_redraw, 2
    
    ; Inicializar caché
    mov ax, 0FFFFh
    mov last_cam_tile_x, ax
    mov last_cam_tile_y, ax
    mov last_player_tile_x, ax
    mov last_player_tile_y, ax
    mov last_player_px, ax
    mov last_player_py, ax
    mov last_scroll_offset_x, ax
    mov last_scroll_offset_y, ax

    xor ax, ax
    mov scroll_offset_x_aligned, ax
    mov scroll_pixel_pan_x, al

    pop di
    pop cx
    pop bx
    pop ax
    ret
inicializar_sistema_opt ENDP

init_sprite_table PROC
    push ax
    push bx
    
    mov cx, 256
    mov bx, OFFSET sprite_data_ptrs
ist_default_loop:
    mov word ptr [bx], OFFSET sprite_grass1
    add bx, 2
    loop ist_default_loop
    
    mov cx, 256
    mov bx, OFFSET sprite_mask_ptrs
ist_mask_loop:
    mov word ptr [bx], OFFSET sprite_grass1_mask
    add bx, 2
    loop ist_mask_loop
    
    mov bx, TILE_PATH
    shl bx, 1
    mov word ptr [sprite_data_ptrs + bx], OFFSET sprite_path
    mov word ptr [sprite_mask_ptrs + bx], OFFSET sprite_path_mask
    
    mov bx, TILE_WATER
    shl bx, 1
    mov word ptr [sprite_data_ptrs + bx], OFFSET sprite_water
    mov word ptr [sprite_mask_ptrs + bx], OFFSET sprite_water_mask
    
    mov bx, TILE_TREE
    shl bx, 1
    mov word ptr [sprite_data_ptrs + bx], OFFSET sprite_tree
    mov word ptr [sprite_mask_ptrs + bx], OFFSET sprite_tree_mask
    
    mov bx, TILE_SAND
    shl bx, 1
    mov word ptr [sprite_data_ptrs + bx], OFFSET sprite_sand
    mov word ptr [sprite_mask_ptrs + bx], OFFSET sprite_sand_mask
    
    mov bx, TILE_ROCK
    shl bx, 1
    mov word ptr [sprite_data_ptrs + bx], OFFSET sprite_rock
    mov word ptr [sprite_mask_ptrs + bx], OFFSET sprite_rock_mask
    
    mov bx, TILE_SNOW
    shl bx, 1
    mov word ptr [sprite_data_ptrs + bx], OFFSET sprite_snow
    mov word ptr [sprite_mask_ptrs + bx], OFFSET sprite_snow_mask
    
    mov bx, TILE_ICE
    shl bx, 1
    mov word ptr [sprite_data_ptrs + bx], OFFSET sprite_ice
    mov word ptr [sprite_mask_ptrs + bx], OFFSET sprite_ice_mask
    
    mov bx, TILE_WALL
    shl bx, 1
    mov word ptr [sprite_data_ptrs + bx], OFFSET sprite_wall
    mov word ptr [sprite_mask_ptrs + bx], OFFSET sprite_wall_mask
    
    mov bx, TILE_DIRT
    shl bx, 1
    mov word ptr [sprite_data_ptrs + bx], OFFSET sprite_dirt
    mov word ptr [sprite_mask_ptrs + bx], OFFSET sprite_dirt_mask
    
    mov bx, TILE_LAVA
    shl bx, 1
    mov word ptr [sprite_data_ptrs + bx], OFFSET sprite_lava
    mov word ptr [sprite_mask_ptrs + bx], OFFSET sprite_lava_mask
    
    mov bx, TILE_BRIDGE
    shl bx, 1
    mov word ptr [sprite_data_ptrs + bx], OFFSET sprite_bridge
    mov word ptr [sprite_mask_ptrs + bx], OFFSET sprite_bridge_mask
    
    pop bx
    pop ax
    ret
init_sprite_table ENDP

obtener_sprite_rapido PROC
    push bx
    
    xor bh, bh
    mov bl, al
    shl bx, 1
    mov di, [sprite_data_ptrs + bx]
    mov si, [sprite_mask_ptrs + bx]
    
    pop bx
    ret
obtener_sprite_rapido ENDP

; ============================================
; MARCAR TILES AFECTADOS - CORREGIDO
; ============================================

marcar_tiles_afectados PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; ===== DETECTAR MOVIMIENTO DE CÁMARA =====
    mov bx, inicio_tile_x
    cmp bx, last_cam_tile_x
    jne mta_camara_movio

    mov bx, inicio_tile_y
    cmp bx, last_cam_tile_y
    jne mta_camara_movio

    mov bx, scroll_offset_x
    cmp bx, last_scroll_offset_x
    jne mta_camara_movio

    mov bx, scroll_offset_y
    cmp bx, last_scroll_offset_y
    jne mta_camara_movio

    jmp mta_check_player

mta_camara_movio:
    ; ✅ Incrementar SOLO cuando hay cambio real
    inc frame_counter_opt
    
    mov force_full_redraw, 2
    
    mov ax, inicio_tile_x
    mov last_cam_tile_x, ax
    mov ax, inicio_tile_y
    mov last_cam_tile_y, ax

    mov ax, scroll_offset_x
    mov last_scroll_offset_x, ax
    mov ax, scroll_offset_y
    mov last_scroll_offset_y, ax

    mov ax, jugador_px
    mov last_player_px, ax
    mov ax, jugador_py
    mov last_player_py, ax

    mov ax, jugador_px
    add ax, 8
    shr ax, 4
    mov last_player_tile_x, ax

    mov ax, jugador_py
    add ax, 8
    shr ax, 4
    mov last_player_tile_y, ax

    call marcar_viewport_completo
    jmp mta_fin

mta_check_player:
    mov ax, jugador_px
    cmp ax, last_player_px
    jne mta_player_movio

    mov ax, jugador_py
    cmp ax, last_player_py
    jne mta_player_movio

    jmp mta_fin

mta_player_movio:
    ; ✅ Incrementar SOLO cuando hay cambio
    inc frame_counter_opt
    
    ; Marcar tiles antiguos (2×2)
    mov ax, last_player_px
    cmp ax, 0FFFFh
    je mta_skip_old

    mov si, ax
    mov ax, last_player_py
    mov di, ax

    mov ax, si
    add ax, 8
    shr ax, 4
    mov bx, ax

    mov ax, di
    add ax, 8
    shr ax, 4
    mov cx, ax

    mov ax, bx
    mov dx, cx
    call marcar_tile_si_visible

    mov ax, bx
    inc ax
    mov dx, cx
    call marcar_tile_si_visible

    mov ax, bx
    mov dx, cx
    inc dx
    call marcar_tile_si_visible

    mov ax, bx
    inc ax
    mov dx, cx
    inc dx
    call marcar_tile_si_visible

mta_skip_old:
    ; Marcar tiles nuevos (2×2)
    mov ax, jugador_px
    mov si, ax
    add ax, 8
    shr ax, 4
    mov bx, ax

    mov ax, jugador_py
    mov di, ax
    add ax, 8
    shr ax, 4
    mov cx, ax

    mov ax, bx
    mov dx, cx
    call marcar_tile_si_visible

    mov ax, bx
    inc ax
    mov dx, cx
    call marcar_tile_si_visible

    mov ax, bx
    mov dx, cx
    inc dx
    call marcar_tile_si_visible

    mov ax, bx
    inc ax
    mov dx, cx
    inc dx
    call marcar_tile_si_visible

    mov ax, bx
    mov last_player_tile_x, ax
    mov ax, cx
    mov last_player_tile_y, ax
    mov ax, si
    mov last_player_px, ax
    mov ax, di
    mov last_player_py, ax

mta_fin:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
marcar_tiles_afectados ENDP

marcar_viewport_completo PROC
    push ax
    push cx
    push di

    mov al, frame_counter_opt
    mov di, OFFSET dirty_map
    mov cx, 273

mvc_loop:
    mov [di], al
    inc di
    loop mvc_loop

    pop di
    pop cx
    pop ax
    ret
marcar_viewport_completo ENDP

marcar_tile_si_visible PROC
    push ax
    push bx
    push cx
    push dx
    
    sub ax, inicio_tile_x
    sub dx, inicio_tile_y
    
    cmp ax, 0
    jl mtsv_fin
    cmp ax, 21
    jge mtsv_fin
    cmp dx, 0
    jl mtsv_fin
    cmp dx, 13
    jge mtsv_fin
    
    mov cx, ax
    mov ax, dx
    mov bx, 21
    mul bx
    add ax, cx
    
    cmp ax, 273
    jae mtsv_fin
    
    mov bx, ax
    mov al, frame_counter_opt
    mov [dirty_map + bx], al

mtsv_fin:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
marcar_tile_si_visible ENDP

tile_esta_sucio PROC
    push ax
    push bx
    push cx
    
    cmp force_full_redraw, 0
    je tes_check_normal

    mov al, 1
    or al, al
    jmp tes_fin

tes_check_normal:
    mov ax, bp
    mov cx, 21
    mul cx
    add ax, si
    
    cmp ax, 273
    jae tes_limpio
    
    mov bx, ax
    mov al, [dirty_map + bx]
    cmp al, frame_counter_opt
    jne tes_limpio
    
    or al, 1
    jmp tes_fin

tes_limpio:
    xor al, al

tes_fin:
    pop cx
    pop bx
    pop ax
    ret
tile_esta_sucio ENDP

limpiar_dirty_flags PROC
    push ax
    
    cmp force_full_redraw, 0
    je ldf_done
    dec force_full_redraw

ldf_done:
    pop ax
    ret
limpiar_dirty_flags ENDP