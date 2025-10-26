;-------------------------------------------------------------------------------
; MENU.INC - Menú principal en modo EGA 640x350
;-------------------------------------------------------------------------------

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
    jz Menu_KeyDone

    mov ah, 0
    int 16h

    cmp ah, 48h
    je Menu_KeyUp
    cmp al, 'W'
    je Menu_KeyUp
    cmp al, 'w'
    je Menu_KeyUp

    cmp ah, 50h
    je Menu_KeyDown
    cmp al, 'S'
    je Menu_KeyDown
    cmp al, 's'
    je Menu_KeyDown

    cmp ah, 1Ch
    je Menu_KeySelect

    cmp ah, 1
    je Menu_KeyExit
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

Menu_DrawSpriteRaw PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    mov bp, cx
    mov di, dx
    mov ax, [si]
    mov [menu_tmp_width], ax
    mov ax, [si+2]
    mov [menu_tmp_height_counter], ax
    lea si, [si+4]

Menu_DrawRowLoop:
    mov ax, [menu_tmp_height_counter]
    cmp ax, 0
    je Menu_DrawDone
    dec ax
    mov [menu_tmp_height_counter], ax

    mov ax, [menu_tmp_width]
    mov [menu_tmp_width_counter], ax
    mov bx, bp

Menu_DrawColLoop:
    mov ax, [menu_tmp_width_counter]
    cmp ax, 0
    je Menu_NextRow
    dec ax
    mov [menu_tmp_width_counter], ax

    mov al, [si]
    inc si
    cmp al, 0
    je Menu_SkipPixel
    mov ah, 0Ch
    mov bh, 0
    mov cx, bx
    mov dx, di
    int 10h
Menu_SkipPixel:
    inc bx
    jmp Menu_DrawColLoop

Menu_NextRow:
    inc di
    jmp Menu_DrawRowLoop

Menu_DrawDone:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
Menu_DrawSpriteRaw ENDP

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
    call dibujar_texto_simple

    mov cx, 440
    mov dx, 60
    mov si, OFFSET menu_debug_selection
    mov al, 11
    call dibujar_texto_simple
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
    call dibujar_texto_simple
Menu_DebugSelectionDone:

    mov cx, 440
    mov dx, 80
    mov si, OFFSET menu_debug_result
    mov al, 11
    call dibujar_texto_simple
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
    call dibujar_texto_simple
Menu_DebugResultDone:

    mov cx, 440
    mov dx, 100
    mov si, OFFSET menu_debug_mouse_x
    mov al, 11
    call dibujar_texto_simple
    mov ax, [mouseX]
    mov cx, 560
    mov dx, 100
    call dibujar_numero

    mov cx, 440
    mov dx, 120
    mov si, OFFSET menu_debug_mouse_y
    mov al, 11
    call dibujar_texto_simple
    mov ax, [mouseY]
    mov cx, 560
    mov dx, 120
    call dibujar_numero

    mov cx, 440
    mov dx, 140
    mov si, OFFSET menu_debug_present
    mov al, 11
    call dibujar_texto_simple
    mov al, [mousePresent]
    mov cx, 560
    mov dx, 140
    cmp al, 0
    jne Menu_DebugMousePresentYes
    mov si, OFFSET menu_debug_no
    mov al, 10
    call dibujar_texto_simple
    jmp Menu_DebugMousePresentDone
Menu_DebugMousePresentYes:
    mov si, OFFSET menu_debug_si
    mov al, 10
    call dibujar_texto_simple
Menu_DebugMousePresentDone:

    mov cx, 440
    mov dx, 160
    mov si, OFFSET menu_debug_btn
    mov al, 11
    call dibujar_texto_simple
    mov al, [mouseBtn]
    xor ah, ah
    mov cx, 560
    mov dx, 160
    call dibujar_numero

    mov cx, 440
    mov dx, 180
    mov si, OFFSET menu_debug_lastbtn
    mov al, 11
    call dibujar_texto_simple
    mov al, [lastMouseBtn]
    xor ah, ah
    mov cx, 560
    mov dx, 180
    call dibujar_numero

    mov cx, 440
    mov dx, 200
    mov si, OFFSET menu_debug_hover
    mov al, 11
    call dibujar_texto_simple
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
    call dibujar_texto_simple
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

    call ClearScreenEGA

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
    call dibujar_texto_simple

    mov cx, 170
    mov dx, 130
    mov si, OFFSET menu_subtitle
    mov al, 11
    call dibujar_texto_simple

    mov cx, 120
    mov dx, 148
    mov si, OFFSET menu_subtitle2
    mov al, 11
    call dibujar_texto_simple

    mov cx, [btnPlayX1]
    mov dx, [btnPlayY1]
    cmp [currentSelection], 0
    jne Menu_DrawPlayNormal
    mov si, OFFSET menu_btn_jugar_s_width
    jmp Menu_DrawPlay
Menu_DrawPlayNormal:
    mov si, OFFSET menu_btn_jugar_n_width
Menu_DrawPlay:
    call Menu_DrawSpriteRaw

    mov cx, [btnOptionsX1]
    mov dx, [btnOptionsY1]
    cmp [currentSelection], 1
    jne Menu_DrawOptNormal
    mov si, OFFSET menu_btn_opciones_s_width
    jmp Menu_DrawOpt
Menu_DrawOptNormal:
    mov si, OFFSET menu_btn_opciones_n_width
Menu_DrawOpt:
    call Menu_DrawSpriteRaw

    mov cx, [btnExitX1]
    mov dx, [btnExitY1]
    cmp [currentSelection], 2
    jne Menu_DrawExitNormal
    mov si, OFFSET menu_btn_salir_s_width
    jmp Menu_DrawExit
Menu_DrawExitNormal:
    mov si, OFFSET menu_btn_salir_n_width
Menu_DrawExit:
    call Menu_DrawSpriteRaw

    call Menu_DrawDebugInfo

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
Menu_Draw ENDP

Menu_ShowOptionsScreen PROC
    push ax
    push bx
    push cx
    push dx
    push si

    call ClearScreenEGA

    mov cx, 220
    mov dx, 120
    mov si, OFFSET menu_options_title
    mov al, 14
    call dibujar_texto_simple

    mov cx, 120
    mov dx, 150
    mov si, OFFSET menu_options_line1
    mov al, 11
    call dibujar_texto_simple

    mov cx, 120
    mov dx, 170
    mov si, OFFSET menu_options_line2
    mov al, 11
    call dibujar_texto_simple

    mov cx, 120
    mov dx, 200
    mov si, OFFSET menu_options_line3
    mov al, 10
    call dibujar_texto_simple

    call Menu_GetMouseState
Menu_OptionsWait:
    call Menu_GetMouseState
    mov al, [mouseBtn]
    and al, 1
    cmp al, 1
    jne Menu_OptionsCheckKey
    mov al, [lastMouseBtn]
    and al, 1
    cmp al, 0
    je Menu_OptionsDone
Menu_OptionsCheckKey:
    mov ah, 1
    int 16h
    jz Menu_OptionsWait
    mov ah, 0
    int 16h
Menu_OptionsDone:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
Menu_ShowOptionsScreen ENDP

Menu_ResetState PROC
    mov [currentSelection], 0
    mov [menuResult], 0FFh
    mov [mouseBtn], 0
    mov [lastMouseBtn], 0
    mov [mouseOverButton], 0FFh
    mov [mouseX], 320
    mov [mouseY], 175
    ret
Menu_ResetState ENDP

mostrar_menu_principal PROC
    push bx
    push cx
    push dx
    push si

Menu_Loop_Start:
    call Menu_InitVideo
    call Menu_InitMouse
    call Menu_ResetState

Menu_MainLoop:
    call Menu_GetMouseState
    call Menu_ProcessKeyboard
    call Menu_ProcessMouse
    call Menu_Draw
    call Menu_DelayShort
    cmp [menuResult], 0FFh
    je Menu_MainLoop

    mov al, [menuResult]
    cmp al, 1
    jne Menu_SelectionMade
    call Menu_ShowOptionsScreen
    call Menu_ResetState
    jmp Menu_MainLoop

Menu_SelectionMade:
    mov bl, al
    call Menu_DeInitMouse
    call Menu_DeInitVideo
    mov al, bl

    pop si
    pop dx
    pop cx
    pop bx
    ret
mostrar_menu_principal ENDP

menu_leer_dimensiones PROC
    push ax
    push bx
    push cx
    push dx
    push si

    mov word ptr menu_loader_width, 0
    mov word ptr menu_loader_height, 0
    mov byte ptr menu_loader_stage, 0

Menu_ReadDimLoop:
    mov bx, [menu_loader_file_handle]
    mov ah, 3Fh
    mov cx, 1
    mov dx, OFFSET buffer_temp
    int 21h
    cmp ax, 0
    jne Menu_ReadDimContinue
    jmp Menu_DimEnd
Menu_ReadDimContinue:

    mov al, [buffer_temp]
    cmp al, 10
    je Menu_DimFinish
    cmp al, 13
    je Menu_ReadDimLoop
    cmp al, ' '
    je Menu_DimSpace
    cmp al, 9
    je Menu_DimSpace
    cmp al, '0'
    jb Menu_ReadDimLoop
    cmp al, '9'
    ja Menu_ReadDimLoop

    sub al, '0'
    mov ah, 0
    mov bx, ax
    cmp byte ptr menu_loader_stage, 0
    jne Menu_DimAddHeight
    mov ax, [menu_loader_width]
    mov cx, 10
    mul cx
    add ax, bx
    mov [menu_loader_width], ax
    jmp Menu_ReadDimLoop

Menu_DimAddHeight:
    mov ax, [menu_loader_height]
    mov cx, 10
    mul cx
    add ax, bx
    mov [menu_loader_height], ax
    jmp Menu_ReadDimLoop

Menu_DimSpace:
    cmp byte ptr menu_loader_stage, 0
    jne Menu_ReadDimLoop
    cmp word ptr menu_loader_width, 0
    jne Menu_DimFinishContinue
    jmp Menu_ReadDimLoop
Menu_DimFinishContinue:
    mov byte ptr menu_loader_stage, 1
    jmp Menu_ReadDimLoop

Menu_DimFinish:
    cmp byte ptr menu_loader_stage, 0
    jne Menu_DimEnd
    cmp word ptr menu_loader_width, 0
    jne Menu_DimFinishLoop
    jmp Menu_ReadDimLoop
Menu_DimFinishLoop:
    mov byte ptr menu_loader_stage, 1

Menu_DimEnd:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
menu_leer_dimensiones ENDP

cargar_sprite_menu PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov di, [menu_loader_dest]
    mov cx, [menu_loader_max_size]

    mov dx, [menu_loader_path]
    mov ax, 3D00h
    int 21h
    jnc csm_open_ok
    jmp csm_error
csm_open_ok:
    mov menu_loader_file_handle, ax

    call menu_leer_dimensiones

    mov ax, [menu_loader_width]
    mov bx, [menu_loader_height]
    mul bx
    mov menu_loader_expected, ax
    cmp dx, 0
    je csm_size_check
    jmp csm_error_close
csm_size_check:
    cmp ax, cx
    jbe csm_size_ok
    jmp csm_error_close
csm_size_ok:

    mov word ptr menu_loader_pixels_read, 0

csm_read_chunk:
    mov ax, [menu_loader_pixels_read]
    cmp ax, [menu_loader_expected]
    jae csm_done_read
    mov bx, [menu_loader_file_handle]
    mov ah, 3Fh
    mov cx, 200
    mov dx, OFFSET buffer_temp
    int 21h
    cmp ax, 0
    je csm_error_close
    mov si, 0
    mov bp, ax

csm_process:
    cmp si, bp
    jae csm_read_chunk
    mov al, [buffer_temp + si]
    inc si
    cmp al, ' '
    je csm_process
    cmp al, 13
    je csm_process
    cmp al, 10
    je csm_process
    cmp al, 9
    je csm_process
    cmp al, '0'
    jb csm_process
    cmp al, '9'
    jbe csm_store_dec
    and al, 0DFh
    cmp al, 'A'
    jb csm_process
    cmp al, 'F'
    ja csm_process
    sub al, 'A' - 10
    jmp csm_store
csm_store_dec:
    sub al, '0'
csm_store:
    mov [di], al
    inc di
    inc word ptr menu_loader_pixels_read
    mov ax, [menu_loader_pixels_read]
    cmp ax, [menu_loader_expected]
    jb csm_process
    jmp csm_done_read

csm_done_read:
    mov bx, [menu_loader_file_handle]
    mov ah, 3Eh
    int 21h
    mov menu_loader_file_handle, 0
    mov ax, [menu_loader_pixels_read]
    cmp ax, [menu_loader_expected]
    jne csm_error
    clc
    jmp csm_exit

csm_error_close:
    mov bx, [menu_loader_file_handle]
    cmp bx, 0
    je csm_error
    mov ah, 3Eh
    int 21h
    mov menu_loader_file_handle, 0

csm_error:
    stc

csm_exit:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
cargar_sprite_menu ENDP

cargar_sprites_menu PROC
    push ax
    push bx
    push cx
    push dx

    mov ax, MENU_BTN_PIXELS
    mov menu_loader_max_size, ax

    mov ax, OFFSET menu_btn_jugar_n_data
    mov menu_loader_dest, ax
    mov ax, OFFSET archivo_btn_jugar_n
    mov menu_loader_path, ax
    call cargar_sprite_menu
    jnc csm_ok_btn_jugar_n
    jmp csm_fail
  csm_ok_btn_jugar_n:
    mov ax, [menu_loader_width]
    mov menu_btn_jugar_n_width, ax
    mov ax, [menu_loader_height]
    mov menu_btn_jugar_n_height, ax
    cmp menu_btn_jugar_n_width, MENU_BTN_WIDTH
    je csm_ok_btn_jugar_n_width
    jmp csm_fail
  csm_ok_btn_jugar_n_width:
    cmp menu_btn_jugar_n_height, MENU_BTN_HEIGHT
    je csm_ok_btn_jugar_n_height
    jmp csm_fail
  csm_ok_btn_jugar_n_height:

    mov ax, OFFSET menu_btn_jugar_s_data
    mov menu_loader_dest, ax
    mov ax, OFFSET archivo_btn_jugar_s
    mov menu_loader_path, ax
    call cargar_sprite_menu
    jnc csm_ok_btn_jugar_s
    jmp csm_fail
  csm_ok_btn_jugar_s:
    mov ax, [menu_loader_width]
    mov menu_btn_jugar_s_width, ax
    mov ax, [menu_loader_height]
    mov menu_btn_jugar_s_height, ax

    mov ax, OFFSET menu_btn_opciones_n_data
    mov menu_loader_dest, ax
    mov ax, OFFSET archivo_btn_opciones_n
    mov menu_loader_path, ax
    call cargar_sprite_menu
    jnc csm_ok_btn_opciones_n
    jmp csm_fail
  csm_ok_btn_opciones_n:
    mov ax, [menu_loader_width]
    mov menu_btn_opciones_n_width, ax
    mov ax, [menu_loader_height]
    mov menu_btn_opciones_n_height, ax

    mov ax, OFFSET menu_btn_opciones_s_data
    mov menu_loader_dest, ax
    mov ax, OFFSET archivo_btn_opciones_s
    mov menu_loader_path, ax
    call cargar_sprite_menu
    jnc csm_ok_btn_opciones_s
    jmp csm_fail
  csm_ok_btn_opciones_s:
    mov ax, [menu_loader_width]
    mov menu_btn_opciones_s_width, ax
    mov ax, [menu_loader_height]
    mov menu_btn_opciones_s_height, ax

    mov ax, OFFSET menu_btn_salir_n_data
    mov menu_loader_dest, ax
    mov ax, OFFSET archivo_btn_salir_n
    mov menu_loader_path, ax
    call cargar_sprite_menu
    jnc csm_ok_btn_salir_n
    jmp csm_fail
  csm_ok_btn_salir_n:
    mov ax, [menu_loader_width]
    mov menu_btn_salir_n_width, ax
    mov ax, [menu_loader_height]
    mov menu_btn_salir_n_height, ax

    mov ax, OFFSET menu_btn_salir_s_data
    mov menu_loader_dest, ax
    mov ax, OFFSET archivo_btn_salir_s
    mov menu_loader_path, ax
    call cargar_sprite_menu
    jnc csm_ok_btn_salir_s
    jmp csm_fail
  csm_ok_btn_salir_s:
    mov ax, [menu_loader_width]
    mov menu_btn_salir_s_width, ax
    mov ax, [menu_loader_height]
    mov menu_btn_salir_s_height, ax

    clc
    jmp csm_done

csm_fail:
    stc

csm_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
cargar_sprites_menu ENDP

