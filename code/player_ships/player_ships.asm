rsect player_ships_replacement

# include constants.asm
ships_array: ext
pointer_len_ship: ext
board_state: ext
player_placement_done: ext
player_placement_mode: ext
x_hor_st: ext
y_hor_st: ext
x_ver_st: ext
y_ver_st: ext

# include replacement.asm
check_placement: ext

# include write_tty.asm
clear_tty: ext
print_place_your_ship: ext
write_bad_placement: ext

enemy_generation_done: ext
print_newline: ext
write_ship_generation: ext
prev_btn_state: ext

# ==========================================
# ИНИЦИАЛИЗАЦИЯ (Вызывается один раз из main)
# ==========================================
player_ships_replacement_init>
    ldi r0, ships_array
    ldi r1, pointer_len_ship
    stw r1, r0

    ldi r0, 0
    ldi r1, player_placement_done
    stw r1, r0

    jsr spawn_current_ship
    rts

# ==========================================
# СПАВН СЛЕДУЮЩЕГО КОРАБЛЯ
# ==========================================
spawn_current_ship>
    ldi r0, pointer_len_ship
    ldw r0, r0
    ldb r0, r0      # r0 = размер корабля
    tst r0
    bnz continue_spawn
    
    # Если корабли кончились
    ldi r0, 1
    ldi r1, player_placement_done
    stw r1, r0
    jsr clear_tty   # Полностью очищаем TTY перед началом боя
    ldi r0, enemy_generation_done
    ldw r0, r0 
    tst r0
    beq write_ship_generation
    rts

continue_spawn:
    # Вызываем нашу новую умную отрисовку TTY
    jsr refresh_placement_tty

    # Сброс режима на горизонтальный
    ldi r0, 0
    ldi r1, player_placement_mode
    stw r1, r0

    # Сброс координат на (0, 0)
    ldi r0, 0
    ldi r1, x_hor_st
    stw r1, r0
    ldi r1, y_hor_st
    stw r1, r0

    jsr draw_preview_hor
    rts

# ==========================================
# УМНАЯ ОТРИСОВКА TTY
# ==========================================
refresh_placement_tty>
    push r0
    
    jsr clear_tty
    
    # 1. Проверяем, генерируется ли еще враг
    ldi r0, enemy_generation_done
    ldw r0, r0
    tst r0
    bnz skip_gen_msg
    
    jsr write_ship_generation
    jsr print_newline
    
skip_gen_msg:
    # 2. Проверяем, расставляет ли еще игрок корабли
    ldi r0, player_placement_done
    ldw r0, r0
    tst r0
    bnz skip_place_msg
    
    jsr print_place_your_ship
    
skip_place_msg:
    pop r0
    rts

# ==========================================
# ШАГ ИГРОКА (Вызывается из прерывания на 1 такт)
# ==========================================
player_placement_step> 
    ldi r0, 0xff80 
    ldb r0, r2       # Читаем кнопку (r2 = текущее нажатие)

    # --- Детектор фронта ---
    # Важно: обновляем состояние ДО проверок, чтобы отжатие (0) тоже записалось!
    ldi r0, prev_btn_state
    ldb r0, r1       # r1 = старое состояние
    stb r0, r2       # Сохраняем текущее в prev_btn_state
    
    not r1, r1
    and r2, r1, r2   # r2 = только новые нажатия (текущее & ~старое)
    tst r2
    bz exit_step     # Если новых нажатий нет - выходим
    # ---------------------------------------------------

    ldi r0, player_placement_mode 
    ldw r0, r0 
    tst r0 
    bz hor_mode 

    jsr handle_ver 
exit_step:
    rts 

hor_mode: 
    jsr handle_hor 
    rts

# ==========================================
# ЛОГИКА ДВИЖЕНИЯ: ГОРИЗОНТАЛЬНАЯ
# ==========================================
handle_hor:
    ldi r6, pointer_len_ship
    ldw r6, r6
    ldb r6, r6      # r6 = размер

    # --- Влево ---
    ldi r3, 1
    and r2, r3, r4
    bz check_up_hor
    ldi r0, x_hor_st
    ldw r0, r0
    tst r0
    bz redraw_hor
    dec r0
    ldi r1, x_hor_st
    stw r1, r0
    br redraw_hor

check_up_hor:
    # --- Вверх ---
    ldi r3, 2
    and r2, r3, r4
    bz check_right_hor
    ldi r0, y_hor_st
    ldw r0, r0
    tst r0
    bz redraw_hor
    dec r0
    ldi r1, y_hor_st
    stw r1, r0
    br redraw_hor

check_right_hor:
    # --- Вправо ---
    ldi r3, 4
    and r2, r3, r4
    bz check_down_hor
    ldi r0, x_hor_st
    ldw r0, r0
    add r0, r6, r4  # r4 = x + size
    ldi r5, 10
    cmp r4, r5
    bge redraw_hor # граница 9
    inc r0
    ldi r1, x_hor_st
    stw r1, r0
    br redraw_hor

check_down_hor:
    # --- Вниз ---
    ldi r3, 8
    and r2, r3, r4
    bz check_reverse_hor
    ldi r0, y_hor_st
    ldw r0, r0
    ldi r5, 9
    cmp r0, r5
    bge redraw_hor
    inc r0
    ldi r1, y_hor_st
    stw r1, r0
    br redraw_hor

check_reverse_hor:
    # --- Поворот ---
    ldi r3, 16
    and r2, r3, r4
    bz check_place_hor
    ldi r0, 1
    ldi r1, player_placement_mode
    stw r1, r0
    ldi r0, x_hor_st
    ldw r0, r0
    ldi r1, x_ver_st
    stw r1, r0
    ldi r0, y_hor_st
    ldw r0, r0
    ldi r1, y_ver_st
    stw r1, r0
    jsr draw_preview_ver
    rts

check_place_hor:
    # --- Установка (Commit) ---
    ldi r3, 32
    and r2, r3, r4
    bz redraw_hor

    jsr get_hor_mask  # r1 = маска
    ldi r0, y_hor_st
    ldw r0, r0
    jsr check_placement
    tst r2
    bnz bad_placement_hor
    
    # Успешно! Пишем в board_state
    jsr get_hor_mask
    ldi r0, y_hor_st
    ldw r0, r0
    ldi r3, board_state
    add r0, r3, r3
    add r0, r3, r3    # r3 теперь указывает на адрес board_state[y]
    
    ldw r3, r4        # r4 = текущее состояние строки board_state[y]
    or r4, r1, r4     # r4 = строка | маска нового корабля
    stw r3, r4        # сохраняем строку обратно в board_state[y]
    
    # Сдвиг указателя на след корабль
    ldi r0, pointer_len_ship
    ldw r0, r1
    inc r1
    inc r1
    ldi r2, pointer_len_ship
    stw r2, r1
    jsr spawn_current_ship
    rts

bad_placement_hor:
    jsr write_bad_placement
redraw_hor:
    jsr draw_preview_hor
    rts

# ==========================================
# ЛОГИКА ДВИЖЕНИЯ: ВЕРТИКАЛЬНАЯ
# ==========================================
handle_ver:
    ldi r6, pointer_len_ship
    ldw r6, r6
    ldb r6, r6      # r6 = размер

    # --- Влево ---
    ldi r3, 1
    and r2, r3, r4
    bz check_up_ver
    ldi r0, x_ver_st
    ldw r0, r0
    tst r0
    bz redraw_ver
    dec r0
    ldi r1, x_ver_st
    stw r1, r0
    br redraw_ver

check_up_ver:
    # --- Вверх ---
    ldi r3, 2
    and r2, r3, r4
    bz check_right_ver
    ldi r0, y_ver_st
    ldw r0, r0
    tst r0
    bz redraw_ver
    dec r0
    ldi r1, y_ver_st
    stw r1, r0
    br redraw_ver

check_right_ver:
    # --- Вправо ---
    ldi r3, 4
    and r2, r3, r4
    bz check_down_ver
    ldi r0, x_ver_st
    ldw r0, r0
    ldi r5, 9
    cmp r0, r5
    bge redraw_ver
    inc r0
    ldi r1, x_ver_st
    stw r1, r0
    br redraw_ver

check_down_ver:
    # --- Вниз ---
    ldi r3, 8
    and r2, r3, r4
    bz check_reverse_ver
    ldi r0, y_ver_st
    ldw r0, r0
    add r0, r6, r4  # y + size
    ldi r5, 10
    cmp r4, r5
    bge redraw_ver
    inc r0
    ldi r1, y_ver_st
    stw r1, r0
    br redraw_ver

check_reverse_ver:
    # --- Поворот ---
    ldi r3, 16
    and r2, r3, r4
    bz check_place_ver
    ldi r0, 0
    ldi r1, player_placement_mode
    stw r1, r0
    ldi r0, x_ver_st
    ldw r0, r0
    ldi r1, x_hor_st
    stw r1, r0
    ldi r0, y_ver_st
    ldw r0, r0
    ldi r1, y_hor_st
    stw r1, r0
    jsr draw_preview_hor
    rts

check_place_ver:
    # --- Установка (Commit) ---
    ldi r3, 32
    and r2, r3, r4
    bz redraw_ver
    
    jsr get_ver_mask
    push r1
    ldi r0, y_ver_st
    ldw r0, r0
    ldi r4, 0       # Накопитель ошибок
    
ver_check_loop:
    push r0
    push r1
    push r6
    jsr check_placement
    pop r6
    pop r1
    pop r0
    or r2, r4, r4
    inc r0
    dec r6
    bne ver_check_loop
    
    pop r1
    tst r4
    bnz bad_placement_ver
    
    # Успешно! Пишем в board_state
    ldi r6, pointer_len_ship
    ldw r6, r6
    ldb r6, r6
    ldi r0, y_ver_st
    ldw r0, r0
    
ver_commit_loop:
    move r0, r3
    shl r3, r3, 1
    ldi r4, board_state
    add r4, r3, r3    # r3 теперь указывает на адрес board_state[y]
    
    ldw r3, r5        # r5 = текущее состояние строки board_state[y]
    or r5, r1, r5     # r5 = строка | маска нового корабля
    stw r3, r5        # сохраняем строку обратно в board_state[y]
    
    inc r0
    dec r6
    bne ver_commit_loop
    
    # Сдвиг указателя
    ldi r0, pointer_len_ship
    ldw r0, r2
    inc r2
    inc r2
    ldi r3, pointer_len_ship
    stw r3, r2
    jsr spawn_current_ship
    rts
    
bad_placement_ver:
    jsr write_bad_placement
redraw_ver:
    jsr draw_preview_ver
    rts

# ==========================================
# ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ (Маски и Отрисовка)
# ==========================================

get_hor_mask: 
    ldi r6, pointer_len_ship 
    ldw r6, r6 
    ldb r6, r6 
    ldi r7, 0 
    ldi r3, 0b1000000000 
mask_loop: 
    or r3, r7, r7 
    shr r7, r7, 1 
    dec r6 
    bne mask_loop 
    shl r7, r7, 1 
    ldi r0, x_hor_st 
    ldw r0, r0 
    tst r0 
    bz mask_done 
shift_loop: 
    shr r7, r7, 1 
    dec r0 
    bne shift_loop 
mask_done: 
    move r7, r1 
    rts

get_ver_mask: 
    ldi r7, 0b1000000000 
    ldi r0, x_ver_st 
    ldw r0, r0 
    tst r0 
    bz v_mask_done 
v_shift_loop: 
    shr r7, r7, 1 
    dec r0 
    bne v_shift_loop 
v_mask_done: 
    move r7, r1 
    rts

# Универсальный покадровый рендер (без шлейфов и багов с наложениями)
draw_preview_hor:
draw_preview_ver:
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5
    push r6

    # ШАГ 1: Полностью очищаем поле, отрисовывая чистое состояние (board_state)
    ldi r0, 0          # Индекс строки y = 0
clean_matrix_loop:
    move r0, r2
    shl r2, r2, 1      # r2 = y * 2 (смещение для слова)

    ldi r3, board_state
    add r3, r2, r3
    ldw r3, r3         # r3 = board_state[y]

    ldi r4, 0xff6a     # Базовый порт матрицы игрока
    add r4, r2, r4
    stw r4, r3         # Восстанавливаем чистую строку в матрице

    inc r0
    ldi r5, 10
    cmp r0, r5
    blt clean_matrix_loop

    # ШАГ 2: Определяем текущий режим и накладываем превью корабля
    ldi r0, player_placement_mode
    ldw r0, r0
    tst r0
    bz draw_h_overlay

draw_v_overlay:
    # Отрисовка вертикального превью
    jsr get_ver_mask
    ldi r6, pointer_len_ship 
    ldw r6, r6 
    ldb r6, r6         # r6 = размер
    ldi r0, y_ver_st 
    ldw r0, r0 
v_overlay_loop: 
    move r0, r2 
    shl r2, r2, 1 
    ldi r4, 0xff6a 
    add r4, r2, r4 

    ldi r3, board_state 
    add r3, r2, r3 
    ldw r3, r3 

    or r3, r1, r5 
    stw r4, r5 

    inc r0 
    dec r6 
    bne v_overlay_loop 
    br finish_draw

draw_h_overlay:
    # Отрисовка горизонтального превью
    jsr get_hor_mask 
    ldi r0, y_hor_st 
    ldw r0, r0 
    move r0, r2 
    shl r2, r2, 1 
    ldi r4, 0xff6a 
    add r4, r2, r4 

    ldi r3, board_state 
    add r3, r2, r3 
    ldw r3, r3 

    or r3, r1, r5 
    stw r4, r5 

finish_draw:
    pop r6
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rts

end.