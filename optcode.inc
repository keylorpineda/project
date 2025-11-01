	inicializar_lookup_tables PROC
	push ax
	push bx
	push cx
	push di
	mov di, OFFSET mul100_table
	xor ax, ax
	mov cx, 200
ilt_loop_mul100:
	mov [di], ax
	add di, 2
	add ax, 100
	loop ilt_loop_mul100
	
	
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
	
	verificar_tile_transitable_opt PROC
	push ax
	push bx
	push dx
	cmp cx, 100
	jae vtt_no_transitable
	cmp dx, 100
	jae vtt_no_transitable
	mov ax, dx
	mov bx, cx
	push bx
	mov bx, ax
	shl bx, 1
	mov ax, [mul100_table + bx]
	pop bx
	add ax, bx
	mov bx, ax
	mov al, [mapa_datos + bx]
        cmp al, 1
        je vtt_no_transitable
        cmp al, 3
        je vtt_no_transitable
        cmp al, 6
        je vtt_no_transitable
        cmp al, 7
        je vtt_no_transitable
        cmp al, 9
        je vtt_no_transitable
        cmp al, 11
        je vtt_no_transitable
        cmp al, 13
        je vtt_no_transitable
        cmp al, 14
        je vtt_no_transitable
        cmp al, 15
        je vtt_no_transitable
        cmp al, 16
        je vtt_no_transitable
        cmp al, 17
        je vtt_no_transitable
        cmp al, 18
        je vtt_no_transitable
        cmp al, 19
        je vtt_no_transitable
        cmp al, 20
        je vtt_no_transitable
	
	pop dx
	pop bx
	pop ax
	stc
	ret
	
vtt_no_transitable:
	pop dx
	pop bx
	pop ax
	clc
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
	
	mov cx, 16
	
cspo_fila:
	push cx
	
	
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
	
	
	mov [di], dl
	mov [di + 32], dh
	mov [di + 64], bl
	mov [di + 96], bh
	
	
	mov al, dl
	or al, dh
	or al, bl
	or al, bh
	mov [bp], al
	
	
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
	
	
	mov [di + 1], dl
	mov [di + 33], dh
	mov [di + 65], bl
	mov [di + 97], bh
	
	
	mov al, dl
	or al, dh
	or al, bl
	or al, bh
	mov [bp + 1], al
	
	
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
	mov [di + 128], dh
	mov [di + 256], bl
	mov [di + 384], bh
	
	
	mov al, dl
	or al, dh
	or al, bl
	or al, bh
	mov [bp], al
	
	inc di
	inc bp
	
	
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
	mov [di + 128], dh
	mov [di + 256], bl
	mov [di + 384], bh
	
	
	mov al, dl
	or al, dh
	or al, bl
	or al, bh
	mov [bp], al
	
	inc di
	inc bp
	
	
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
	mov [di + 128], dh
	mov [di + 256], bl
	mov [di + 384], bh
	
	
	mov al, dl
	or al, dh
	or al, bl
	or al, bh
	mov [bp], al
	
	inc di
	inc bp
	
	
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
	mov [di + 128], dh
	mov [di + 256], bl
	mov [di + 384], bh
	
	
	mov al, dl
	or al, dh
	or al, bl
	or al, bh
	mov [bp], al
	
	inc di
	inc bp
	
	
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
	
	
	
	
	precalcular_mascaras_tiles PROC
	push si
	push di
	push cx
	push ax
	
	
        mov si, OFFSET sprite_roca_volcanica
        mov di, OFFSET sprite_roca_volcanica_mask
        call calcular_mascara_16x16


        mov si, OFFSET sprite_lava
        mov di, OFFSET sprite_lava_mask
        call calcular_mascara_16x16


        mov si, OFFSET sprite_ceniza
        mov di, OFFSET sprite_ceniza_mask
        call calcular_mascara_16x16


        mov si, OFFSET sprite_roca_bloque
        mov di, OFFSET sprite_roca_bloque_mask
        call calcular_mascara_16x16


        mov si, OFFSET sprite_nieve
        mov di, OFFSET sprite_nieve_mask
        call calcular_mascara_16x16


        mov si, OFFSET sprite_hielo
        mov di, OFFSET sprite_hielo_mask
        call calcular_mascara_16x16


        mov si, OFFSET sprite_agua_congelada
        mov di, OFFSET sprite_agua_congelada_mask
        call calcular_mascara_16x16


        mov si, OFFSET sprite_roca_nevada
        mov di, OFFSET sprite_roca_nevada_mask
        call calcular_mascara_16x16


        mov si, OFFSET sprite_lodo
        mov di, OFFSET sprite_lodo_mask
        call calcular_mascara_16x16


        mov si, OFFSET sprite_agua_toxica
        mov di, OFFSET sprite_agua_toxica_mask
        call calcular_mascara_16x16


        mov si, OFFSET sprite_tierra_muerta
        mov di, OFFSET sprite_tierra_muerta_mask
        call calcular_mascara_16x16


        mov si, OFFSET sprite_arbol_muerto
        mov di, OFFSET sprite_arbol_muerto_mask
        call calcular_mascara_16x16
	
	
        mov si, OFFSET sprite_cesped
        mov di, OFFSET sprite_cesped_mask
        call calcular_mascara_16x16
	
	
        mov si, OFFSET sprite_estanque_aves
        mov di, OFFSET sprite_estanque_aves_mask
        call calcular_mascara_16x16
	
	
        mov si, OFFSET sprite_totem_aves
        mov di, OFFSET sprite_totem_aves_mask
        call calcular_mascara_16x16


        mov si, OFFSET sprite_casa_techo_izq
        mov di, OFFSET sprite_casa_techo_izq_mask
        call calcular_mascara_16x16


        mov si, OFFSET sprite_casa_techo_cen
        mov di, OFFSET sprite_casa_techo_cen_mask
        call calcular_mascara_16x16


        mov si, OFFSET sprite_casa_techo_der
        mov di, OFFSET sprite_casa_techo_der_mask
        call calcular_mascara_16x16


        mov si, OFFSET sprite_casa_pared
        mov di, OFFSET sprite_casa_pared_mask
        call calcular_mascara_16x16


        mov si, OFFSET sprite_casa_ventana
        mov di, OFFSET sprite_casa_ventana_mask
        call calcular_mascara_16x16


        mov si, OFFSET sprite_casa_puerta
        mov di, OFFSET sprite_casa_puerta_mask
        call calcular_mascara_16x16


        mov si, OFFSET sprite_cristal
        mov di, OFFSET sprite_cristal_mask
        call calcular_mascara_16x16
	
	mov si, OFFSET sprite_gema
	mov di, OFFSET sprite_gema_mask
	call calcular_mascara_16x16
	
	mov si, OFFSET sprite_moneda
	mov di, OFFSET sprite_moneda_mask
	call calcular_mascara_16x16
	
	pop ax
	pop cx
	pop di
	pop si
	ret
	precalcular_mascaras_tiles ENDP
	
	calcular_mascara_16x16 PROC
	push bx
	push cx
	
	mov cx, 16
cm16_loop:
	
	mov al, [si]
	or al, [si + 32]
	or al, [si + 64]
	or al, [si + 96]
	mov [di], al
	
	
	mov al, [si + 1]
	or al, [si + 33]
	or al, [si + 65]
	or al, [si + 97]
	mov [di + 1], al
	
	add si, 2
	add di, 2
	loop cm16_loop
	
	pop cx
	pop bx
	ret
	calcular_mascara_16x16 ENDP
	
	
	
	
	precalcular_mascaras_jugador PROC
	push si
	push di
	
	mov si, OFFSET jugador_up_a
	mov di, OFFSET jugador_up_a_mask
	call calcular_mascara_32x32
	
	mov si, OFFSET jugador_up_b
	mov di, OFFSET jugador_up_b_mask
	call calcular_mascara_32x32
	
	mov si, OFFSET jugador_down_a
	mov di, OFFSET jugador_down_a_mask
	call calcular_mascara_32x32
	
	mov si, OFFSET jugador_down_b
	mov di, OFFSET jugador_down_b_mask
	call calcular_mascara_32x32
	
	mov si, OFFSET jugador_izq_a
	mov di, OFFSET jugador_izq_a_mask
	call calcular_mascara_32x32
	
	mov si, OFFSET jugador_izq_b
	mov di, OFFSET jugador_izq_b_mask
	call calcular_mascara_32x32
	
	mov si, OFFSET jugador_der_a
	mov di, OFFSET jugador_der_a_mask
	call calcular_mascara_32x32
	
	mov si, OFFSET jugador_der_b
	mov di, OFFSET jugador_der_b_mask
	call calcular_mascara_32x32
	
	pop di
	pop si
	ret
	precalcular_mascaras_jugador ENDP
	
	calcular_mascara_32x32 PROC
	push bx
	push cx
	
	mov cx, 32
cm32_loop:
	
	mov al, [si]
	or al, [si + 128]
	or al, [si + 256]
	or al, [si + 384]
	mov [di], al
	
	
	mov al, [si + 1]
	or al, [si + 129]
	or al, [si + 257]
	or al, [si + 385]
	mov [di + 1], al
	
	
	mov al, [si + 2]
	or al, [si + 130]
	or al, [si + 258]
	or al, [si + 386]
	mov [di + 2], al
	
	
	mov al, [si + 3]
	or al, [si + 131]
	or al, [si + 259]
	or al, [si + 387]
	mov [di + 3], al
	
	add si, 4
	add di, 4
	loop cm32_loop
	
	pop cx
	pop bx
	ret
	calcular_mascara_32x32 ENDP
	
	
	
	
	ajustar_coords_scroll PROC
	
	
	push ax
	
	mov ax, scroll_offset_x
	sub cx, ax
	
	mov ax, scroll_offset_y
	sub dx, ax
	
	pop ax
	ret
	ajustar_coords_scroll ENDP
	
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
	
	mov bx, dx
	shl bx, 1
	mov bp, [video_offsets + bx]
	mov ax, cx
	shr ax, 3
	add bp, ax
	add bp, temp_offset
	
	mov bx, di
	
	
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
	
	push bp
	push bx
	push si
	
	mov cx, 4
	
dsp16_p0:
	mov di, bp
	
	mov ah, [si]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 1]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 1]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	add di, 80
	mov ah, [si + 2]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 2]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 3]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 3]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	add di, 80
	mov ah, [si + 4]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 4]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 5]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 5]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	add di, 80
	mov ah, [si + 6]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 6]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 7]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 7]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	add bp, 320
	add si, 8
	add bx, 8
	dec cx
	jz dsp16_p0_done
	jmp dsp16_p0
	
dsp16_p0_done:
	pop si
	pop bx
	pop bp
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
	push bp
	push bx
	push si
	mov cx, 4
	
dsp16_p1:
	mov di, bp
	
	mov ah, [si]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 32]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 1]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 33]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	add di, 80
	mov ah, [si + 2]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 34]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 3]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 35]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	add di, 80
	mov ah, [si + 4]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 36]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 5]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 37]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	add di, 80
	mov ah, [si + 6]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 38]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 7]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 39]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	add bp, 320
	add si, 8
	add bx, 8
	dec cx
	jz dsp16_p1_done
	jmp dsp16_p1
	
dsp16_p1_done:
	
	pop si
	pop bx
	pop bp
	
	
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
	
	push bp
	push bx
	push si
	
	mov cx, 4
	
dsp16_p2:
	mov di, bp
	
	mov ah, [si]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 64]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 1]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 65]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	add di, 80
	mov ah, [si + 2]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 66]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 3]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 67]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	add di, 80
	mov ah, [si + 4]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 68]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 5]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 69]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	add di, 80
	mov ah, [si + 6]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 70]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 7]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 71]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	add bp, 320
	add si, 8
	add bx, 8
	dec cx
	jz dsp16_p2_done
	jmp dsp16_p2
	
dsp16_p2_done:
	
	pop si
	pop bx
	pop bp
	
	
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
	
	
	push bp
	push bx
	push si
	
	
	mov cx, 4
	
dsp16_p3:
	mov di, bp
	
	mov ah, [si]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 96]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 1]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 97]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	add di, 80
	mov ah, [si + 2]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 98]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 3]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 99]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	add di, 80
	mov ah, [si + 4]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 100]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 5]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 101]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	add di, 80
	mov ah, [si + 6]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 102]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 7]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 103]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	add bp, 320
	add si, 8
	add bx, 8
	dec cx
	jz dsp16_p3_done
	jmp dsp16_p3
	
dsp16_p3_done:
	
	
	pop si
	pop bx
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
	
	
	mov bx, dx
	shl bx, 1
	mov bp, [video_offsets + bx]
	mov ax, cx
	shr ax, 3
	add bp, ax
	add bp, temp_offset
	
	mov bx, di
	
	
	
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
	
	push bp
	push bx
	push si
	
	
	mov cx, 8
	
dsp32_p0_loop:
	mov di, bp
	
	
	mov ah, [si]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 1]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 1]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	mov ah, [si + 2]
	mov al, ah
	not al
and al, es:[di + 2]
	mov dl, [bx + 2]
	and dl, ah
	or al, dl
mov es:[di + 2], al
	
	mov ah, [si + 3]
	mov al, ah
	not al
and al, es:[di + 3]
	mov dl, [bx + 3]
	and dl, ah
	or al, dl
mov es:[di + 3], al
	
	
	add di, 80
	mov ah, [si + 4]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 4]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 5]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 5]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	mov ah, [si + 6]
	mov al, ah
	not al
and al, es:[di + 2]
	mov dl, [bx + 6]
	and dl, ah
	or al, dl
mov es:[di + 2], al
	
	mov ah, [si + 7]
	mov al, ah
	not al
and al, es:[di + 3]
	mov dl, [bx + 7]
	and dl, ah
	or al, dl
mov es:[di + 3], al
	
	
	add di, 80
	mov ah, [si + 8]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 8]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 9]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 9]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	mov ah, [si + 10]
	mov al, ah
	not al
and al, es:[di + 2]
	mov dl, [bx + 10]
	and dl, ah
	or al, dl
mov es:[di + 2], al
	
	mov ah, [si + 11]
	mov al, ah
	not al
and al, es:[di + 3]
	mov dl, [bx + 11]
	and dl, ah
	or al, dl
mov es:[di + 3], al
	
	
	add di, 80
	mov ah, [si + 12]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 12]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 13]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 13]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	mov ah, [si + 14]
	mov al, ah
	not al
and al, es:[di + 2]
	mov dl, [bx + 14]
	and dl, ah
	or al, dl
mov es:[di + 2], al
	
	mov ah, [si + 15]
	mov al, ah
	not al
and al, es:[di + 3]
	mov dl, [bx + 15]
	and dl, ah
	or al, dl
mov es:[di + 3], al
	
	add bp, 320
	add si, 16
	add bx, 16
	dec cx
	jz dsp32_p0_done
	jmp dsp32_p0_loop
	
dsp32_p0_done:
	pop si
	pop bx
	pop bp
	
	
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
	
	push bp
	push bx
	push si
	mov cx, 8
	
dsp32_p1_loop:
	mov di, bp
	
	
	mov ah, [si]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 128]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 1]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 129]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	mov ah, [si + 2]
	mov al, ah
	not al
and al, es:[di + 2]
	mov dl, [bx + 130]
	and dl, ah
	or al, dl
mov es:[di + 2], al
	
	mov ah, [si + 3]
	mov al, ah
	not al
and al, es:[di + 3]
	mov dl, [bx + 131]
	and dl, ah
	or al, dl
mov es:[di + 3], al
	
	
	add di, 80
	mov ah, [si + 4]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 132]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 5]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 133]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	mov ah, [si + 6]
	mov al, ah
	not al
and al, es:[di + 2]
	mov dl, [bx + 134]
	and dl, ah
	or al, dl
mov es:[di + 2], al
	
	mov ah, [si + 7]
	mov al, ah
	not al
and al, es:[di + 3]
	mov dl, [bx + 135]
	and dl, ah
	or al, dl
mov es:[di + 3], al
	
	
	add di, 80
	mov ah, [si + 8]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 136]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 9]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 137]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	mov ah, [si + 10]
	mov al, ah
	not al
and al, es:[di + 2]
	mov dl, [bx + 138]
	and dl, ah
	or al, dl
mov es:[di + 2], al
	
	mov ah, [si + 11]
	mov al, ah
	not al
and al, es:[di + 3]
	mov dl, [bx + 139]
	and dl, ah
	or al, dl
mov es:[di + 3], al
	
	
	add di, 80
	mov ah, [si + 12]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 140]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 13]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 141]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	mov ah, [si + 14]
	mov al, ah
	not al
and al, es:[di + 2]
	mov dl, [bx + 142]
	and dl, ah
	or al, dl
mov es:[di + 2], al
	
	mov ah, [si + 15]
	mov al, ah
	not al
and al, es:[di + 3]
	mov dl, [bx + 143]
	and dl, ah
	or al, dl
mov es:[di + 3], al
	
	add bp, 320
	add si, 16
	add bx, 16
	dec cx
	jz dsp32_p1_done
	jmp dsp32_p1_loop
	
dsp32_p1_done:
	pop si
	pop bx
	pop bp
	
	
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
	
	push bp
	push bx
	push si
	mov cx, 8
	
dsp32_p2_loop:
	mov di, bp
	
	
	mov ah, [si]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 256]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 1]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 257]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	mov ah, [si + 2]
	mov al, ah
	not al
and al, es:[di + 2]
	mov dl, [bx + 258]
	and dl, ah
	or al, dl
mov es:[di + 2], al
	
	mov ah, [si + 3]
	mov al, ah
	not al
and al, es:[di + 3]
	mov dl, [bx + 259]
	and dl, ah
	or al, dl
mov es:[di + 3], al
	add di, 80
	mov ah, [si + 4]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 260]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 5]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 261]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	mov ah, [si + 6]
	mov al, ah
	not al
and al, es:[di + 2]
	mov dl, [bx + 262]
	and dl, ah
	or al, dl
mov es:[di + 2], al
	
	mov ah, [si + 7]
	mov al, ah
	not al
and al, es:[di + 3]
	mov dl, [bx + 263]
	and dl, ah
	or al, dl
mov es:[di + 3], al
	
	
	add di, 80
	mov ah, [si + 8]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 264]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 9]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 265]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	mov ah, [si + 10]
	mov al, ah
	not al
and al, es:[di + 2]
	mov dl, [bx + 266]
	and dl, ah
	or al, dl
mov es:[di + 2], al
	
	mov ah, [si + 11]
	mov al, ah
	not al
and al, es:[di + 3]
	mov dl, [bx + 267]
	and dl, ah
	or al, dl
mov es:[di + 3], al
	
	add di, 80
	mov ah, [si + 12]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 268]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 13]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 269]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	mov ah, [si + 14]
	mov al, ah
	not al
and al, es:[di + 2]
	mov dl, [bx + 270]
	and dl, ah
	or al, dl
mov es:[di + 2], al
	
	mov ah, [si + 15]
	mov al, ah
	not al
and al, es:[di + 3]
	mov dl, [bx + 271]
	and dl, ah
	or al, dl
mov es:[di + 3], al
	
	add bp, 320
	add si, 16
	add bx, 16
	dec cx
	jz dsp32_p2_done
	jmp dsp32_p2_loop
	
dsp32_p2_done:
	pop si
	pop bx
	pop bp
	
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
	
dsp32_p3_loop:
	mov di, bp
	
	
	mov ah, [si]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 384]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 1]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 385]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	mov ah, [si + 2]
	mov al, ah
	not al
and al, es:[di + 2]
	mov dl, [bx + 386]
	and dl, ah
	or al, dl
mov es:[di + 2], al
	
	mov ah, [si + 3]
	mov al, ah
	not al
and al, es:[di + 3]
	mov dl, [bx + 387]
	and dl, ah
	or al, dl
mov es:[di + 3], al
	
	
	add di, 80
	mov ah, [si + 4]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 388]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 5]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 389]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	mov ah, [si + 6]
	mov al, ah
	not al
and al, es:[di + 2]
	mov dl, [bx + 390]
	and dl, ah
	or al, dl
mov es:[di + 2], al
	
	mov ah, [si + 7]
	mov al, ah
	not al
and al, es:[di + 3]
	mov dl, [bx + 391]
	and dl, ah
	or al, dl
mov es:[di + 3], al
	
	
	add di, 80
	mov ah, [si + 8]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 392]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 9]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 393]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	mov ah, [si + 10]
	mov al, ah
	not al
and al, es:[di + 2]
	mov dl, [bx + 394]
	and dl, ah
	or al, dl
mov es:[di + 2], al
	
	mov ah, [si + 11]
	mov al, ah
	not al
and al, es:[di + 3]
	mov dl, [bx + 395]
	and dl, ah
	or al, dl
mov es:[di + 3], al
	
	
	add di, 80
	mov ah, [si + 12]
	mov al, ah
	not al
and al, es:[di]
	mov dl, [bx + 396]
	and dl, ah
	or al, dl
mov es:[di], al
	
	mov ah, [si + 13]
	mov al, ah
	not al
and al, es:[di + 1]
	mov dl, [bx + 397]
	and dl, ah
	or al, dl
mov es:[di + 1], al
	
	mov ah, [si + 14]
	mov al, ah
	not al
and al, es:[di + 2]
	mov dl, [bx + 398]
	and dl, ah
	or al, dl
mov es:[di + 2], al
	
	mov ah, [si + 15]
	mov al, ah
	not al
and al, es:[di + 3]
	mov dl, [bx + 399]
	and dl, ah
	or al, dl
mov es:[di + 3], al
	
	add bp, 320
	add si, 16
	add bx, 16
	dec cx
	jz dsp32_p3_done
	jmp dsp32_p3_loop
	
dsp32_p3_done:
	
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
	
	aplicar_scroll_hardware PROC
	push ax
	push dx
	mov ax, camara_px
	and ax, 15
	mov scroll_offset_x, ax
	
	mov ax, camara_py
	and ax, 15
	mov scroll_offset_y, ax
	
	pop dx
	pop ax
	ret
	aplicar_scroll_hardware ENDP
	
	centrar_camara_suave PROC
	push ax
	push bx
	
	mov ax, jugador_px
	sub ax, 200
	jge ccs_x_pos
	xor ax, ax
ccs_x_pos:
	cmp ax, 1200
	jle ccs_x_ok
	mov ax, 1200
ccs_x_ok:
	mov camara_px, ax
	
	mov ax, jugador_py
	sub ax, 120
	jge ccs_y_pos
	xor ax, ax
ccs_y_pos:
	cmp ax, 1360
	jle ccs_y_ok
	mov ax, 1360
ccs_y_ok:
	mov camara_py, ax
	
	call aplicar_scroll_hardware
	
	pop bx
	pop ax
	ret
centrar_camara_suave ENDP