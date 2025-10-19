; ============================================
; INVCODE.INC - Sistema de Inventario COMPLETO Y CORREGIDO
; Universidad Nacional - Proyecto II Ciclo 2025
; ============================================

verificar_colision_recursos PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    ; Calcular hitbox del jugador (32×32 píxeles)
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
    xor ah, ah
    cmp si, ax
    jae vcr_fin                 ; Si procesamos todos, salir

    ; Verificar si ya fue recogido
    mov ax, recursos_recogidos
    test ax, bx
    jnz vcr_next                ; Ya recogido, saltar

    ; Obtener posición del recurso
    mov ax, si
    mov dx, 3
    mul dx                      ; AX = SI × 3
    mov di, ax

    ; Leer X (en tiles) → convertir a píxeles
    mov al, [recursos_mapa + di]
    xor ah, ah
    shl ax, 4                   ; X × 16
    mov cx, ax

    ; Leer Y (en tiles) → convertir a píxeles
    mov al, [recursos_mapa + di + 1]
    xor ah, ah
    shl ax, 4                   ; Y × 16
    mov dx, ax

    ; Calcular límites del recurso (16×16 píxeles)
    mov ax, cx
    add ax, 15
    mov bp, ax                  ; Derecha del recurso

    mov ax, dx
    add ax, 15
    mov di, ax                  ; Parte inferior del recurso

    ; Verificar colisión AABB (Axis-Aligned Bounding Box)
    mov ax, player_right_temp
    cmp ax, cx                  ; ¿Jugador.derecha < Recurso.izquierda?
    jl vcr_next

    mov ax, player_left_temp
    cmp ax, bp                  ; ¿Jugador.izquierda > Recurso.derecha?
    jg vcr_next

    mov ax, player_bottom_temp
    cmp ax, dx                  ; ¿Jugador.abajo < Recurso.arriba?
    jl vcr_next

    mov ax, player_top_temp
    cmp ax, di                  ; ¿Jugador.arriba > Recurso.abajo?
    jg vcr_next

    ; ¡COLISIÓN DETECTADA!
    push bx                     ; Guardar máscara antes de llamar
    push si                     ; Guardar índice
    call recoger_recurso        ; SI y BX ya están configurados
    pop si                      ; Restaurar
    pop bx                      ; Restaurar

vcr_next:
    shl bx, 1                   ; Siguiente bit
    inc si                      ; Siguiente recurso
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

    ; Marcar como recogido (BX = máscara de bit)
    or recursos_recogidos, bx

    ; Obtener tipo de recurso
    mov ax, si
    mov dx, 3
    mul dx
    mov di, ax

    mov al, [recursos_mapa + di + 2]    ; Tipo (1, 2 o 3)
    mov bl, al

    ; Incrementar contador según tipo
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
    ; Actualizar slots del inventario
    mov al, bl
    call actualizar_inventario_slots

    ; ✅ NUEVO: Activar HUD de recolección
    mov hud_recoger_activo, 1
    mov hud_recoger_contador, 60        ; Mostrar por ~1 segundo (60 frames)
    mov hud_recoger_tipo, bl
    
    ; Determinar sprite para el HUD
    cmp bl, 1
    jne rr_hud_tipo2
    mov ax, OFFSET sprite_cristal
    jmp rr_hud_guardar
    
rr_hud_tipo2:
    cmp bl, 2
    jne rr_hud_tipo3
    mov ax, OFFSET sprite_gema
    jmp rr_hud_guardar
    
rr_hud_tipo3:
    mov ax, OFFSET sprite_moneda
    
rr_hud_guardar:
    mov hud_recoger_sprite_offset, ax
    
    ; Reproducir sonido de recolección MEJORADO
    call reproducir_sonido_recoger_largo
    
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
    xor ah, ah
    cmp si, ax
    jb  drm_continuar           ; Si aún hay recursos, continuar
    jmp drm_fin                 ; Si ya procesamos todos, salir

drm_continuar:

    ; Verificar si ya fue recogido
    mov ax, recursos_recogidos
    test ax, bx                 ; ← Verificar si el bit está set
    jz  NEAR PTR drm_procesar   ; Si no fue recogido, procesar

drm_skip:
    shl bx, 1                   ; Siguiente bit
    inc si                      ; Siguiente recurso
    jmp drm_loop

drm_procesar:

    ; Obtener posición del recurso (X, Y, Tipo)
    mov ax, si
    mov dx, 3
    mul dx                      ; AX = SI × 3
    mov di, ax

    ; Leer X (en tiles)
    mov al, [recursos_mapa + di]
    xor ah, ah
    shl ax, 4                   ; X × 16 = píxeles
    mov cx, ax

    ; Leer Y (en tiles)
    mov al, [recursos_mapa + di + 1]
    xor ah, ah
    shl ax, 4                   ; Y × 16 = píxeles
    mov dx, ax

    ; Verificar si está visible en viewport
    mov ax, cx
    sub ax, camara_px
    cmp ax, -16
    jl  NEAR PTR drm_skip
    cmp ax, 320
    jg  NEAR PTR drm_skip

    mov ax, dx
    sub ax, camara_py
    cmp ax, -16
    jl  NEAR PTR drm_skip
    cmp ax, 192
    jg  NEAR PTR drm_skip

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
    mov al, [recursos_mapa + di + 2]  ; Tipo (1, 2 o 3)

    push si                     ; Guardar índice
    push bx                     ; Guardar máscara

    cmp al, 1
    jne drm_tipo2
    mov di, OFFSET sprite_cristal
    mov si, OFFSET sprite_cristal_mask
    jmp drm_dibujar

drm_tipo2:
    cmp al, 2
    jne drm_tipo3
    mov di, OFFSET sprite_gema
    mov si, OFFSET sprite_gema_mask
    jmp drm_dibujar

drm_tipo3:
    mov di, OFFSET sprite_moneda
    mov si, OFFSET sprite_moneda_mask

drm_dibujar:
    ; CX, DX ya tienen las coordenadas
    ; DI = datos del sprite
    ; SI = máscara del sprite
    call dibujar_sprite_planar_16x16_opt

    pop bx                      ; Restaurar máscara
    pop si                      ; Restaurar índice

    jmp NEAR PTR drm_skip
    
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
    je di_salir_directo
    
    ; ✅ LIMPIAR TODA LA PANTALLA CON NEGRO (AMBOS PLANOS)
    push es
    mov ax, VIDEO_SEG
    mov es, ax
    
    ; Configurar para escribir en todos los planos
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    
    ; Limpiar página actual
    mov di, temp_offset
    mov cx, 14000
    xor ax, ax
    rep stosw
    
    pop es
    
    ; ✅ DIBUJAR FONDO DEL PANEL (NEGRO - YA ESTÁ LIMPIO)
    ; Solo dibujar el marco
    mov cx, INV_X
    mov dx, INV_Y
    mov ax, INV_WIDTH
    mov bx, INV_HEIGHT
    mov si, COLOR_MARCO
    call dibujar_rectangulo_vacio
    
    ; ✅ PASO 1: LIMPIAR TODA LA PANTALLA CON NEGRO
    mov cx, 0
    mov dx, 0
    mov ax, 640
    mov bx, 350
    mov si, 0                   ; Negro sólido
    call dibujar_rectangulo_lleno
    
    ; ✅ PASO 2: DIBUJAR FONDO DEL PANEL
    mov cx, INV_X
    mov dx, INV_Y
    mov ax, INV_WIDTH
    mov bx, INV_HEIGHT
    mov si, 1                   ; Azul oscuro
    call dibujar_rectangulo_lleno

    ; ✅ PASO 3: DIBUJAR MARCO
    mov cx, INV_X
    mov dx, INV_Y
    mov ax, INV_WIDTH
    mov bx, INV_HEIGHT
    mov si, COLOR_MARCO
    call dibujar_rectangulo_vacio

    ; ✅ PASO 4: TÍTULO
    mov cx, INV_X
    add cx, 120
    mov dx, INV_Y
    add dx, 15
    mov si, OFFSET msg_inventario
    mov al, COLOR_TEXTO
    call dibujar_texto_simple

    ; ✅ PASO 5: JUGADOR (IZQUIERDA)
    call dibujar_jugador_inventario
    
    ; ✅ PASO 6: SLOTS DE ITEMS (CENTRO) - CON SPRITES
    call dibujar_slots_items_mejorado
    
    ; ✅ PASO 7: ESTADÍSTICAS (DERECHA) - MEJORADO
    call dibujar_estadisticas_mejorado
    
di_salir_directo:
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
    
    ; ✅ POSICIÓN CORREGIDA: IZQUIERDA DEL PANEL
    mov cx, INV_X + 30          ; X = 190 (columna izquierda)
    mov dx, INV_Y + 100         ; Y = 150 (centrado verticalmente)
    
    call dibujar_sprite_planar_32x32_opt
    
    pop di
    pop si
    pop dx
    pop cx
    ret
dibujar_jugador_inventario ENDP

; ============================================
; DIBUJAR SLOTS MEJORADO - CON SPRITES VISIBLES
; ============================================
dibujar_slots_items_mejorado PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    xor si, si                  ; Índice de slot (0-7)

dsim_loop:
    cmp si, MAX_ITEMS
    jb dsim_procesar
    jmp dsim_fin

dsim_procesar:

    ; Calcular posición del slot (2 filas × 4 columnas)
    mov ax, si
    xor dx, dx
    mov bx, 4
    div bx                      ; AX = fila, DX = columna
    
    mov bp, ax                  ; BP = fila
    
    ; ✅ CX = X del slot (CENTRADO EN EL PANEL)
    mov ax, dx                  ; AX = columna (0-3)
    mov bx, 50                  ; Espaciado
    mul bx
    add ax, INV_X + 100         ; Centrado horizontalmente
    mov cx, ax
    
    ; ✅ DX = Y del slot
    mov ax, bp                  ; AX = fila (0-1)
    mov bx, 50
    mul bx
    add ax, INV_Y + 80          ; Centrado verticalmente
    mov dx, ax
    
    ; DX = Y del slot
    mov ax, bp
    mov bx, 50                  ; Espaciado vertical
    mul bx
    add ax, 80                  ; Y inicial
    mov dx, ax
    
    ; Dibujar fondo del slot (negro)
    push cx
    push dx
    push si
    mov ax, 48                  ; Ancho del slot
    mov bx, 48                  ; Alto del slot
    mov si, 0                   ; Negro
    call dibujar_rectangulo_lleno
    pop si
    pop dx
    pop cx
    
    ; Dibujar marco del slot
    push cx
    push dx
    push si
    mov ax, 48
    mov bx, 48
    mov si, COLOR_ITEM_SLOT
    call dibujar_rectangulo_vacio
    pop si
    pop dx
    pop cx
    
    ; Verificar si hay item en este slot
    mov bx, OFFSET inventario_slots
    add bx, si
    mov al, [bx]
    test al, al
    jz dsim_next                ; Si está vacío, siguiente slot
    
    ; ✅ HAY ITEM: Dibujar sprite centrado (16x16 en slot de 48x48)
    mov dl, al                  ; Guardar tipo
    
    ; Calcular posición centrada del sprite
    push cx
    push dx
    
    mov ax, cx
    add ax, 16                  ; Centrar: (48-16)/2 = 16
    mov cx, ax
    
    mov ax, dx
    add ax, 16
    mov dx, ax
    
    ; Seleccionar sprite según tipo
    cmp dl, 1
    jne dsim_tipo2
    mov di, OFFSET sprite_cristal
    push si
    mov si, OFFSET sprite_cristal_mask
    jmp dsim_dibujar_sprite
    
dsim_tipo2:
    cmp dl, 2
    jne dsim_tipo3
    mov di, OFFSET sprite_gema
    push si
    mov si, OFFSET sprite_gema_mask
    jmp dsim_dibujar_sprite
    
dsim_tipo3:
    mov di, OFFSET sprite_moneda
    push si
    mov si, OFFSET sprite_moneda_mask
    
dsim_dibujar_sprite:
    call dibujar_sprite_planar_16x16_opt
    pop si                      ; Restaurar SI (índice del slot)
    
    pop dx                      ; Restaurar DX, CX originales
    pop cx
    
    ; Dibujar cantidad (abajo a la derecha del slot)
    push si                     ; Guardar SI actual
    mov bx, OFFSET inventario_cantidades
    mov ax, si                  ; AX = índice del slot
    add bx, ax
    mov al, [bx]
    xor ah, ah
    pop si                      ; Restaurar SI
    
    push ax
    mov ax, cx
    add ax, 30                  ; Posición X de la cantidad
    mov cx, ax
    mov ax, dx
    add ax, 30                  ; Posición Y de la cantidad
    mov dx, ax
    pop ax
    
    call dibujar_numero

dsim_next:
    inc si
    jmp dsim_loop

dsim_fin:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_slots_items_mejorado ENDP

; ============================================
; DIBUJAR ESTADÍSTICAS MEJORADO - SIN SOLAPAMIENTO
; ============================================
dibujar_estadisticas_mejorado PROC
    push ax
    push bx
    push cx
    push dx
    push si

    ; ✅ POSICIÓN CORREGIDA: MÁS A LA DERECHA Y ARRIBA
    mov dx, INV_Y + 30          ; Y = 80 (arriba del todo)
    mov cx, INV_X + INV_WIDTH - 120  ; X = 360 (columna derecha)

    ; Título "RECURSOS"
    mov si, OFFSET msg_recursos
    mov si, OFFSET msg_recursos
    mov al, COLOR_TEXTO
    call dibujar_texto_simple

    add dx, 20
    mov si, OFFSET msg_objetivo
    mov al, COLOR_TEXTO
    call dibujar_texto_simple

    add dx, 25

    ; ===== CRISTALES =====
    mov si, OFFSET msg_cristales
    mov al, 12                  ; Azul brillante
    call dibujar_texto_simple

    add dx, 15
    mov al, recursos_tipo1
    xor ah, ah
    call dibujar_numero

    mov si, OFFSET msg_slash
    mov al, COLOR_TEXTO
    call dibujar_texto_simple

    mov ax, META_POR_TIPO
    call dibujar_numero

    add dx, 12
    mov al, recursos_tipo1
    xor ah, ah
    mov bx, META_POR_TIPO
    call dibujar_barra_progreso

    add dx, 25

    ; ===== GEMAS =====
    mov si, OFFSET msg_gemas
    mov al, 12                  ; Rojo brillante
    call dibujar_texto_simple

    add dx, 15
    mov al, recursos_tipo2
    xor ah, ah
    call dibujar_numero

    mov si, OFFSET msg_slash
    mov al, COLOR_TEXTO
    call dibujar_texto_simple

    mov ax, META_POR_TIPO
    call dibujar_numero

    add dx, 12
    mov al, recursos_tipo2
    xor ah, ah
    mov bx, META_POR_TIPO
    call dibujar_barra_progreso

    add dx, 25

    ; ===== MONEDAS =====

    mov si, OFFSET msg_monedas
    mov al, 14                  ; Amarillo
    call dibujar_texto_simple

    add dx, 15

    mov al, recursos_tipo3
    xor ah, ah
    call dibujar_numero

    mov si, OFFSET msg_slash
    mov al, COLOR_TEXTO
    call dibujar_texto_simple


    mov ax, META_POR_TIPO
    call dibujar_numero

    add dx, 12
 
    mov al, recursos_tipo3
    xor ah, ah
    mov bx, META_POR_TIPO
    call dibujar_barra_progreso

    add dx, 30

    ; Verificar victoria
    mov al, recursos_tipo1
    cmp al, META_POR_TIPO
    jb dem_no_victoria
    mov al, recursos_tipo2
    cmp al, META_POR_TIPO
    jb dem_no_victoria
    mov al, recursos_tipo3
    cmp al, META_POR_TIPO
    jb dem_no_victoria

    mov si, OFFSET msg_completado
    mov al, 10                  ; Verde brillante
    call dibujar_texto_simple

dem_no_victoria:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_estadisticas_mejorado ENDP

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

dibujar_rectangulo_lleno PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    push bp
    
    mov bp, ax              ; BP = ancho
    mov di, bx              ; DI = alto

    mov ax, VIDEO_SEG
    mov es, ax

    ; ✅ CONFIGURAR PARA ESCRIBIR EN TODOS LOS PLANOS
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al

    ; ✅ MODO DE ESCRITURA DIRECTO
    mov dx, 3CEh
    mov al, 5
    out dx, al
    inc dx
    mov al, 0
    out dx, al

    mov dx, 3CEh
    mov al, 3
    out dx, al
    inc dx
    mov al, 0
    out dx, al

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
    shr bx, 3
    add ax, bx
    add ax, temp_offset
    mov bx, ax

    ; Obtener color
    mov ax, si
    and al, 0Fh
    
    ; ✅ EXPANDIR COLOR A 8 BITS
    mov ah, al
    shl ah, 4
    or al, ah

    ; Dibujar línea horizontal
    mov cx, bp
    shr cx, 3
    test cx, cx
    jz drl_pixel_final
    
drl_byte_loop:
    mov es:[bx], al
    inc bx
    loop drl_byte_loop

drl_pixel_final:
    mov cx, bp
    and cx, 7
    test cx, cx
    jz drl_siguiente_fila
    
    mov ah, 80h
drl_pixel_loop:
    test ah, ah
    jz drl_siguiente_fila
    shr ah, 1
    loop drl_pixel_loop

drl_siguiente_fila:
    pop dx
    pop cx

    inc dx
    dec di
    jmp drl_fila

drl_fin:
    ; ✅ RESTAURAR CONFIGURACIÓN
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al

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

    mov di, ax              ; Guardar ancho
    mov bp, bx              ; Guardar alto

    push cx
    push dx
    push si
    mov si, 0               ; Negro
    mov ax, di
    mov bx, bp
    call dibujar_rectangulo_lleno
    pop si
    pop dx
    pop cx

    ; Ahora dibujar el marco encima
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
    mov ax, 1
    mov bx, bp
    call dibujar_rectangulo_lleno
    pop dx
    pop cx

    ; Línea derecha
    push cx
    push dx
    add cx, di
    dec cx
    mov ax, 1
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

; ============================================
; DIBUJAR NÚMERO (0-99)
; Entrada: CX = X, DX = Y, AX = número
; ============================================
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
; HUD DE RECOLECCIÓN - MOSTRAR EN PANTALLA
; ============================================
dibujar_hud_recoleccion PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    cmp hud_recoger_activo, 0
    je dhr_fin
    
    ; Posición fija en la parte superior central
    mov cx, 240                 ; X centrado
    mov dx, 30                  ; Y superior
    
    ; Dibujar fondo negro semitransparente
    push cx
    push dx
    mov ax, 160
    mov bx, 40
    mov si, 0
    call dibujar_rectangulo_lleno
    pop dx
    pop cx
    
    ; Dibujar marco
    push cx
    push dx
    mov ax, 160
    mov bx, 40
    mov si, 14                  ; Amarillo
    call dibujar_rectangulo_vacio
    pop dx
    pop cx
    
    ; Dibujar sprite del recurso
    mov ax, cx
    add ax, 10
    mov cx, ax
    mov ax, dx
    add ax, 12
    mov dx, ax
    
    mov di, hud_recoger_sprite_offset
    
    ; Seleccionar máscara según tipo
    mov al, hud_recoger_tipo
    cmp al, 1
    jne dhr_tipo2
    mov si, OFFSET sprite_cristal_mask
    jmp dhr_dibujar_sprite
    
dhr_tipo2:
    cmp al, 2
    jne dhr_tipo3
    mov si, OFFSET sprite_gema_mask
    jmp dhr_dibujar_sprite
    
dhr_tipo3:
    mov si, OFFSET sprite_moneda_mask
    
dhr_dibujar_sprite:
    call dibujar_sprite_planar_16x16_opt
    
    ; Dibujar texto "RECOLECTADO!"
    mov cx, 280
    mov dx, 43
    mov si, OFFSET msg_recurso_recolectado
    mov al, 14                  ; Amarillo
    call dibujar_texto_simple
    
dhr_fin:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_hud_recoleccion ENDP

; ============================================
; ACTUALIZAR HUD DE RECOLECCIÓN
; ============================================
actualizar_hud_recoleccion PROC
    push ax
    
    cmp hud_recoger_activo, 0
    je ahr_fin
    
    dec hud_recoger_contador
    cmp hud_recoger_contador, 0
    jne ahr_fin
    
    ; Desactivar HUD
    mov hud_recoger_activo, 0
    
ahr_fin:
    pop ax
    ret
actualizar_hud_recoleccion ENDP

; ============================================
; SONIDO DE RECOLECCIÓN MEJORADO - MÁS LARGO Y AGRADABLE
; ============================================
reproducir_sonido_recoger_largo PROC
    push ax
    push bx
    push cx
    push dx

    ; ✅ TONO 1: Nota ascendente (440 Hz - La)
    mov al, 0B6h
    out 43h, al

    mov ax, 0A8Fh               ; Divisor para ~440 Hz
    out 42h, al
    mov al, ah
    out 42h, al

    ; Activar speaker
    in al, 61h
    mov bl, al
    or al, 3
    out 61h, al

    ; Duración media
    mov cx, 2000
rsrl_delay1:
    loop rsrl_delay1

    ; ✅ TONO 2: Nota más alta (554 Hz - Do#)
    mov al, 0B6h
    out 43h, al

    mov ax, 0877h               ; Divisor para ~554 Hz
    out 42h, al
    mov al, ah
    out 42h, al

    mov cx, 2000
rsrl_delay2:
    loop rsrl_delay2

    ; ✅ TONO 3: Nota final aún más alta (659 Hz - Mi)
    mov al, 0B6h
    out 43h, al

    mov ax, 0715h               ; Divisor para ~659 Hz
    out 42h, al
    mov al, ah
    out 42h, al

    mov cx, 3000                ; Duración más larga para el final
rsrl_delay3:
    loop rsrl_delay3

    ; Desactivar speaker
    mov al, bl
    out 61h, al

    pop dx
    pop cx
    pop bx
    pop ax
    ret
reproducir_sonido_recoger_largo ENDP

; ============================================
; ACTUALIZAR ANIMACIÓN DE RECOLECCIÓN (MANTENER POR COMPATIBILIDAD)
; ============================================
actualizar_animacion_recoger PROC
    push ax
    
    ; Actualizar HUD en su lugar
    call actualizar_hud_recoleccion
    
    pop ax
    ret
actualizar_animacion_recoger ENDP

; ============================================
; DIBUJAR ANIMACIÓN DE RECOLECCIÓN (REDIRIGIR A HUD)
; ============================================
dibujar_animacion_recoger PROC
    push ax
    
    ; Redirigir al nuevo HUD
    call dibujar_hud_recoleccion
    
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