rsect game_player_turn

# include constants.asm
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

# include game_kill_end.asm
check_kill_or_end: ext
bot_hit: ext
player_win: ext

player_hit>
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
        bz shift_fire_row_to_x_done
        shift_fire_row_to_x:
        shl r2, r2, 1
        dec r0
        tst r0
        bne shift_fire_row_to_x
        shift_fire_row_to_x_done:
        
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

end.
