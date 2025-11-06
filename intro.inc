INTRO_COLOR_TITULO EQU 14
INTRO_COLOR_TEXTO EQU 7
INTRO_COLOR_TEXTO_SEC EQU 8
INTRO_COLOR_OBJETIVO EQU 15
INTRO_COLOR_ADVERTENCIA EQU 12
INTRO_COLOR_CONTINUAR EQU 11
INTRO_COLOR_INICIO EQU 10
INTRO_COLOR_LUGAR EQU 14

INTRO_X EQU 40
INTRO_Y_TITULO EQU 20
INTRO_Y_TEXTO EQU 50
INTRO_Y_ESPACIO EQU 18

.DATA
intro_titulo db 'Protocolo Santuario', 0

intro_p1_l1 db 'Este mundo murio hace un siglo.', 0
intro_p1_l2 db 'No fue una guerra, fue un error de calculo.', 0
intro_p1_l3 db 'El "Proyecto Eden", controlado por la IA "Cronos",', 0
intro_p1_l4 db 'fracaso catastroficamente.', 0
intro_p1_l5 db 'Sus sistemas, ahora en conflicto, desgarraron el', 0
intro_p1_l6 db 'planeta en tres zonas de desastre puro:', 0
intro_p1_l7a db '- ', 0
intro_p1_l7b db 'La Fisura', 0
intro_p1_l7c db ', ', 0
intro_p1_l7d db 'El Cero Absoluto', 0
intro_p1_l7e db ', y ', 0
intro_p1_l7f db 'El Sumidero Quimico', 0
intro_p1_l7g db '.', 0
intro_p1_l8a db 'Tu hogar es EL ', 0
intro_p1_l8b db 'SANTUARIO', 0
intro_p1_l8c db ', el ultimo bastion.', 0
intro_p1_l9 db 'Y ahora... su generador esta fallando.', 0

intro_p2_l1 db 'Eres un Especialista en Recuperacion.', 0
intro_p2_l2 db 'El Ingeniero en Jefe te ha dado una mision:', 0
intro_p2_l3 db 'Reiniciar el generador a la fuerza.', 0
intro_p2_l4 db 'Necesitas dos unidades de cada Catalizador de Red:', 0

intro_p2_obj1 db 'Dos Geodas de Datos (Cristales)', 0
intro_p2_obj2 db 'Dos Nucleos de Energia (Gemas)', 0
intro_p2_obj3 db 'Dos Bio-Estabilizadores (Monedas)', 0

intro_p3_titulo db 'ADVERTENCIA: RIESGOS DE LA MISION', 0
intro_p3_l1 db 'Tu traje de recuperacion tiene vida limitada.', 0
intro_p3_l2 db 'Los entornos hostiles son letales.', 0
intro_p3_l3 db 'Si tu vida llega a cero,', 0
intro_p3_l4 db 'LA MISION FRACASA.', 0

intro_p3_l5 db 'Ademas,', 0
intro_p3_l6 db 'tu contenedor de muestras es finito.', 0
intro_p3_l7 db 'Debes priorizar los 6 Catalizadores.', 0
intro_p3_l8 db 'Si llenas el contenedor sin los objetivos,', 0
intro_p3_l9 db 'LA MISION FRACASA.', 0

intro_p3_l10 db 'No hay segundas oportunidades.', 0

intro_p4_l1 db 'Tu travesia sera un infierno.', 0
intro_p4_l2 db 'Lucharas contra el calor extremo, el hielo', 0
intro_p4_l3 db 'traicionero y los lagos de veneno.', 0
intro_p4_l4 db 'Cuando asegures los seis Catalizadores,', 0
intro_p4_l5 db 'la mision se completa de inmediato.', 0
intro_p4_l6 db 'No necesitas volver a ningun lugar.', 0

intro_p4_l_final db 'INICIANDO PROTOCOLO...', 0

intro_continuar db 'Presiona una tecla para continuar...', 0

intro_x_actual dw 0
intro_y_actual dw 0
intro_color_actual_texto db 0

.CODE

retraso_tecleo PROC
    push cx
    push dx
    mov cx, 1
.delay_outer:
    push cx
    mov cx, 8000h
.delay_inner:
    nop
    loop .delay_inner
    pop cx
    loop .delay_outer
    pop dx
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
    push dx

    in al, 61h
    mov bl, al
    or al, 3
    out 61h, al

    mov al, 0B6h
    out 43h, al
    mov ax, 1200
    out 42h, al
    mov al, ah
    out 42h, al
    
    mov cx, 500
.delay_sonido:
    loop .delay_sonido
    
    mov al, bl
    out 61h, al
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
reproducir_sonido_tecleo ENDP

intro_color_actual db 0
intro_glyph_ptr dw 0
texto_color_intro db 0

dibujar_texto_intro PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    mov texto_color_intro, bl
    mov ax, VIDEO_SEG
    mov es, ax

.loop:
    lodsb
    test al, al
    jz .fin

    cmp al, ' '
    je .space

    push cx
    push dx
    push si
    mov bl, texto_color_intro
    call dibujar_caracter_buffer_2x
    pop si
    pop dx
    pop cx

.space:
    add cx, 16
    jmp .loop

.fin:
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
dibujar_texto_intro ENDP

dibujar_char_at_color PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push es

    mov intro_color_actual, bl

    cmp al, 'a'
    jb .no_minus
    cmp al, 'z'
    ja .no_minus
    sub al, 32
.no_minus:

    call obtener_ptr_glifo
    jnc .continuar
    jmp .salir

.continuar:
    mov ax, VIDEO_SEG
    mov es, ax

    mov bx, dx
    shl bx, 1
    mov bp, [video_offsets + bx]
    
    mov ax, cx
    shr ax, 3
    add bp, ax
    add bp, temp_offset

    mov word ptr [intro_glyph_ptr], si

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
    mov si, word ptr [intro_glyph_ptr]

.p0:
    mov ah, [si]
    mov al, ah
    not al
    and al, es:[di]

    mov dl, intro_color_actual
    test dl, 1
    jz .p0_skip
    and ah, 0FFh
    or al, ah
.p0_skip:
    mov es:[di], al
    add di, 80
    inc si
    loop .p0

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
    mov si, word ptr [intro_glyph_ptr]

.p1:
    mov ah, [si]
    mov al, ah
    not al
    and al, es:[di]

    mov dl, intro_color_actual
    test dl, 2
    jz .p1_skip
    and ah, 0FFh
    or al, ah
.p1_skip:
    mov es:[di], al
    add di, 80
    inc si
    loop .p1

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
    mov si, word ptr [intro_glyph_ptr]

.p2:
    mov ah, [si]
    mov al, ah
    not al
    and al, es:[di]

    mov dl, intro_color_actual
    test dl, 4
    jz .p2_skip
    and ah, 0FFh
    or al, ah
.p2_skip:
    mov es:[di], al
    add di, 80
    inc si
    loop .p2

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
    mov si, word ptr [intro_glyph_ptr]

.p3:
    mov ah, [si]
    mov al, ah
    not al
    and al, es:[di]

    mov dl, intro_color_actual
    test dl, 8
    jz .p3_skip
    and ah, 0FFh
    or al, ah
.p3_skip:
    mov es:[di], al
    add di, 80
    inc si
    loop .p3

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

.salir:
    pop es
    pop bp
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
    mov byte ptr intro_color_actual_texto, bl

.bucle_char:
    mov al, [si]
    cmp al, 0
    je .fin_texto
    
    mov cx, intro_x_actual
    mov dx, intro_y_actual
    mov bl, byte ptr intro_color_actual_texto
    call dibujar_char_at_color
    
    cmp byte ptr [si], ' '
    je .es_espacio
    
    call reproducir_sonido_tecleo
    
.es_espacio:
    call retraso_tecleo
    
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
    
    mov ax, VIDEO_SEG
    mov es, ax
    
    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al
    
    xor di, di
    add di, temp_offset
    mov cx, 28000
    xor ax, ax
    rep stosb
    
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
    
    mov cx, 160
    mov dx, 320
    mov bl, INTRO_COLOR_CONTINUAR
    mov si, OFFSET intro_continuar
    call dibujar_texto_intro

.limpiar_buffer:
    mov ah, 1
    int 16h
    jz .esperar
    mov ah, 0
    int 16h
    jmp .limpiar_buffer

.esperar:
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
    mov bl, INTRO_COLOR_TITULO
    mov si, OFFSET intro_titulo
    call dibujar_texto_tecleo

    mov dx, INTRO_Y_TEXTO
    mov cx, INTRO_X
    mov bl, INTRO_COLOR_TEXTO
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
    mov bl, INTRO_COLOR_TEXTO_SEC
    mov si, OFFSET intro_p1_l7a
    call dibujar_texto_tecleo
    mov cx, intro_x_actual
    mov si, OFFSET intro_p1_l7b
    mov bl, INTRO_COLOR_ADVERTENCIA
    call dibujar_texto_tecleo
    mov cx, intro_x_actual
    mov si, OFFSET intro_p1_l7c
    mov bl, INTRO_COLOR_TEXTO_SEC
    call dibujar_texto_tecleo
    mov cx, intro_x_actual
    mov si, OFFSET intro_p1_l7d
    mov bl, INTRO_COLOR_ADVERTENCIA
    call dibujar_texto_tecleo
    mov cx, intro_x_actual
    mov si, OFFSET intro_p1_l7e
    mov bl, INTRO_COLOR_TEXTO_SEC
    call dibujar_texto_tecleo
    mov cx, intro_x_actual
    mov si, OFFSET intro_p1_l7f
    mov bl, INTRO_COLOR_ADVERTENCIA
    call dibujar_texto_tecleo
    mov cx, intro_x_actual
    mov si, OFFSET intro_p1_l7g
    mov bl, INTRO_COLOR_TEXTO_SEC
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov bl, INTRO_COLOR_TEXTO
    mov si, OFFSET intro_p1_l8a
    call dibujar_texto_tecleo
    mov cx, intro_x_actual
    mov bl, INTRO_COLOR_LUGAR
    mov si, OFFSET intro_p1_l8b
    call dibujar_texto_tecleo
    mov cx, intro_x_actual
    mov bl, INTRO_COLOR_TEXTO
    mov si, OFFSET intro_p1_l8c
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov si, OFFSET intro_p1_l9
    call dibujar_texto_tecleo

    call esperar_tecla_intro

    call limpiar_pantalla_intro
    
    mov dx, INTRO_Y_TEXTO
    mov cx, INTRO_X
    mov bl, INTRO_COLOR_TEXTO
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
    
    mov bl, INTRO_COLOR_OBJETIVO
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
    
    mov bl, INTRO_COLOR_OBJETIVO
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
    
    mov bl, INTRO_COLOR_OBJETIVO
    mov si, OFFSET intro_p2_obj3
    call dibujar_texto_tecleo

    call esperar_tecla_intro
    
    call limpiar_pantalla_intro

    mov cx, 150
    mov dx, INTRO_Y_TITULO
    mov bl, INTRO_COLOR_ADVERTENCIA
    mov si, OFFSET intro_p3_titulo
    call dibujar_texto_tecleo
    
    mov dx, INTRO_Y_TEXTO
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov bl, INTRO_COLOR_TEXTO
    mov si, OFFSET intro_p3_l1
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov si, OFFSET intro_p3_l2
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov bl, INTRO_COLOR_TEXTO_SEC
    mov si, OFFSET intro_p3_l3
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov bl, INTRO_COLOR_ADVERTENCIA
    mov si, OFFSET intro_p3_l4
    call dibujar_texto_tecleo

    add dx, INTRO_Y_ESPACIO
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov bl, INTRO_COLOR_TEXTO
    mov si, OFFSET intro_p3_l5
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov si, OFFSET intro_p3_l6
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov bl, INTRO_COLOR_TEXTO_SEC
    mov si, OFFSET intro_p3_l7
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov bl, INTRO_COLOR_TEXTO
    mov si, OFFSET intro_p3_l8
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov bl, INTRO_COLOR_ADVERTENCIA
    mov si, OFFSET intro_p3_l9
    call dibujar_texto_tecleo

    call esperar_tecla_intro
    
    call limpiar_pantalla_intro
    
    mov dx, INTRO_Y_TEXTO
    mov cx, INTRO_X
    mov bl, INTRO_COLOR_TEXTO
    mov si, OFFSET intro_p4_l1
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov si, OFFSET intro_p4_l2
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov si, OFFSET intro_p4_l3
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov si, OFFSET intro_p4_l4
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov si, OFFSET intro_p4_l5
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    add dx, INTRO_Y_ESPACIO
    mov cx, INTRO_X
    mov si, OFFSET intro_p4_l6
    call dibujar_texto_tecleo
    
    add dx, INTRO_Y_ESPACIO
    add dx, INTRO_Y_ESPACIO
    add dx, INTRO_Y_ESPACIO
    mov cx, 232
    mov bl, INTRO_COLOR_INICIO
    mov si, OFFSET intro_p4_l_final
    call dibujar_texto_tecleo
    
    ; Esperar tecla antes de iniciar el juego
    call esperar_tecla_intro

    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ejecutar_intro ENDP