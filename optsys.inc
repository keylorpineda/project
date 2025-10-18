; ============================================
; OPTSYS.INC - Sistema de Optimización FASE 1
; Universidad Nacional - Proyecto II Ciclo 2025
; ============================================
; IMPLEMENTACIÓN DESDE CERO:
; - Tabla de punteros de sprites (sin comparaciones)
; - Sistema de dirty tiles (redibujo selectivo)
; ============================================

; ============================================
; DATOS DEL SISTEMA DE OPTIMIZACIÓN
; ============================================

; --- Tabla de Punteros de Sprites (256 entradas) ---
sprite_data_ptrs    dw 256 dup(0)
sprite_mask_ptrs    dw 256 dup(0)

; --- Sistema de Dirty Tiles ---
dirty_map           db 273 dup(0)    ; 21×13 = 273 tiles en viewport
frame_counter_opt   db 0
force_full_redraw   db 1             ; Flag: 1=forzar redibujado completo

; --- Caché de Estado Anterior ---
last_cam_tile_x     dw 0
last_cam_tile_y     dw 0
last_player_tile_x  dw 0
last_player_tile_y  dw 0

; ============================================
; INICIALIZACIÓN DEL SISTEMA
; ============================================

inicializar_sistema_opt PROC
    push ax
    push bx
    push cx
    
    ; ===== PASO 1: Inicializar tabla de punteros =====
    call init_sprite_table
    
    ; ===== PASO 2: Limpiar dirty map =====
    mov cx, 273
    xor ax, ax
    mov bx, OFFSET dirty_map
iso_clear_loop:
    mov [bx], al
    inc bx
    loop iso_clear_loop
    
    ; ===== PASO 3: Forzar primer frame completo =====
    mov force_full_redraw, 1
    mov frame_counter_opt, 0
    
    ; ===== PASO 4: Inicializar caché =====
    mov ax, 0FFFFh
    mov last_cam_tile_x, ax
    mov last_cam_tile_y, ax
    mov last_player_tile_x, ax
    mov last_player_tile_y, ax
    
    pop cx
    pop bx
    pop ax
    ret
inicializar_sistema_opt ENDP

; ============================================
; TABLA DE PUNTEROS - Mapeo de Tiles
; ============================================

init_sprite_table PROC
    push ax
    push bx
    
    ; Por defecto: GRASS1 para todos los tiles
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
    
    ; ===== Mapear cada tipo de tile =====
    
    ; TILE_PATH (3)
    mov bx, TILE_PATH
    shl bx, 1
    mov word ptr [sprite_data_ptrs + bx], OFFSET sprite_path
    mov word ptr [sprite_mask_ptrs + bx], OFFSET sprite_path_mask
    
    ; TILE_WATER (4)
    mov bx, TILE_WATER
    shl bx, 1
    mov word ptr [sprite_data_ptrs + bx], OFFSET sprite_water
    mov word ptr [sprite_mask_ptrs + bx], OFFSET sprite_water_mask
    
    ; TILE_TREE (5)
    mov bx, TILE_TREE
    shl bx, 1
    mov word ptr [sprite_data_ptrs + bx], OFFSET sprite_tree
    mov word ptr [sprite_mask_ptrs + bx], OFFSET sprite_tree_mask
    
    ; TILE_SAND (6)
    mov bx, TILE_SAND
    shl bx, 1
    mov word ptr [sprite_data_ptrs + bx], OFFSET sprite_sand
    mov word ptr [sprite_mask_ptrs + bx], OFFSET sprite_sand_mask
    
    ; TILE_ROCK (7)
    mov bx, TILE_ROCK
    shl bx, 1
    mov word ptr [sprite_data_ptrs + bx], OFFSET sprite_rock
    mov word ptr [sprite_mask_ptrs + bx], OFFSET sprite_rock_mask
    
    ; TILE_SNOW (8)
    mov bx, TILE_SNOW
    shl bx, 1
    mov word ptr [sprite_data_ptrs + bx], OFFSET sprite_snow
    mov word ptr [sprite_mask_ptrs + bx], OFFSET sprite_snow_mask
    
    ; TILE_ICE (9)
    mov bx, TILE_ICE
    shl bx, 1
    mov word ptr [sprite_data_ptrs + bx], OFFSET sprite_ice
    mov word ptr [sprite_mask_ptrs + bx], OFFSET sprite_ice_mask
    
    ; TILE_WALL (10)
    mov bx, TILE_WALL
    shl bx, 1
    mov word ptr [sprite_data_ptrs + bx], OFFSET sprite_wall
    mov word ptr [sprite_mask_ptrs + bx], OFFSET sprite_wall_mask
    
    ; TILE_DIRT (13)
    mov bx, TILE_DIRT
    shl bx, 1
    mov word ptr [sprite_data_ptrs + bx], OFFSET sprite_dirt
    mov word ptr [sprite_mask_ptrs + bx], OFFSET sprite_dirt_mask
    
    ; TILE_LAVA (14)
    mov bx, TILE_LAVA
    shl bx, 1
    mov word ptr [sprite_data_ptrs + bx], OFFSET sprite_lava
    mov word ptr [sprite_mask_ptrs + bx], OFFSET sprite_lava_mask
    
    ; TILE_BRIDGE (15)
    mov bx, TILE_BRIDGE
    shl bx, 1
    mov word ptr [sprite_data_ptrs + bx], OFFSET sprite_bridge
    mov word ptr [sprite_mask_ptrs + bx], OFFSET sprite_bridge_mask
    
    pop bx
    pop ax
    ret
init_sprite_table ENDP

; ============================================
; OBTENER SPRITE (3 CICLOS vs 40+ antes)
; ============================================

obtener_sprite_rapido PROC
    ; Entrada: AL = tipo de tile
    ; Salida: DI = datos planar, SI = máscara
    push bx
    
    movzx bx, al
    shl bx, 1
    mov di, [sprite_data_ptrs + bx]
    mov si, [sprite_mask_ptrs + bx]
    
    pop bx
    ret
obtener_sprite_rapido ENDP

; ============================================
; SISTEMA DE DIRTY TILES
; ============================================

marcar_tiles_afectados PROC
    push ax
    push bx
    push cx
    push dx
    
    ; Incrementar frame counter
    inc frame_counter_opt
    
    ; ===== DETECTAR MOVIMIENTO DE CÁMARA =====
    mov ax, inicio_tile_x
    cmp ax, last_cam_tile_x
    jne mta_camara_movio
    
    mov ax, inicio_tile_y
    cmp ax, last_cam_tile_y
    jne mta_camara_movio
    
    jmp mta_check_player

mta_camara_movio:
    ; Si la cámara se movió, forzar redibujado completo
    mov force_full_redraw, 1
    
    ; Actualizar caché de cámara
    mov ax, inicio_tile_x
    mov last_cam_tile_x, ax
    mov ax, inicio_tile_y
    mov last_cam_tile_y, ax
    
    jmp mta_fin

mta_check_player:
    ; ===== DETECTAR MOVIMIENTO DE JUGADOR =====
    ; Calcular tile actual del jugador
    mov ax, jugador_px
    shr ax, 4
    mov bx, ax              ; BX = player_tile_x actual
    
    mov ax, jugador_py
    shr ax, 4
    mov cx, ax              ; CX = player_tile_y actual
    
    ; Comparar con posición anterior
    cmp bx, last_player_tile_x
    jne mta_player_movio
    cmp cx, last_player_tile_y
    jne mta_player_movio
    
    ; No hubo cambios
    jmp mta_fin

mta_player_movio:
    ; ===== MARCAR TILES ANTIGUOS DEL JUGADOR =====
    mov ax, last_player_tile_x
    cmp ax, 0FFFFh
    je mta_skip_old         ; Primera iteración
    
    mov dx, last_player_tile_y
    call marcar_tile_si_visible
    
    inc ax
    call marcar_tile_si_visible
    
    inc dx
    call marcar_tile_si_visible
    
    dec ax
    call marcar_tile_si_visible

mta_skip_old:
    ; ===== MARCAR TILES NUEVOS DEL JUGADOR =====
    mov ax, bx              ; player_tile_x actual
    mov dx, cx              ; player_tile_y actual
    
    call marcar_tile_si_visible
    
    inc ax
    call marcar_tile_si_visible
    
    inc dx
    call marcar_tile_si_visible
    
    dec ax
    call marcar_tile_si_visible
    
    ; Actualizar caché del jugador
    mov last_player_tile_x, bx
    mov last_player_tile_y, cx

mta_fin:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
marcar_tiles_afectados ENDP

; ============================================
; MARCAR UN TILE COMO SUCIO (si está visible)
; ============================================

marcar_tile_si_visible PROC
    ; Entrada: AX = tile_x, DX = tile_y
    push bx
    push cx
    
    ; Convertir a coordenadas relativas al viewport
    sub ax, inicio_tile_x
    sub dx, inicio_tile_y
    
    ; Verificar límites
    cmp ax, 0
    jl mtsv_fin
    cmp ax, 21
    jge mtsv_fin
    cmp dx, 0
    jl mtsv_fin
    cmp dx, 13
    jge mtsv_fin
    
    ; Calcular índice en dirty_map: y×21 + x
    mov bx, dx
    mov cx, 21
    push ax
    mov ax, bx
    mul cx
    pop cx
    add ax, cx
    mov bx, ax
    
    ; Marcar tile
    mov al, frame_counter_opt
    mov [dirty_map + bx], al

mtsv_fin:
    pop cx
    pop bx
    ret
marcar_tile_si_visible ENDP

; ============================================
; VERIFICAR SI UN TILE ESTÁ SUCIO
; ============================================

tile_esta_sucio PROC
    ; Entrada: SI = columna, BP = fila
    ; Salida: ZF=0 (JNZ) si está sucio
    push ax
    push bx
    
    ; Si hay redibujado forzado, todos están sucios
    cmp force_full_redraw, 1
    je tes_sucio
    
    ; Calcular índice: fila×21 + columna
    mov ax, bp
    mov bx, 21
    mul bx
    add ax, si
    mov bx, ax
    
    ; Comparar con frame actual
    mov al, [dirty_map + bx]
    cmp al, frame_counter_opt
    
tes_sucio:
    pop bx
    pop ax
    ret
tile_esta_sucio ENDP

; ============================================
; LIMPIAR FLAGS DE REDIBUJADO
; ============================================

limpiar_dirty_flags PROC
    push ax
    
    mov force_full_redraw, 0
    
    pop ax
    ret
limpiar_dirty_flags ENDP

; ============================================
; FIN DE OPTSYS.INC
; ============================================