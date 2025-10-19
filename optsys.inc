; ============================================
; OPTSYS.INC - VERSIÓN SIMPLIFICADA PARA DIAGNÓSTICO
; (SIN DIRTY TILES - DIBUJA TODO CADA FRAME)
; ============================================

inicializar_sistema_opt PROC
    push ax
    push bx
    
    call init_sprite_table
    
    ; Inicializar force_full_redraw en 1 (siempre dibujar todo)
    mov force_full_redraw, 1
    mov frame_counter_opt, 0
    
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
; FUNCIONES DUMMY PARA COMPATIBILIDAD
; ============================================

marcar_tiles_afectados PROC
    ; No hace nada - versión de diagnóstico
    ret
marcar_tiles_afectados ENDP

tile_esta_sucio PROC
    ; ✅ SIEMPRE devuelve "sucio" (ZF=0)
    mov al, 1
    or al, al
    ret
tile_esta_sucio ENDP

limpiar_dirty_flags PROC
    ; No hace nada
    ret
limpiar_dirty_flags ENDP