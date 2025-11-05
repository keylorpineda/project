COLOR_TITULO EQU 14
COLOR_TEXTO EQU 7
COLOR_TEXTO_SEC EQU 8
COLOR_OBJETIVO EQU 15
COLOR_CONTINUAR EQU 11
COLOR_INICIO EQU 10

INTRO_X EQU 40
INTRO_Y_TITULO EQU 30
INTRO_Y_TEXTO EQU 60
INTRO_Y_ESPACIO EQU 12

.DATA
intro_titulo db 'Protocolo Santuario', 0

intro_p1_l1 db 'Este mundo murio hace un siglo.', 0
intro_p1_l2 db 'No fue una guerra, fue un error de calculo.', 0
intro_p1_l3 db 'El "Proyecto Eden", controlado por la IA "Cronos",', 0
intro_p1_l4 db 'fracaso catastroficamente.', 0
intro_p1_l5 db 'Sus sistemas, ahora en conflicto, desgarraron el', 0
intro_p1_l6 db 'planeta en tres zonas de desastre puro:', 0
intro_p1_l7 db 'La Fisura, El Cero Absoluto, y El Sumidero Quimico.', 0
intro_p1_l8 db 'Tu hogar es "Santuario", el ultimo bastion.', 0
intro_p1_l9 db 'Y ahora... su generador esta fallando.', 0

intro_p2_l1 db 'Eres un Especialista en Recuperacion.', 0
intro_p2_l2 db 'El Ingeniero en Jefe te ha dado una mision suicida:', 0
intro_p2_l3 db 'Reiniciar el generador a la fuerza.', 0
intro_p2_l4 db 'Necesitas dos unidades de cada Catalizador de Red:', 0

intro_p2_obj1 db ': Dos Geodas de Datos (Cristales)', 0
intro_p2_obj2 db ': Dos Nucleos de Energia (Gemas)', 0
intro_p2_obj3 db ': Dos Bio-Estabilizadores (Monedas)', 0

intro_p3_l1 db 'Tu travesia sera un infierno.', 0
intro_p3_l2 db 'Lucharas contra el calor extremo, el hielo', 0
intro_p3_l3 db 'traicionero y los lagos de veneno.', 0
intro_p3_l4 db 'Cuando asegures los seis Catalizadores,', 0
intro_p3_l5 db 'regresa a la Sala del Generador.', 0
intro_p3_l6 db 'Has comprado mas tiempo para la humanidad.', 0

intro_p3_l_final db 'INICIANDO PROTOCOLO...', 0

intro_continuar db 'Presiona una tecla para continuar...', 0

intro_x_actual dw 0
intro_y_actual dw 0

.CODE

retraso_tecleo PROC
    push cx
    mov cx, 3000
.delay:
    loop .delay
    pop cx
    ret
retraso_tecleo ENDP

retraso_tecla_largo PROC
    push cx
    mov cx, 0FFFFh
.delay_l:
    loop .delay_l
    pop cx
    ret
retraso_tecla_largo ENDP

reproducir_sonido_tecleo PROC
    push ax
    push bx
    push cx

    mov al, 0B6h
    out 43h, al
    mov ax, 900
    out 42h, al
    mov al, ah
    out 42h, al
    
    in al, 61h
    mov bl, al
    or al, 3
    out 61h, al
    
    mov cx, 150
.delay_sonido:
    loop .delay_sonido
    
    mov al, bl
    out 61h, al
    
    pop cx
    pop bx
    pop ax
    ret
reproducir_sonido_tecleo ENDP

dibujar_char_at_color PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    push bp

    mov ax, VIDEO_SEG
    mov es, ax

    mov ax, dx
    mov dx, 320
    mul dx
    add ax, cx
    mov di, ax

    cmp al, ' '
    je .char_fin
    cmp al, ':'
    je .es_dos_puntos
    cmp al, '/'
    je .es_slash
    cmp al, '!'
    je .es_exclam
    
    cmp al, 'A'
    jb .es_numero
    
    sub al, 'A'
    add al, FONT_LETTER_OFFSET
    jmp .es_indice
    
.es_numero:
    sub al, '0'
    jmp .es_indice

.es_dos_puntos:
    mov al, FONT_COLON_INDEX
    jmp .es_indice

.es_slash:
    mov al, FONT_SLASH_INDEX
    jmp .es_indice
    
.es_exclam:
    mov al, FONT_EXCLAM_INDEX
    
.es_indice:
    xor ah, ah
    mov bx, ax
    shl bx, 3
    mov si, OFFSET font_8x8
    add si, bx

    mov bp, 8
.fila_loop:
    push di
    mov al, [si]
    
    mov cx, 8
.pixel_loop:
    rol al, 1
    jnc .pixel_off

    mov [es:di], bl
    
.pixel_off:
    inc di
    loop .pixel_loop
    
    pop di
    add di, 320
    inc si
    dec bp
    jnz .fila_loop

.char_fin:
    pop bp
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_char_at_color ENDP

dibujar_texto_tecleo PROC
    push ax
    push bx
    push cx
    push dx
    push si

    mov intro_x_actual, cx
    mov intro_y_actual, dx

.bucle_char:
    mov al, [si]
    cmp al, 0
    je .fin_texto
    
    cmp al, ' '
    je .es_espacio

    push ax
    mov cx, intro_x_actual
    mov dx, intro_y_actual
    call dibujar_char_at_color
    call reproducir_sonido_tecleo
    call retraso_tecleo
    pop ax
    
    jmp .siguiente_char

.es_espacio:
    call retraso_tecleo

.siguiente_char:
    add intro_x_actual, 8
    inc si
    jmp .bucle_char

.fin_texto:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_texto_tecleo ENDP

limpiar_pantalla_intro PROC
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
    xor di, di
    mov cx, 14000
    xor ax, ax
    rep stosw
    
    pop es
    pop di
    pop dx
    pop cx
    pop ax
    ret
limpiar_pantalla_intro ENDP

esperar_tecla_intro PROC
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov cx, 200
    mov dx, 420
    mov bl, COLOR_CONTINUAR
    mov si, OFFSET intro_continuar
    call dibujar_texto_tecleo

    mov ah, 0
    int 16h

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
esperar_tecla_intro ENDP

ejecutar_intro PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    
    mov temp_offset, 0

    call limpiar_pantalla_intro
    mov cx, 220
    mov dx, INTRO_Y_TITULO
    mov bl, COLOR_TITULO
    mov si, OFFSET intro_titulo
    call dibujar_texto_tecleo

    mov dx, INTRO_Y_TEXTO
    mov cx, INTRO_X
    mov bl, COLOR_TEXTO
    mov si, OFFSET intro_p1_l1
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov si, OFFSET intro_p1_l2
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov si, OFFSET intro_p1_l3
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov si, OFFSET intro_p1_l4
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov si, OFFSET intro_p1_l5
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov si, OFFSET intro_p1_l6
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov bl, COLOR_TEXTO_SEC
    mov si, OFFSET intro_p1_l7
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov bl, COLOR_TEXTO
    mov si, OFFSET intro_p1_l8
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov si, OFFSET intro_p1_l9
    call dibujar_texto_tecleo

    call esperar_tecla_intro

    call limpiar_pantalla_intro
    
    mov dx, INTRO_Y_TEXTO
    mov cx, INTRO_X
    mov bl, COLOR_TEXTO
    mov si, OFFSET intro_p2_l1
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov si, OFFSET intro_p2_l2
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov si, OFFSET intro_p2_l3
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov si, OFFSET intro_p2_l4
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    add cx, 32
    
    mov di, OFFSET sprite_cristal
    mov si, OFFSET sprite_cristal_mask
    push dx
    mov ax, cx
    sub ax, 24
    mov cx, ax
    add dx, 16
    call dibujar_sprite_planar_16x16_opt
    pop dx
    
    mov bl, COLOR_OBJETIVO
    mov si, OFFSET intro_p2_obj1
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    add cx, 32
    
    mov di, OFFSET sprite_gema
    mov si, OFFSET sprite_gema_mask
    push dx
    mov ax, cx
    sub ax, 24
    mov cx, ax
    add dx, 16
    call dibujar_sprite_planar_16x16_opt
    pop dx
    
    mov bl, COLOR_OBJETIVO
    mov si, OFFSET intro_p2_obj2
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    add cx, 32
    
    mov di, OFFSET sprite_moneda
    mov si, OFFSET sprite_moneda_mask
    push dx
    mov ax, cx
    sub ax, 24
    mov cx, ax
    add dx, 16
    call dibujar_sprite_planar_16x16_opt
    pop dx
    
    mov bl, COLOR_OBJETIVO
    mov si, OFFSET intro_p2_obj3
    call dibujar_texto_tecleo

    call esperar_tecla_intro
    
    call limpiar_pantalla_intro
    
    mov dx, INTRO_Y_TEXTO
    mov cx, INTRO_X
    mov bl, COLOR_TEXTO
    mov si, OFFSET intro_p3_l1
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov si, OFFSET intro_p3_l2
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov si, OFFSET intro_p3_l3
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov si, OFFSET intro_p3_l4
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov si, OFFSET intro_p3_l5
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov si, OFFSET intro_p3_l6
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    add dx, INTRO_Y_ESPACIO
    add dx, INTRO_Y_ESPACIO
    mov cx, 232
    mov bl, COLOR_INICIO
    mov si, OFFSET intro_p3_l_final
    call dibujar_texto_tecleo
    
    call retraso_tecla_largo
    call retraso_tecla_largo

    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ejecutar_intro ENDP