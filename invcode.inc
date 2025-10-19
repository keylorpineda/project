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
    
    ; Obtener tile del jugador
    mov cx, jugador_px
    shr cx, 4                   ; Convertir a tile X
    
    mov dx, jugador_py
    shr dx, 4                   ; Convertir a tile Y
    
    ; Recorrer todos los recursos
    xor si, si                  ; Índice de recurso
    mov bx, 1                   ; Máscara de bit

vcr_loop:
    cmp si, NUM_RECURSOS
    jae vcr_fin
    
    ; Verificar si ya fue recogido
    push bx
    mov ax, recursos_recogidos
    and ax, bx
    pop bx
    jnz vcr_next                ; Ya recogido, saltar
    
    ; Obtener posición del recurso
    push cx
    push dx
    
    mov ax, si
    mov cl, 3                   ; Multiplicar por 3 (cada entrada son 3 bytes)
    mul cl
    mov di, ax
    
    movzx ax, byte ptr [recursos_mapa + di]     ; X del recurso
    mov cx, ax
    
    movzx ax, byte ptr [recursos_mapa + di + 1] ; Y del recurso
    mov dx, ax
    
    pop ax                      ; AX = jugador Y
    pop di                      ; DI = jugador X
    
    ; Verificar si está en el mismo tile
    cmp di, cx
    jne vcr_next
    cmp ax, dx
    jne vcr_next
    
    ; ¡COLISIÓN! Recoger recurso
    call recoger_recurso
    
vcr_next:
    shl bx, 1                   ; Siguiente bit
    inc si
    jmp vcr_loop
    
vcr_fin:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
verificar_colision_recursos ENDP

; ============================================
; RECOGER RECURSO
; Entrada: SI = índice del recurso, BX = máscara de bit
; ============================================
recoger_recurso PROC
    push ax
    push bx
    push di
    
    ; Marcar como recogido
    or recursos_recogidos, bx
    
    ; Obtener tipo de recurso
    mov ax, si
    mov cl, 3
    mul cl
    mov di, ax
    
    movzx ax, byte ptr [recursos_mapa + di + 2] ; Tipo (1, 2 o 3)
    
    ; Incrementar contador según tipo
    cmp al, 1
    jne rr_tipo2
    inc recursos_tipo1
    jmp rr_fin
    
rr_tipo2:
    cmp al, 2
    jne rr_tipo3
    inc recursos_tipo2
    jmp rr_fin
    
rr_tipo3:
    inc recursos_tipo3
    
rr_fin:
    ; Activar animación de recolección
    mov anim_recoger_activa, 1
    mov anim_recoger_frame, 0
    mov ax, jugador_px
    mov anim_recoger_x, ax
    mov ax, jugador_py
    sub ax, 32                  ; Aparecer arriba del jugador
    mov anim_recoger_y, ax
    
    pop di
    pop bx
    pop ax
    ret
recoger_recurso ENDP

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
    cmp si, NUM_RECURSOS
    jae drm_fin
    
    ; Verificar si ya fue recogido
    push bx
    mov ax, recursos_recogidos
    and ax, bx
    pop bx
    jnz drm_next
    
    ; Obtener posición del recurso
    push bx
    push si
    
    mov ax, si
    mov cl, 3
    mul cl
    mov di, ax
    
    movzx ax, byte ptr [recursos_mapa + di]     ; X (en tiles)
    shl ax, 4                                     ; Convertir a píxeles
    mov cx, ax
    
    movzx ax, byte ptr [recursos_mapa + di + 1]  ; Y (en tiles)
    shl ax, 4
    mov dx, ax
    
    ; Verificar si está visible en viewport
    mov ax, cx
    sub ax, camara_px
    cmp ax, -16
    jl drm_next_pop
    cmp ax, 320
    jg drm_next_pop
    
    mov ax, dx
    sub ax, camara_py
    cmp ax, -16
    jl drm_next_pop
    cmp ax, 192
    jg drm_next_pop
    
    ; Calcular posición en pantalla
    mov ax, cx
    sub ax, camara_px
    add ax, viewport_x
    mov cx, ax
    
    mov ax, dx
    sub ax, camara_py
    add ax, viewport_y
    mov dx, ax
    
    ; Obtener sprite según tipo
    movzx ax, byte ptr [recursos_mapa + di + 2] ; Tipo
    
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
    je di_fin
    
    ; Dibujar fondo semitransparente (simplificado: rectángulo oscuro)
    mov cx, INV_X
    mov dx, INV_Y
    mov ax, INV_WIDTH
    mov bx, INV_HEIGHT
    mov al, COLOR_FONDO
    call dibujar_rectangulo_lleno
    
    ; Dibujar marco
    mov cx, INV_X
    mov dx, INV_Y
    mov ax, INV_WIDTH
    mov bx, INV_HEIGHT
    mov al, COLOR_MARCO
    call dibujar_rectangulo_vacio
    
    ; Dibujar sprite del jugador (izquierda)
    call dibujar_jugador_inventario
    
    ; Dibujar slots de items (centro)
    call dibujar_slots_items
    
    ; Dibujar estadísticas (derecha)
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

; ============================================
; DIBUJAR JUGADOR EN INVENTARIO
; ============================================
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

; ============================================
; DIBUJAR SLOTS DE ITEMS (8 espacios: 2 filas × 4 columnas)
; ============================================
dibujar_slots_items PROC
    push ax
    push bx
    push cx
    push dx
    push si
    
    xor si, si                  ; Contador de slot
    
dsi_loop:
    cmp si, MAX_ITEMS
    jae dsi_fin
    
    ; Calcular posición del slot
    mov ax, si
    and ax, 3                   ; Columna (0-3)
    mov bx, ITEM_SIZE
    add bx, ITEM_SPACING
    mul bx
    add ax, ZONA_ITEMS_X
    mov cx, ax                  ; CX = X del slot
    
    mov ax, si
    shr ax, 2                   ; Fila (0-1)
    mov bx, ITEM_SIZE
    add bx, ITEM_SPACING
    mul bx
    add ax, ZONA_ITEMS_Y
    mov dx, ax                  ; DX = Y del slot
    
    ; Dibujar marco del slot
    push cx
    push dx
    mov ax, ITEM_SIZE
    mov bx, ITEM_SIZE
    mov al, COLOR_ITEM_SLOT
    call dibujar_rectangulo_vacio
    pop dx
    pop cx
    
    ; TODO: Dibujar item si el slot tiene algo
    ; (Por ahora solo mostramos slots vacíos)
    
    inc si
    jmp dsi_loop
    
dsi_fin:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_slots_items ENDP

; ============================================
; DIBUJAR ESTADÍSTICAS (contadores y barras de progreso)
; ============================================
dibujar_estadisticas PROC
    push ax
    push bx
    push cx
    push dx
    
    ; Base Y para los textos
    mov dx, ZONA_STATS_Y
    
    ; Dibujar "RECURSOS"
    mov cx, ZONA_STATS_X
    push dx
    mov si, OFFSET msg_recursos
    mov al, COLOR_TEXTO
    call dibujar_texto_simple
    pop dx
    
    add dx, 16
    
    ; Cristales: "Cristales: X/2"
    mov cx, ZONA_STATS_X
    push dx
    mov si, OFFSET msg_cristales
    mov al, COLOR_TEXTO
    call dibujar_texto_simple
    pop dx
    
    ; Dibujar contador
    add cx, 80
    movzx ax, recursos_tipo1
    call dibujar_numero
    
    add dx, 12
    
    ; Barra de progreso de cristales
    mov cx, ZONA_STATS_X
    push dx
    movzx ax, recursos_tipo1
    mov bx, META_POR_TIPO
    call dibujar_barra_progreso
    pop dx
    
    add dx, 20
    
    ; Gemas: "Gemas: X/2"
    mov cx, ZONA_STATS_X
    push dx
    mov si, OFFSET msg_gemas
    mov al, COLOR_TEXTO
    call dibujar_texto_simple
    pop dx
    
    add cx, 80
    movzx ax, recursos_tipo2
    call dibujar_numero
    
    add dx, 12
    
    ; Barra de progreso de gemas
    mov cx, ZONA_STATS_X
    push dx
    movzx ax, recursos_tipo2
    mov bx, META_POR_TIPO
    call dibujar_barra_progreso
    pop dx
    
    add dx, 20
    
    ; Monedas: "Monedas: X/2"
    mov cx, ZONA_STATS_X
    push dx
    mov si, OFFSET msg_monedas
    mov al, COLOR_TEXTO
    call dibujar_texto_simple
    pop dx
    
    add cx, 80
    movzx ax, recursos_tipo3
    call dibujar_numero
    
    add dx, 12
    
    ; Barra de progreso de monedas
    mov cx, ZONA_STATS_X
    movzx ax, recursos_tipo3
    mov bx, META_POR_TIPO
    call dibujar_barra_progreso
    
    ; Verificar victoria
    cmp recursos_tipo1, META_POR_TIPO
    jb de_no_victoria
    cmp recursos_tipo2, META_POR_TIPO
    jb de_no_victoria
    cmp recursos_tipo3, META_POR_TIPO
    jb de_no_victoria
    
    ; ¡VICTORIA! Mostrar mensaje
    add dx, 30
    mov cx, ZONA_STATS_X
    mov si, OFFSET msg_completado
    mov al, 10                  ; Verde claro
    call dibujar_texto_simple
    
de_no_victoria:
    pop dx
    pop cxpop bx
    pop ax
    ret
dibujar_estadisticas ENDP

; ============================================
; DIBUJAR BARRA DE PROGRESO
; Entrada: CX = X, DX = Y, AX = valor actual, BX = valor máximo
; ============================================
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
    mov ax, 60                  ; Ancho de la barra
    mov bx, 8                   ; Alto de la barra
    mov al, COLOR_BARRA_VACIA
    call dibujar_rectangulo_lleno
    pop dx
    pop cx
    
    ; Calcular ancho de la barra llena
    mov ax, si                  ; Valor actual
    mov bx, 60                  ; Ancho total
    mul bx
    div di                      ; Dividir por valor máximo
    
    ; Si es 0, no dibujar nada
    test ax, ax
    jz dbp_fin
    
    ; Dibujar barra llena
    mov bx, ax                  ; BX = ancho calculado
    mov ax, bx                  ; AX también
    mov bx, 8                   ; Alto
    mov al, COLOR_BARRA_LLENA
    call dibujar_rectangulo_lleno
    
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
; Entrada: CX = X, DX = Y, AX = ancho, BX = alto, AL (último) = color
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
    mov si, bx                  ; SI = alto
    mov di, ax                  ; Guardar ancho antes de que AL cambie
    and di, 0FFh                ; DI = color (solo byte bajo)
    
    mov ax, VIDEO_SEG
    mov es, ax
    
drl_fila:
    test si, si
    jz drl_fin
    
    push cx
    push dx
    
    ; Calcular offset de video
    mov bx, dx
    shl bx, 1
    mov ax, [video_offsets + bx]
    mov bx, cx
    shr bx, 3                   ; Dividir X por 8
    add ax, bx
    add ax, temp_offset
    mov bx, ax                  ; BX = offset de video
    
    ; Dibujar línea horizontal
    mov ax, di                  ; AL = color
    
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
    shr cx, 3                   ; Convertir a bytes
    
drl_pixel:
    mov es:[bx], al
    inc bx
    loop drl_pixel
    
    pop dx
    pop cx
    
    inc dx                      ; Siguiente fila
    dec si
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
; Entrada: CX = X, DX = Y, AX = ancho, BX = alto, AL (último) = color
; ============================================
dibujar_rectangulo_vacio PROC
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov si, ax                  ; Guardar ancho
    and si, 0FFh                ; SI = color
    push ax
    push bx
    
    ; Línea superior
    push cx
    push dx
    pop ax                      ; AX = ancho original
    mov bx, 1                   ; Alto = 1
    mov al, sil                 ; Color
    call dibujar_rectangulo_lleno
    pop dx
    pop cx
    
    ; Línea inferior
    pop bx                      ; Recuperar alto original
    push bx
    add dx, bx
    dec dx
    push cx
    push dx
    pop ax
    mov bx, 1
    mov al, sil
    call dibujar_rectangulo_lleno
    pop dx
    pop cx
    sub dx, bx
    inc dx
    
    ; Línea izquierda
    pop bx                      ; Alto original
    pop ax                      ; Ancho original
    push ax
    push bx
    push cx
    push dx
    mov ax, 8                   ; Ancho = 8 píxeles
    ; BX ya tiene el alto
    mov al, sil
    call dibujar_rectangulo_lleno
    pop dx
    pop cx
    
    ; Línea derecha
    pop bx
    pop ax
    add cx, ax
    sub cx, 8
    mov ax, 8
    ; BX ya tiene el alto
    mov al, sil
    call dibujar_rectangulo_lleno
    
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
; Nota: Usa fuente 8x8 de la BIOS (simplificado)
; ============================================
dibujar_texto_simple PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov bl, al                  ; BL = color
    
dts_loop:
    lodsb                       ; Cargar carácter
    test al, al                 ; ¿Fin de string?
    jz dts_fin
    
    ; Dibujar carácter (simplificado - solo un píxel por ahora)
    ; TODO: Implementar fuente bitmap completa
    
    add cx, 8                   ; Siguiente posición X
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

; ============================================
; DIBUJAR NÚMERO (0-99)
; Entrada: CX = X, DX = Y, AX = número
; ============================================
dibujar_numero PROC
    push ax
    push bx
    push cx
    push dx
    
    ; Convertir número a ASCII
    mov bl, 10
    div bl                      ; AH = unidades, AL = decenas
    
    ; Si las decenas son 0, solo dibujar unidades
    test al, al
    jz dn_unidades
    
    ; Dibujar decenas
    add al, '0'
    push ax
    push cx
    push dx
    mov si, sp
    add si, 6                   ; Apuntar al carácter
    mov al, COLOR_TEXTO
    call dibujar_texto_simple
    pop dx
    pop cx
    pop ax
    
    add cx, 8                   ; Siguiente posición
    
dn_unidades:
    ; Dibujar unidades
    mov al, ah
    add al, '0'
    push ax
    push cx
    push dx
    mov si, sp
    add si, 6
    mov al, COLOR_TEXTO
    call dibujar_texto_simple
    pop dx
    pop cx
    pop ax
    
    pop dx
    pop cx
    pop bx
    pop ax
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