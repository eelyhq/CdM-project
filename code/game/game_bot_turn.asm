rsect game_bot_turn

# include <constants.asm>
player_ship_count: ext
bot_state: ext
hit_start_x: ext
hit_start_y: ext
target_dir: ext
curr_hit_x: ext
curr_hit_y: ext
board_state_miss: ext
board_state_hit: ext
board_state: ext
pointer_hit_matrix_arr: ext
pointer_miss_matrix_arr: ext
pointer_miss_arr: ext
board_state_miss_bot: ext
pointer_hit_arr: ext

# include <game_kill_end.asm>
check_kill_or_end: ext
player_hit: ext
bot_win: ext

bot_hit>

    ldi r0, player_ship_count
    ldw r0, r0
    tst r0
    beq bot_win

    # Сбрасывать счетчик ретраев больше не нужно, переходим сразу к логике бота
    normal_bot_flow:
    ldi r0, bot_state
    ldw r0, r0
    tst r0 
    beq generate_random_cell 

    ldi r1, 1
    cmp r1, r0
    beq search_from_start # Состояние 1

    # Состояние 2
    ldi r0, curr_hit_x
    ldw r0, r0
    ldi r1, curr_hit_y
    ldw r1, r1
    br apply_direction

    search_from_start:
    ldi r0, hit_start_x
    ldw r0, r0
    ldi r1, hit_start_y
    ldw r1, r1

    apply_direction:
    ldi r2, target_dir
    ldw r2, r2

    tst r2 
    beq dir0
    dec r2
    tst r2
    beq dir1
    dec r2
    tst r2
    beq dir2
    br dir3             

    dir0:
    tst r1
    beq direction_blocked     
    dec r1
    br candidate_cell_ready

    dir1:
    ldi r2, 9
    cmp r2, r0
    beq direction_blocked
    inc r0
    br candidate_cell_ready

    dir2:
    ldi r2, 9
    cmp r2, r1
    beq direction_blocked
    inc r1
    br candidate_cell_ready

    dir3:
    tst r0              
    beq direction_blocked
    dec r0
    br candidate_cell_ready

    direction_blocked:
    br handle_miss_without_write   # Смена направления, если уперлись в стену

    generate_random_cell:
    ldi r2, 0xff82
    ldw r2, r0 # сгенерировали x
    ldw r2, r1 # сгенерировали y

    # Берем остаток от деления на 10
    ldi r2, 0x000f
    and r2, r0, r0 # берем первые 4 бита
    and r2, r1, r1
    ldi r3, 10

    normalize_random_x:
    cmp r3, r0
    bgt normalize_random_y    # ИСПРАВЛЕНИЕ: строго bgt, чтобы 10 не проходило!
    sub r0, r3, r0 # отнимаем 10
    br normalize_random_x

    normalize_random_y:
    cmp r3, r1
    bgt candidate_cell_ready      # ИСПРАВЛЕНИЕ: строго bgt
    sub r1, r3, r1 # отнимаем 10
    br normalize_random_y

    # --- ШАГАЕМ ВПРАВО, ЕСЛИ КЛЕТКА ЗАНЯТА (Состояние 0) ---
    advance_scan_cursor:
    inc r0              # x = x + 1
    ldi r2, 10
    cmp r2, r0          # (10 - X)
    bgt candidate_cell_ready           # ИСПРАВЛЕНИЕ: bgt! Если X < 10 (10-X > 0), идем проверять клетку
    ldi r0, 0           # Иначе (дошли до края): x = 0
    inc r1              # y = y + 1
    cmp r2, r1          # (10 - Y)
    bgt candidate_cell_ready           # ИСПРАВЛЕНИЕ: bgt! Если y < 10, идем проверять клетку
    ldi r1, 0           # Иначе (дошли до конца поля 9:9): y = 0
    br candidate_cell_ready            # Идем проверять клетку 0:0

    candidate_cell_ready:
    # --- ГЕНЕРАЦИЯ МАСКИ (Единая для всех проверок и записи) ---
    ldi r4, 0b1000000000
    move r0, r3 # r3 = координата X
    build_fire_mask:
    tst r3
    beq build_fire_mask_done
    shr r4, r4, 1
    dec r3
    br build_fire_mask
    build_fire_mask_done:
    # Теперь в r4 лежит идеальная маска выстрела!

    # Проверка на промахи
    ldi r2, board_state_miss
    add r1, r2, r2
    add r1, r2, r2
    ldw r2, r3 
    and r4, r3, r3 # маска & строка промахов
    tst r3
    beq check_hit_arr   # Если 0 -> не промахивались сюда, проверяем хиты

    # Если уже стреляли (промах):
    ldi r2, bot_state
    ldw r2, r2
    tst r2
    beq advance_scan_cursor  # Состояние 0 -> шагаем вправо!
    br handle_miss_without_write   # Состояние 1/2 -> меняем направление

    check_hit_arr:
    ldi r2, board_state_hit
    add r1, r2, r2
    add r1, r2, r2
    ldw r2, r3 
    and r4, r3, r3 # маска & строка попаданий
    tst r3
    beq candidate_has_ship           # Если 0 -> клетка абсолютно чистая!

    # ЕСЛИ УЖЕ ПОПАДАЛИ СЮДА:
    ldi r2, bot_state
    ldw r2, r2
    tst r2
    beq advance_scan_cursor  # Состояние 0 -> шагаем вправо!

    ldi r3, 1
    cmp r2, r3
    beq handle_miss_without_write  # Состояние 1 -> направление заблокировано, меняем

    # Состояние 2 -> Проскакиваем уже убитую клетку!
    ldi r3, curr_hit_x
    stw r3, r0
    ldi r3, curr_hit_y
    stw r3, r1
    br apply_direction

    candidate_has_ship:
    ldi r2, board_state
    add r1, r2, r2
    add r1, r2, r2
    ldw r2, r3 
    and r4, r3, r3 # маска & корабли
    tst r3
    beq handle_miss           # Корабля нет -> пишем промах!

    hit2:
    # --- ОБНОВЛЕНИЕ СОСТОЯНИЯ БОТА ---
    ldi r2, bot_state
    ldw r2, r2

    tst r2
    bne update_state_1_to_2 

    ldi r3, 1
    ldi r5, bot_state
    stw r5, r3

    ldi r3, hit_start_x
    stw r3, r0
    ldi r3, hit_start_y
    stw r3, r1

    ldi r3, target_dir
    ldi r5, 0
    stw r3, r5
    br save_hit_data

    update_state_1_to_2:
    ldi r3, 2
    ldi r5, bot_state
    stw r5, r3

    save_hit_data:
    ldi r3, curr_hit_x
    stw r3, r0
    ldi r3, curr_hit_y
    stw r3, r1

    # --- ЗАПИСЬ ПОПАДАНИЯ НА ЭКРАН (Маска уже готова в r4) ---
    ldi r2, 0xff56
    add r1, r2, r2
    add r1, r2, r2     

    ldi r5, board_state_hit
    add r1, r5, r5
    add r1, r5, r5

    ldw r5, r6      # Читаем старые попадания
    or r4, r6, r6   # r6 = старые попадания | маска нового (r4)
    stw r5, r6      # Записываем обратно в память

    move r4, r5     # ВАЖНО: Кладем маску в r5 для check_kill_or_end
    move r6, r3     # Кладем всю строку в r3 для экрана
    shl r3, r3, 3   # Сдвиг для матрицы 8086
    stw r2, r3      # Выводим попадание на экран

    # Свап X и Y перед проверкой на убийство (т.к. функция ждет r0=Y, r1=X)
    move r0, r4
    move r1, r0
    move r4, r1

    # проверка, убили ли корабль
    ldi r2, board_state

    ldi r3, pointer_hit_matrix_arr
    ldi r4, 0xff56
    stw r3, r4
    ldi r3, pointer_miss_matrix_arr
    ldi r4, 0xff40
    stw r3, r4 

    ldi r3, pointer_miss_arr
    ldi r4, board_state_miss
    stw r3, r4 

    ldi r3, pointer_hit_arr
    ldi r4, board_state_hit
    stw r3, r4 

    jsr check_kill_or_end
    br end_bot_turn

    # --- ЛОГИКА "ГЛУХИХ" ПРОМАХОВ ---
    handle_miss_without_write:
    ldi r2, bot_state
    ldw r2, r2
    ldi r5, 1
    cmp r5, r2
    beq advance_direction_no_write
    ldi r5, 2
    cmp r5, r2
    bne end_bot_turn
    br reverse_direction_no_write

    advance_direction_no_write:
    ldi r2, target_dir
    ldw r2, r5
    inc r5
    ldi r6, 0b11
    and r5, r6, r5     
    stw r2, r5
    br normal_bot_flow  

    reverse_direction_no_write:
    ldi r2, target_dir
    ldw r2, r5
    inc r5
    inc r5
    ldi r6, 0b11
    and r5, r6, r5     
    stw r2, r5

    ldi r2, hit_start_x
    ldw r2, r5
    ldi r6, curr_hit_x
    stw r6, r5
    ldi r2, hit_start_y
    ldw r2, r5
    ldi r6, curr_hit_y
    stw r6, r5
    br normal_bot_flow  

    # --- ЛОГИКА ОБЫЧНЫХ ПРОМАХОВ ---
    handle_miss:
    ldi r2, bot_state
    ldw r2, r2
    ldi r5, 1
    cmp r5, r2
    beq advance_direction  
    ldi r5, 2
    cmp r5, r2
    bne write_miss_record 

    reverse_direction: 
    ldi r2, target_dir
    ldw r2, r5
    inc r5
    inc r5
    ldi r6, 0b11
    and r5, r6, r5     
    stw r2, r5

    ldi r2, hit_start_x
    ldw r2, r5
    ldi r6, curr_hit_x
    stw r6, r5
    ldi r2, hit_start_y
    ldw r2, r5
    ldi r6, curr_hit_y
    stw r6, r5
    br write_miss_record   

    advance_direction:
    ldi r2, target_dir
    ldw r2, r5
    inc r5
    ldi r6, 0b11
    and r5, r6, r5     
    stw r2, r5

    write_miss_record:
    # Запись промаха
    ldi r2, 0xff40
    add r1, r2, r2
    add r1, r2, r2

    ldi r5, board_state_miss
    add r1, r5, r5
    add r1, r5, r5

    ldw r5, r6
    or r4, r6, r3   # r3 = старые промахи | маска (r4)
    stw r5, r3      # сохранили в память

    shl r3, r3, 2   # Сдвиг на 2 влево для промахов бота (0xff40)
    stw r2, r3      # выводим на экран

    br end_bot_turn

    end_bot_turn:
    br player_hit

end.
