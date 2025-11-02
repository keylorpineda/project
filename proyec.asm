	.MODEL SMALL
	.STACK 2048
	TILE_ROCA_VOLCANICA EQU 0
	TILE_LAVA EQU 1
	TILE_CENIZA EQU 2
	TILE_ROCA_BLOQUE EQU 3
	TILE_NIEVE EQU 4
	TILE_HIELO EQU 5
	TILE_AGUA_CONGELADA EQU 6
	TILE_ROCA_NEVADA EQU 7
	TILE_LODO EQU 8
	TILE_AGUA_TOXICA EQU 9
	TILE_TIERRA_MUERTA EQU 10
	TILE_ARBOL_MUERTO EQU 11
	TILE_CESPED EQU 12
	TILE_TOTEM_AVES EQU 13
	TILE_ESTANQUE_AVES EQU 14
	TILE_CASA_TECHO_IZQ EQU 15
	TILE_CASA_TECHO_CEN EQU 16
	TILE_CASA_TECHO_DER EQU 17
	TILE_CASA_PARED EQU 18
	TILE_CASA_VENTANA EQU 19
	TILE_CASA_PUERTA EQU 20
	TILE_SIZE EQU 16
	VIDEO_SEG EQU 0A000h
	VELOCIDAD EQU 4
	VELOCIDAD_LENTA EQU 2
	VELOCIDAD_RAPIDA EQU 6
	
	DIR_ABAJO EQU 0
	DIR_ARRIBA EQU 1
	DIR_IZQUIERDA EQU 2
	DIR_DERECHA EQU 3
	
	.DATA
	archivo_mapa db 'MAPA.TXT', 0
	archivo_roca_volcanica db 'SPRITES\VOLCROC.TXT', 0
	archivo_lava db 'SPRITES\VOLCLAV.TXT', 0
	archivo_ceniza db 'SPRITES\VOLCASH.TXT', 0
	archivo_roca_bloque db 'SPRITES\VOLCROB.TXT', 0
	archivo_nieve db 'SPRITES\TUNSNOW.TXT', 0
	archivo_hielo db 'SPRITES\TUNICE.TXT', 0
	archivo_agua_congelada db 'SPRITES\TUNWATR.TXT', 0
	archivo_roca_nevada db 'SPRITES\TUNROCK.TXT', 0
	archivo_lodo db 'SPRITES\SWMLODO.TXT', 0
	archivo_agua_toxica db 'SPRITES\SWMWATR.TXT', 0
	archivo_tierra_muerta db 'SPRITES\SWMDEAD.TXT', 0
	archivo_arbol_muerto db 'SPRITES\SWMTREE.TXT', 0
	archivo_cesped db 'SPRITES\GRSCESP.TXT', 0
	archivo_estanque_aves db 'SPRITES\GRSPOOL.TXT', 0
	archivo_totem_aves db 'SPRITES\GRSTOTM.TXT', 0
	archivo_casa_techo_izq db 'SPRITES\HSE_TL.TXT', 0
	archivo_casa_techo_cen db 'SPRITES\HSE_TC.TXT', 0
	archivo_casa_techo_der db 'SPRITES\HSE_TR.TXT', 0
	archivo_casa_pared db 'SPRITES\HSE_WL.TXT', 0
	archivo_casa_ventana db 'SPRITES\HSE_WN.TXT', 0
	archivo_casa_puerta db 'SPRITES\HSE_DR.TXT', 0
	
	archivo_player_up_a db 'SPRITES\PLAYER\UP1.TXT', 0
	archivo_player_up_b db 'SPRITES\PLAYER\UP2.TXT', 0
	archivo_player_down_a db 'SPRITES\PLAYER\DOWN1.TXT', 0
	archivo_player_down_b db 'SPRITES\PLAYER\DOWN2.TXT', 0
	archivo_player_izq_a db 'SPRITES\PLAYER\LEFT1.TXT', 0
	archivo_player_izq_b db 'SPRITES\PLAYER\LEFT2.TXT', 0
	archivo_player_der_a db 'SPRITES\PLAYER\RIGHT1.TXT', 0
	archivo_player_der_b db 'SPRITES\PLAYER\RIGHT2.TXT', 0
	archivo_player_hurt_up_a db 'SPRITES\PLAYER\HURT_UP1.TXT', 0
	archivo_player_hurt_up_b db 'SPRITES\PLAYER\HURT_UP2.TXT', 0
	archivo_player_hurt_down_a db 'SPRITES\PLAYER\HURTDWN1.TXT', 0
	archivo_player_hurt_down_b db 'SPRITES\PLAYER\HURTDWN2.TXT', 0
	archivo_player_hurt_izq_a db 'SPRITES\PLAYER\HURTLFT1.TXT', 0
	archivo_player_hurt_izq_b db 'SPRITES\PLAYER\HURTLFT2.TXT', 0
	archivo_player_hurt_der_a db 'SPRITES\PLAYER\HURTRGT1.TXT', 0
	archivo_player_hurt_der_b db 'SPRITES\PLAYER\HURTRGT2.TXT', 0
	
	mapa_datos db 10000 dup(0)
	
	sprite_buffer_16 db 256 dup(0)
	sprite_buffer_32 db 1024 dup(0)
	
	sprite_roca_volcanica db 128 dup(0)
	sprite_lava db 128 dup(0)
	sprite_ceniza db 128 dup(0)
	sprite_roca_bloque db 128 dup(0)
	sprite_nieve db 128 dup(0)
	sprite_hielo db 128 dup(0)
	sprite_agua_congelada db 128 dup(0)
	sprite_roca_nevada db 128 dup(0)
	sprite_lodo db 128 dup(0)
	sprite_agua_toxica db 128 dup(0)
	sprite_tierra_muerta db 128 dup(0)
	sprite_arbol_muerto db 128 dup(0)
	sprite_cesped db 128 dup(0)
	sprite_estanque_aves db 128 dup(0)
	sprite_totem_aves db 128 dup(0)
	sprite_casa_techo_izq db 128 dup(0)
	sprite_casa_techo_cen db 128 dup(0)
	sprite_casa_techo_der db 128 dup(0)
	sprite_casa_pared db 128 dup(0)
	sprite_casa_ventana db 128 dup(0)
	sprite_casa_puerta db 128 dup(0)
	
	jugador_up_a db 512 dup(0)
	jugador_up_b db 512 dup(0)
	jugador_down_a db 512 dup(0)
	jugador_down_b db 512 dup(0)
	jugador_izq_a db 512 dup(0)
	jugador_izq_b db 512 dup(0)
	jugador_der_a db 512 dup(0)
	jugador_der_b db 512 dup(0)
	jugador_hurt_up_a db 512 dup(0)
	jugador_hurt_up_b db 512 dup(0)
	jugador_hurt_down_a db 512 dup(0)
	jugador_hurt_down_b db 512 dup(0)
	jugador_hurt_izq_a db 512 dup(0)
	jugador_hurt_izq_b db 512 dup(0)
	jugador_hurt_der_a db 512 dup(0)
	jugador_hurt_der_b db 512 dup(0)
	
	buffer_temp db 300 dup(0)
	
	cm_acumulando db 0
	cm_valor_actual dw 0
	cm_digito_temp db 0
	
	jugador_px dw 808
	jugador_py dw 536
	jugador_dir db DIR_ABAJO
	jugador_frame db 0
	
	jugador_px_old dw 808
	jugador_py_old dw 536
	frame_old db 0
	
	moviendo db 0
	pasos_dados db 0
	
	camara_px dw 0
	camara_py dw 72
	
	pagina_visible db 0
	pagina_dibujo db 1
	
	viewport_x dw 120
	viewport_y dw 55
	
	temp_offset dw 0
	inicio_tile_x dw 0
	inicio_tile_y dw 0
	temp_fila dw 0
	temp_col dw 0
	
	scroll_offset_x dw 0
	scroll_offset_y dw 0
	
	inventario_abierto db 0
	inventario_toggle_bloqueado db 0
	requiere_redibujar db 0
	tecla_e_presionada db 0
	MAX_ITEMS EQU 8
	MAX_TIPOS_RECURSO EQU 3
	META_POR_TIPO EQU 2
	recursos_tipo1 db 0
	recursos_tipo2 db 0
	recursos_tipo3 db 0
	recursos_recogidos dw 0
	hud_slot_seleccionado db 0
	NUM_RECURSOS EQU 15
	recursos_mapa db NUM_RECURSOS * 3 dup(0)
	recursos_cantidad db NUM_RECURSOS dup(0)
	num_recursos_cargados db 0
	inventario_slots db MAX_ITEMS dup(0)
	inventario_cantidades db MAX_ITEMS dup(0)
	
	player_left_temp dw 0
	player_right_temp dw 0
	player_top_temp dw 0
	player_bottom_temp dw 0
	
	mov_dx dw 0
	mov_dy dw 0
	deslizando db 0
	deslizando_dx dw 0
	deslizando_dy dw 0
	col_tile_x dw 0
	col_tile_y dw 0
	
	carga_recursos_estado db 0
	carga_recursos_guardar db 0
	carga_recursos_comentario db 0
	carga_recursos_char_pend db 0
	carga_recursos_tiene_pend db 0
	carga_recursos_handle dw 0
	carga_recursos_temp dw 0
	carga_recursos_offset dw 0
	
	sprite_cristal db 128 dup(0)
	sprite_gema db 128 dup(0)
	sprite_moneda db 128 dup(0)
	
	archivo_cristal db 'SPRITES\CRYSTAL.TXT', 0
	archivo_gema db 'SPRITES\GEM.TXT', 0
	archivo_moneda db 'SPRITES\COIN.TXT', 0
	COLOR_FONDO EQU 0
	COLOR_MARCO EQU 7
	COLOR_TEXTO EQU 14
	COLOR_BARRA_VACIA EQU 8
	COLOR_BARRA_LLENA EQU 10
	COLOR_ITEM_SLOT EQU 1
	
msg_vida db 'VIDA:', 0
	msg_muerto db 'HAS MUERTO. Presiona tecla...$'
	msg_inventario db 'INVENTARIO', 0
	msg_recursos db 'RECURSOS', 0
msg_cristales db 'CRISTALES:', 0
msg_gemas db 'GEMAS:', 0
msg_monedas db 'MONEDAS:', 0
msg_objetivo db 'OBJETIVO:', 0
msg_progreso db 'PROGRESO:', 0
	msg_completado db 'COMPLETADO!', 0
	msg_slash db ' / ', 0
	
	jugador_vida dw 200
	jugador_vida_maxima dw 200
	jugador_invencible_timer dw 0
	
	INV_X EQU 80
	INV_Y EQU 40
	INV_WIDTH EQU 480
	INV_HEIGHT EQU 270
	
	
	ZONA_PLAYER_X EQU 100
	ZONA_PLAYER_Y EQU 80
	ZONA_PLAYER_W EQU 64
	
	ZONA_ITEMS_X EQU 180
	ZONA_ITEMS_Y EQU 70
	ITEM_SIZE EQU 40
	ITEM_SPACING EQU 8
	ITEM_TOTAL EQU 48
	ITEM_ICON_OFFSET EQU 12
	ITEM_COUNT_OFFSET_X EQU 28
	ITEM_COUNT_OFFSET_Y EQU 28
	
	ZONA_STATS_X EQU 420
	ZONA_STATS_Y EQU 70
	ZONA_STATS_W EQU 120
	
	STAT_VAL_OFFSET EQU 88
	STAT_SLASH_OFFSET EQU 104
	STAT_META_OFFSET EQU 112
	
	anim_recoger_activa db 0
	anim_recoger_frame db 0
	anim_recoger_x dw 0
	anim_recoger_y dw 0
	texto_color_actual db 0
	font_base_x_temp dw 0
	font_base_y_temp dw 0
	font_row_mask db 0
	numero_buffer db 6 dup(0)

	pv_anim_frame db 0
	pv_random_seed dw 1234
	
	MAX_PARTICULAS EQU 50
	particulas_x dw MAX_PARTICULAS dup(0)
	particulas_y dw MAX_PARTICULAS dup(0)
	particulas_vx dw MAX_PARTICULAS dup(0)
	particulas_vy dw MAX_PARTICULAS dup(0)
	particulas_color db MAX_PARTICULAS dup(0)
	particulas_vida db MAX_PARTICULAS dup(0)
	
	FONT_LETTER_OFFSET EQU 10
	FONT_COLON_INDEX EQU 36
	FONT_SLASH_INDEX EQU 37
	FONT_EXCLAM_INDEX EQU 38
	
	font_8x8 LABEL BYTE
	
	db 00111100b, 01000010b, 01000110b, 01001010b, 01010010b, 01100010b, 01000010b, 00111100b
	
	db 00011000b, 00101000b, 01001000b, 00001000b, 00001000b, 00001000b, 00001000b, 01111110b
	
	db 00111100b, 01000010b, 00000010b, 00000100b, 00001000b, 00010000b, 00100000b, 01111110b
	
	db 00111100b, 01000010b, 00000010b, 00011100b, 00000010b, 00000010b, 01000010b, 00111100b
	
	db 00000100b, 00001100b, 00010100b, 00100100b, 01000100b, 01111110b, 00000100b, 00000100b
	
	db 01111110b, 01000000b, 01000000b, 01111100b, 00000010b, 00000010b, 01000010b, 00111100b
	
	db 00111100b, 01000010b, 01000000b, 01111100b, 01000010b, 01000010b, 01000010b, 00111100b
	
	db 01111110b, 00000010b, 00000100b, 00001000b, 00010000b, 00100000b, 00100000b, 00100000b
	
	db 00111100b, 01000010b, 01000010b, 00111100b, 01000010b, 01000010b, 01000010b, 00111100b
	
	db 00111100b, 01000010b, 01000010b, 01000010b, 00111110b, 00000010b, 01000010b, 00111100b
	
	db 00011000b, 00100100b, 01000010b, 01000010b, 01111110b, 01000010b, 01000010b, 00000000b
	
	db 01111100b, 01000010b, 01000010b, 01111100b, 01000010b, 01000010b, 01111100b, 00000000b
	
	db 00111100b, 01000010b, 01000000b, 01000000b, 01000000b, 01000010b, 00111100b, 00000000b
	
	db 01111000b, 01000100b, 01000010b, 01000010b, 01000010b, 01000100b, 01111000b, 00000000b
	
	db 01111110b, 01000000b, 01000000b, 01111100b, 01000000b, 01000000b, 01111110b, 00000000b
	
	db 01111110b, 01000000b, 01000000b, 01111100b, 01000000b, 01000000b, 01000000b, 00000000b
	
	db 00111100b, 01000010b, 01000000b, 01011110b, 01000010b, 01000010b, 00111100b, 00000000b
	
	db 01000010b, 01000010b, 01000010b, 01111110b, 01000010b, 01000010b, 01000010b, 00000000b
	
	db 00111100b, 00011000b, 00011000b, 00011000b, 00011000b, 00011000b, 00111100b, 00000000b
	
	db 00011110b, 00000100b, 00000100b, 00000100b, 00000100b, 01000100b, 00111000b, 00000000b
	
	db 01000010b, 01000100b, 01001000b, 01110000b, 01001000b, 01000100b, 01000010b, 00000000b
	
	db 01000000b, 01000000b, 01000000b, 01000000b, 01000000b, 01000000b, 01111110b, 00000000b
	
	db 01000010b, 01100110b, 01011010b, 01000010b, 01000010b, 01000010b, 01000010b, 00000000b
	
	db 01000010b, 01100010b, 01010010b, 01001010b, 01000110b, 01000010b, 01000010b, 00000000b
	
	db 00111100b, 01000010b, 01000010b, 01000010b, 01000010b, 01000010b, 00111100b, 00000000b
	
	db 01111100b, 01000010b, 01000010b, 01111100b, 01000000b, 01000000b, 01000000b, 00000000b
	
	db 00111100b, 01000010b, 01000010b, 01000010b, 01001010b, 01000110b, 00111110b, 00000000b
	
	db 01111100b, 01000010b, 01000010b, 01111100b, 01001000b, 01000100b, 01000010b, 00000000b
	
	db 00111110b, 01000000b, 01000000b, 00111100b, 00000010b, 00000010b, 01111100b, 00000000b
	
	db 01111110b, 00011000b, 00011000b, 00011000b, 00011000b, 00011000b, 00011000b, 00000000b
	
	db 01000010b, 01000010b, 01000010b, 01000010b, 01000010b, 01000010b, 00111100b, 00000000b
	
	db 01000010b, 01000010b, 01000010b, 01000010b, 00100100b, 00100100b, 00011000b, 00000000b
	
	db 01000010b, 01000010b, 01000010b, 01000010b, 01011010b, 01100110b, 01000010b, 00000000b
	
	db 01000010b, 00100100b, 00011000b, 00011000b, 00011000b, 00100100b, 01000010b, 00000000b
	
	db 01000010b, 00100100b, 00011000b, 00011000b, 00011000b, 00011000b, 00011000b, 00000000b
	
	db 01111110b, 00000010b, 00000100b, 00001000b, 00010000b, 00100000b, 01111110b, 00000000b
	
	db 00000000b, 00011000b, 00011000b, 00000000b, 00000000b, 00011000b, 00011000b, 00000000b
	
	db 00000010b, 00000100b, 00001000b, 00010000b, 00100000b, 01000000b, 10000000b, 00000000b
	
	db 00011000b, 00011000b, 00011000b, 00011000b, 00011000b, 00000000b, 00011000b, 00000000b
	
	zoom_lookup_table db 00h, 03h, 0Ch, 0Fh, 30h, 33h, 3Ch, 3Fh, 0C0h, 0C3h, 0CCh, 0CFh, 0F0h, 0F3h, 0FCh, 0FFh
	INCLUDE OPTDATA.INC
	
	msg_titulo db 'JUEGO EGA - Universidad Nacional', 13, 10, '$'
	msg_cargando db 'Cargando archivos...', 13, 10, '$'
msg_mapa db 'Mapa: $'
msg_sprites db 'Sprites terreno: $'
msg_anim db 'Sprites jugador: $'
	msg_convert db 'Generando mascaras...$'
msg_tablas db 'Lookup tables: $'
	msg_ok db 'OK', 13, 10, '$'
	msg_error db 'ERROR', 13, 10, '$'
	msg_controles db 13, 10, 'WASD = Mover, ESC = Salir', 13, 10
	msg_victoria db 'VICTORIA!', 0
	msg_victoria_sub db 'Presiona tecla...$'
	db 'Presiona tecla...$'
	
	.CODE
inicio:
	mov ax, @data
	mov ds, ax
	mov dx, OFFSET msg_cargando
	mov ah, 9
	int 21h
	
	
	mov dx, OFFSET msg_mapa
	mov ah, 9
	int 21h
	call cargar_mapa
	jnc cm_ok
	jmp error_carga
cm_ok:
	call cargar_recursos_desde_mapa
	jnc crm_ok
	jmp error_carga
crm_ok:
	mov dx, OFFSET msg_ok
	mov ah, 9
	int 21h
	
	
	mov dx, OFFSET msg_sprites
	mov ah, 9
	int 21h
	call cargar_sprites_terreno
	jnc st_ok
	jmp error_carga
st_ok:
	mov dx, OFFSET msg_ok
	mov ah, 9
	int 21h
	
	
	mov dx, OFFSET msg_anim
	mov ah, 9
	int 21h
	call cargar_animaciones_jugador
	jnc anim_ok
	jmp error_carga
anim_ok:
	mov dx, OFFSET msg_ok
	mov ah, 9
	int 21h
	
	
	mov dx, OFFSET msg_convert
	mov ah, 9
	int 21h
	call precalcular_mascaras_tiles
	call precalcular_mascaras_jugador
	mov dx, OFFSET msg_ok
	mov ah, 9
	int 21h
	
	
	mov dx, OFFSET msg_tablas
	mov ah, 9
	int 21h
	call inicializar_lookup_tables
	mov dx, OFFSET msg_ok
	mov ah, 9
	int 21h
	call debug_verificar_todo
	
continuar_juego:
	mov ax, 10h
	int 10h
	call inicializar_paleta_ega
	mov dx, 3C4h
	mov al, 2
	out dx, al
	inc dx
	mov al, 0Fh
	out dx, al
	mov dx, 3CEh
	mov al, 5
	out dx, al
	inc dx
	mov al, 0
	out dx, al
	mov dx, 3CEh
	mov al, 8
	out dx, al
	inc dx
	mov al, 0FFh
	out dx, al
	mov ax, VIDEO_SEG
	mov es, ax
	xor di, di
	mov cx, 14000
	xor ax, ax
	rep stosw
	mov di, 8000h
	mov cx, 14000
	xor ax, ax
	rep stosw
	call centrar_camara
	mov temp_offset, 0
	call dibujar_mapa_en_offset
	call dibujar_jugador_en_offset
	mov temp_offset, 8000h
	call dibujar_mapa_en_offset
	call dibujar_jugador_en_offset
	
	mov ax, jugador_px
	mov jugador_px_old, ax
	mov ax, jugador_py
	mov jugador_py_old, ax
	mov al, jugador_frame
	mov frame_old, al
	mov ah, 5
	mov al, 0
	int 10h
	mov pagina_visible, 0
	mov pagina_dibujo, 1
bucle_juego:
	call verificar_colision_recursos
	call actualizar_animacion_recoger
	call procesar_movimiento_continuo
	call actualizar_animacion
	call centrar_camara_suave
	call verificar_victoria
	jnc bg_continuar
	call pantalla_victoria
	jmp fin_juego
	
bg_continuar:
	
	mov ax, jugador_px
	cmp ax, jugador_px_old
	jne bg_hay_cambio
	
	mov ax, jugador_py
	cmp ax, jugador_py_old
	jne bg_hay_cambio
	
	mov al, jugador_frame
	cmp al, frame_old
	jne bg_hay_cambio
	
	cmp requiere_redibujar, 0
	jne bg_hay_cambio
	
	
	call esperar_retrace
	jmp bucle_juego
	
bg_hay_cambio:
	mov ax, jugador_px
	mov jugador_px_old, ax
	mov ax, jugador_py
	mov jugador_py_old, ax
	mov al, jugador_frame
	mov frame_old, al
	
	mov al, requiere_redibujar
	cmp al, 0
	je bg_redraw_reset
	dec al
	mov requiere_redibujar, al
	jmp bg_redraw_done
bg_redraw_reset:
	mov requiere_redibujar, 0
bg_redraw_done:
	
	call esperar_retrace
	
	mov al, pagina_dibujo
	test al, 1
	jz bg_render_p0
	
	mov temp_offset, 8000h
	call limpiar_pagina_actual
	call dibujar_mapa_en_offset
	call dibujar_jugador_en_offset
	call dibujar_inventario
	call dibujar_hud
	jmp bg_cambiar_pagina
	
bg_render_p0:
	mov temp_offset, 0
	call limpiar_pagina_actual
	call dibujar_mapa_en_offset
	call dibujar_jugador_en_offset
	call dibujar_inventario
	call dibujar_hud
	
bg_cambiar_pagina:
	mov ah, 5
	mov al, pagina_dibujo
	int 10h
	
	xor pagina_dibujo, 1
	xor pagina_visible, 1
	
	jmp bucle_juego
	
error_carga:
	mov dx, OFFSET msg_error
	mov ah, 9
	int 21h
	mov ah, 0
	int 16h
	
fin_juego:
	mov ax, 3
	int 10h
	mov ax, 4C00h
	int 21h
	
	inicializar_paleta_ega PROC
	mov dx, 3C0h
	mov al, 20h
	out dx, al
	ret
	inicializar_paleta_ega ENDP
	
	procesar_movimiento_continuo PROC
	push ax
	push bx
	push cx
	push dx
	push si
	
	mov mov_dx, 0
	mov mov_dy, 0
	mov moviendo, 0
	
	mov ah, 1
	int 16h
	jnz pmc_tiene_tecla
	jmp NEAR PTR pmc_no_key_pressed
	
pmc_tiene_tecla:
	mov ah, 0
	int 16h
	
	cmp ah, 01h
	jne pmc_check_ascii
	jmp pmc_salir
	
pmc_check_ascii:
	cmp al, 27
	jne pmc_continuar
	jmp pmc_salir
	
pmc_continuar:
	mov bl, al
	test bl, bl
	jz pmc_usar_scan
	mov al, bl
	jmp pmc_normalizar
	
pmc_usar_scan:
	mov al, bh
	
pmc_normalizar:
	cmp al, 'a'
	jb pmc_verificar
	cmp al, 'z'
	ja pmc_verificar
	and al, 5Fh
	
pmc_verificar:
	cmp al, 'E'
	jne pmc_verificar_movimiento
	cmp tecla_e_presionada, 1
	jne pmc_toggle_e
	jmp NEAR PTR pmc_fin_frame
	
pmc_toggle_e:
	mov tecla_e_presionada, 1
	xor inventario_abierto, 1
	mov requiere_redibujar, 2
	jmp NEAR PTR pmc_fin_frame
	
pmc_verificar_movimiento:
	cmp inventario_abierto, 1
	jne pmc_verificar_teclas
	jmp NEAR PTR pmc_fin_frame
	
pmc_verificar_teclas:
	mov dl, al
	call get_tile_under_player
	mov bl, al
	mov al, dl
	
	cmp al, '1'
	jb pmc_check_w_keys
	cmp al, '8'
	ja pmc_check_w_keys
	
	sub al, '1'
	mov hud_slot_seleccionado, al
	mov requiere_redibujar, 2
	jmp NEAR PTR pmc_fin_frame
	
pmc_check_w_keys:
	cmp al, 48h
	jne pmc_check_w
	mov ax, - VELOCIDAD
	cmp bl, TILE_NIEVE
	je pmc_up_lento
	cmp bl, TILE_HIELO
	je pmc_up_rapido
	jmp pmc_up_set
	
pmc_check_w:
	cmp al, 'W'
	jne pmc_check_down
	mov ax, - VELOCIDAD
	cmp bl, TILE_NIEVE
	je pmc_up_lento
	cmp bl, TILE_HIELO
	je pmc_up_rapido
	jmp pmc_up_set
	
pmc_up_lento:
	mov ax, - VELOCIDAD_LENTA
	jmp pmc_up_set
pmc_up_rapido:
	mov ax, - VELOCIDAD_RAPIDA
pmc_up_set:
	mov mov_dy, ax
	mov jugador_dir, DIR_ARRIBA
	mov moviendo, 1
	jmp pmc_llamar_resolver      ; ← FIX: Saltar a resolver
	
pmc_check_down:
	cmp al, 50h
	jne pmc_check_s
	mov ax, VELOCIDAD
	cmp bl, TILE_NIEVE
	je pmc_down_lento
	cmp bl, TILE_HIELO
	je pmc_down_rapido
	jmp pmc_down_set
	
pmc_check_s:
	cmp al, 'S'
	jne pmc_check_left
	mov ax, VELOCIDAD
	cmp bl, TILE_NIEVE
	je pmc_down_lento
	cmp bl, TILE_HIELO
	je pmc_down_rapido
	jmp pmc_down_set
	
pmc_down_lento:
	mov ax, VELOCIDAD_LENTA
	jmp pmc_down_set
pmc_down_rapido:
	mov ax, VELOCIDAD_RAPIDA
pmc_down_set:
	mov mov_dy, ax
	mov jugador_dir, DIR_ABAJO
	mov moviendo, 1
	jmp pmc_llamar_resolver      ; ← FIX: Saltar a resolver
	
pmc_check_left:
	cmp al, 4Bh
	jne pmc_check_a
	mov ax, - VELOCIDAD
	cmp bl, TILE_NIEVE
	je pmc_left_lento
	cmp bl, TILE_HIELO
	je pmc_left_rapido
	jmp pmc_left_set
	
pmc_check_a:
	cmp al, 'A'
	jne pmc_check_right
	mov ax, - VELOCIDAD
	cmp bl, TILE_NIEVE
	je pmc_left_lento
	cmp bl, TILE_HIELO
	je pmc_left_rapido
	jmp pmc_left_set
	
pmc_left_lento:
	mov ax, - VELOCIDAD_LENTA
	jmp pmc_left_set
pmc_left_rapido:
	mov ax, - VELOCIDAD_RAPIDA
pmc_left_set:
	mov mov_dx, ax
	mov jugador_dir, DIR_IZQUIERDA
	mov moviendo, 1
	jmp pmc_llamar_resolver      ; ← FIX: Saltar a resolver
	
pmc_check_right:
	cmp al, 4Dh
	jne pmc_check_d
	mov ax, VELOCIDAD
	cmp bl, TILE_NIEVE
	je pmc_right_lento
	cmp bl, TILE_HIELO
	je pmc_right_rapido
	jmp pmc_right_set
	
pmc_check_d:
	cmp al, 'D'
	jne pmc_default
	mov ax, VELOCIDAD
	cmp bl, TILE_NIEVE
	je pmc_right_lento
	cmp bl, TILE_HIELO
	je pmc_right_rapido
	jmp pmc_right_set
	
pmc_right_lento:
	mov ax, VELOCIDAD_LENTA
	jmp pmc_right_set
pmc_right_rapido:
	mov ax, VELOCIDAD_RAPIDA
pmc_right_set:
	mov mov_dx, ax
	mov jugador_dir, DIR_DERECHA
	mov moviendo, 1
	jmp pmc_llamar_resolver      ; ← FIX: Saltar a resolver
	
pmc_default:
	jmp pmc_fin_frame
	
pmc_no_key_pressed:
	mov tecla_e_presionada, 0
	
	cmp deslizando, 0
	jne pmc_deslizando_activo
	jmp NEAR PTR pmc_fin_frame
	
pmc_deslizando_activo:
	call get_tile_under_player
	cmp al, TILE_HIELO
	jne pmc_parar_desliz
	
	mov ax, deslizando_dx
	mov bx, ax
	or ax, deslizando_dy
	jz pmc_parar_desliz
	
	mov mov_dx, bx
	mov ax, deslizando_dy
	mov mov_dy, ax
	
	mov ax, mov_dx
	cmp ax, 0
	je pmc_slide_check_y
	js pmc_slide_dir_izq
	mov jugador_dir, DIR_DERECHA
	jmp pmc_slide_dir_done
	
pmc_slide_dir_izq:
	mov jugador_dir, DIR_IZQUIERDA
	jmp pmc_slide_dir_done
	
pmc_slide_check_y:
	mov ax, mov_dy
	cmp ax, 0
	je pmc_slide_dir_done
	js pmc_slide_dir_arriba
	mov jugador_dir, DIR_ABAJO
	jmp pmc_slide_dir_done
	
pmc_slide_dir_arriba:
	mov jugador_dir, DIR_ARRIBA
	
pmc_slide_dir_done:
	mov moviendo, 1
	jmp pmc_llamar_resolver
	
pmc_parar_desliz:
	mov deslizando, 0
	mov deslizando_dx, 0
	mov deslizando_dy, 0
	jmp pmc_fin_frame
	
pmc_llamar_resolver:
	; ← FIX: Nuevo label para resolver colisiones
	call get_tile_under_player
	cmp al, TILE_HIELO
	jne pmc_resolver_no_hielo
	
	; Si estamos en hielo y hay movimiento, activar deslizamiento
	mov ax, mov_dx
	or ax, mov_dy
	jz pmc_resolver_continuar    ; ← FIX: Sin movimiento, solo resolver
	
	mov ax, mov_dx
	mov deslizando_dx, ax
	mov ax, mov_dy
	mov deslizando_dy, ax
	mov deslizando, 1
	jmp pmc_resolver_continuar
	
pmc_resolver_no_hielo:
	; No estamos en hielo, detener deslizamiento
	mov deslizando, 0
	mov deslizando_dx, 0
	mov deslizando_dy, 0
	
pmc_resolver_continuar:
	mov ax, mov_dx
	or ax, mov_dy
	jz pmc_fin_frame
	
	call resolver_colisiones_y_mover
	
pmc_fin_frame:
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
	
pmc_salir:
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	mov ax, 3
	int 10h
	mov ax, 4C00h
	int 21h
	procesar_movimiento_continuo ENDP
	
	resolver_colisiones_y_mover PROC
	push ax
	push bx
	push cx
	push dx
	push si
	
	mov ax, mov_dx
	test ax, ax
	jnz rcm_procesar_x
	jmp rcm_fase_y
	
rcm_procesar_x:
	
	mov bx, jugador_px
	add bx, ax
	
	cmp ax, 0
	jg rcm_x_derecha
	
rcm_x_izquierda:
	mov ax, bx
	sub ax, 8
	shr ax, 4
	mov col_tile_x, ax
	
	mov si, jugador_py
	sub si, 8
	shr si, 4
	mov cx, jugador_py
	add cx, 7
	shr cx, 4
	jmp rcm_x_loop
	
rcm_x_derecha:
	mov ax, bx
	add ax, 7
	shr ax, 4
	mov col_tile_x, ax
	
	mov si, jugador_py
	sub si, 8
	shr si, 4
	mov cx, jugador_py
	add cx, 7
	shr cx, 4
	jmp rcm_x_loop
	
rcm_x_loop:
	cmp si, cx
	jg rcm_x_sin_colision
	
	push cx
	mov dx, si
	mov cx, col_tile_x
	call verificar_tile_transitable
	pop cx
	
	jc rcm_x_no_colision
	jmp rcm_x_colision
	
rcm_x_no_colision:
	inc si
	jmp rcm_x_loop
	
rcm_x_colision:
	mov ax, col_tile_x
	shl ax, 4
	
	cmp [mov_dx], 0
	jg rcm_x_snap_der
	
rcm_x_snap_izq:
	add ax, 24
	mov jugador_px, ax
	jmp rcm_x_col_fin
	
rcm_x_snap_der:
	sub ax, 8
	mov jugador_px, ax
	
rcm_x_col_fin:
	mov mov_dx, 0
	mov deslizando, 0            ; Chocar detiene el deslizamiento
	mov deslizando_dx, 0
	
	jmp rcm_fase_y
	
rcm_x_sin_colision:
	mov jugador_px, bx
	
rcm_fase_y:
	mov ax, mov_dy
	test ax, ax
	jnz rcm_procesar_y
	jmp rcm_fin
	
rcm_procesar_y:
	
	mov bx, jugador_py
	add bx, ax
	
	cmp ax, 0
	jg rcm_y_abajo
	
rcm_y_arriba:
	mov ax, bx
	sub ax, 8
	shr ax, 4
	mov col_tile_y, ax
	
	mov si, jugador_px
	sub si, 8
	shr si, 4
	mov cx, jugador_px
	add cx, 7
	shr cx, 4
	jmp rcm_y_loop
	
rcm_y_abajo:
	mov ax, bx
	add ax, 7
	shr ax, 4
	mov col_tile_y, ax
	
	mov si, jugador_px
	sub si, 8
	shr si, 4
	mov cx, jugador_px
	add cx, 7
	shr cx, 4
	jmp rcm_y_loop
	
rcm_y_loop:
	cmp si, cx
	jg rcm_y_sin_colision
	
	push cx
	mov dx, col_tile_y
	mov cx, si
	call verificar_tile_transitable
	pop cx
	
	jc rcm_y_no_colision
	jmp rcm_y_colision
	
rcm_y_no_colision:
	inc si
	jmp rcm_y_loop
	
rcm_y_colision:
	mov ax, col_tile_y
	shl ax, 4
	
	cmp [mov_dy], 0
	jg rcm_y_snap_abajo
	
rcm_y_snap_arriba:
	add ax, 24
	mov jugador_py, ax
	jmp rcm_y_col_fin
	
rcm_y_snap_abajo:
	sub ax, 8
	mov jugador_py, ax
	
rcm_y_col_fin:
	mov mov_dy, 0
	mov deslizando, 0            ; Chocar detiene el deslizamiento
	mov deslizando_dy, 0
	
	jmp rcm_fin
	
rcm_y_sin_colision:
	mov jugador_py, bx
	
rcm_fin:
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
	resolver_colisiones_y_mover ENDP
	
	limpiar_pagina_actual PROC
	push ax
	push cx
	push dx
	push di
	push es
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
	mov ax, VIDEO_SEG
	mov es, ax
	mov di, [temp_offset]
	mov cx, 14000
	xor ax, ax
	rep stosw
	
	pop es
	pop di
	pop dx
	pop cx
	pop ax
	ret
	limpiar_pagina_actual ENDP
	
	actualizar_animacion PROC
	push ax
	
	cmp moviendo, 0
	je aa_fin
	
	inc pasos_dados
	mov al, pasos_dados
	cmp al, 4
	jb aa_fin
	
	mov pasos_dados, 0
	xor jugador_frame, 1
	call reproducir_sonido_paso
	
aa_fin:
	pop ax
	ret
	actualizar_animacion ENDP
	
	reproducir_sonido_paso PROC
	push ax
	push bx
	push cx
	push dx
	
	mov al, 0B6h
	out 43h, al
	
	mov ax, 0F89h
	out 42h, al
	mov al, ah
	out 42h, al
	
	in al, 61h
	mov bl, al
	or al, 3
	out 61h, al
	
	mov cx, 600
rsp_delay:
	loop rsp_delay
	
	mov al, bl
	out 61h, al
	
	mov cx, 150
rsp_silencio:
	loop rsp_silencio
	
	pop dx
	pop cx
	pop bx
	pop ax
	ret
	reproducir_sonido_paso ENDP
	
	reproducir_sonido_recoleccion PROC
	push ax
	
	mov ax, 2200
	call PlayNote
	call SoundDurationDelay
	
	mov ax, 1800
	call PlayNote
	call SoundDurationDelay
	
	mov ax, 1500
	call PlayNote
	call SoundDurationDelay
	
	call SpeakerOff
	pop ax
	ret
	reproducir_sonido_recoleccion ENDP
	
	PlayNote PROC
	push ax
	call SetSpeakerFreq
	call SpeakerOn
	pop ax
	ret
	PlayNote ENDP
	
	SpeakerOn PROC
	push ax
	in al, 61h
	or al, 03h
	out 61h, al
	pop ax
	ret
	SpeakerOn ENDP
	
	SpeakerOff PROC
	push ax
	in al, 61h
	and al, 0FCh
	out 61h, al
	pop ax
	ret
	SpeakerOff ENDP
	
	SetSpeakerFreq PROC
	push ax
	push dx
	
	mov al, 182
	out 43h, al
	
	pop dx
	push ax
	
	out 42h, al
	mov al, ah
	out 42h, al
	
	pop ax
	pop dx
	ret
	SetSpeakerFreq ENDP
	
	SoundDurationDelay PROC
	push cx
	push dx
	
	mov dx, 9
.sdd_outer_loop:
	mov cx, 0FFFFh
.sdd_loop:
	loop .sdd_loop
	
	dec dx
	jnz .sdd_outer_loop
	
	pop dx
	pop cx
	ret
	SoundDurationDelay ENDP
	
	centrar_camara PROC
	push ax
	push bx
	
	mov ax, jugador_px
	sub ax, 200
	jge cc_x_pos
	xor ax, ax
cc_x_pos:
	cmp ax, 1200
	jle cc_x_ok
	mov ax, 1200
cc_x_ok:
	mov camara_px, ax
	
	mov ax, jugador_py
	sub ax, 120
	jge cc_y_pos
	xor ax, ax
cc_y_pos:
	cmp ax, 1360
	jle cc_y_ok
	mov ax, 1360
cc_y_ok:
	mov camara_py, ax
	
	pop bx
	pop ax
	ret
	centrar_camara ENDP
	
	verificar_tile_transitable PROC
	call verificar_tile_transitable_opt
	ret
	verificar_tile_transitable ENDP
	
	
	cargar_sprites_terreno PROC
	push dx
	push di
	push si
	push bp
	
	mov dx, OFFSET archivo_roca_volcanica
	mov di, OFFSET sprite_buffer_16
	call cargar_sprite_16x16
	jnc cst_ok_roca_volcanica
	jmp cst_error
cst_ok_roca_volcanica:
	mov si, OFFSET sprite_buffer_16
	mov di, OFFSET sprite_roca_volcanica
	mov bp, OFFSET sprite_roca_volcanica_mask
	call convertir_sprite_a_planar_opt
	
	mov dx, OFFSET archivo_lava
	mov di, OFFSET sprite_buffer_16
	call cargar_sprite_16x16
	jnc cst_ok_lava
	jmp cst_error
cst_ok_lava:
	mov si, OFFSET sprite_buffer_16
	mov di, OFFSET sprite_lava
	mov bp, OFFSET sprite_lava_mask
	call convertir_sprite_a_planar_opt
	
	mov dx, OFFSET archivo_ceniza
	mov di, OFFSET sprite_buffer_16
	call cargar_sprite_16x16
	jnc cst_ok_ceniza
	jmp cst_error
cst_ok_ceniza:
	mov si, OFFSET sprite_buffer_16
	mov di, OFFSET sprite_ceniza
	mov bp, OFFSET sprite_ceniza_mask
	call convertir_sprite_a_planar_opt
	
	mov dx, OFFSET archivo_roca_bloque
	mov di, OFFSET sprite_buffer_16
	call cargar_sprite_16x16
	jnc cst_ok_roca_bloque
	jmp cst_error
cst_ok_roca_bloque:
	mov si, OFFSET sprite_buffer_16
	mov di, OFFSET sprite_roca_bloque
	mov bp, OFFSET sprite_roca_bloque_mask
	call convertir_sprite_a_planar_opt
	
	mov dx, OFFSET archivo_nieve
	mov di, OFFSET sprite_buffer_16
	call cargar_sprite_16x16
	jnc cst_ok_nieve
	jmp cst_error
cst_ok_nieve:
	mov si, OFFSET sprite_buffer_16
	mov di, OFFSET sprite_nieve
	mov bp, OFFSET sprite_nieve_mask
	call convertir_sprite_a_planar_opt
	
	mov dx, OFFSET archivo_hielo
	mov di, OFFSET sprite_buffer_16
	call cargar_sprite_16x16
	jnc cst_ok_hielo
	jmp cst_error
cst_ok_hielo:
	mov si, OFFSET sprite_buffer_16
	mov di, OFFSET sprite_hielo
	mov bp, OFFSET sprite_hielo_mask
	call convertir_sprite_a_planar_opt
	
	mov dx, OFFSET archivo_agua_congelada
	mov di, OFFSET sprite_buffer_16
	call cargar_sprite_16x16
	jnc cst_ok_agua_congelada
	jmp cst_error
cst_ok_agua_congelada:
	mov si, OFFSET sprite_buffer_16
	mov di, OFFSET sprite_agua_congelada
	mov bp, OFFSET sprite_agua_congelada_mask
	call convertir_sprite_a_planar_opt
	
	mov dx, OFFSET archivo_roca_nevada
	mov di, OFFSET sprite_buffer_16
	call cargar_sprite_16x16
	jnc cst_ok_roca_nevada
	jmp cst_error
cst_ok_roca_nevada:
	mov si, OFFSET sprite_buffer_16
	mov di, OFFSET sprite_roca_nevada
	mov bp, OFFSET sprite_roca_nevada_mask
	call convertir_sprite_a_planar_opt
	
	mov dx, OFFSET archivo_lodo
	mov di, OFFSET sprite_buffer_16
	call cargar_sprite_16x16
	jnc cst_ok_lodo
	jmp cst_error
cst_ok_lodo:
	mov si, OFFSET sprite_buffer_16
	mov di, OFFSET sprite_lodo
	mov bp, OFFSET sprite_lodo_mask
	call convertir_sprite_a_planar_opt
	
	mov dx, OFFSET archivo_agua_toxica
	mov di, OFFSET sprite_buffer_16
	call cargar_sprite_16x16
	jnc cst_ok_agua_toxica
	jmp cst_error
cst_ok_agua_toxica:
	mov si, OFFSET sprite_buffer_16
	mov di, OFFSET sprite_agua_toxica
	mov bp, OFFSET sprite_agua_toxica_mask
	call convertir_sprite_a_planar_opt
	
	mov dx, OFFSET archivo_tierra_muerta
	mov di, OFFSET sprite_buffer_16
	call cargar_sprite_16x16
	jnc cst_ok_tierra_muerta
	jmp cst_error
cst_ok_tierra_muerta:
	mov si, OFFSET sprite_buffer_16
	mov di, OFFSET sprite_tierra_muerta
	mov bp, OFFSET sprite_tierra_muerta_mask
	call convertir_sprite_a_planar_opt
	
	mov dx, OFFSET archivo_arbol_muerto
	mov di, OFFSET sprite_buffer_16
	call cargar_sprite_16x16
	jnc cst_ok_arbol_muerto
	jmp cst_error
cst_ok_arbol_muerto:
	mov si, OFFSET sprite_buffer_16
	mov di, OFFSET sprite_arbol_muerto
	mov bp, OFFSET sprite_arbol_muerto_mask
	call convertir_sprite_a_planar_opt
	
	mov dx, OFFSET archivo_cesped
	mov di, OFFSET sprite_buffer_16
	call cargar_sprite_16x16
	jnc cst_ok_cesped
	jmp cst_error
cst_ok_cesped:
	mov si, OFFSET sprite_buffer_16
	mov di, OFFSET sprite_cesped
	mov bp, OFFSET sprite_cesped_mask
	call convertir_sprite_a_planar_opt
	
	mov dx, OFFSET archivo_estanque_aves
	mov di, OFFSET sprite_buffer_16
	call cargar_sprite_16x16
	jnc cst_ok_estanque_aves
	jmp cst_error
cst_ok_estanque_aves:
	mov si, OFFSET sprite_buffer_16
	mov di, OFFSET sprite_estanque_aves
	mov bp, OFFSET sprite_estanque_aves_mask
	call convertir_sprite_a_planar_opt
	
	mov dx, OFFSET archivo_totem_aves
	mov di, OFFSET sprite_buffer_16
	call cargar_sprite_16x16
	jnc cst_ok_totem_aves
	jmp cst_error
cst_ok_totem_aves:
	mov si, OFFSET sprite_buffer_16
	mov di, OFFSET sprite_totem_aves
	mov bp, OFFSET sprite_totem_aves_mask
	call convertir_sprite_a_planar_opt
	
	mov dx, OFFSET archivo_casa_techo_izq
	mov di, OFFSET sprite_buffer_16
	call cargar_sprite_16x16
	jnc cst_ok_casa_techo_izq
	jmp cst_error
cst_ok_casa_techo_izq:
	mov si, OFFSET sprite_buffer_16
	mov di, OFFSET sprite_casa_techo_izq
	mov bp, OFFSET sprite_casa_techo_izq_mask
	call convertir_sprite_a_planar_opt
	
	mov dx, OFFSET archivo_casa_techo_cen
	mov di, OFFSET sprite_buffer_16
	call cargar_sprite_16x16
	jnc cst_ok_casa_techo_cen
	jmp cst_error
cst_ok_casa_techo_cen:
	mov si, OFFSET sprite_buffer_16
	mov di, OFFSET sprite_casa_techo_cen
	mov bp, OFFSET sprite_casa_techo_cen_mask
	call convertir_sprite_a_planar_opt
	
	mov dx, OFFSET archivo_casa_techo_der
	mov di, OFFSET sprite_buffer_16
	call cargar_sprite_16x16
	jnc cst_ok_casa_techo_der
	jmp cst_error
cst_ok_casa_techo_der:
	mov si, OFFSET sprite_buffer_16
	mov di, OFFSET sprite_casa_techo_der
	mov bp, OFFSET sprite_casa_techo_der_mask
	call convertir_sprite_a_planar_opt
	
	mov dx, OFFSET archivo_casa_pared
	mov di, OFFSET sprite_buffer_16
	call cargar_sprite_16x16
	jnc cst_ok_casa_pared
	jmp cst_error
cst_ok_casa_pared:
	mov si, OFFSET sprite_buffer_16
	mov di, OFFSET sprite_casa_pared
	mov bp, OFFSET sprite_casa_pared_mask
	call convertir_sprite_a_planar_opt
	
	mov dx, OFFSET archivo_casa_ventana
	mov di, OFFSET sprite_buffer_16
	call cargar_sprite_16x16
	jnc cst_ok_casa_ventana
	jmp cst_error
cst_ok_casa_ventana:
	mov si, OFFSET sprite_buffer_16
	mov di, OFFSET sprite_casa_ventana
	mov bp, OFFSET sprite_casa_ventana_mask
	call convertir_sprite_a_planar_opt
	
	mov dx, OFFSET archivo_casa_puerta
	mov di, OFFSET sprite_buffer_16
	call cargar_sprite_16x16
	jnc cst_ok_casa_puerta
	jmp cst_error
cst_ok_casa_puerta:
	mov si, OFFSET sprite_buffer_16
	mov di, OFFSET sprite_casa_puerta
	mov bp, OFFSET sprite_casa_puerta_mask
	call convertir_sprite_a_planar_opt
	
	mov dx, OFFSET archivo_cristal
	mov di, OFFSET sprite_buffer_16
	call cargar_sprite_16x16
	jnc cst_ok_cristal
	jmp cst_error
cst_ok_cristal:
	mov si, OFFSET sprite_buffer_16
	mov di, OFFSET sprite_cristal
	mov bp, OFFSET sprite_cristal_mask
	call convertir_sprite_a_planar_opt
	
	mov dx, OFFSET archivo_gema
	mov di, OFFSET sprite_buffer_16
	call cargar_sprite_16x16
	jnc cst_ok_gema
	jmp cst_error
cst_ok_gema:
	mov si, OFFSET sprite_buffer_16
	mov di, OFFSET sprite_gema
	mov bp, OFFSET sprite_gema_mask
	call convertir_sprite_a_planar_opt
	
	mov dx, OFFSET archivo_moneda
	mov di, OFFSET sprite_buffer_16
	call cargar_sprite_16x16
	jnc cst_ok_moneda
	jmp cst_error
cst_ok_moneda:
	mov si, OFFSET sprite_buffer_16
	mov di, OFFSET sprite_moneda
	mov bp, OFFSET sprite_moneda_mask
	call convertir_sprite_a_planar_opt
	clc
	jmp cst_fin
	
cst_error:
	stc
	
cst_fin:
	pop bp
	pop si
	pop di
	pop dx
	ret
	cargar_sprites_terreno ENDP
	
	cargar_animaciones_jugador PROC
	push dx
	push di
	push si
	push bp
	
	mov dx, OFFSET archivo_player_up_a
	mov di, OFFSET sprite_buffer_32
	call cargar_sprite_32x32
	jnc caj_ok_up_a
	jmp caj_error
caj_ok_up_a:
	mov si, OFFSET sprite_buffer_32
	mov di, OFFSET jugador_up_a
	mov bp, OFFSET jugador_up_a_mask
	call convertir_sprite_32x32_a_planar_opt
	
	mov dx, OFFSET archivo_player_up_b
	mov di, OFFSET sprite_buffer_32
	call cargar_sprite_32x32
	jnc caj_ok_up_b
	jmp caj_error
caj_ok_up_b:
	mov si, OFFSET sprite_buffer_32
	mov di, OFFSET jugador_up_b
	mov bp, OFFSET jugador_up_b_mask
	call convertir_sprite_32x32_a_planar_opt
	
	mov dx, OFFSET archivo_player_down_a
	mov di, OFFSET sprite_buffer_32
	call cargar_sprite_32x32
	jnc caj_ok_down_a
	jmp caj_error
caj_ok_down_a:
	mov si, OFFSET sprite_buffer_32
	mov di, OFFSET jugador_down_a
	mov bp, OFFSET jugador_down_a_mask
	call convertir_sprite_32x32_a_planar_opt
	
	mov dx, OFFSET archivo_player_down_b
	mov di, OFFSET sprite_buffer_32
	call cargar_sprite_32x32
	jnc caj_ok_down_b
	jmp caj_error
caj_ok_down_b:
	mov si, OFFSET sprite_buffer_32
	mov di, OFFSET jugador_down_b
	mov bp, OFFSET jugador_down_b_mask
	call convertir_sprite_32x32_a_planar_opt
	
	mov dx, OFFSET archivo_player_izq_a
	mov di, OFFSET sprite_buffer_32
	call cargar_sprite_32x32
	jnc caj_ok_izq_a
	jmp caj_error
caj_ok_izq_a:
	mov si, OFFSET sprite_buffer_32
	mov di, OFFSET jugador_izq_a
	mov bp, OFFSET jugador_izq_a_mask
	call convertir_sprite_32x32_a_planar_opt
	
	mov dx, OFFSET archivo_player_izq_b
	mov di, OFFSET sprite_buffer_32
	call cargar_sprite_32x32
	jnc caj_ok_izq_b
	jmp caj_error
caj_ok_izq_b:
	mov si, OFFSET sprite_buffer_32
	mov di, OFFSET jugador_izq_b
	mov bp, OFFSET jugador_izq_b_mask
	call convertir_sprite_32x32_a_planar_opt
	
	mov dx, OFFSET archivo_player_der_a
	mov di, OFFSET sprite_buffer_32
	call cargar_sprite_32x32
	jnc caj_ok_der_a
	jmp caj_error
caj_ok_der_a:
	mov si, OFFSET sprite_buffer_32
	mov di, OFFSET jugador_der_a
	mov bp, OFFSET jugador_der_a_mask
	call convertir_sprite_32x32_a_planar_opt
	
	mov dx, OFFSET archivo_player_der_b
	mov di, OFFSET sprite_buffer_32
	call cargar_sprite_32x32
	jnc caj_ok_der_b
	jmp caj_error
caj_ok_der_b:
	mov si, OFFSET sprite_buffer_32
	mov di, OFFSET jugador_der_b
	mov bp, OFFSET jugador_der_b_mask
	call convertir_sprite_32x32_a_planar_opt
	mov dx, OFFSET archivo_player_hurt_up_a
	mov di, OFFSET sprite_buffer_32
	call cargar_sprite_32x32
	jnc caj_ok_hurt_up_a
	jmp caj_error
caj_ok_hurt_up_a:
	mov si, OFFSET sprite_buffer_32
	mov di, OFFSET jugador_hurt_up_a
	mov bp, OFFSET jugador_hurt_up_a_mask
	call convertir_sprite_32x32_a_planar_opt
	
	mov dx, OFFSET archivo_player_hurt_up_b
	mov di, OFFSET sprite_buffer_32
	call cargar_sprite_32x32
	jnc caj_ok_hurt_up_b
	jmp caj_error
caj_ok_hurt_up_b:
	mov si, OFFSET sprite_buffer_32
	mov di, OFFSET jugador_hurt_up_b
	mov bp, OFFSET jugador_hurt_up_b_mask
	call convertir_sprite_32x32_a_planar_opt
	
	mov dx, OFFSET archivo_player_hurt_down_a
	mov di, OFFSET sprite_buffer_32
	call cargar_sprite_32x32
	jnc caj_ok_hurt_down_a
	jmp caj_error
caj_ok_hurt_down_a:
	mov si, OFFSET sprite_buffer_32
	mov di, OFFSET jugador_hurt_down_a
	mov bp, OFFSET jugador_hurt_down_a_mask
	call convertir_sprite_32x32_a_planar_opt
	
	mov dx, OFFSET archivo_player_hurt_down_b
	mov di, OFFSET sprite_buffer_32
	call cargar_sprite_32x32
	jnc caj_ok_hurt_down_b
	jmp caj_error
caj_ok_hurt_down_b:
	mov si, OFFSET sprite_buffer_32
	mov di, OFFSET jugador_hurt_down_b
	mov bp, OFFSET jugador_hurt_down_b_mask
	call convertir_sprite_32x32_a_planar_opt
	
	mov dx, OFFSET archivo_player_hurt_izq_a
	mov di, OFFSET sprite_buffer_32
	call cargar_sprite_32x32
	jnc caj_ok_hurt_izq_a
	jmp caj_error
caj_ok_hurt_izq_a:
	mov si, OFFSET sprite_buffer_32
	mov di, OFFSET jugador_hurt_izq_a
	mov bp, OFFSET jugador_hurt_izq_a_mask
	call convertir_sprite_32x32_a_planar_opt
	
	mov dx, OFFSET archivo_player_hurt_izq_b
	mov di, OFFSET sprite_buffer_32
	call cargar_sprite_32x32
	jnc caj_ok_hurt_izq_b
	jmp caj_error
caj_ok_hurt_izq_b:
	mov si, OFFSET sprite_buffer_32
	mov di, OFFSET jugador_hurt_izq_b
	mov bp, OFFSET jugador_hurt_izq_b_mask
	call convertir_sprite_32x32_a_planar_opt
	
	mov dx, OFFSET archivo_player_hurt_der_a
	mov di, OFFSET sprite_buffer_32
	call cargar_sprite_32x32
	jnc caj_ok_hurt_der_a
	jmp caj_error
caj_ok_hurt_der_a:
	mov si, OFFSET sprite_buffer_32
	mov di, OFFSET jugador_hurt_der_a
	mov bp, OFFSET jugador_hurt_der_a_mask
	call convertir_sprite_32x32_a_planar_opt
	
	mov dx, OFFSET archivo_player_hurt_der_b
	mov di, OFFSET sprite_buffer_32
	call cargar_sprite_32x32
	jnc caj_ok_hurt_der_b
	jmp caj_error
caj_ok_hurt_der_b:
	mov si, OFFSET sprite_buffer_32
	mov di, OFFSET jugador_hurt_der_b
	mov bp, OFFSET jugador_hurt_der_b_mask
	call convertir_sprite_32x32_a_planar_opt
	clc
	jmp caj_fin
	
caj_error:
	stc
	
caj_fin:
	pop bp
	pop si
	pop di
	pop dx
	ret
	cargar_animaciones_jugador ENDP
	
	obtener_sprite_jugador PROC
	push ax
	push bx
	
osj_normal:
	mov al, jugador_dir
	mov bl, jugador_frame
	
	cmp al, DIR_ABAJO
	jne osj_arr
	test bl, bl
	jz osj_down_a
	mov di, OFFSET jugador_down_b
	mov si, OFFSET jugador_down_b_mask
	jmp osj_fin
osj_down_a:
	mov di, OFFSET jugador_down_a
	mov si, OFFSET jugador_down_a_mask
	jmp osj_fin
	
osj_arr:
	cmp al, DIR_ARRIBA
	jne osj_izq
	test bl, bl
	jz osj_up_a
	mov di, OFFSET jugador_up_b
	mov si, OFFSET jugador_up_b_mask
	jmp osj_fin
osj_up_a:
	mov di, OFFSET jugador_up_a
	mov si, OFFSET jugador_up_a_mask
	jmp osj_fin
	
osj_izq:
	cmp al, DIR_IZQUIERDA
	jne osj_der
	test bl, bl
	jz osj_izq_a
	mov di, OFFSET jugador_izq_b
	mov si, OFFSET jugador_izq_b_mask
	jmp osj_fin
osj_izq_a:
	mov di, OFFSET jugador_izq_a
	mov si, OFFSET jugador_izq_a_mask
	jmp osj_fin
	
osj_der:
	test bl, bl
	jz osj_der_a
	mov di, OFFSET jugador_der_b
	mov si, OFFSET jugador_der_b_mask
	jmp osj_fin
osj_der_a:
	mov di, OFFSET jugador_der_a
	mov si, OFFSET jugador_der_a_mask
	
osj_fin:
	pop bx
	pop ax
	ret
	obtener_sprite_jugador ENDP
	
	renderizar_en_pagina_0 PROC
	push ax
	push es
	
	mov ax, VIDEO_SEG
	mov es, ax
	mov ax, 0
	call dibujar_todo_en_offset
	
	pop es
	pop ax
	ret
	renderizar_en_pagina_0 ENDP
	
	renderizar_en_pagina_1 PROC
	push ax
	push es
	
	mov ax, VIDEO_SEG
	mov es, ax
	mov ax, 8000h
	call dibujar_todo_en_offset
	
	pop es
	pop ax
	ret
	renderizar_en_pagina_1 ENDP
	
	dibujar_todo_en_offset PROC
	push ax
	
	mov temp_offset, ax
	call dibujar_mapa_en_offset
	call dibujar_jugador_en_offset
	
	pop ax
	ret
	dibujar_todo_en_offset ENDP
	
	dibujar_mapa_en_offset PROC
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	push bp
	
	mov ax, camara_px
	shr ax, 4
	mov inicio_tile_x, ax
	
	mov ax, camara_py
	shr ax, 4
	mov inicio_tile_y, ax
	
	xor bp, bp
	
dmo_fila:
	cmp bp, 15
	jae dmo_fin
	
	xor si, si
dmo_col:
	cmp si, 25
	jae dmo_next_fila
	
	mov ax, inicio_tile_y
	add ax, bp
	cmp ax, 100
	jae dmo_next_col
	
	mov bx, ax
	shl bx, 1
	mov ax, [mul100_table + bx]
	
	mov bx, inicio_tile_x
	add bx, si
	cmp bx, 100
	jae dmo_next_col
	
	add ax, bx
	
	mov bx, ax
	mov al, [mapa_datos + bx]
	
	cmp al, TILE_CASA_PUERTA
	ja dmo_next_col
	push si
	push bp
	call obtener_sprite_tile
	push si
	push di
	push bp
	mov bp, sp
	
	mov ax, [bp + 6]
	shl ax, 4
	add ax, viewport_y
	mov dx, ax
	mov ax, [bp + 8]
	shl ax, 4
	add ax, viewport_x
	mov cx, ax
	pop bp
	pop di
	pop si
	
	call dibujar_sprite_planar_16x16_opt
	
	pop bp
	pop si
	
dmo_next_col:
	inc si
	jmp dmo_col
	
dmo_next_fila:
	inc bp
	jmp dmo_fila
	
dmo_fin:
	call dibujar_recursos_en_mapa
	pop bp
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
	dibujar_mapa_en_offset ENDP
	
	obtener_sprite_tile PROC
	push ax
	push bx
	
	mov bl, al
	
	
	mov di, OFFSET sprite_roca_volcanica
	mov si, OFFSET sprite_roca_volcanica_mask
	
	cmp bl, TILE_LAVA
	jne ost_ceniza
	mov di, OFFSET sprite_lava
	mov si, OFFSET sprite_lava_mask
	jmp ost_fin
	
ost_ceniza:
	cmp bl, TILE_CENIZA
	jne ost_roca_bloque
	mov di, OFFSET sprite_ceniza
	mov si, OFFSET sprite_ceniza_mask
	jmp ost_fin
	
ost_roca_bloque:
	cmp bl, TILE_ROCA_BLOQUE
	jne ost_nieve
	mov di, OFFSET sprite_roca_bloque
	mov si, OFFSET sprite_roca_bloque_mask
	jmp ost_fin
	
ost_nieve:
	cmp bl, TILE_NIEVE
	jne ost_hielo
	mov di, OFFSET sprite_nieve
	mov si, OFFSET sprite_nieve_mask
	jmp ost_fin
	
ost_hielo:
	cmp bl, TILE_HIELO
	jne ost_agua_congelada
	mov di, OFFSET sprite_hielo
	mov si, OFFSET sprite_hielo_mask
	jmp ost_fin
	
ost_agua_congelada:
	cmp bl, TILE_AGUA_CONGELADA
	jne ost_roca_nevada
	mov di, OFFSET sprite_agua_congelada
	mov si, OFFSET sprite_agua_congelada_mask
	jmp ost_fin
	
ost_roca_nevada:
	cmp bl, TILE_ROCA_NEVADA
	jne ost_lodo
	mov di, OFFSET sprite_roca_nevada
	mov si, OFFSET sprite_roca_nevada_mask
	jmp ost_fin
	
ost_lodo:
	cmp bl, TILE_LODO
	jne ost_agua_toxica
	mov di, OFFSET sprite_lodo
	mov si, OFFSET sprite_lodo_mask
	jmp ost_fin
	
ost_agua_toxica:
	cmp bl, TILE_AGUA_TOXICA
	jne ost_tierra_muerta
	mov di, OFFSET sprite_agua_toxica
	mov si, OFFSET sprite_agua_toxica_mask
	jmp ost_fin
	
ost_tierra_muerta:
	cmp bl, TILE_TIERRA_MUERTA
	jne ost_arbol_muerto
	mov di, OFFSET sprite_tierra_muerta
	mov si, OFFSET sprite_tierra_muerta_mask
	jmp ost_fin
	
ost_arbol_muerto:
	cmp bl, TILE_ARBOL_MUERTO
	jne ost_cesped
	mov di, OFFSET sprite_arbol_muerto
	mov si, OFFSET sprite_arbol_muerto_mask
	jmp ost_fin
	
ost_cesped:
	cmp bl, TILE_CESPED
	jne ost_totem_aves
	mov di, OFFSET sprite_cesped
	mov si, OFFSET sprite_cesped_mask
	jmp ost_fin
	
ost_totem_aves:
	cmp bl, TILE_TOTEM_AVES
	jne ost_estanque_aves
	mov di, OFFSET sprite_totem_aves
	mov si, OFFSET sprite_totem_aves_mask
	jmp ost_fin
	
ost_estanque_aves:
	cmp bl, TILE_ESTANQUE_AVES
	jne ost_casa_techo_izq
	mov di, OFFSET sprite_estanque_aves
	mov si, OFFSET sprite_estanque_aves_mask
	jmp ost_fin
	
ost_casa_techo_izq:
	cmp bl, TILE_CASA_TECHO_IZQ
	jne ost_casa_techo_cen
	mov di, OFFSET sprite_casa_techo_izq
	mov si, OFFSET sprite_casa_techo_izq_mask
	jmp ost_fin
	
ost_casa_techo_cen:
	cmp bl, TILE_CASA_TECHO_CEN
	jne ost_casa_techo_der
	mov di, OFFSET sprite_casa_techo_cen
	mov si, OFFSET sprite_casa_techo_cen_mask
	jmp ost_fin
	
ost_casa_techo_der:
	cmp bl, TILE_CASA_TECHO_DER
	jne ost_casa_pared
	mov di, OFFSET sprite_casa_techo_der
	mov si, OFFSET sprite_casa_techo_der_mask
	jmp ost_fin
	
ost_casa_pared:
	cmp bl, TILE_CASA_PARED
	jne ost_casa_ventana
	mov di, OFFSET sprite_casa_pared
	mov si, OFFSET sprite_casa_pared_mask
	jmp ost_fin
	
ost_casa_ventana:
	cmp bl, TILE_CASA_VENTANA
	jne ost_casa_puerta
	mov di, OFFSET sprite_casa_ventana
	mov si, OFFSET sprite_casa_ventana_mask
	jmp ost_fin
	
ost_casa_puerta:
	cmp bl, TILE_CASA_PUERTA
	jne ost_fin
	mov di, OFFSET sprite_casa_puerta
	mov si, OFFSET sprite_casa_puerta_mask
	
ost_fin:
	pop bx
	pop ax
	ret
	obtener_sprite_tile ENDP
	
	dibujar_jugador_en_offset PROC
	push ax
	push cx
	push dx
	push si
	push di
	
	mov ax, jugador_px
	sub ax, camara_px
	add ax, viewport_x
	sub ax, 16
	mov cx, ax
	
	mov ax, jugador_py
	sub ax, camara_py
	add ax, viewport_y
	sub ax, 16
	mov dx, ax
	
	call obtener_sprite_jugador
	call dibujar_sprite_planar_32x32_opt
	call dibujar_item_sostenido
	call dibujar_animacion_recoger
	
	pop di
	pop si
	pop dx
	pop cx
	pop ax
	ret
	dibujar_jugador_en_offset ENDP
	
	dibujar_item_sostenido PROC
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	
	mov al, hud_slot_seleccionado
	xor ah, ah
	mov si, ax
	
	mov al, [inventario_slots + si]
	test al, al
	jz dis_fin
	
	cmp al, 1
	jne dis_tipo2
	mov di, OFFSET sprite_cristal
	mov si, OFFSET sprite_cristal_mask
	jmp dis_calcular_pos
	
dis_tipo2:
	cmp al, 2
	jne dis_tipo3
	mov di, OFFSET sprite_gema
	mov si, OFFSET sprite_gema_mask
	jmp dis_calcular_pos
	
dis_tipo3:
	mov di, OFFSET sprite_moneda
	mov si, OFFSET sprite_moneda_mask
	
dis_calcular_pos:
	push si
	
	mov al, jugador_dir
	
	cmp al, DIR_ABAJO
	jne dis_dir_arriba
	add cx, 8
	add dx, 20
	jmp dis_dibujar
	
dis_dir_arriba:
	cmp al, DIR_ARRIBA
	jne dis_dir_izq
	add cx, 8
	sub dx, 4
	jmp dis_dibujar
	
dis_dir_izq:
	cmp al, DIR_IZQUIERDA
	jne dis_dir_der
	sub cx, 4
	add dx, 8
	jmp dis_dibujar
	
dis_dir_der:
	add cx, 20
	add dx, 8
	
dis_dibujar:
	pop si
	
	cmp inventario_abierto, 1
	je dis_fin_no_draw
	
	call dibujar_sprite_planar_16x16_opt
	
dis_fin_no_draw:
	jmp dis_fin
	
dis_fin:
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
	dibujar_item_sostenido ENDP
	
	esperar_retrace PROC
	push ax
	push dx
	
	mov dx, 3DAh
	
	
er_wait_not_retrace:
	in al, dx
	test al, 8
	jnz er_wait_not_retrace
	
	
er_wait_start:
	in al, dx
	test al, 8
	jz er_wait_start
	
	pop dx
	pop ax
	ret
	esperar_retrace ENDP
	
	cargar_mapa PROC
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	push bp
	
	mov ax, 3D00h
	mov dx, OFFSET archivo_mapa
	int 21h
	jnc cm_archivo_abierto
	jmp cm_error
	
cm_archivo_abierto:
	
	mov bx, ax
	call saltar_linea
	
	mov di, OFFSET mapa_datos
	xor bp, bp
	mov byte ptr cm_acumulando, 0
	mov word ptr cm_valor_actual, 0
	
cm_leer:
	mov ah, 3Fh
	mov cx, 200
	mov dx, OFFSET buffer_temp
	int 21h
	
	cmp ax, 0
	jne cm_buffer_tiene_datos
	jmp cm_fin_buffer
	
cm_buffer_tiene_datos:
	
	mov cx, ax
	xor si, si
	
cm_proc:
	cmp si, cx
	jae cm_leer
	
	mov al, [buffer_temp + si]
	inc si
	
	cmp al, ' '
	je cm_delimitador
	cmp al, 13
	je cm_delimitador
	cmp al, 10
	je cm_delimitador
	cmp al, 9
	je cm_delimitador
	
	cmp al, '0'
	jb cm_chk_letra
	cmp al, '9'
	ja cm_chk_letra
	
	cmp byte ptr cm_acumulando, 0
	jne cm_digito_cont
	mov byte ptr cm_acumulando, 1
	mov word ptr cm_valor_actual, 0
	
cm_digito_cont:
	sub al, '0'
	mov byte ptr cm_digito_temp, al
	mov ax, cm_valor_actual
	mov dx, ax
	shl ax, 1
	shl dx, 3
	add ax, dx
	mov dl, byte ptr cm_digito_temp
	xor dh, dh
	add ax, dx
	mov cm_valor_actual, ax
	jmp cm_proc
	
cm_chk_letra:
	cmp al, 'A'
	jb cm_chk_lower
	cmp al, 'F'
	ja cm_chk_lower
	sub al, 'A'
	add al, 10
	jmp cm_store_letra
	
cm_chk_lower:
	cmp al, 'a'
	jb cm_proc
	cmp al, 'f'
	ja cm_proc
	sub al, 'a'
	add al, 10
	
cm_store_letra:
	mov byte ptr cm_acumulando, 0
	mov [di], al
	inc di
	inc bp
	cmp bp, 10000
	jae cm_cerrar
	jmp cm_proc
	
cm_delimitador:
	cmp byte ptr cm_acumulando, 0
	jne cm_delimitador_store
	jmp cm_proc
	
cm_delimitador_store:
	mov al, byte ptr cm_valor_actual
	mov byte ptr cm_acumulando, 0
	mov [di], al
	inc di
	inc bp
	cmp bp, 10000
	jae cm_cerrar
	jmp cm_proc
	
cm_fin_buffer:
	cmp byte ptr cm_acumulando, 0
	je cm_cerrar
	mov al, byte ptr cm_valor_actual
	mov byte ptr cm_acumulando, 0
	mov [di], al
	inc di
	inc bp
	cmp bp, 10000
	jb cm_cerrar
	
cm_cerrar:
	mov ah, 3Eh
	int 21h
	clc
	jmp cm_fin
	
cm_error:
	stc
	
cm_fin:
	pop bp
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
	cargar_mapa ENDP
	
	cargar_recursos_obtener_char PROC
	push dx
	push cx
	push bx
	
	cmp carga_recursos_tiene_pend, 0
	je croc_leer
	
	mov al, carga_recursos_char_pend
	mov carga_recursos_tiene_pend, 0
	clc
	jmp croc_fin
	
croc_leer:
	mov bx, carga_recursos_handle
	mov ah, 3Fh
	mov cx, 1
	mov dx, OFFSET buffer_temp
	int 21h
	cmp ax, 0
	jne croc_ok
	stc
	jmp croc_fin
	
croc_ok:
	mov al, [buffer_temp]
	clc
	
croc_fin:
	pop bx
	pop cx
	pop dx
	ret
	cargar_recursos_obtener_char ENDP
	
	cargar_recursos_leer_numero PROC
	push bx
	push cx
	push dx
	push si
	
	mov carga_recursos_temp, 0
	
crln_loop:
	sub al, '0'
	mov ah, 0
	mov si, ax
	mov ax, carga_recursos_temp
	mov cx, 10
	mul cx
	add ax, si
	mov carga_recursos_temp, ax
	
	call cargar_recursos_obtener_char
	jc crln_fin
	
	cmp al, '0'
	jb crln_set_pend
	cmp al, '9'
	jbe crln_loop
	
crln_set_pend:
	mov carga_recursos_char_pend, al
	mov carga_recursos_tiene_pend, 1
	
crln_fin:
	mov ax, carga_recursos_temp
	
	pop si
	pop dx
	pop cx
	pop bx
	ret
	cargar_recursos_leer_numero ENDP
	
	cargar_recursos_desde_mapa PROC
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	
	mov recursos_tipo1, 0
	mov recursos_tipo2, 0
	mov recursos_tipo3, 0
	mov recursos_recogidos, 0
	mov num_recursos_cargados, 0
	
	cld
	mov di, OFFSET recursos_mapa
	mov cx, NUM_RECURSOS * 3
	mov al, 0
	rep stosb
	
	mov di, OFFSET recursos_cantidad
	mov cx, NUM_RECURSOS
	mov al, 0
	rep stosb
	
	mov di, OFFSET inventario_slots
	mov cx, MAX_ITEMS
	mov al, 0
	rep stosb
	
	mov di, OFFSET inventario_cantidades
	mov cx, MAX_ITEMS
	mov al, 0
	rep stosb
	
	mov carga_recursos_estado, 0
	mov carga_recursos_guardar, 0
	mov carga_recursos_comentario, 0
	mov carga_recursos_tiene_pend, 0
	
	mov ax, 3D00h
	mov dx, OFFSET archivo_mapa
	int 21h
	jnc crm_open_ok
	jmp crm_error
	
crm_open_ok:
	mov carga_recursos_handle, ax
	
crm_loop:
	call cargar_recursos_obtener_char
	jnc crm_continuar_lectura
	jmp crm_fin_lectura
	
crm_continuar_lectura:
	
	cmp carga_recursos_comentario, 0
	je crm_no_comentario
	cmp al, 10
	jne crm_loop
	mov carga_recursos_comentario, 0
	jmp crm_loop
	
crm_no_comentario:
	cmp al, ';'
	jne crm_no_puntoycoma
	mov carga_recursos_comentario, 1
	jmp crm_loop
	
crm_no_puntoycoma:
	cmp carga_recursos_estado, 0
	jne crm_estado_en_progreso
	
	cmp al, 'R'
	je crm_inicio_recurso
	cmp al, 'r'
	jne crm_loop
	
crm_inicio_recurso:
	cmp num_recursos_cargados, NUM_RECURSOS
	jb crm_guardar
	mov carga_recursos_guardar, 0
	mov carga_recursos_estado, 1
	jmp crm_loop
	
crm_guardar:
	mov carga_recursos_guardar, 1
	mov al, num_recursos_cargados
	mov ah, 0
	mov bl, 3
	mul bl
	mov carga_recursos_offset, ax
	mov carga_recursos_estado, 1
	jmp crm_loop
	
crm_estado_en_progreso:
	cmp al, ' '
	je crm_loop
	cmp al, 9
	je crm_loop
	cmp al, 13
	je crm_loop
	cmp al, 10
	je crm_loop
	
	cmp al, '0'
	jb crm_loop
	cmp al, '9'
	ja crm_loop
	
	call cargar_recursos_leer_numero
	mov bx, ax
	
	cmp carga_recursos_estado, 1
	jne crm_estado_y
	mov carga_recursos_estado, 2
	cmp carga_recursos_guardar, 0
	je crm_estado_x_skip
	mov di, carga_recursos_offset
	mov al, bl
	mov [recursos_mapa + di], al
crm_estado_x_skip:
	jmp crm_loop
	
crm_estado_y:
	cmp carga_recursos_estado, 2
	jne crm_estado_tipo
	mov carga_recursos_estado, 3
	cmp carga_recursos_guardar, 0
	je crm_estado_y_skip
	mov di, carga_recursos_offset
	mov al, bl
	mov [recursos_mapa + di + 1], al
crm_estado_y_skip:
	jmp crm_loop
	
crm_estado_tipo:
	cmp carga_recursos_estado, 3
	jne crm_estado_cant
	mov carga_recursos_estado, 4
	cmp carga_recursos_guardar, 0
	je crm_estado_tipo_skip
	mov di, carga_recursos_offset
	mov al, bl
	mov [recursos_mapa + di + 2], al
crm_estado_tipo_skip:
	jmp crm_loop
	
crm_estado_cant:
	mov carga_recursos_estado, 0
	cmp carga_recursos_guardar, 0
	je crm_estado_cant_skip
	
	cmp bx, 255
	jbe crm_cant_ok
	mov bx, 255
	
crm_cant_ok:
	mov al, num_recursos_cargados
	mov ah, 0
	mov si, ax
	mov al, bl
	mov [recursos_cantidad + si], al
	
	inc num_recursos_cargados
	mov carga_recursos_guardar, 0
	jmp crm_loop
	
crm_estado_cant_skip:
	jmp crm_loop
	
crm_fin_lectura:
	mov bx, carga_recursos_handle
	mov ah, 3Eh
	int 21h
	clc
	jmp crm_fin
	
crm_error:
	stc
	
crm_fin:
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
	cargar_recursos_desde_mapa ENDP
	
	cargar_sprite_16x16 PROC
	push ax
	push bx
	push cx
	push si
	push bp
	
	mov ax, 3D00h
	int 21h
	jc cs16_error
	
	mov bx, ax
	call saltar_linea
	
	xor bp, bp
	
cs16_leer:
	mov ah, 3Fh
	mov cx, 200
	push dx
	mov dx, OFFSET buffer_temp
	int 21h
	pop dx
	
	cmp ax, 0
	je cs16_cerrar
	
	mov cx, ax
	xor si, si
	
cs16_proc:
	cmp si, cx
	jae cs16_leer
	
	mov al, [buffer_temp + si]
	inc si
	
	cmp al, ' '
	je cs16_proc
	cmp al, 13
	je cs16_proc
	cmp al, 10
	je cs16_proc
	cmp al, 9
	je cs16_proc
	
	cmp al, '0'
	jb cs16_proc
	cmp al, '9'
	jbe cs16_dec
	
	and al, 0DFh
	cmp al, 'A'
	jb cs16_proc
	cmp al, 'F'
	ja cs16_proc
	sub al, 'A' - 10
	jmp cs16_guardar
	
cs16_dec:
	sub al, '0'
	
cs16_guardar:
	mov [di], al
	inc di
	inc bp
	cmp bp, 256
	jb cs16_proc
	
cs16_cerrar:
	mov ah, 3Eh
	int 21h
	clc
	jmp cs16_fin
	
cs16_error:
	stc
	
cs16_fin:
	pop bp
	pop si
	pop cx
	pop bx
	pop ax
	ret
	cargar_sprite_16x16 ENDP
	
	cargar_sprite_32x32 PROC
	push ax
	push bx
	push cx
	push si
	push bp
	
	mov ax, 3D00h
	int 21h
	jc cs32_error
	
	mov bx, ax
	call saltar_linea
	
	xor bp, bp
	
cs32_leer:
	mov ah, 3Fh
	mov cx, 200
	push dx
	mov dx, OFFSET buffer_temp
	int 21h
	pop dx
	
	cmp ax, 0
	je cs32_cerrar
	
	mov cx, ax
	xor si, si
	
cs32_proc:
	cmp si, cx
	jae cs32_leer
	
	mov al, [buffer_temp + si]
	inc si
	
	cmp al, ' '
	je cs32_proc
	cmp al, 13
	je cs32_proc
	cmp al, 10
	je cs32_proc
	cmp al, 9
	je cs32_proc
	
	cmp al, '0'
	jb cs32_proc
	cmp al, '9'
	jbe cs32_dec
	
	and al, 0DFh
	cmp al, 'A'
	jb cs32_proc
	cmp al, 'F'
	ja cs32_proc
	sub al, 'A' - 10
	jmp cs32_guardar
	
cs32_dec:
	sub al, '0'
	
cs32_guardar:
	mov [di], al
	inc di
	inc bp
	cmp bp, 1024
	jb cs32_proc
	
cs32_cerrar:
	mov ah, 3Eh
	int 21h
	clc
	jmp cs32_fin
	
cs32_error:
	stc
	
cs32_fin:
	pop bp
	pop si
	pop cx
	pop bx
	pop ax
	ret
	cargar_sprite_32x32 ENDP
	
	saltar_linea PROC
	push ax
	push cx
	push dx
	
sl_loop:
	mov ah, 3Fh
	mov cx, 1
	mov dx, OFFSET buffer_temp
	int 21h
	
	cmp ax, 0
	je sl_fin
	
	mov al, [buffer_temp]
	cmp al, 10
	je sl_fin
	cmp al, 13
	jne sl_loop
	
sl_fin:
	pop dx
	pop cx
	pop ax
	ret
	saltar_linea ENDP
	
	debug_mostrar_tile PROC
	push ax
	push bx
	push cx
	push dx
	
	
	mov bx, 19
	shl bx, 1
	mov ax, [mul100_table + bx]
	add ax, 15
	mov bx, ax
	
	mov al, [mapa_datos + bx]
	
	
	add al, '0'
	mov [msg_error], al
	mov dx, OFFSET msg_error
	mov ah, 9
	int 21h
	
	pop dx
	pop cx
	pop bx
	pop ax
	ret
	debug_mostrar_tile ENDP
	
	debug_verificar_mapa PROC
	push ax
	push bx
	mov bx, 25
	shl bx, 1
	mov ax, [mul100_table + bx]
	add ax, 25
	mov bx, ax
	mov al, [mapa_datos + bx]
	test al, al
	jnz dvm_ok
	mov ax, 3
	int 10h
	mov dx, OFFSET msg_error
	mov ah, 9
	int 21h
	mov ah, 0
	int 16h
	
dvm_ok:
	pop bx
	pop ax
	ret
	debug_verificar_mapa ENDP
	
	
	debug_verificar_todo PROC
	push ax
	push bx
	mov bx, 2
	mov ax, [mul100_table + bx]
	cmp ax, 100
	je dvt_tabla_ok
	mov ax, 3
	int 10h
	mov dx, OFFSET msg_error
	mov ah, 9
	int 21h
	mov ah, 0
	int 16h
	jmp fin_juego
	
dvt_tabla_ok:
	mov al, [mapa_datos + 0]
	test al, al
	jnz dvt_mapa_ok
	mov ax, 3
	int 10h
	mov dx, OFFSET msg_error
	mov ah, 9
	int 21h
	mov ah, 0
	int 16h
	jmp fin_juego
	
dvt_mapa_ok:
	pop bx
	pop ax
	ret
	debug_verificar_todo ENDP
	
	get_tile_under_player PROC
	push bx
	push cx
	push dx
	
	mov ax, [jugador_px]
	shr ax, 4
	mov cx, ax
	
	mov ax, [jugador_py]
	add ax, 8
	shr ax, 4
	mov dx, ax
	
	cmp cx, 99
	ja gtup_invalid
	cmp dx, 99
	ja gtup_invalid
	
	mov ax, dx
	shl ax, 1
	mov bx, ax
	mov bx, [mul100_table + bx]
	add bx, cx
	
	mov al, [mapa_datos + bx]
	mov ah, 0
	jmp gtup_fin
	
gtup_invalid:
	mov al, TILE_ROCA_VOLCANICA
	mov ah, 0
	
gtup_fin:
	pop dx
	pop cx
	pop bx
	ret
	get_tile_under_player ENDP
	
	INCLUDE OPTCODE.INC
	INCLUDE INVCODE.INC
	
	END inicio
