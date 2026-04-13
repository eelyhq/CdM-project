rsect game_kill_end

# include <constants.asm>
board_state: ext
ship_mask: ext
y_min: ext
y_max: ext
pointer_hit_arr: ext
pointer_hit_matrix_arr: ext
pointer_miss_matrix_arr: ext
pointer_miss_arr: ext
bot_state: ext
bot_ship_count: ext
player_ship_count: ext
bot_word: ext
win_word: ext
player_word: ext

# include write_tty.asm
clear_tty: ext
write_bot: ext
write_player: ext
write_win: ext

check_kill_or_end>
    # в r5 - маска корабля
    # в r0 - координата y корабля 
    # в r1 - координата x корабля
    # в r2 - массив состояния кораблей

    # проверяем, горизонтальный ли корабль
    add r0, r2, r4
    add r0, r4, r4
    ldw r4, r4 # состояние корабля

    # нащупываем левую границу
    ldi r3, 0 # количество сдвигов влево

    left:
    tst r1 
    blt left_scan_done # значит влево нет

    and r4, r5, r6 # в r6 - есть ли корабль в такой клетке
    tst r6
    beq left_scan_done # значит корабля там нет

    ldi r6, ship_mask
    ldw r6, r7 # загружаем переменную для хранения текущей маски 
    or r5, r7, r7 # запомнили место удара
    stw r6, r7 # записали

    shl r5, r5, 1 # cдвигаем
    inc r3 # увеличиваем число сдвигов 
    br left

    # нащупываем правую границу 
    left_scan_done:
    restore_left_shift: # откатываем сдвиг
    tst r3 
    beq restore_left_shift_done
    shr r5, r5, 1
    dec r3
    br restore_left_shift
    restore_left_shift_done:

    right:
    ldi r6, 9 # проверка на край
    cmp r1, r6
    bgt right_scan_done # значит вправо нет

    and r4, r5, r6 # в r6 - есть ли корабль в такой клетке
    tst r6
    beq right_scan_done # значит корабля там нет

    ldi r6, ship_mask
    ldw r6, r7 # загружаем переменную для хранения текущей маски 
    or r5, r7, r7 # запомнили место удара
    stw r6, r7 # записали

    shr r5, r5, 1 # cдвигаем
    inc r3 # увеличиваем число сдвигов 
    br right

    right_scan_done:
    restore_right_shift: # откатываем сдвиг
    tst r3 
    beq restore_right_shift_done
    shl r5, r5, 1
    dec r3
    br restore_right_shift
    restore_right_shift_done:

    # проверка, горизонтален ли корабль, если да, то в переменной ship_mask больше 1 еденицы
    ldi r3, ship_mask
    ldw r3, r3

    # в переменной ship_mask обязательно еденица там же где и в r5, но если есть еще, то корабль горизонтален,
    # тогда просто сравним r5 и ship_mask, если равны, то корабль еденичный или вертикальный
    cmp r3, r5
    bne horizontal_kill_check # значит корабль вертикальный и тогда проверяем на убийство

    # провекрка на вертикальный или еденичный корабль
    ldi r3, 0 # количество сдвигов вверх

    # нащупываем верхнюю границу
    up:
    tst r0
    blt up_scan_done

    add r0, r2, r4
    add r0, r4, r4
    ldw r4, r4 # состояние корабля
    and r4, r5, r6 # в r6 - есть ли корабль в такой клетке

    tst r6
    beq up_scan_done

    ldi r6, y_min
    stw r6, r0
    inc r3
    dec r0
    br up

    up_scan_done:
    restore_up_shift: # откатываем Y
    tst r3 
    beq restore_up_shift_done
    inc r0
    dec r3
    br restore_up_shift
    restore_up_shift_done:

    down:
    ldi r6, 9 # проверка на край
    cmp r0, r6
    bgt down_scan_done # значит вниз нет

    add r0, r2, r4
    add r0, r4, r4
    ldw r4, r4 # состояние корабля
    and r4, r5, r6 # в r6 - есть ли корабль в такой клетке

    tst r6
    beq down_scan_done

    ldi r6, y_max
    stw r6, r0
    inc r3
    inc r0
    br down

    down_scan_done:
    restore_down_shift: # откатываем Y
    tst r3 
    beq restore_down_shift_done
    dec r0
    dec r3
    br restore_down_shift
    restore_down_shift_done:

    br vertical_kill_check

    horizontal_kill_check: 
    ldi r4, pointer_hit_arr
    ldw r4, r4
    add r4, r0, r4
    add r4, r0, r4
    ldw r4, r4 # загружаем удареные корабли

    and r4, r3, r4 # маска корабля and удареные палубы
    cmp r4, r3 # если не равны, то корабль еще не убит 
    bne cleanup_and_return

    # значит убит, и если это был ход бота, меняю ему состояние на 0,
    ldi r1, pointer_hit_matrix_arr
    ldw r1, r1
    ldi r4, 0xff56
    cmp r1, r4
    bne dec_count_ship_bot # значит ход не бота

    ldi r6, player_ship_count # уменьшаем количество кораблей
    ldw r6, r4
    dec r4
    stw r6, r4

    ldi r1, bot_state
    ldi r4, 0
    stw r1, r4
    br build_horizontal_aoe

    dec_count_ship_bot:
    ldi r6, bot_ship_count # уменьшаем количество кораблей
    ldw r6, r4
    dec r4
    stw r6, r4

    build_horizontal_aoe:
    ldi r1, pointer_miss_matrix_arr
    ldw r1, r1
    add r1, r0, r1
    add r1, r0, r1

    ldi r4, pointer_miss_arr
    ldw r4, r4
    add r4, r0, r4
    add r4, r0, r4

    ldw r4, r7

    shl r3, r6, 1 # закрашиваю слева от корабля
    or r3, r6, r3
    shr r3, r6, 1 # закрашиваю справа от корабля
    or r3, r6, r3

    or r7, r3, r7 # сливаю с уже закрашенными
    stw r4, r7 # применяю (в RAM)

    # --- ДИНАМИЧЕСКИЙ СДВИГ 1 (ТЕКУЩАЯ СТРОКА ГОРИЗ) ---
    move r7, r2
    ldi r5, pointer_miss_matrix_arr
    ldw r5, r5
    push r6
    ldi r6, 0xff40
    cmp r5, r6
    pop r6
    bne skip_horizontal_matrix_shift_1
    shl r2, r2, 2  # Сдвигаем на 2 если это матрица бота (80a2)
    skip_horizontal_matrix_shift_1:
    stw r1, r2 # вывожу на экран

    inc r4 # закрашиваю снизу от корабля
    inc r4
    inc r1
    inc r1

    ldw r4, r7
    or r7, r3, r7
    stw r4, r7 # применяю (в RAM)

    # --- ДИНАМИЧЕСКИЙ СДВИГ 2 (СТРОКА НИЖЕ ГОРИЗ) ---
    move r7, r2
    ldi r5, pointer_miss_matrix_arr
    ldw r5, r5
    push r6
    ldi r6, 0xff40
    cmp r5, r6
    pop r6
    bne skip_horizontal_matrix_shift_2
    shl r2, r2, 2
    skip_horizontal_matrix_shift_2:
    stw r1, r2 # вывожу на экран

    dec r4 # закрашиваю сверху от корабля
    dec r4
    dec r4 
    dec r4
    dec r1
    dec r1
    dec r1
    dec r1

    ldw r4, r7
    or r7, r3, r7
    stw r4, r7 # применяю (в RAM)

    # --- ДИНАМИЧЕСКИЙ СДВИГ 3 (СТРОКА ВЫШЕ ГОРИЗ) ---
    move r7, r2
    ldi r5, pointer_miss_matrix_arr
    ldw r5, r5
    push r6
    ldi r6, 0xff40
    cmp r5, r6
    pop r6
    bne skip_horizontal_matrix_shift_3
    shl r2, r2, 2
    skip_horizontal_matrix_shift_3:
    stw r1, r2 # вывожу на экран

    br cleanup_and_return

    vertical_kill_check:
    # проверка, убили ли корабль
    ldi r4, y_min
    ldw r4, r4
    ldi r6, y_max
    ldw r6, r6  

    ldi r1, pointer_hit_arr
    ldw r1, r1
    add r4, r1, r1
    add r4, r1, r1
    dec r1
    dec r1
    scan_vertical_cells:
    cmp r4, r6
    bgt mark_ship_as_sunk

    inc r1
    inc r1

    ldw r1, r7
    inc r4

    and r7, r5, r7 
    tst r7
    beq cleanup_and_return
    br scan_vertical_cells

    mark_ship_as_sunk:
    # значит убит, и если это был ход бота, меняю ему состояние на 0,
    ldi r4, pointer_hit_matrix_arr
    ldw r4, r4
    ldi r6, 0xff56
    cmp r4, r6
    bne dec_count_ship_bot2 # значит ход не бот

    ldi r6, player_ship_count # уменьшаем количество кораблей игрока
    ldw r6, r4
    dec r4
    stw r6, r4

    ldi r6, bot_state
    ldi r4, 0
    stw r6, r4

    br build_vertical_aoe       # ИСПРАВЛЕНИЕ: ЖИЗНЕННО ВАЖНЫЙ ПРЫЖОК! Чтобы не отнять корабль еще и у бота!

    dec_count_ship_bot2:
    ldi r6, bot_ship_count # уменьшаем количество кораблей бота
    ldw r6, r4
    dec r4
    stw r6, r4


    build_vertical_aoe:
    # выкидываем ореол
    ldi r4, y_min
    ldw r4, r4
    ldi r6, y_max
    ldw r6, r6

    shl r5, r7, 1 # делаем ореол
    or r5, r7, r5
    shr r5, r7, 1
    or r5, r7, r5

    ldi r7, pointer_miss_arr
    ldw r7, r7
    add r7, r4, r7    
    add r7, r4, r7
    ldi r1, pointer_miss_matrix_arr
    ldw r1, r1
    add r1, r4, r1
    add r1, r4, r1

    # делаем ореол на клетку выше
    dec r7
    dec r7
    dec r1
    dec r1
    ldw r7, r2 # состояние на клетку выше
    or r2, r5, r3 # мерджим

    # --- ДИНАМИЧЕСКИЙ СДВИГ 1 (СТРОКА ВЫШЕ ВЕРТИК) ---
    move r3, r2
    ldi r0, pointer_miss_matrix_arr
    ldw r0, r0
    push r6
    ldi r6, 0xff40
    cmp r0, r6
    pop r6
    bne skip_vertical_matrix_shift_1
    shl r2, r2, 2  # Сдвигаем на 2 если это матрица бота (80a2)
    skip_vertical_matrix_shift_1:
    stw r1, r2 # вывожу на экран
    stw r7, r3 # RAM: обвели на клетку выше 

    inc r7 
    inc r7
    inc r1 
    inc r1

    ldw r7, r2 # состояние текущей клетки (y_min)
    or r2, r5, r3 # мерджим

    # --- ДИНАМИЧЕСКИЙ СДВИГ 2 (ПЕРВАЯ ПАЛУБА ВЕРТИК) ---
    move r3, r2
    ldi r0, pointer_miss_matrix_arr
    ldw r0, r0
    push r6
    ldi r6, 0xff40
    cmp r0, r6
    pop r6
    bne skip_vertical_matrix_shift_2
    shl r2, r2, 2
    skip_vertical_matrix_shift_2:
    stw r1, r2 # вывожу на экран
    stw r7, r3 # RAM: y_min обвели

    scan_vertical_body:
    cmp r4, r6
    beq single_cell_ship # значит однопалубный или осталась одна клетка

    inc r4 
    inc r7
    inc r7
    inc r1
    inc r1

    ldw r7, r2 
    or r2, r5, r3 # мерджим

    # --- ДИНАМИЧЕСКИЙ СДВИГ 3 (ТЕЛО КОРАБЛЯ ВЕРТИК) ---
    move r3, r2
    ldi r0, pointer_miss_matrix_arr
    ldw r0, r0
    push r6
    ldi r6, 0xff40
    cmp r0, r6
    pop r6
    bne skip_vertical_matrix_shift_3
    shl r2, r2, 2
    skip_vertical_matrix_shift_3:
    stw r1, r2 # вывожу на экран
    stw r7, r3 # RAM

    br scan_vertical_body

    single_cell_ship:
    inc r7 
    inc r7
    inc r1 
    inc r1

    ldw r7, r2 # состояние на клетку ниже
    or r2, r5, r3 # мерджим

    # --- ДИНАМИЧЕСКИЙ СДВИГ 4 (СТРОКА НИЖЕ ВЕРТИК) ---
    move r3, r2
    ldi r0, pointer_miss_matrix_arr
    ldw r0, r0
    push r6
    ldi r6, 0xff40
    cmp r0, r6
    pop r6
    bne skip_vertical_matrix_shift_4
    shl r2, r2, 2
    skip_vertical_matrix_shift_4:
    stw r1, r2 # вывожу на экран
    stw r7, r3 # RAM

    cleanup_and_return:
    ldi r0, ship_mask
    ldi r1, 0
    stw r0, r1
    rts
        

bot_win>
    jsr clear_tty
    jsr write_bot
    
    ldi r1, 32
    stb r0, r1

    jsr write_win
    rts

player_win>
    jsr clear_tty
    jsr write_player
    
    ldi r1, 32
    stb r0, r1

    jsr write_win
    rts
    
end.
