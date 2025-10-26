;-------------------------------------------------------------------------------
; MENU.INC
; Lógica de menú funcional para MODO EGA 640x350 (Modo 10h)
;
; Este archivo DEBE ser incluido en tu 'proyec.asm' principal.
;
; REQUIERE que tu 'proyec.asm' defina las rutinas de dibujo de sprites
; (ej. 'DibujaTuSprite_Fondo', 'DibujaTuSprite_Jugar_Normal', etc.)
; y una rutina 'ClearScreenEGA' que sepa limpiar la pantalla del Modo 10h.
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; SECCIÓN DE DATOS DEL MENÚ
; (Debes copiar esto dentro de la sección .DATA de tu proyec.asm)
;-------------------------------------------------------------------------------
; currentSelection    DB 0    ; 0=Jugar, 1=Opciones, 2=Salir
; menuResult          DB 2    ; Resultado a devolver (2=Salir por defecto)
;
; ; --- Variables del mouse ---
; mousePresent        DB 0    ; 0=No, 1=Si
; mouseX              DW 320  ; Posición X del mouse (centro de 640)
; mouseY              DW 175  ; Posición Y del mouse (centro de 350)
; mouseBtn            DB 0    ; Estado del botón (1=presionado)
; lastMouseBtn        DB 0    ; Estado del botón en el frame anterior
; mouseOverButton     DB 0FFh ; Botón sobre el que está el mouse (0, 1, 2, o FFh=ninguno)
;
; ; --- Definiciones de Hitbox (Rectángulos) para 640x350 ---
; ; ¡AJUSTA ESTAS COORDENADAS AL TAMAÑO Y POSICIÓN DE TUS SPRITES!
; ; Botón JUGAR
; btnPlayX1         DW 260
; btnPlayY1         DW 120
; btnPlayX2         DW 380  ; Asumiendo un botón de 120px de ancho
; btnPlayY2         DW 150  ; Asumiendo un botón de 30px de alto
;
; ; Botón OPCIONES
; btnOptionsX1      DW 260
; btnOptionsY1      DW 170
; btnOptionsX2      DW 380
; btnOptionsY2      DW 200
;
; ; Botón SALIR
; btnExitX1         DW 260
; btnExitY1         DW 220
; btnExitX2         DW 380
; btnExitY2         DW 250
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; SECCIÓN DE CÓDIGO DEL MENÚ
; (Debes poner 'INCLUDE menu.inc' al final de tu sección .CODE)
;-------------------------------------------------------------------------------

; --- Rutinas de Video (para Modo 10h) ---

Menu_InitVideo PROC
    ; Poner Modo 10h (640x350, 16 colores, EGA/VGA)
    MOV AX, 0010h
    INT 10h
    
    MOV [menuResult], 0FFh ; Marcar que aún no hay selección
    RET
Menu_InitVideo ENDP

Menu_DeInitVideo PROC
    ; Volver a Modo Texto (80x25)
    MOV AX, 0003h
    INT 10h
    RET
Menu_DeInitVideo ENDP

; --- Rutinas de Mouse (INT 33h funciona igual) ---

Menu_InitMouse PROC
    MOV AX, 0       ; Resetear mouse
    INT 33h
    CMP AX, 0       ; AX=0 si no hay mouse
    JE Menu_NoMouse
    
    MOV [mousePresent], 1
    
    ; Configurar límites horizontales del mouse para 640
    MOV AX, 7
    MOV CX, 0       ; Mínimo X = 0
    MOV DX, 639     ; Máximo X = 639
    INT 33h
    
    ; Configurar límites verticales del mouse para 350
    MOV AX, 8
    MOV CX, 0       ; Mínimo Y = 0
    MOV DX, 349     ; Máximo Y = 349
    INT 33h
    
    MOV AX, 1       ; Mostrar cursor del mouse
    INT 33h
Menu_NoMouse:
    RET
Menu_InitMouse ENDP

Menu_DeInitMouse PROC
    CMP [mousePresent], 0
    JE Menu_NoMouse2
    MOV AX, 2       ; Ocultar cursor del mouse
    INT 33h
Menu_NoMouse2:
    RET
Menu_DeInitMouse ENDP

Menu_GetMouseState PROC
    CMP [mousePresent], 0
    JE Menu_NoMouse3
    MOV AX, 3       ; Obtener estado del mouse
    INT 33h
    MOV [mouseX], CX
    MOV [mouseY], DX
    MOV [lastMouseBtn], BL  ; Guardar estado del botón
    MOV [mouseBtn], BL
Menu_NoMouse3:
    RET
Menu_GetMouseState ENDP

; --- Rutinas de Teclado (sin cambios) ---

Menu_ProcessKeyboard PROC
    MOV AH, 1       ; Comprobar si hay tecla
    INT 16h
    JZ Menu_NoKey   ; Si no hay tecla, salir
    
    MOV AH, 0       ; Leer tecla
    INT 16h
    
    CMP AH, 48h     ; Flecha Arriba
    JE Menu_KeyUp
    CMP AL, 'w'
    JE Menu_KeyUp
    CMP AL, 'W'
    JE Menu_KeyUp
    
    CMP AH, 50h     ; Flecha Abajo
    JE Menu_KeyDown
    CMP AL, 's'
    JE Menu_KeyDown
    CMP AL, 'S'
    JE Menu_KeyDown

    CMP AH, 1Ch     ; Enter
    JE Menu_KeySelect
    
    CMP AH, 1       ; ESC
    JE Menu_KeyExit
    
    JMP Menu_NoKey

Menu_KeyUp:
    CALL Menu_PlayNavSound
    DEC [currentSelection]
    CMP [currentSelection], 0FFh ; ¿Underflow?
    JNE Menu_NoKey
    MOV [currentSelection], 2    ; Wrap a Salir
    JMP Menu_NoKey

Menu_KeyDown:
    CALL Menu_PlayNavSound
    INC [currentSelection]
    CMP [currentSelection], 3    ; ¿Overflow?
    JNE Menu_NoKey
    MOV [currentSelection], 0    ; Wrap a Jugar
    JMP Menu_NoKey

Menu_KeySelect:
    CALL Menu_PlaySelectSound
    MOV AL, [currentSelection]
    MOV [menuResult], AL         ; Guardar la selección
    JMP Menu_NoKey

Menu_KeyExit:
    MOV [menuResult], 2          ; Seleccionar "Salir"
    JMP Menu_NoKey

Menu_NoKey:
    RET
Menu_ProcessKeyboard ENDP

; --- Rutina de Lógica del Mouse (con coords 640x350) ---

Menu_ProcessMouse PROC
    CMP [mousePresent], 0
    JE Menu_NoMouse4

    MOV [mouseOverButton], 0FFh ; Asumir que no está sobre ninguno
    
    MOV AX, [mouseX]
    MOV BX, [mouseY]
    
    ; Comprobar Botón 0 (Jugar)
    CMP AX, [btnPlayX1]
    JL Menu_CheckBtn1
    CMP AX, [btnPlayX2]
    JG Menu_CheckBtn1
    CMP BX, [btnPlayY1]
    JL Menu_CheckBtn1
    CMP BX, [btnPlayY2]
    JG Menu_CheckBtn1
    MOV [mouseOverButton], 0
    JMP Menu_MouseOverDone

Menu_CheckBtn1:
    ; Comprobar Botón 1 (Opciones)
    CMP AX, [btnOptionsX1]
    JL Menu_CheckBtn2
    CMP AX, [btnOptionsX2]
    JG Menu_CheckBtn2
    CMP BX, [btnOptionsY1]
    JL Menu_CheckBtn2
    CMP BX, [btnOptionsY2]
    JG Menu_CheckBtn2
    MOV [mouseOverButton], 1
    JMP Menu_MouseOverDone
    
Menu_CheckBtn2:
    ; Comprobar Botón 2 (Salir)
    CMP AX, [btnExitX1]
    JL Menu_MouseOverDone
    CMP AX, [btnExitX2]
    JG Menu_MouseOverDone
    CMP BX, [btnExitY1]
    JL Menu_MouseOverDone
    CMP BX, [btnExitY2]
    JG Menu_MouseOverDone
    MOV [mouseOverButton], 2
    
Menu_MouseOverDone:
    MOV AL, [mouseOverButton]
    CMP AL, 0FFh
    JE Menu_CheckClick

    CMP AL, [currentSelection]
    JE Menu_CheckClick

    MOV [currentSelection], AL
    CALL Menu_PlayNavSound
    
Menu_CheckClick:
    MOV AL, [mouseBtn]
    AND AL, 1
    CMP AL, 1
    JNE Menu_NoClick
    
    MOV AL, [lastMouseBtn]
    AND AL, 1
    CMP AL, 0
    JNE Menu_NoClick
    
    CMP [mouseOverButton], 0FFh
    JE Menu_NoClick
    
    CALL Menu_PlaySelectSound
    MOV AL, [currentSelection]
    MOV [menuResult], AL

Menu_NoClick:
Menu_NoMouse4:
    RET
Menu_ProcessMouse ENDP


; --- Rutinas de Sonido (PC Speaker, sin cambios) ---

Menu_PlayNavSound PROC
    CALL Menu_Beep(2000, 50)
    RET
Menu_PlayNavSound ENDP

Menu_PlaySelectSound PROC
    CALL Menu_Beep(1000, 100)
    RET
Menu_PlaySelectSound ENDP

Menu_Beep PROC
    PUSH BP
    MOV BP, SP
    ; BP+4 = frecuencia
    ; BP+6 = duracion_ms
    
    MOV DX, 18
    MOV AX, 4F38h
    DIV WORD PTR [BP+4]
    
    MOV AL, 0B6h
    OUT 43h, AL
    OUT 42h, AL
    MOV AL, AH
    OUT 42h, AL
    
    IN AL, 61h
    OR AL, 3
    OUT 61h, AL
    
    MOV CX, [BP+6]
    CALL Menu_DelayMilliseconds
    
    IN AL, 61h
    AND AL, 0FCh
    OUT 61h, AL
    
    POP BP
    RET
Menu_Beep ENDP

Menu_DelayMilliseconds PROC
    ; Rutina de delay simple
    ; CX = milisegundos
Menu_DelayMsLoop:
    MOV DX, 11000   ; Ajustar este valor para tu CPU/emulador
Menu_DelayInner:
    DEC DX
    JNZ Menu_DelayInner
    LOOP Menu_DelayMsLoop
    RET
Menu_DelayMilliseconds ENDP

Menu_DelayShort PROC
    PUSH CX
    MOV CX, 10
    CALL Menu_DelayMilliseconds
    POP CX
    RET
Menu_DelayShort ENDP

;-------------------------------------------------------------------------------
; RUTINA DE DIBUJADO PRINCIPAL - ¡AQUÍ ES DONDE PONES TU CÓDIGO!
;-------------------------------------------------------------------------------
Menu_Draw PROC
    ; 1. Limpiar la pantalla o dibujar tu fondo
    ; ¡DEBES CREAR ESTA RUTINA!
    ; CALL ClearScreenEGA
    
    ; O dibuja tu fondo
    ; ¡DEBES TENER ESTA RUTINA ADAPTADA A MODO 10h!
    ; CALL DibujaTuSprite_Fondo(0, 0)
    
    ; 2. Dibujar los botones según la selección
    CMP [currentSelection], 0
    JE Menu_DrawPlaySel
    CMP [currentSelection], 1
    JE Menu_DrawOptionsSel
    CMP [currentSelection], 2
    JE Menu_DrawExitSel
    JMP Menu_DrawDone

Menu_DrawPlaySel:
    ; --- ¡REEMPLAZA ESTO CON TUS RUTINAS ADAPTADAS A MODO 10h! ---
    ; CALL DibujaTuSprite_Jugar_Seleccionado(btnPlayX1, btnPlayY1)
    ; CALL DibujaTuSprite_Opciones_Normal(btnOptionsX1, btnOptionsY1)
    ; CALL DibujaTuSprite_Salir_Normal(btnExitX1, btnExitY1)
    JMP Menu_DrawDone
    
Menu_DrawOptionsSel:
    ; --- ¡REEMPLAZA ESTO CON TUS RUTINAS ADAPTADAS A MODO 10h! ---
    ; CALL DibujaTuSprite_Jugar_Normal(btnPlayX1, btnPlayY1)
    ; CALL DibujaTuSprite_Opciones_Seleccionado(btnOptionsX1, btnOptionsY1)
    ; CALL DibujaTuSprite_Salir_Normal(btnExitX1, btnExitY1)
    JMP Menu_DrawDone
    
Menu_DrawExitSel:
    ; --- ¡REEMPLAZA ESTO CON TUS RUTINAS ADAPTADAS A MODO 10h! ---
    ; CALL DibujaTuSprite_Jugar_Normal(btnPlayX1, btnPlayY1)
    ; CALL DibujaTuSprite_Opciones_Normal(btnOptionsX1, btnOptionsY1)
    ; CALL DibujaTuSprite_Salir_Seleccionado(btnExitX1, btnExitY1)
    JMP Menu_DrawDone
    
Menu_DrawDone:
    ; El cursor de hardware del mouse se dibuja solo.
    RET
Menu_Draw ENDP