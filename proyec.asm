; Proyecto de Exploración - FUNCIONAL Y SIMPLE
; 8086/8088 TASM - Modo EGA 640x350 16 colores
; Carga sprites y renderiza correctamente

.MODEL SMALL
.STACK 512

; === CONSTANTES ===
TILE_SIZE       EQU 16
VIEWPORT_W      EQU 10
VIEWPORT_H      EQU 6

; Tipos de tiles
TILE_GRASS      EQU 0
TILE_WALL       EQU 1  
TILE_PATH       EQU 2
TILE_WATER      EQU 3
TILE_TREE       EQU 4
TILE_ROCK       EQU 5

.DATA
; === MAPA ===
map_width       dw 20
map_height      dw 15
map_data        db 300 dup(0)

; === JUGADOR ===
player_x        dw 5
player_y        dw 5
camera_x        dw 0
camera_y        dw 0

; === SPRITES (ancho, alto, datos) ===
sprite_grass    dw 16, 16
                db 256 dup(2)
sprite_wall     dw 16, 16
                db 256 dup(8)
sprite_path     dw 16, 16
                db 256 dup(6)
sprite_water    dw 16, 16
                db 256 dup(9)
sprite_tree     dw 16, 16
                db 256 dup(10)
sprite_rock     dw 16, 16
                db 256 dup(7)
sprite_player   dw 8, 8
                db 64 dup(14)

; === ARCHIVOS ===
file_handle     dw 0
spr_grass_f     db 'grass.spr',0
spr_wall_f      db 'wall.spr',0
spr_path_f      db 'path.spr',0
spr_water_f     db 'water.spr',0
spr_tree_f      db 'tree.spr',0
spr_rock_f      db 'rock.spr',0
spr_player_f    db 'player.spr',0

; === BUFFERS ===
line_buffer     db 256 dup(0)

; === MENSAJES ===
msg_loading     db 'Cargando sprites...$'
msg_ready       db 13,10,'Listo! [ESC]=Salir [WASD]=Mover',13,10,'$'

.CODE
main PROC
    mov ax, @data
    mov ds, ax
    
    ; Cargar sprites
    mov dx, OFFSET msg_loading
    mov ah, 09h
    int 21h
    
    call LoadAllSprites
    call CreateDefaultMap
    
    mov dx, OFFSET msg_ready
    mov ah, 09h
    int 21h
    
    ; Esperar tecla
    mov ah, 00h
    int 16h
    
    ; Modo EGA
    mov ax, 0010h
    int 10h
    
    ; Render inicial
    call UpdateCamera
    call RenderWorld
    call RenderPlayer
    
game_loop:
    ; Esperar tecla
    mov ah, 00h
    int 16h
    
    ; ESC = salir
    cmp al, 27
    je exit_game
    
    ; Guardar posición
    push player_x
    push player_y
    
    ; Procesar input
    call ProcessInput
    jnc check_collision
    
    ; No hubo movimiento
    pop ax
    pop ax
    jmp game_loop

check_collision:
    call CheckCollision
    jnc redraw
    
    ; Colisión - restaurar
    pop player_y
    pop player_x
    jmp game_loop

redraw:
    pop ax
    pop ax
    
    ; Redibujar
    call UpdateCamera
    call RenderWorld
    call RenderPlayer
    jmp game_loop

exit_game:
    mov ax, 0003h
    int 10h
    mov ax, 4C00h
    int 21h
main ENDP

; === CARGAR TODOS LOS SPRITES ===
LoadAllSprites PROC
    push dx
    push di
    
    ; Primero inicializar sprites por defecto
    call InitDefaultSprites
    
    ; Intentar cargar desde archivos (ignorar errores)
    mov dx, OFFSET spr_grass_f
    mov di, OFFSET sprite_grass
    call LoadSprite
    
    mov dx, OFFSET spr_wall_f
    mov di, OFFSET sprite_wall
    call LoadSprite
    
    mov dx, OFFSET spr_path_f
    mov di, OFFSET sprite_path
    call LoadSprite
    
    mov dx, OFFSET spr_water_f
    mov di, OFFSET sprite_water
    call LoadSprite
    
    mov dx, OFFSET spr_tree_f
    mov di, OFFSET sprite_tree
    call LoadSprite
    
    mov dx, OFFSET spr_rock_f
    mov di, OFFSET sprite_rock
    call LoadSprite
    
    mov dx, OFFSET spr_player_f
    mov di, OFFSET sprite_player
    call LoadSprite
    
    pop di
    pop dx
    ret
LoadAllSprites ENDP

; === INICIALIZAR SPRITES POR DEFECTO ===
InitDefaultSprites PROC
    push ax
    push cx
    push di
    
    ; Grass (verde oscuro con puntos claros)
    mov di, OFFSET sprite_grass + 4
    mov cx, 256
    mov al, 2
ids_grass:
    mov [di], al
    inc di
    loop ids_grass
    
    ; Wall (gris)
    mov di, OFFSET sprite_wall + 4
    mov cx, 256
    mov al, 8
ids_wall:
    mov [di], al
    inc di
    loop ids_wall
    
    ; Path (marrón)
    mov di, OFFSET sprite_path + 4
    mov cx, 256
    mov al, 6
ids_path:
    mov [di], al
    inc di
    loop ids_path
    
    ; Water (azul claro)
    mov di, OFFSET sprite_water + 4
    mov cx, 256
    mov al, 9
ids_water:
    mov [di], al
    inc di
    loop ids_water
    
    ; Tree (verde claro)
    mov di, OFFSET sprite_tree + 4
    mov cx, 256
    mov al, 10
ids_tree:
    mov [di], al
    inc di
    loop ids_tree
    
    ; Rock (gris claro)
    mov di, OFFSET sprite_rock + 4
    mov cx, 256
    mov al, 7
ids_rock:
    mov [di], al
    inc di
    loop ids_rock
    
    ; Player (amarillo)
    mov di, OFFSET sprite_player + 4
    mov cx, 64
    mov al, 14
ids_player:
    mov [di], al
    inc di
    loop ids_player
    
    pop di
    pop cx
    pop ax
    ret
InitDefaultSprites ENDP

; === CARGAR UN SPRITE ===
; DX = nombre archivo, DI = destino
LoadSprite PROC
    push ax
    push bx
    push cx
    push si
    push di
    
    ; Intentar abrir archivo
    mov al, 0
    mov ah, 3Dh
    int 21h
    jc ls_exit          ; Si falla, usar sprite por defecto
    
    mov bx, ax          ; Guardar handle
    mov file_handle, bx
    
    ; Leer primera línea (dimensiones)
    call ReadLine
    jc ls_close         ; Si falla leer, cerrar y salir
    
    ; Parsear ancho
    mov si, OFFSET line_buffer
    call SkipSpaces
    call ParseNumber
    cmp ax, 0
    je ls_close
    cmp ax, 32
    ja ls_close
    mov [di], ax
    
    ; Parsear alto
    call SkipSpaces
    call ParseNumber
    cmp ax, 0
    je ls_close
    cmp ax, 32
    ja ls_close
    mov [di+2], ax
    
    ; Apuntar a datos
    add di, 4
    mov cx, [di-2]      ; Alto (número de filas)
    
ls_row:
    push cx
    
    call ReadLine
    jc ls_row_done
    
    mov si, OFFSET line_buffer
    call SkipSpaces
    
    ; Leer pixels de la fila
    push di
    mov cx, [di-4]      ; Ancho
    
ls_pixel:
    cmp cx, 0
    je ls_pixel_done
    
    lodsb
    cmp al, 0
    je ls_pixel_done
    
    ; Convertir hex
    cmp al, '0'
    jb ls_skip
    cmp al, '9'
    jbe ls_digit
    cmp al, 'A'
    jb ls_skip
    cmp al, 'F'
    jbe ls_upper
    cmp al, 'a'
    jb ls_skip
    cmp al, 'f'
    ja ls_skip
    
    sub al, 'a'
    add al, 10
    jmp ls_store
    
ls_upper:
    sub al, 'A'
    add al, 10
    jmp ls_store
    
ls_digit:
    sub al, '0'
    jmp ls_store
    
ls_skip:
    xor al, al
    
ls_store:
    stosb
    call SkipSpaces
    dec cx
    jmp ls_pixel
    
ls_pixel_done:
    pop di
    mov ax, [di-4]
    add di, ax
    
ls_row_done:
    pop cx
    dec cx
    jnz ls_row
    
ls_close:
    ; Cerrar archivo
    mov bx, file_handle
    mov ah, 3Eh
    int 21h

ls_exit:
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret
LoadSprite ENDP

; === LEER LÍNEA ===
ReadLine PROC
    push ax
    push bx
    push cx
    push dx
    push di
    
    ; Limpiar buffer
    mov di, OFFSET line_buffer
    mov cx, 256
    xor al, al
    rep stosb
    
    mov di, OFFSET line_buffer
    mov bx, file_handle
    mov cx, 0           ; Contador de bytes leídos
    
rl_loop:
    ; Leer un byte
    push cx
    push di
    mov cx, 1
    mov dx, di
    mov ah, 3Fh
    int 21h
    pop di
    pop cx
    
    ; Verificar error o EOF
    jc rl_error
    cmp ax, 0
    je rl_eof
    
    ; Verificar carácter
    mov al, [di]
    cmp al, 10          ; LF
    je rl_done
    cmp al, 13          ; CR
    je rl_loop          ; Ignorar CR
    
    ; Carácter válido
    inc di
    inc cx
    cmp cx, 255
    jl rl_loop
    
rl_done:
    mov byte ptr [di], 0
    clc
    jmp rl_exit

rl_eof:
    cmp cx, 0           ; Si leímos algo, es válido
    jne rl_done
    ; Si no leímos nada, es error
    
rl_error:
    stc
    
rl_exit:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ReadLine ENDP

; === PARSEAR NÚMERO ===
ParseNumber PROC
    push bx
    push cx
    
    xor ax, ax
    
pn_loop:
    mov bl, [si]
    cmp bl, '0'
    jb pn_done
    cmp bl, '9'
    ja pn_done
    
    sub bl, '0'
    mov cx, 10
    mul cx
    add al, bl
    inc si
    jmp pn_loop
    
pn_done:
    pop cx
    pop bx
    ret
ParseNumber ENDP

; === SALTAR ESPACIOS ===
SkipSpaces PROC
    push ax
ss_loop:
    mov al, [si]
    cmp al, 0
    je ss_done
    cmp al, ' '
    je ss_next
    cmp al, 9
    je ss_next
    jmp ss_done
ss_next:
    inc si
    jmp ss_loop
ss_done:
    pop ax
    ret
SkipSpaces ENDP

; === PROCESAR INPUT ===
ProcessInput PROC
    cmp ah, 48h
    je pi_up
    cmp ah, 50h
    je pi_down
    cmp ah, 4Bh
    je pi_left
    cmp ah, 4Dh
    je pi_right
    cmp al, 'w'
    je pi_up
    cmp al, 'W'
    je pi_up
    cmp al, 's'
    je pi_down
    cmp al, 'S'
    je pi_down
    cmp al, 'a'
    je pi_left
    cmp al, 'A'
    je pi_left
    cmp al, 'd'
    je pi_right
    cmp al, 'D'
    je pi_right
    stc
    ret

pi_up:
    cmp player_y, 1
    jle pi_fail
    dec player_y
    clc
    ret

pi_down:
    mov ax, player_y
    inc ax
    cmp ax, map_height
    jge pi_fail
    inc player_y
    clc
    ret

pi_left:
    cmp player_x, 1
    jle pi_fail
    dec player_x
    clc
    ret

pi_right:
    mov ax, player_x
    inc ax
    cmp ax, map_width
    jge pi_fail
    inc player_x
    clc
    ret

pi_fail:
    stc
    ret
ProcessInput ENDP

; === VERIFICAR COLISIÓN ===
CheckCollision PROC
    push ax
    push bx
    push si
    
    mov ax, player_y
    mov bx, map_width
    mul bx
    add ax, player_x
    mov si, ax
    add si, OFFSET map_data
    
    mov al, [si]
    cmp al, TILE_GRASS
    je cc_ok
    cmp al, TILE_PATH
    je cc_ok
    
    stc
    jmp cc_exit

cc_ok:
    clc

cc_exit:
    pop si
    pop bx
    pop ax
    ret
CheckCollision ENDP

; === ACTUALIZAR CÁMARA ===
UpdateCamera PROC
    push ax
    push bx
    
    mov ax, player_x
    sub ax, 5
    jns uc_x_ok
    xor ax, ax
uc_x_ok:
    mov bx, map_width
    sub bx, VIEWPORT_W
    cmp ax, bx
    jle uc_x_set
    mov ax, bx
uc_x_set:
    mov camera_x, ax
    
    mov ax, player_y
    sub ax, 3
    jns uc_y_ok
    xor ax, ax
uc_y_ok:
    mov bx, map_height
    sub bx, VIEWPORT_H
    cmp ax, bx
    jle uc_y_set
    mov ax, bx
uc_y_set:
    mov camera_y, ax
    
    pop bx
    pop ax
    ret
UpdateCamera ENDP

; === RENDERIZAR MUNDO ===
RenderWorld PROC
    push ax
    push bx
    push cx
    push dx
    push si
    
    xor dx, dx

rw_row:
    cmp dx, VIEWPORT_H
    jge rw_done
    
    xor cx, cx

rw_col:
    cmp cx, VIEWPORT_W
    jge rw_next_row
    
    push cx
    push dx
    
    ; Obtener tile
    mov ax, camera_y
    add ax, dx
    mov bx, map_width
    mul bx
    add ax, camera_x
    add ax, cx
    mov si, ax
    add si, OFFSET map_data
    
    xor ah, ah
    mov al, [si]
    
    ; Calcular posición
    pop bx
    push bx
    shl bx, 4
    
    pop dx
    pop cx
    push cx
    push dx
    
    mov dx, cx
    shl dx, 4
    
    ; Dibujar
    call DrawTile
    
    pop dx
    pop cx
    inc cx
    jmp rw_col

rw_next_row:
    inc dx
    jmp rw_row

rw_done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
RenderWorld ENDP

; === DIBUJAR TILE ===
; AL=tipo, DX=X, BX=Y
DrawTile PROC
    push si
    
    mov si, OFFSET sprite_grass
    cmp al, TILE_WALL
    jne dt_2
    mov si, OFFSET sprite_wall
    jmp dt_draw
dt_2:
    cmp al, TILE_PATH
    jne dt_3
    mov si, OFFSET sprite_path
    jmp dt_draw
dt_3:
    cmp al, TILE_WATER
    jne dt_4
    mov si, OFFSET sprite_water
    jmp dt_draw
dt_4:
    cmp al, TILE_TREE
    jne dt_5
    mov si, OFFSET sprite_tree
    jmp dt_draw
dt_5:
    cmp al, TILE_ROCK
    jne dt_draw
    mov si, OFFSET sprite_rock

dt_draw:
    call DrawSprite
    
    pop si
    ret
DrawTile ENDP

; === DIBUJAR SPRITE (INT 10h simple) ===
; SI=sprite, DX=X, BX=Y
DrawSprite PROC
    push ax
    push bx
    push cx
    push dx
    
    mov ax, [si]        ; Ancho
    mov cx, [si+2]      ; Alto
    add si, 4
    
ds_row:
    cmp cx, 0
    je ds_done
    
    push ax
    push dx
    push cx

ds_col:
    cmp ax, 0
    je ds_next_row
    
    lodsb
    cmp al, 0
    je ds_skip
    
    push ax
    push bx
    push cx
    push dx
    
    mov ah, 0Ch
    mov bh, 0
    int 10h
    
    pop dx
    pop cx
    pop bx
    pop ax

ds_skip:
    inc dx
    dec ax
    jmp ds_col

ds_next_row:
    pop cx
    pop dx
    pop ax
    inc bx
    dec cx
    jmp ds_row

ds_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DrawSprite ENDP

; === DIBUJAR JUGADOR ===
RenderPlayer PROC
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov ax, player_x
    sub ax, camera_x
    cmp ax, VIEWPORT_W
    jge rp_done
    
    mov dx, ax
    shl dx, 4
    add dx, 4
    
    mov ax, player_y
    sub ax, camera_y
    cmp ax, VIEWPORT_H
    jge rp_done
    
    mov bx, ax
    shl bx, 4
    add bx, 4
    
    mov si, OFFSET sprite_player
    call DrawSprite

rp_done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
RenderPlayer ENDP

; === CREAR MAPA POR DEFECTO ===
CreateDefaultMap PROC
    push ax
    push bx
    push cx
    push di
    
    mov di, OFFSET map_data
    mov cx, 300
    xor bx, bx

cdm_loop:
    mov ax, bx
    and ax, 15
    
    cmp al, 0
    jne cdm_1
    mov byte ptr [di], TILE_WALL
    jmp cdm_next
cdm_1:
    cmp al, 5
    jne cdm_2
    mov byte ptr [di], TILE_WATER
    jmp cdm_next
cdm_2:
    cmp al, 10
    jne cdm_3
    mov byte ptr [di], TILE_TREE
    jmp cdm_next
cdm_3:
    cmp al, 7
    jne cdm_4
    mov byte ptr [di], TILE_PATH
    jmp cdm_next
cdm_4:
    mov byte ptr [di], TILE_GRASS

cdm_next:
    inc di
    inc bx
    loop cdm_loop
    
    call CreateBorders
    
    pop di
    pop cx
    pop bx
    pop ax
    ret
CreateDefaultMap ENDP

; === CREAR BORDES ===
CreateBorders PROC
    push ax
    push cx
    push di
    
    ; Superior
    mov di, OFFSET map_data
    mov cx, map_width
cb_top:
    mov byte ptr [di], TILE_WALL
    inc di
    loop cb_top
    
    ; Inferior
    mov ax, map_height
    dec ax
    mul map_width
    add ax, OFFSET map_data
    mov di, ax
    mov cx, map_width
cb_bot:
    mov byte ptr [di], TILE_WALL
    inc di
    loop cb_bot
    
    ; Laterales
    mov cx, map_height
    mov di, OFFSET map_data
cb_side:
    mov byte ptr [di], TILE_WALL
    push di
    add di, map_width
    dec di
    mov byte ptr [di], TILE_WALL
    pop di
    add di, map_width
    loop cb_side
    
    pop di
    pop cx
    pop ax
    ret
CreateBorders ENDP

END main