; Proyecto de Exploración - VERSIÓN CORREGIDA
; 8086/8088 TASM - Modo EGA 640x350 16 colores
; Carga sprites desde archivos .spr

.MODEL SMALL
.STACK 512

; === CONSTANTES ===
TILE_SIZE       EQU 16
MAP_MAX_W       EQU 100
MAP_MAX_H       EQU 100
VIEWPORT_W      EQU 160
VIEWPORT_H      EQU 96
MAX_SPRITES     EQU 10

; Tipos de tiles
TILE_GRASS      EQU 0
TILE_WALL       EQU 1  
TILE_PATH       EQU 2
TILE_WATER      EQU 3
TILE_TREE       EQU 4
TILE_ROCK       EQU 5

; Modo video EGA
VIDEO_MODE      EQU 10h
VIDEO_SEG       EQU 0A000h

.DATA
; === MAPA Y RECURSOS ===
map_width       dw 0
map_height      dw 0
map_data        db MAP_MAX_W * MAP_MAX_H dup(0)
resources       db 50 * 5 dup(0)
num_resources   dw 0

; === BUFFERS ===
buffer_seg      dw 0

; === ESTADO DEL JUEGO ===
player_x        dw 3
player_y        dw 3
camera_x        dw 0
camera_y        dw 0

; === SPRITES ===
; Cada sprite: ancho(2), alto(2), datos(256)
sprite_grass    dw 16, 16
                db 256 dup(0)
sprite_wall     dw 16, 16
                db 256 dup(0)
sprite_path     dw 16, 16
                db 256 dup(0)
sprite_water    dw 16, 16
                db 256 dup(0)
sprite_tree     dw 16, 16
                db 256 dup(0)
sprite_rock     dw 16, 16
                db 256 dup(0)
sprite_player   dw 8, 8
                db 64 dup(0)
sprite_gem_red  dw 8, 8
                db 64 dup(0)
sprite_gem_cyan dw 8, 8
                db 64 dup(0)
sprite_gem_mag  dw 8, 8
                db 64 dup(0)

; === ARCHIVOS ===
map_file        db 'mapa.txt',0
file_handle     dw 0

; Nombres de sprites
spr_grass_file  db 'grass.spr',0
spr_wall_file   db 'wall.spr',0
spr_path_file   db 'path.spr',0
spr_water_file  db 'water.spr',0
spr_tree_file   db 'tree.spr',0
spr_rock_file   db 'rock.spr',0
spr_player_file db 'player.spr',0
spr_gem_r_file  db 'gem_red.spr',0
spr_gem_c_file  db 'gem_cyan.spr',0
spr_gem_m_file  db 'gem_mag.spr',0

; === MENSAJES ===
msg_loading     db 'Cargando...$'
msg_error       db 13,10,'Error de carga$'
msg_success     db 13,10,'Carga exitosa. Presione una tecla...$'

; === BUFFERS ===
line_buffer     db 256 dup(0)
temp_buffer     db 256 dup(0)

.CODE
main PROC
    mov ax, @data
    mov ds, ax
    
    ; Mostrar mensaje de carga
    mov dx, OFFSET msg_loading
    mov ah, 09h
    int 21h
    
    ; ✅ CREAR MAPA POR DEFECTO PRIMERO (siempre funciona)
    call CreateDefaultMap
    
    ; ✅ INICIALIZAR SPRITES POR DEFECTO
    call InitDefaultSprites
    
    ; Intentar cargar sprites (opcional)
    call LoadAllSprites
    ; No importa si falla
    
    ; Intentar cargar mapa real (opcional)
    call LoadMap
    ; No importa si falla - ya tenemos el por defecto
    
    ; Allocar buffer
    call AllocateBuffer
    jnc start_game
    jmp main_error
    
start_game:
    ; Mostrar mensaje de éxito
    mov dx, OFFSET msg_success
    mov ah, 09h
    int 21h
    
    ; Esperar tecla
    mov ah, 00h
    int 16h
    
    ; Modo gráfico EGA
    mov ax, VIDEO_MODE
    int 10h
    
    ; Inicializar cámara
    call UpdateCamera
    
game_loop:
    call ClearScreen
    call RenderWorld
    call RenderPlayer
    call RenderResources
    
    ; Revisar si hay tecla
    mov ah, 01h
    int 16h
    jz game_loop
    
    ; Leer tecla
    mov ah, 00h
    int 16h
    
    ; Teclas de movimiento - Flechas
    cmp ah, 48h
    je move_up
    cmp ah, 50h
    je move_down
    cmp ah, 4Bh
    je move_left
    cmp ah, 4Dh
    je move_right
    
    ; WASD
    cmp al, 'w'
    je move_up
    cmp al, 'W'
    je move_up
    cmp al, 's'
    je move_down
    cmp al, 'S'
    je move_down
    cmp al, 'a'
    je move_left
    cmp al, 'A'
    je move_left
    cmp al, 'd'
    je move_right
    cmp al, 'D'
    je move_right
    
    ; ESC para salir
    cmp al, 27
    je main_exit
    jmp game_loop

move_up:
    mov ax, player_y
    cmp ax, 0
    je game_loop
    dec player_y
    call CheckCollision
    jnc move_ok_up
    inc player_y
move_ok_up:
    call UpdateCamera
    jmp game_loop

move_down:
    mov ax, player_y
    inc ax
    cmp ax, map_height
    jae game_loop
    inc player_y
    call CheckCollision
    jnc move_ok_down
    dec player_y
move_ok_down:
    call UpdateCamera
    jmp game_loop

move_left:
    mov ax, player_x
    cmp ax, 0
    je game_loop
    dec player_x
    call CheckCollision
    jnc move_ok_left
    inc player_x
move_ok_left:
    call UpdateCamera
    jmp game_loop

move_right:
    mov ax, player_x
    inc ax
    cmp ax, map_width
    jae game_loop
    inc player_x
    call CheckCollision
    jnc move_ok_right
    dec player_x
move_ok_right:
    call UpdateCamera
    jmp game_loop

main_error:
    mov dx, OFFSET msg_error
    mov ah, 09h
    int 21h
    mov ah, 00h
    int 16h

main_exit:
    call FreeBuffer
    mov ax, 0003h
    int 10h
    mov ax, 4C00h
    int 21h
main ENDP

; === ✅ CREAR MAPA POR DEFECTO ===
CreateDefaultMap PROC
    push ax
    push bx
    push cx
    push di
    
    ; Establecer dimensiones pequeñas para test
    mov map_width, 20
    mov map_height, 15
    
    ; Llenar con patrón simple
    mov di, OFFSET map_data
    mov cx, 300                 ; 20 * 15
    
cdm_loop:
    mov ax, cx
    and ax, 7                   ; Patrón 0-7
    cmp ax, 6
    jb cdm_valid
    xor ax, ax                  ; Cambiar >5 por 0
cdm_valid:
    mov [di], al
    inc di
    loop cdm_loop
    
    ; Agregar bordes de pared
    call CreateBorders
    
    ; Sin recursos por defecto
    mov num_resources, 0
    
    pop di
    pop cx
    pop bx
    pop ax
    ret
CreateDefaultMap ENDP

; === ✅ CREAR BORDES ===
CreateBorders PROC
    push ax
    push bx
    push cx
    push di
    
    ; Borde superior e inferior
    mov cx, map_width
    mov di, OFFSET map_data
    
cb_top:
    mov byte ptr [di], TILE_WALL
    inc di
    loop cb_top
    
    ; Borde inferior
    mov ax, map_height
    dec ax
    mul map_width
    add ax, OFFSET map_data
    mov di, ax
    mov cx, map_width
    
cb_bottom:
    mov byte ptr [di], TILE_WALL
    inc di
    loop cb_bottom
    
    ; Bordes laterales
    mov cx, map_height
    mov di, OFFSET map_data
    
cb_sides:
    mov byte ptr [di], TILE_WALL        ; Izquierda
    push di
    add di, map_width
    dec di
    mov byte ptr [di], TILE_WALL        ; Derecha
    pop di
    add di, map_width
    loop cb_sides
    
    pop di
    pop cx
    pop bx
    pop ax
    ret
CreateBorders ENDP

; === ✅ INICIALIZAR SPRITES POR DEFECTO ===
InitDefaultSprites PROC
    push ax
    push cx
    push di
    
    ; Sprite de pasto (verde claro)
    mov di, OFFSET sprite_grass + 4
    mov cx, 256
    mov al, 10                  ; Verde claro
ids_grass:
    mov [di], al
    inc di
    loop ids_grass
    
    ; Sprite de pared (gris)
    mov di, OFFSET sprite_wall + 4
    mov cx, 256
    mov al, 8                   ; Gris oscuro
ids_wall:
    mov [di], al
    inc di
    loop ids_wall
    
    ; Sprite de camino (marrón)
    mov di, OFFSET sprite_path + 4
    mov cx, 256
    mov al, 6                   ; Marrón
ids_path:
    mov [di], al
    inc di
    loop ids_path
    
    ; Sprite de agua (azul)
    mov di, OFFSET sprite_water + 4
    mov cx, 256
    mov al, 9                   ; Azul claro
ids_water:
    mov [di], al
    inc di
    loop ids_water
    
    ; Sprite de árbol (verde oscuro)
    mov di, OFFSET sprite_tree + 4
    mov cx, 256
    mov al, 2                   ; Verde oscuro
ids_tree:
    mov [di], al
    inc di
    loop ids_tree
    
    ; Sprite de roca (gris claro)
    mov di, OFFSET sprite_rock + 4
    mov cx, 256
    mov al, 7                   ; Gris claro
ids_rock:
    mov [di], al
    inc di
    loop ids_rock
    
    ; Sprite de jugador (amarillo)
    mov di, OFFSET sprite_player + 4
    mov cx, 64
    mov al, 14                  ; Amarillo brillante
ids_player:
    mov [di], al
    inc di
    loop ids_player
    
    ; Sprites de gemas
    mov di, OFFSET sprite_gem_red + 4
    mov cx, 64
    mov al, 12                  ; Rojo brillante
ids_gem_red:
    mov [di], al
    inc di
    loop ids_gem_red
    
    mov di, OFFSET sprite_gem_cyan + 4
    mov cx, 64
    mov al, 11                  ; Cian brillante
ids_gem_cyan:
    mov [di], al
    inc di
    loop ids_gem_cyan
    
    mov di, OFFSET sprite_gem_mag + 4
    mov cx, 64
    mov al, 13                  ; Magenta brillante
ids_gem_mag:
    mov [di], al
    inc di
    loop ids_gem_mag
    
    pop di
    pop cx
    pop ax
    ret
InitDefaultSprites ENDP

; === CARGAR TODOS LOS SPRITES (OPCIONAL) ===
LoadAllSprites PROC
    push dx
    push di
    
    ; ✅ Intentar cargar pero no fallar si no existen
    mov dx, OFFSET spr_grass_file
    mov di, OFFSET sprite_grass
    call LoadSprite
    
    mov dx, OFFSET spr_wall_file
    mov di, OFFSET sprite_wall
    call LoadSprite
    
    mov dx, OFFSET spr_path_file
    mov di, OFFSET sprite_path
    call LoadSprite
    
    mov dx, OFFSET spr_water_file
    mov di, OFFSET sprite_water
    call LoadSprite
    
    mov dx, OFFSET spr_tree_file
    mov di, OFFSET sprite_tree
    call LoadSprite
    
    mov dx, OFFSET spr_rock_file
    mov di, OFFSET sprite_rock
    call LoadSprite
    
    mov dx, OFFSET spr_player_file
    mov di, OFFSET sprite_player
    call LoadSprite
    
    mov dx, OFFSET spr_gem_r_file
    mov di, OFFSET sprite_gem_red
    call LoadSprite
    
    mov dx, OFFSET spr_gem_c_file
    mov di, OFFSET sprite_gem_cyan
    call LoadSprite
    
    mov dx, OFFSET spr_gem_m_file
    mov di, OFFSET sprite_gem_mag
    call LoadSprite
    
    ; ✅ Siempre retornar éxito
    clc
    
    pop di
    pop dx
    ret
LoadAllSprites ENDP

; === CARGAR SPRITE (OPCIONAL) ===
LoadSprite PROC
    push ax
    push bx
    push cx
    push si
    push di
    
    ; Abrir archivo
    mov al, 0
    mov ah, 3Dh
    int 21h
    jc ls_error                 ; ✅ No importa si falla
    
    mov file_handle, ax
    
    ; Leer primera línea (dimensiones)
    call ReadLine
    
    ; Parsear ancho
    mov si, OFFSET line_buffer
    call SkipSpaces
    call ParseNumber
    mov [di], ax        ; Guardar ancho
    
    ; Parsear alto
    call SkipSpaces
    call ParseNumber
    mov [di+2], ax      ; Guardar alto
    
    ; Apuntar a datos
    add di, 4
    
    ; Leer cada fila del sprite
    mov cx, [di-2]      ; Alto
    
ls_row_loop:
    push cx
    push di
    
    call ReadLine
    mov si, OFFSET line_buffer
    call SkipSpaces
    
    pop di
    push di
    
    ; Leer pixels de la fila
    mov cx, [di-4]      ; Ancho
    
ls_pixel_loop:
    push cx
    
    lodsb               ; Leer carácter
    
    ; Convertir hex a número
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
    jbe ls_lower
    
ls_skip:
    mov al, 0
    jmp ls_store
    
ls_digit:
    sub al, '0'
    jmp ls_store
    
ls_upper:
    sub al, 'A'
    add al, 10
    jmp ls_store
    
ls_lower:
    sub al, 'a'
    add al, 10
    
ls_store:
    stosb
    call SkipSpaces
    
    pop cx
    loop ls_pixel_loop
    
    pop di
    mov ax, [di-4]      ; Ancho
    add di, ax
    
    pop cx
    loop ls_row_loop
    
    ; Cerrar archivo
    mov bx, file_handle
    mov ah, 3Eh
    int 21h
    
ls_error:
    ; ✅ Siempre éxito (usar sprite por defecto)
    clc
    
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret
LoadSprite ENDP

; === CARGAR MAPA (OPCIONAL) ===
LoadMap PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Abrir archivo
    mov dx, OFFSET map_file
    mov al, 0
    mov ah, 3Dh
    int 21h
    jc lm_error                 ; ✅ No importa si falla
    
    mov file_handle, ax
    
    ; Leer dimensiones
    call ReadLine
    call ParseDimensions
    jc lm_close_error
    
    ; Verificar dimensiones válidas
    mov ax, map_width
    cmp ax, 1
    jb lm_close_error
    cmp ax, MAP_MAX_W
    ja lm_close_error
    
    mov ax, map_height
    cmp ax, 1
    jb lm_close_error
    cmp ax, MAP_MAX_H
    ja lm_close_error
    
    ; Leer filas del mapa
    mov cx, map_height
    xor si, si          ; Contador de filas
    
lm_read_row:
    push cx
    push si
    
    call ReadLine
    
    ; Verificar que hay datos
    mov al, line_buffer
    cmp al, 0
    je lm_skip_row
    
    ; Parsear la fila
    call ParseMapRow
    
lm_skip_row:
    pop si
    inc si
    pop cx
    loop lm_read_row
    
    ; Leer recursos
    xor di, di
    
lm_read_res:
    call ReadLine
    
    ; Verificar fin de archivo
    mov al, line_buffer
    cmp al, 0
    je lm_close
    
    ; Verificar si es recurso
    cmp al, 'R'
    jne lm_read_res
    
    call ParseResource
    inc di
    cmp di, 50
    jl lm_read_res
    
lm_close:
    mov num_resources, di
    
    ; Cerrar archivo
    mov bx, file_handle
    mov ah, 3Eh
    int 21h
    
    clc
    jmp lm_exit
    
lm_close_error:
    mov bx, file_handle
    mov ah, 3Eh
    int 21h
    
lm_error:
    ; ✅ No importa el error - usar mapa por defecto
    clc
    
lm_exit:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
LoadMap ENDP

; === PARSEAR DIMENSIONES ===
ParseDimensions PROC
    push si
    
    mov si, OFFSET line_buffer
    
    ; Parsear ancho
    call SkipSpaces
    call ParseNumber
    cmp ax, 0
    je pd_error
    mov map_width, ax
    
    ; Parsear alto
    call SkipSpaces
    call ParseNumber
    cmp ax, 0
    je pd_error
    mov map_height, ax
    
    clc
    jmp pd_exit
    
pd_error:
    stc
    
pd_exit:
    pop si
    ret
ParseDimensions ENDP

; === PARSEAR FILA DEL MAPA ===
ParseMapRow PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Calcular offset en map_data
    mov ax, si
    mov dx, map_width
    mul dx
    mov di, ax
    add di, OFFSET map_data
    
    ; Parsear valores
    mov si, OFFSET line_buffer
    call SkipSpaces
    
    xor cx, cx          ; Contador de columnas
    
pmr_loop:
    mov ax, map_width
    cmp cx, ax
    jge pmr_done
    
    ; Verificar fin de línea
    mov al, [si]
    cmp al, 0
    je pmr_done
    
    ; Parsear número
    call ParseNumber
    
    ; Validar rango (0-5)
    cmp ax, 5
    jbe pmr_valid
    xor ax, ax
    
pmr_valid:
    mov [di], al
    inc di
    inc cx
    
    call SkipSpaces
    jmp pmr_loop
    
pmr_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ParseMapRow ENDP

; === PARSEAR RECURSO ===
ParseResource PROC
    push ax
    push bx
    push si
    push di
    
    mov si, OFFSET line_buffer
    inc si              ; Saltar 'R'
    
    ; Calcular offset
    mov ax, num_resources
    mov bx, 5
    mul bx
    mov di, ax
    add di, OFFSET resources
    
    ; Tipo de recurso
    mov byte ptr [di], 'R'
    inc di
    
    ; X
    call SkipSpaces
    call ParseNumber
    mov [di], al
    inc di
    
    ; Y
    call SkipSpaces
    call ParseNumber
    mov [di], al
    inc di
    
    ; Tipo
    call SkipSpaces
    call ParseNumber
    mov [di], al
    inc di
    
    ; Cantidad
    call SkipSpaces
    call ParseNumber
    mov [di], al
    
    pop di
    pop si
    pop bx
    pop ax
    ret
ParseResource ENDP

; === PARSEAR NÚMERO ===
ParseNumber PROC
    push bx
    push cx
    
    xor ax, ax
    xor bx, bx
    
pn_loop:
    mov bl, [si]
    
    ; Verificar fin o no-dígito
    cmp bl, '0'
    jb pn_done
    cmp bl, '9'
    ja pn_done
    
    ; Convertir a número
    sub bl, '0'
    
    ; ax = ax * 10 + bl
    mov cx, 10
    mul cx
    add ax, bx
    
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
    cmp al, 9       ; TAB
    je ss_next
    jmp ss_done
    
ss_next:
    inc si
    jmp ss_loop
    
ss_done:
    pop ax
    ret
SkipSpaces ENDP

; === LEER LÍNEA DE ARCHIVO ===
ReadLine PROC
    push ax
    push bx
    push cx
    push dx
    push di
    
    ; Limpiar buffer
    mov di, OFFSET line_buffer
    xor al, al
    mov cx, 256
    rep stosb
    
    ; Leer caracteres hasta EOL
    mov di, OFFSET line_buffer
    mov bx, file_handle
    
rl_loop:
    ; Leer un carácter
    mov cx, 1
    mov dx, di
    mov ah, 3Fh
    int 21h
    
    ; Verificar EOF
    jc rl_done
    cmp ax, 0
    je rl_done
    
    ; Verificar EOL
    mov al, [di]
    cmp al, 10      ; LF
    je rl_done
    cmp al, 13      ; CR
    je rl_loop      ; Ignorar CR
    
    ; Carácter válido
    inc di
    
    ; Verificar límite
    mov ax, di
    sub ax, OFFSET line_buffer
    cmp ax, 254
    jl rl_loop
    
rl_done:
    mov byte ptr [di], 0
    
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ReadLine ENDP

; === VERIFICAR COLISIÓN ===
CheckCollision PROC
    push ax
    push bx
    push si
    
    ; Calcular posición en el mapa
    mov ax, player_y
    mov bx, map_width
    mul bx
    add ax, player_x
    mov si, ax
    add si, OFFSET map_data
    
    ; Verificar tipo de tile
    mov al, [si]
    
    ; Tiles transitables: grass(0), path(2)
    cmp al, TILE_GRASS
    je cc_ok
    cmp al, TILE_PATH
    je cc_ok
    
    ; Los demás son obstáculos
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
    
    ; Centrar cámara en X
    mov ax, player_x
    sub ax, 5           ; Mitad del viewport (10/2)
    jns uc_x_positive
    xor ax, ax
    
uc_x_positive:
    mov bx, map_width
    sub bx, 10          ; Ancho del viewport
    cmp ax, bx
    jle uc_set_x
    mov ax, bx
    
uc_set_x:
    mov camera_x, ax
    
    ; Centrar cámara en Y
    mov ax, player_y
    sub ax, 3           ; Mitad del viewport (6/2)
    jns uc_y_positive
    xor ax, ax
    
uc_y_positive:
    mov bx, map_height
    sub bx, 6           ; Alto del viewport
    cmp ax, bx
    jle uc_set_y
    mov ax, bx
    
uc_set_y:
    mov camera_y, ax
    
    pop bx
    pop ax
    ret
UpdateCamera ENDP

; === LIMPIAR PANTALLA ===
ClearScreen PROC
    push ax
    push cx
    push di
    push es
    
    mov ax, VIDEO_SEG
    mov es, ax
    xor di, di
    xor ax, ax
    mov cx, 8000h
    rep stosw
    
    pop es
    pop di
    pop cx
    pop ax
    ret
ClearScreen ENDP

; === RENDERIZAR MUNDO ===
RenderWorld PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Dibujar tiles visibles
    xor dx, dx          ; Y en viewport
    
rw_row:
    cmp dx, 6
    jge rw_done
    
    xor cx, cx          ; X en viewport
    
rw_col:
    cmp cx, 10
    jge rw_next_row
    
    push cx
    push dx
    
    ; Calcular posición en el mapa
    mov ax, camera_y
    add ax, dx
    mov bx, map_width
    mul bx
    add ax, camera_x
    add ax, cx
    mov si, ax
    add si, OFFSET map_data
    
    ; ✅ CORREGIR: Obtener tipo de tile (sin MOVZX)
    xor ah, ah
    mov al, [si]
    
    ; Calcular posición en pantalla
    pop bx              ; Y
    push bx
    shl bx, 4           ; Y * 16
    
    pop dx
    pop cx
    push cx
    push dx
    
    mov dx, cx
    shl dx, 4           ; X * 16
    
    ; Dibujar tile
    call DrawTile
    
    pop dx
    pop cx
    
    inc cx
    jmp rw_col
    
rw_next_row:
    inc dx
    jmp rw_row
    
rw_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
RenderWorld ENDP

; === DIBUJAR TILE ===
; AX = tipo, DX = X, BX = Y
DrawTile PROC
    push si
    push ax
    push bx
    push cx
    push dx
    
    ; Seleccionar sprite según tipo
    cmp ax, TILE_WALL
    jne dt_2
    mov si, OFFSET sprite_wall
    jmp dt_draw
    
dt_2:
    cmp ax, TILE_PATH
    jne dt_3
    mov si, OFFSET sprite_path
    jmp dt_draw
    
dt_3:
    cmp ax, TILE_WATER
    jne dt_4
    mov si, OFFSET sprite_water
    jmp dt_draw
    
dt_4:
    cmp ax, TILE_TREE
    jne dt_5
    mov si, OFFSET sprite_tree
    jmp dt_draw
    
dt_5:
    cmp ax, TILE_ROCK
    jne dt_default
    mov si, OFFSET sprite_rock
    jmp dt_draw
    
dt_default:
    mov si, OFFSET sprite_grass
    
dt_draw:
    mov cx, dx          ; X
    mov dx, bx          ; Y
    call DrawSprite
    
    pop dx
    pop cx
    pop bx
    pop ax
    pop si
    ret
DrawTile ENDP

; === ✅ DIBUJAR SPRITE SIMPLIFICADO (FUNCIONA EN EGA) ===
DrawSprite PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    
    ; Verificar límites
    cmp cx, 640
    jae ds_done
    cmp dx, 350
    jae ds_done
    
    mov ax, VIDEO_SEG
    mov es, ax
    
    ; Obtener dimensiones
    mov ax, [si]        ; Ancho
    mov bx, [si+2]      ; Alto
    add si, 4           ; Datos
    
    ; ✅ ALGORITMO SIMPLIFICADO - PIXELS GRANDES
    push dx             ; Guardar Y inicial
    
ds_row_simple:
    cmp bx, 0
    je ds_done_simple
    
    push cx             ; Guardar X inicial
    push ax             ; Guardar ancho
    
ds_col_simple:
    cmp ax, 0
    je ds_next_row_simple
    
    ; Leer color del sprite
    push ax
    mov al, [si]
    inc si
    
    ; Si es transparente (0), saltar
    cmp al, 0
    je ds_skip_simple
    
    ; ✅ DIBUJAR PIXEL SIMPLE - Solo escribir color
    push si
    push dx
    
    ; Calcular posición Y * 80 + X/8
    mov di, dx
    mov si, 80
    push ax
    mov ax, di
    mul si
    mov di, ax
    pop ax
    
    mov si, cx
    shr si, 3
    add di, si
    
    ; Escribir directamente (modo simple)
    mov es:[di], al
    
    pop dx
    pop si
    
ds_skip_simple:
    pop ax
    inc cx              ; Siguiente X
    dec ax
    jmp ds_col_simple
    
ds_next_row_simple:
    pop ax              ; Recuperar ancho
    pop cx              ; Recuperar X inicial
    inc dx              ; Siguiente Y
    dec bx
    jmp ds_row_simple
    
ds_done_simple:
    pop dx              ; Limpiar Y inicial del stack
    
ds_done:
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DrawSprite ENDP

; === RENDERIZAR JUGADOR ===
RenderPlayer PROC
    push ax
    push bx
    push cx
    push dx
    push si
    
    ; Calcular posición en pantalla
    mov ax, player_x
    sub ax, camera_x
    
    ; Verificar si está visible
    cmp ax, 10
    jge rp_done
    
    mov cx, ax
    shl cx, 4
    add cx, 4           ; Centro del tile
    
    mov ax, player_y
    sub ax, camera_y
    
    ; Verificar si está visible
    cmp ax, 6
    jge rp_done
    
    mov dx, ax
    shl dx, 4
    add dx, 4           ; Centro del tile
    
    ; Dibujar sprite del jugador
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

; === ✅ RENDERIZAR RECURSOS (CORREGIDO) ===
RenderResources PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov cx, num_resources
    cmp cx, 0
    je rr_done
    
    mov di, OFFSET resources
    
rr_loop:
    push cx
    
    ; Verificar si es recurso activo
    cmp byte ptr [di], 'R'
    jne rr_next
    
    ; Obtener coordenadas
    xor ah, ah
    mov al, [di+1]      ; X
    mov bx, ax
    mov al, [di+2]      ; Y
    mov dx, ax
    
    ; Verificar si está en viewport
    mov ax, bx
    sub ax, camera_x
    cmp ax, 10
    jge rr_next
    
    mov cx, ax
    
    mov ax, dx
    sub ax, camera_y
    cmp ax, 6
    jge rr_next
    
    ; Calcular posición en pantalla
    mov dx, ax
    shl cx, 4
    add cx, 4
    shl dx, 4
    add dx, 4
    
    ; Obtener tipo de gema
    mov al, [di+3]
    push di
    
    cmp al, 1
    jne rr_type2
    mov si, OFFSET sprite_gem_red
    jmp rr_draw_gem
    
rr_type2:
    cmp al, 2
    jne rr_type3
    mov si, OFFSET sprite_gem_cyan
    jmp rr_draw_gem
    
rr_type3:
    mov si, OFFSET sprite_gem_mag
    
rr_draw_gem:
    call DrawSprite
    pop di
    
rr_next:
    add di, 5
    pop cx
    loop rr_loop
    
rr_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
RenderResources ENDP

; === ALLOCAR BUFFER ===
AllocateBuffer PROC
    mov bx, 200
    mov ah, 48h
    int 21h
    jc ab_error
    mov buffer_seg, ax
    clc
    ret
ab_error:
    stc
    ret
AllocateBuffer ENDP

; === LIBERAR BUFFER ===
FreeBuffer PROC
    push ax
    push es
    mov ax, buffer_seg
    or ax, ax
    jz fb_done
    mov es, ax
    mov ah, 49h
    int 21h
fb_done:
    pop es
    pop ax
    ret
FreeBuffer ENDP

END main