Menu_InitVideo PROC
    mov ax, 0010h
    int 10h
    mov [menuResult], 0FFh
    ret
Menu_InitVideo ENDP

Menu_DeInitVideo PROC
    mov ax, 0003h
    int 10h
    ret
Menu_DeInitVideo ENDP

Menu_InitMouse PROC
    mov ax, 0
    int 33h
    cmp ax, 0
    je Menu_NoMouseInit

    mov [mousePresent], 1

    mov ax, 7
    mov cx, 0
    mov dx, 639
    int 33h

    mov ax, 8
    mov cx, 0
    mov dx, 349
    int 33h

    mov ax, 4
    mov cx, 320
    mov dx, 175
    int 33h

    mov ax, 1
    int 33h
Menu_NoMouseInit:
    ret
Menu_InitMouse ENDP

Menu_DeInitMouse PROC
    cmp [mousePresent], 0
    je Menu_NoMouseHide
    mov ax, 2
    int 33h
Menu_NoMouseHide:
    ret
Menu_DeInitMouse ENDP

Menu_GetMouseState PROC
    cmp [mousePresent], 0
    je Menu_NoMouseState
    mov al, [mouseBtn]
    mov [lastMouseBtn], al
    mov ax, 3
    int 33h
    mov [mouseX], cx
    mov [mouseY], dx
    mov [mouseBtn], bl
Menu_NoMouseState:
    ret
Menu_GetMouseState ENDP

Menu_ProcessKeyboard PROC
    push ax
    push bx
    push cx
    push dx

        mov ah, 1
        int 16h
        jnz Menu_KeyContinue
        jmp Menu_KeyDone

    Menu_KeyContinue:
        mov ah, 0
        int 16h



        mov bl, al
        cmp bl, 0
        je  Menu_KeyNormalized
        cmp bl, 'a'
        jb  Menu_KeyNormalized
        cmp bl, 'z'
        ja  Menu_KeyNormalized
        and bl, 5Fh
    Menu_KeyNormalized:
        mov al, bl

    cmp [menuState], 1
    jne .CheckMain_Kbd


    cmp ah, 1
    jne .Not_Exit_Kbd
    jmp Menu_KeyExit
.Not_Exit_Kbd:


    mov [menuState], 0
    mov [lastSelection], 0FFh
    call Menu_PlaySelectSound
    jmp Menu_KeyDone

.CheckMain_Kbd:

    cmp ah, 48h
    je Menu_KeyUp
    cmp al, 'W'
    je Menu_KeyUp

    cmp ah, 50h
    je Menu_KeyDown
    cmp al, 'S'
    je Menu_KeyDown

    cmp ah, 1Ch
    je Menu_KeySelect

    cmp ah, 1
    jne .Not_Exit_Main_Kbd
    jmp Menu_KeyExit
.Not_Exit_Main_Kbd:
    jmp Menu_KeyDone

Menu_KeyUp:
    call Menu_PlayNavSound
    dec [currentSelection]
    cmp [currentSelection], 0FFh
    jne Menu_KeyDone
    mov [currentSelection], 2
    jmp Menu_KeyDone

Menu_KeyDown:
    call Menu_PlayNavSound
    inc [currentSelection]
    cmp [currentSelection], 3
    jne Menu_KeyDone
    mov [currentSelection], 0
    jmp Menu_KeyDone

Menu_KeySelect:
    call Menu_PlaySelectSound
    mov al, [currentSelection]

    cmp al, 1
    jne Menu_SetResult_Kbd


    mov [menuState], 1
    mov [lastSelection], 0FFh
    jmp Menu_KeyDone
Menu_SetResult_Kbd:
    mov [menuResult], al
    jmp Menu_KeyDone

Menu_KeyExit:
    mov [menuResult], 2

Menu_KeyDone:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
Menu_ProcessKeyboard ENDP

Menu_ProcessMouse PROC
    push ax
    push bx

    cmp [mousePresent], 0
    jne Menu_MouseContinue
    jmp Menu_MouseEnd
Menu_MouseContinue:

    cmp [menuState], 1
    jne .CheckMain_Mouse


    mov al, [mouseBtn]
    and al, 1
    cmp al, 1
    je  .MenuMouse_CheckLast
    jmp Menu_MouseEnd

.MenuMouse_CheckLast:
    mov al, [lastMouseBtn]
    and al, 1
    cmp al, 0
    je  .MenuMouse_HandleClick
    jmp Menu_MouseEnd

.MenuMouse_HandleClick:

    mov [menuState], 0
    mov [lastSelection], 0FFh
    call Menu_PlaySelectSound
    jmp Menu_MouseEnd

.CheckMain_Mouse:


    mov [mouseOverButton], 0FFh

    mov ax, [mouseX]
    mov bx, [mouseY]

    cmp ax, [btnPlayX1]
    jl Menu_CheckOptions
    cmp ax, [btnPlayX2]
    jg Menu_CheckOptions
    cmp bx, [btnPlayY1]
    jl Menu_CheckOptions
    cmp bx, [btnPlayY2]
    jg Menu_CheckOptions
    mov [mouseOverButton], 0
    jmp Menu_MouseHoverDone

Menu_CheckOptions:
    cmp ax, [btnOptionsX1]
    jl Menu_CheckExit
    cmp ax, [btnOptionsX2]
    jg Menu_CheckExit
    cmp bx, [btnOptionsY1]
    jl Menu_CheckExit
    cmp bx, [btnOptionsY2]
    jg Menu_CheckExit
    mov [mouseOverButton], 1
    jmp Menu_MouseHoverDone

Menu_CheckExit:
    cmp ax, [btnExitX1]
    jl Menu_MouseHoverDone
    cmp ax, [btnExitX2]
    jg Menu_MouseHoverDone
    cmp bx, [btnExitY1]
    jl Menu_MouseHoverDone
    cmp bx, [btnExitY2]
    jg Menu_MouseHoverDone
    mov [mouseOverButton], 2

Menu_MouseHoverDone:
    mov al, [mouseOverButton]
    cmp al, 0FFh
    je Menu_CheckMouseClick
    cmp al, [currentSelection]
    je Menu_CheckMouseClick
    mov [currentSelection], al
    call Menu_PlayNavSound

Menu_CheckMouseClick:
    mov al, [mouseBtn]
    and al, 1
    cmp al, 1
    jne Menu_MouseEnd
    mov al, [lastMouseBtn]
    and al, 1
    cmp al, 0
    jne Menu_MouseEnd
    cmp [mouseOverButton], 0FFh
    je Menu_MouseEnd
    call Menu_PlaySelectSound
    mov al, [currentSelection]

    cmp al, 1
    jne Menu_SetResult


    mov [menuState], 1
    mov [lastSelection], 0FFh
    jmp Menu_MouseEnd
Menu_SetResult:

    mov [menuResult], al

Menu_MouseEnd:
    pop bx
    pop ax
    ret
Menu_ProcessMouse ENDP

Menu_PlayNavSound PROC
    push ax
    push cx

    mov ax, 40
    push ax
    mov ax, 1700
    push ax
    call Menu_Beep
    add sp, 4

    mov ax, 30
    push ax
    mov ax, 2100
    push ax
    call Menu_Beep
    add sp, 4

    pop cx
    pop ax
    ret
Menu_PlayNavSound ENDP

Menu_PlaySelectSound PROC
    push ax
    push cx

    mov ax, 70
    push ax
    mov ax, 700
    push ax
    call Menu_Beep
    add sp, 4

    mov ax, 90
    push ax
    mov ax, 1100
    push ax
    call Menu_Beep
    add sp, 4

    mov ax, 120
    push ax
    mov ax, 1500
    push ax
    call Menu_Beep
    add sp, 4

    pop cx
    pop ax
    ret
Menu_PlaySelectSound ENDP

Menu_Beep PROC
    push bp
    mov bp, sp

    mov dx, 18
    mov ax, 4F38h
    div word ptr [bp+4]

    mov al, 0B6h
    out 43h, al
    out 42h, al
    mov al, ah
    out 42h, al

    in al, 61h
    or al, 3
    out 61h, al

    mov cx, [bp+6]
    call Menu_DelayMilliseconds

    in al, 61h
    and al, 0FCh
    out 61h, al

    pop bp
    ret 4
Menu_Beep ENDP

Menu_DelayMilliseconds PROC
    cmp cx, 0
    je Menu_DelayEnd
Menu_DelayOuter:
    mov dx, 11000
Menu_DelayInner:
    dec dx
    jnz Menu_DelayInner
    loop Menu_DelayOuter
Menu_DelayEnd:
    ret
Menu_DelayMilliseconds ENDP

Menu_DelayShort PROC
    push cx
    mov cx, 6
    call Menu_DelayMilliseconds
    pop cx
    ret
Menu_DelayShort ENDP

ClearScreenEGA PROC
    push ax
    push cx
    push dx
    push di
    push es

    mov dx, 3C4h
    mov al, 2
    out dx, al
    inc dx
    mov al, 0Fh
    out dx, al

    mov ax, 0A000h
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
ClearScreenEGA ENDP

Menu_DrawDebugInfo PROC
    push ax
    push bx
    push cx
    push dx
    push si

    mov cx, 440
    mov dx, 40
    mov si, OFFSET menu_debug_title
    mov al, 12
    call dibujar_texto_buffer

    mov cx, 440
    mov dx, 60
    mov si, OFFSET menu_debug_selection
    mov al, 11
    call dibujar_texto_buffer
    mov al, [currentSelection]
    cmp al, 0FFh
    je Menu_DebugSelectionNone
    xor ah, ah
    mov cx, 560
    mov dx, 60
    call dibujar_numero
    jmp Menu_DebugSelectionDone
Menu_DebugSelectionNone:
    mov cx, 560
    mov dx, 60
    mov si, OFFSET menu_debug_none
    mov al, 10
    call dibujar_texto_buffer
Menu_DebugSelectionDone:

    mov cx, 440
    mov dx, 80
    mov si, OFFSET menu_debug_result
    mov al, 11
    call dibujar_texto_buffer
    mov al, [menuResult]
    cmp al, 0FFh
    je Menu_DebugResultPending
    xor ah, ah
    mov cx, 560
    mov dx, 80
    call dibujar_numero
    jmp Menu_DebugResultDone
Menu_DebugResultPending:
    mov cx, 560
    mov dx, 80
    mov si, OFFSET menu_debug_pending
    mov al, 10
    call dibujar_texto_buffer
Menu_DebugResultDone:

    mov cx, 440
    mov dx, 100
    mov si, OFFSET menu_debug_mouse_x
    mov al, 11
    call dibujar_texto_buffer
    mov ax, [mouseX]
    mov cx, 560
    mov dx, 100
    call dibujar_numero

    mov cx, 440
    mov dx, 120
    mov si, OFFSET menu_debug_mouse_y
    mov al, 11
    call dibujar_texto_buffer
    mov ax, [mouseY]
    mov cx, 560
    mov dx, 120
    call dibujar_numero

    mov cx, 440
    mov dx, 140
    mov si, OFFSET menu_debug_present
    mov al, 11
    call dibujar_texto_buffer
    mov al, [mousePresent]
    mov cx, 560
    mov dx, 140
    cmp al, 0
    jne Menu_DebugMousePresentYes
    mov si, OFFSET menu_debug_no
    mov al, 10
    call dibujar_texto_buffer
    jmp Menu_DebugMousePresentDone
Menu_DebugMousePresentYes:
    mov si, OFFSET menu_debug_si
    mov al, 10
    call dibujar_texto_buffer
Menu_DebugMousePresentDone:

    mov cx, 440
    mov dx, 160
    mov si, OFFSET menu_debug_btn
    mov al, 11
    call dibujar_texto_buffer
    mov al, [mouseBtn]
    xor ah, ah
    mov cx, 560
    mov dx, 160
    call dibujar_numero

    mov cx, 440
    mov dx, 180
    mov si, OFFSET menu_debug_lastbtn
    mov al, 11
    call dibujar_texto_buffer
    mov al, [lastMouseBtn]
    xor ah, ah
    mov cx, 560
    mov dx, 180
    call dibujar_numero

    mov cx, 440
    mov dx, 200
    mov si, OFFSET menu_debug_hover
    mov al, 11
    call dibujar_texto_buffer
    mov al, [mouseOverButton]
    cmp al, 0FFh
    je Menu_DebugHoverNone
    xor ah, ah
    mov cx, 560
    mov dx, 200
    call dibujar_numero
    jmp Menu_DebugHoverDone
Menu_DebugHoverNone:
    mov cx, 560
    mov dx, 200
    mov si, OFFSET menu_debug_none
    mov al, 10
    call dibujar_texto_buffer
Menu_DebugHoverDone:

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
Menu_DrawDebugInfo ENDP

Menu_Draw PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di




    mov cx, 96
    mov dx, 96
    mov ax, 448
    mov bx, 200
    mov si, 3
    call dibujar_rectangulo_lleno

    mov cx, 96
    mov dx, 96
    mov ax, 448
    mov bx, 200
    mov si, 15
    call dibujar_rectangulo_vacio

    mov cx, 160
    mov dx, 110
    mov si, OFFSET menu_title
    mov al, 14
    call dibujar_texto_buffer

    mov cx, 170
    mov dx, 130
    mov si, OFFSET menu_subtitle
    mov al, 11
    call dibujar_texto_buffer

    mov cx, 120
    mov dx, 148
    mov si, OFFSET menu_subtitle2
    mov al, 11
    call dibujar_texto_buffer

    mov cx, [btnPlayX1]
    mov dx, [btnPlayY1]
    cmp [currentSelection], 0
    jne Menu_DrawPlayNormal

    mov di, OFFSET menu_btn_jugar_s_planar
    mov si, OFFSET menu_btn_jugar_s_mask
    call dibujar_sprite_planar_32x32_opt
    jmp Menu_DrawPlayDone

Menu_DrawPlayNormal:
    mov di, OFFSET menu_btn_jugar_n_planar
    mov si, OFFSET menu_btn_jugar_n_mask
    call dibujar_sprite_planar_32x32_opt

Menu_DrawPlayDone:

    mov cx, [btnOptionsX1]
    mov dx, [btnOptionsY1]
    cmp [currentSelection], 1
    jne Menu_DrawOptNormal

    mov di, OFFSET menu_btn_opciones_s_planar
    mov si, OFFSET menu_btn_opciones_s_mask
    call dibujar_sprite_planar_32x32_opt
    jmp Menu_DrawOptDone

Menu_DrawOptNormal:
    mov di, OFFSET menu_btn_opciones_n_planar
    mov si, OFFSET menu_btn_opciones_n_mask
    call dibujar_sprite_planar_32x32_opt

Menu_DrawOptDone:

    mov cx, [btnExitX1]
    mov dx, [btnExitY1]
    cmp [currentSelection], 2
    jne Menu_DrawExitNormal

    mov di, OFFSET menu_btn_salir_s_planar
    mov si, OFFSET menu_btn_salir_s_mask
    call dibujar_sprite_planar_32x32_opt
    jmp Menu_DrawExitDone

Menu_DrawExitNormal:
    mov di, OFFSET menu_btn_salir_n_planar
    mov si, OFFSET menu_btn_salir_n_mask
    call dibujar_sprite_planar_32x32_opt

Menu_DrawExitDone:

    call Menu_DrawDebugInfo

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
Menu_Draw ENDP

Menu_DrawOptionsScreen PROC
    push ax
    push bx
    push cx
    push dx
    push si
    mov cx, 220
    mov dx, 120
    mov si, OFFSET menu_options_title
    mov al, 14
    call dibujar_texto_buffer

    mov cx, 120
    mov dx, 150
    mov si, OFFSET menu_options_line1
    mov al, 11
    call dibujar_texto_buffer

    mov cx, 120
    mov dx, 170
    mov si, OFFSET menu_options_line2
    mov al, 11
    call dibujar_texto_buffer

    mov cx, 120
    mov dx, 200
    mov si, OFFSET menu_options_line3
    mov al, 10
    call dibujar_texto_buffer

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
Menu_DrawOptionsScreen ENDP

Menu_ResetState PROC
    mov [currentSelection], 0
    mov [lastSelection], 0FFh
    mov [menuResult], 0FFh
    mov [menuState], 0
    mov [mouseBtn], 0
    mov [lastMouseBtn], 0
    mov [mouseOverButton], 0FFh
    mov [mouseX], 320
    mov [mouseY], 175
    ret
Menu_ResetState ENDP

Menu_SetPage0 PROC
    push ax
    mov ah, 5
    mov al, 0
    int 10h
    pop ax
    ret
Menu_SetPage0 ENDP

Menu_SwapPages PROC
    push ax
    mov ah, 5
    mov al, [pagina_dibujo]
    int 10h
    xor [pagina_dibujo], 1
    xor [pagina_visible], 1
    pop ax
    ret
Menu_SwapPages ENDP

mostrar_menu_principal PROC
    push bx
    push cx
    push dx
    push si

    call Menu_InitVideo
    call Menu_InitMouse
    call Menu_ResetState

    mov pagina_visible, 0
    mov pagina_dibujo, 1

    mov al, [currentSelection]
    mov [lastSelection], al
    mov al, [menuState]
    mov [lastMenuState], al
    mov temp_offset, 0
    call limpiar_pagina_actual
    cmp [menuState], 1
    jne mmp_draw_main_p0
    call Menu_DrawOptionsScreen
    jmp mmp_draw_done_p0
mmp_draw_main_p0:
    call Menu_Draw
mmp_draw_done_p0:
    call Menu_SetPage0
    mov temp_offset, 8000h
    call limpiar_pagina_actual
    cmp [menuState], 1
    jne mmp_draw_main_p1
    call Menu_DrawOptionsScreen
    jmp mmp_draw_done_p1
mmp_draw_main_p1:
    call Menu_Draw
mmp_draw_done_p1:
mmp_loop:
    call Menu_DelayShort
    call Menu_GetMouseState
    call Menu_ProcessKeyboard
    call Menu_ProcessMouse
    cmp [menuResult], 0FFh
    je      mmp_check_redraw
    jmp     mmp_exit

mmp_check_redraw:

    mov     al, [currentSelection]
    cmp     al, [lastSelection]
    jne     mmp_state_changed
    mov     al, [menuState]
    cmp     al, [lastMenuState]
    je      mmp_loop

mmp_state_changed:

    mov al, [currentSelection]
    mov [lastSelection], al
    mov al, [menuState]
    mov [lastMenuState], al

mmp_redraw:
    mov al, [pagina_dibujo]
    test al, 1
    jz mmp_set_offset_0
    mov temp_offset, 8000h
    jmp mmp_draw_content
mmp_set_offset_0:
    mov temp_offset, 0

mmp_draw_content:
    call    limpiar_pagina_actual

    cmp [menuState], 1
    jne mmp_draw_main
    call Menu_DrawOptionsScreen
    jmp mmp_swap_pages
mmp_draw_main:
    call Menu_Draw

mmp_swap_pages:
    call Menu_SwapPages
    jmp mmp_loop

mmp_exit:
    mov al, [menuResult]
    call Menu_DeInitMouse

    pop si
    pop dx
    pop cx
    pop bx
    ret
mostrar_menu_principal ENDP
