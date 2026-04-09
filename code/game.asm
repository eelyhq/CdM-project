rsect game

# include constants 
bot_ship_count: ext
board_state_fire_bot: ext
x_hor_st: ext
y_hor_st: ext
board_state_hit_bot: ext
board_state_bot: ext
pointer_hit_matrix_arr: ext
pointer_miss_matrix_arr: ext
pointer_miss_arr: ext
board_state_miss_bot: ext
pointer_hit_arr: ext
player_ship_count: ext
bot_state: ext
hit_start_x: ext
hit_start_y: ext
target_dir: ext
board_state_miss: ext
curr_hit_x: ext
curr_hit_y: ext
prev_btn_state: ext
board_state_hit: ext
board_state: ext
ship_mask: ext
y_min: ext
y_max: ext
bot_word: ext
win_word: ext
player_word: ext

game>
    # СТРЕЛЬБА ПО ОЧЕРЕДИ-------------------------------
    # ВЫСТРЕЛ ИГРОКА
    player_hit:
    ldi r0, bot_ship_count
    ldw r0, r0
    tst r0
    beq player_win

    ldi r5, 0b1000000000000 # для добавления нулей в маску

    ldi r4, 0xff00 # адрес первой строки

    ldi r1, board_state_fire_bot

    ldw r1, r1                        
    move r5, r7 # в r5 маска
    or r1, r7, r7
    stw r4, r7 # пишем в первую строку корабль 
    shr r5, r5, 3


    # cохраняем начальные координаты для проверки границ
    ldi r1, 0
    ldi r0, x_hor_st
    stw r0, r1
    ldi r0, y_hor_st
    stw r0, r1

    pop r7
    push r7
    #--------------------------------------------


    check_button_fire:

    ldi r0, 0xff80
    ldb r0, r1

    # детектор фронта----------

    ldi r3, prev_btn_state 
    ldb r3, r2
    stb r3, r1

    not r2, r2

    and r2, r1, r2
    
    #--------------------------

    check_left_fire:
        ldi r3, 1
        and r2,r3,r7
        tst r7
        beq check_up_fire

        # проверка на границы
        ldi r3, x_hor_st
        ldw r3, r3
        tst r3
        beq check_button_fire
        
        dec r3
        ldi r2, x_hor_st
        stw r2, r3  

        # Отрисовка
        ldi r0, y_hor_st
        ldw r0, r0
        ldi r1, board_state_fire_bot
        add r1, r0, r1
        add r1, r0, r1
        ldw r1, r1      # r1 = фон

        shl r5, r5, 1   # Сдвигаем сам курсор влево
        move r1, r7     # Копируем фон
        or r5, r7, r7   # r7 = фон + курсор
        shl r7, r7, 3   # Сдвигаем ВСЁ на 3 бита для матрицы 0xff00
        stw r4, r7      # Выводим на экран
        br check_button_fire

    check_up_fire:
        ldi r3, 0b10
        and r2,r3,r7
        tst r7
        beq check_right_fire

        # проверка на границы
        ldi r3, y_hor_st
        ldw r3, r3
        tst r3
        beq check_button_fire

        # 1. СТИРАЕМ курсор со старой строки
        ldi r0, board_state_fire_bot
        add r0, r3, r0
        add r0, r3, r0
        ldw r0, r7      # Берем чистый фон старой строки
        shl r7, r7, 3   # Сдвиг для матрицы 8070
        stw r4, r7      # Рисуем чистый фон (стираем курсор)

        # 2. Обновляем координаты и указатель экрана
        dec r3
        ldi r2, y_hor_st
        stw r2, r3      # Сохранили новый Y
        dec r4
        dec r4          # Сдвинули указатель экрана (r4) на строку вверх

        # 3. РИСУЕМ курсор на новой строке
        ldi r0, board_state_fire_bot
        add r0, r3, r0
        add r0, r3, r0
        ldw r0, r7      # r7 = фон новой строки
        or r5, r7, r7   # Добавляем курсор
        shl r7, r7, 3   # Сдвиг для матрицы 8070
        stw r4, r7      # Выводим на экран
        br check_button_fire

    check_right_fire:
        ldi r3, 0b100
        and r2,r3,r7
        tst r7
        beq check_down_fire

        # проверка на границы
        ldi r3, x_hor_st
        ldw r3, r3
        ldi r2, 9
        cmp r2, r3
        beq check_button_fire

        inc r3
        ldi r2, x_hor_st
        stw r2, r3

        # Отрисовка
        ldi r0, y_hor_st
        ldw r0, r0
        ldi r1, board_state_fire_bot
        add r1, r0, r1
        add r1, r0, r1
        ldw r1, r1      # r1 = фон

        shr r5, r5, 1   # Сдвигаем курсор вправо
        move r1, r7
        or r5, r7, r7   # Сливаем фон и курсор
        shl r7, r7, 3   # Сдвиг на 3 для экрана 8070
        stw r4, r7      # Рисуем
        br check_button_fire

    check_down_fire:
        ldi r3, 0b1000
        and r2,r3,r7
        tst r7
        beq check_fire

        # проверка на границы
        ldi r3, y_hor_st
        ldw r3, r3
        ldi r2, 9
        cmp r2, r3
        beq check_button_fire

        # 1. СТИРАЕМ курсор со старой строки
        ldi r0, board_state_fire_bot
        add r0, r3, r0
        add r0, r3, r0
        ldw r0, r7      
        shl r7, r7, 3   
        stw r4, r7      

        # 2. Обновляем координаты и указатель
        inc r3
        ldi r2, y_hor_st
        stw r2, r3      # Сохранили новый Y
        inc r4
        inc r4          # Сдвинули указатель экрана вниз

        # 3. РИСУЕМ курсор на новой строке
        ldi r0, board_state_fire_bot
        add r0, r3, r0
        add r0, r3, r0
        ldw r0, r7      
        or r5, r7, r7   
        shl r7, r7, 3   
        stw r4, r7      
        br check_button_fire

    check_fire:
        ldi r3, 0b100000
        and r2, r3, r7        
        tst r7
        beq check_button_fire

        ldi r1, y_hor_st
        ldw r1, r1

        ldi r0, board_state_hit_bot # проверка на повторный удар в одно и то же место
        add r0, r1, r0
        add r0, r1, r0
        ldw r0, r0

        and r0, r5, r0

        tst r0
        bne check_button_fire

        ldi r0, board_state_miss_bot
        add r0, r1, r0
        add r0, r1, r0
        ldw r0, r0

        and r0, r5, r0
        tst r0
        bne check_button_fire


        ldi r0, x_hor_st
        ldw r0, r0

        move r1, r7       # r7 = Y (понадобится для записи попаданий)

        ldi r2, board_state_bot
        add r2, r1, r2
        add r2, r1, r2
        ldw r2, r2        # Загружаем строку бота

        tst r0
        bz end_loop20
        loop20:
        shl r2, r2, 1
        dec r0
        tst r0
        bne loop20
        end_loop20:
        
        ldi r0, 0
        stw r4, r0

        ldi r0, 0b1000000000
        and r0, r2, r0    # ПРОВЕРКА ПОПАДАНИЯ (Устанавливает Z-флаг)
        
        beq miss          # Если корабля нет (Z=1), прыгаем в промах

        hit:
        ldi r3, 0xff14  
        add r3, r7, r3
        add r3, r7, r3    # r3 = адрес экрана попаданий (сдвиг 2 влево)

        ldi r6, board_state_hit_bot
        add r6, r7, r6
        add r6, r7, r6    # r6 = адрес памяти попаданий

        ldw r6, r4        # Читаем старые попадания из памяти
        or r4, r5, r4     # Накладываем новое попадание (по стандартной маске r5)
        stw r6, r4        # Сохраняем обратно в память

        shl r4, r4, 2     # Сдвигаем ВСЮ СТРОКУ на 2 влево для матрицы 805c
        stw r3, r4        # Выводим на матрицу попаданий

        # Проверка на убийство / конец игры
        ldi r0, y_hor_st
        ldw r0, r0
        ldi r1, x_hor_st
        ldw r1, r1
        ldi r2, board_state_bot

        ldi r3, pointer_hit_matrix_arr
        ldi r4, 0xff14
        stw r3, r4
        ldi r3, pointer_miss_matrix_arr
        ldi r4, 0xff2a
        stw r3, r4 

        ldi r3, pointer_miss_arr
        ldi r4, board_state_miss_bot
        stw r3, r4 

        ldi r3, pointer_hit_arr
        ldi r4, board_state_hit_bot
        stw r3, r4 

        jsr check_kill_or_end


        br player_hit   # Возвращаемся к опросу (не сбрасываем курсор)

        miss:
        ldi r3, 0xff2a
        add r3, r7, r3
        add r3, r7, r3    # r3 = адрес экрана промахов (без сдвига)

        ldi r6, board_state_miss_bot
        add r6, r7, r6
        add r6, r7, r6

        ldw r6, r4        # Читаем старые промахи
        or r4, r5, r4     # Добавляем новый
        stw r6, r4        # Сохраняем в память
        stw r3, r4        # Выводим на экран (матрица 10 клеток, сдвиг не нужен)

    br bot_hit

    # ВЫСТРЕЛ БОТА
    bot_hit:

    ldi r0, player_ship_count
    ldw r0, r0
    tst r0
    beq bot_win

    # Сбрасывать счетчик ретраев больше не нужно, переходим сразу к логике бота
    normal_bot_flow:
    ldi r0, bot_state
    ldw r0, r0
    tst r0 
    beq next_cell 

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
    beq blocked_dir     
    dec r1
    br good2

    dir1:
    ldi r2, 9
    cmp r2, r0
    beq blocked_dir
    inc r0
    br good2

    dir2:
    ldi r2, 9
    cmp r2, r1
    beq blocked_dir
    inc r1
    br good2

    dir3:
    tst r0              
    beq blocked_dir
    dec r0
    br good2

    blocked_dir:
    br miss2_no_write   # Смена направления, если уперлись в стену

    next_cell:
    ldi r2, 0xff82
    ldw r2, r0 # сгенерировали x
    ldw r2, r1 # сгенерировали y

    # Берем остаток от деления на 10
    ldi r2, 0x000f
    and r2, r0, r0 # берем первые 4 бита
    and r2, r1, r1
    ldi r3, 10

    mod10X2:
    cmp r3, r0
    bgt mod10Y2    # ИСПРАВЛЕНИЕ: строго bgt, чтобы 10 не проходило!
    sub r0, r3, r0 # отнимаем 10
    br mod10X2

    mod10Y2:
    cmp r3, r1
    bgt good2      # ИСПРАВЛЕНИЕ: строго bgt
    sub r1, r3, r1 # отнимаем 10
    br mod10Y2

    # --- ШАГАЕМ ВПРАВО, ЕСЛИ КЛЕТКА ЗАНЯТА (Состояние 0) ---
    scan_next_cell:
    inc r0              # x = x + 1
    ldi r2, 10
    cmp r2, r0          # (10 - X)
    bgt good2           # ИСПРАВЛЕНИЕ: bgt! Если X < 10 (10-X > 0), идем проверять клетку
    ldi r0, 0           # Иначе (дошли до края): x = 0
    inc r1              # y = y + 1
    cmp r2, r1          # (10 - Y)
    bgt good2           # ИСПРАВЛЕНИЕ: bgt! Если y < 10, идем проверять клетку
    ldi r1, 0           # Иначе (дошли до конца поля 9:9): y = 0
    br good2            # Идем проверять клетку 0:0

    good2:
    check_again_hit:
    # --- ГЕНЕРАЦИЯ МАСКИ (Единая для всех проверок и записи) ---
    ldi r4, 0b1000000000
    move r0, r3 # r3 = координата X
    loop_mask:
    tst r3
    beq end_loop_mask
    shr r4, r4, 1
    dec r3
    br loop_mask
    end_loop_mask:
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
    beq scan_next_cell  # Состояние 0 -> шагаем вправо!
    br miss2_no_write   # Состояние 1/2 -> меняем направление

    check_hit_arr:
    ldi r2, board_state_hit
    add r1, r2, r2
    add r1, r2, r2
    ldw r2, r3 
    and r4, r3, r3 # маска & строка попаданий
    tst r3
    beq good3           # Если 0 -> клетка абсолютно чистая!

    # ЕСЛИ УЖЕ ПОПАДАЛИ СЮДА:
    ldi r2, bot_state
    ldw r2, r2
    tst r2
    beq scan_next_cell  # Состояние 0 -> шагаем вправо!

    ldi r3, 1
    cmp r2, r3
    beq miss2_no_write  # Состояние 1 -> направление заблокировано, меняем

    # Состояние 2 -> Проскакиваем уже убитую клетку!
    ldi r3, curr_hit_x
    stw r3, r0
    ldi r3, curr_hit_y
    stw r3, r1
    br apply_direction

    good3:
    ldi r2, board_state
    add r1, r2, r2
    add r1, r2, r2
    ldw r2, r3 
    and r4, r3, r3 # маска & корабли
    tst r3
    beq miss2           # Корабля нет -> пишем промах!

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
    br bot_hit

    # --- ЛОГИКА "ГЛУХИХ" ПРОМАХОВ ---
    miss2_no_write:
    ldi r2, bot_state
    ldw r2, r2
    ldi r5, 1
    cmp r5, r2
    beq change_dir_nw
    ldi r5, 2
    cmp r5, r2
    bne switch_move
    br change_dir_opp_nw

    change_dir_nw:
    ldi r2, target_dir
    ldw r2, r5
    inc r5
    ldi r6, 0b11
    and r5, r6, r5     
    stw r2, r5
    br normal_bot_flow  

    change_dir_opp_nw:
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
    miss2:
    ldi r2, bot_state
    ldw r2, r2
    ldi r5, 1
    cmp r5, r2
    beq change_dir  
    ldi r5, 2
    cmp r5, r2
    bne do_miss_write 

    change_dir_opposite: 
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
    br do_miss_write   

    change_dir:
    ldi r2, target_dir
    ldw r2, r5
    inc r5
    ldi r6, 0b11
    and r5, r6, r5     
    stw r2, r5

    do_miss_write:
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

    br switch_move

    switch_move:
    br player_hit

    # =====================================================================
    # ФУНКЦИЯ ПРОВЕРКИ УБИЙСТВА И ОТРИСОВКИ ОРЕОЛА
    # =====================================================================
    check_kill_or_end:
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
    blt next17 # значит влево нет

    and r4, r5, r6 # в r6 - есть ли корабль в такой клетке
    tst r6
    beq next17 # значит корабля там нет

    ldi r6, ship_mask
    ldw r6, r7 # загружаем переменную для хранения текущей маски 
    or r5, r7, r7 # запомнили место удара
    stw r6, r7 # записали

    shl r5, r5, 1 # cдвигаем
    inc r3 # увеличиваем число сдвигов 
    br left

    # нащупываем правую границу 
    next17:
    cancel_shift: # откатываем сдвиг
    tst r3 
    beq end_cancel_shift
    shr r5, r5, 1
    dec r3
    br cancel_shift
    end_cancel_shift:

    right:
    ldi r6, 9 # проверка на край
    cmp r1, r6
    bgt next18 # значит вправо нет

    and r4, r5, r6 # в r6 - есть ли корабль в такой клетке
    tst r6
    beq next18 # значит корабля там нет

    ldi r6, ship_mask
    ldw r6, r7 # загружаем переменную для хранения текущей маски 
    or r5, r7, r7 # запомнили место удара
    stw r6, r7 # записали

    shr r5, r5, 1 # cдвигаем
    inc r3 # увеличиваем число сдвигов 
    br right

    next18:
    cancel_shift2: # откатываем сдвиг
    tst r3 
    beq end_cancel_shift2
    shl r5, r5, 1
    dec r3
    br cancel_shift2
    end_cancel_shift2:

    # проверка, горизонтален ли корабль, если да, то в переменной ship_mask больше 1 еденицы
    ldi r3, ship_mask
    ldw r3, r3

    # в переменной ship_mask обязательно еденица там же где и в r5, но если есть еще, то корабль горизонтален,
    # тогда просто сравним r5 и ship_mask, если равны, то корабль еденичный или вертикальный
    cmp r3, r5
    bne kill_check_hor # значит корабль вертикальный и тогда проверяем на убийство

    # провекрка на вертикальный или еденичный корабль
    ldi r3, 0 # количество сдвигов вверх

    # нащупываем верхнюю границу
    up:
    tst r0
    blt next19

    add r0, r2, r4
    add r0, r4, r4
    ldw r4, r4 # состояние корабля
    and r4, r5, r6 # в r6 - есть ли корабль в такой клетке

    tst r6
    beq next19

    ldi r6, y_min
    stw r6, r0
    inc r3
    dec r0
    br up

    next19:
    cancel_shift3: # откатываем Y
    tst r3 
    beq end_cancel_shift3
    inc r0
    dec r3
    br cancel_shift3
    end_cancel_shift3:

    down:
    ldi r6, 9 # проверка на край
    cmp r0, r6
    bgt next20 # значит вниз нет

    add r0, r2, r4
    add r0, r4, r4
    ldw r4, r4 # состояние корабля
    and r4, r5, r6 # в r6 - есть ли корабль в такой клетке

    tst r6
    beq next20

    ldi r6, y_max
    stw r6, r0
    inc r3
    inc r0
    br down

    next20:
    cancel_shift4: # откатываем Y
    tst r3 
    beq end_cancel_shift4
    dec r0
    dec r3
    br cancel_shift4
    end_cancel_shift4:

    br kill_check_ver

    kill_check_hor: 
    ldi r4, pointer_hit_arr
    ldw r4, r4
    add r4, r0, r4
    add r4, r0, r4
    ldw r4, r4 # загружаем удареные корабли

    and r4, r3, r4 # маска корабля and удареные палубы
    cmp r4, r3 # если не равны, то корабль еще не убит 
    bne end_check

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
    br next21

    dec_count_ship_bot:
    ldi r6, bot_ship_count # уменьшаем количество кораблей
    ldw r6, r4
    dec r4
    stw r6, r4

    next21:
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
    bne skip_hor_sh1
    shl r2, r2, 2  # Сдвигаем на 2 если это матрица бота (80a2)
    skip_hor_sh1:
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
    bne skip_hor_sh2
    shl r2, r2, 2
    skip_hor_sh2:
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
    bne skip_hor_sh3
    shl r2, r2, 2
    skip_hor_sh3:
    stw r1, r2 # вывожу на экран

    br end_check

    kill_check_ver:
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
    loop25:
    cmp r4, r6
    bgt kill

    inc r1
    inc r1

    ldw r1, r7
    inc r4

    and r7, r5, r7 
    tst r7
    beq end_check
    br loop25

    kill:
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

    br next21_ver       # ИСПРАВЛЕНИЕ: ЖИЗНЕННО ВАЖНЫЙ ПРЫЖОК! Чтобы не отнять корабль еще и у бота!

    dec_count_ship_bot2:
    ldi r6, bot_ship_count # уменьшаем количество кораблей бота
    ldw r6, r4
    dec r4
    stw r6, r4


    next21_ver:
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
    bne skip_ver_sh1
    shl r2, r2, 2  # Сдвигаем на 2 если это матрица бота (80a2)
    skip_ver_sh1:
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
    bne skip_ver_sh2
    shl r2, r2, 2
    skip_ver_sh2:
    stw r1, r2 # вывожу на экран
    stw r7, r3 # RAM: y_min обвели

    test_one_ship:
    cmp r4, r6
    beq one_ship # значит однопалубный или осталась одна клетка

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
    bne skip_ver_sh3
    shl r2, r2, 2
    skip_ver_sh3:
    stw r1, r2 # вывожу на экран
    stw r7, r3 # RAM

    br test_one_ship

    one_ship:
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
    bne skip_ver_sh4
    shl r2, r2, 2
    skip_ver_sh4:
    stw r1, r2 # вывожу на экран
    stw r7, r3 # RAM

    end_check:
    ldi r0, ship_mask
    ldi r1, 0
    stw r0, r1
    rts
        

    bot_win:
    ldi r0, 0xff84 # clear
    stb r0,r0

    ldi r0, 0xffc0
    ldi r1, bot_word

    ldi r2, 3

    loop29:
    tst r2
    beq end_loop29
    ldb r1, r3
    stb r0, r3
    inc r1
    dec r2
    br loop29
    end_loop29:
    ldi r1, 32
    stb r0, r1
    ldi r2, 4
    ldi r1, win_word

    loop28:
    tst r2
    beq end_loop28
    ldb r1, r3
    stb r0, r3
    inc r1
    dec r2
    br loop28
    end_loop28:

    br halt_bot_win

    player_win:
    ldi r0, 0xff84 # clear
    stb r0,r0

    ldi r0, 0xffc0
    ldi r1, player_word
    ldi r2, 6

    loop26:
    tst r2
    beq end_loop26
    ldb r1, r3
    stb r0, r3
    inc r1
    dec r2
    br loop26
    end_loop26:
    ldi r1, 32
    stb r0, r1
    ldi r2, 4
    ldi r1, win_word

    loop27:
    tst r2
    beq end_loop27
    ldb r1, r3
    stb r0, r3
    inc r1
    dec r2
    br loop27
    end_loop27:

    halt_bot_win:    
        rts

end.
