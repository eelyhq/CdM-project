rsect player_ships_replacement

# include constants.asm
ships_array: ext
pointer_len_ship: ext
place_array: ext
board_state: ext
x_hor_st: ext
y_hor_st: ext
x_hor_fn: ext
y_hor_fn: ext
prev_btn_state: ext
x_ver: ext
x_ver_st: ext
y_ver: ext
y_ver_st: ext
y_ver_fn: ext

# include replacement.asm
check_placement: ext

exit: 
    rts

player_ships_replacement> 
    ldi r5, ships_array # array with length of ships 
    ldi r6, pointer_len_ship
    stw r6, r5 # mem[pointer_len_ship] = ships_array[0]

    return:
        ldi r6, pointer_len_ship
        ldw r6, r6 # r6 = pointer_len_ship
        ldb r6, r6 # r6 = *r6

        ldi r0, place_array
        ldi r1, 11
        ldi r2, 0xffc0

        # надпись---------
        ldi r3, 0xffc2
        stb r3, r3  
        tst r6
        beq exit

    loop3:
    ldb r0, r3
    stb r2, r3

    inc r0

    dec r1

    tst r1
    bne loop3

    ldi r3, 48
    add r6, r3, r3
    stb r2, r3

    ldi r1, 11

    loop4:
    ldb r0, r3
    stb r2, r3

    inc r0

    dec r1

    tst r1
    bne loop4
    #----------------

    push r6 # кладем его в стек, чтобы осовободить регистр

    ldi r7, 0b0 # для создания маски горизонтального корабля
    ldi r3, 0b1000000000 # для добавления нулей в маску

    make_ship: # создаем маску на основании размера корабля
    or r3, r7, r7
    shr r7,r7, 1
    dec r6
    tst r6
    bne make_ship

    shl r7,r7, 1 # откат, так как сделали лишний из-за особенности цикла

    ldi r4, 0xff6a # адрес первой строки

    ldi r1, board_state

    ldw r1, r1
    move r7, r5 # в r5 маска
    or r1, r7, r7
    stw r4,r7 # пишем в первую строку корабль 

    # cохраняем начальные координаты для проверки границ
    ldi r1, 0
    ldi r0, x_hor_st
    stw r0, r1
    ldi r0, y_hor_st
    stw r0, r1

    pop r7
    push r7

    ldi r1, -1
    add r1, r7, r1
    ldi r0, x_hor_fn
    stw r0, r1
    #--------------------------------------------

    check_button_hor:

    ldi r0, 0xff80
    ldb r0, r1

    # детектор фронта----------

    ldi r3, prev_btn_state 
    ldb r3, r2
    stb r3, r1

    not r2, r2

    and r2, r1, r2
    
    #--------------------------

    check_left_hor:
        ldi r3, 1
        and r2,r3,r7
        tst r7
        beq check_up_hor

        # проверка на границы
        ldi r3, x_hor_st
        ldw r3, r3

        tst r3
        beq check_button_hor

        dec r3
        ldi r2, x_hor_st
        stw r2, r3  

        ldi r2, x_hor_fn
        ldw r2, r3
        dec r3
        stw r2, r3
        #-------------------

        ldi r0, y_hor_st
        ldw r0, r0
        ldi r1, board_state
        add r1, r0, r1
        add r1, r0, r1
        ldw r1, r1

        shl r5, r5, 1 
        move r5, r7
        or r1, r7, r7
        stw r4, r7
        br check_button_hor

    check_up_hor:
        ldi r3, 0b10
        and r2,r3,r7
        tst r7
        beq check_right_hor

        # проверка на границы
        ldi r3, y_hor_st
        ldw r3, r3

        tst r3
        beq check_button_hor

        dec r3
        ldi r2, y_hor_st
        stw r2, r3

        #-------------------

        ldi r0, y_hor_st
        ldw r0, r0
        ldi r1, board_state
        add r1, r0, r1
        add r1, r0, r1
        inc r1
        inc r1
        
        ldw r1,r2
        stw r4,r2
        dec r1
        dec r1
        
        ldw r1, r1
        

        move r5, r7
        or r1, r7, r7

    
        
        dec r4
        dec r4
        stw r4, r7
        br check_button_hor

    check_right_hor:
        ldi r3, 0b100
        and r2,r3,r7
        tst r7
        beq check_down_hor

        # проверка на границы
        ldi r3, x_hor_fn
        ldw r3, r3

        ldi r2, 9
        cmp r2, r3
        beq check_button_hor

        inc r3
        ldi r2, x_hor_fn
        stw r2, r3

        ldi r2, x_hor_st
        ldw r2, r3
        inc r3
        stw r2, r3
        #------------------

        ldi r0, y_hor_st
        ldw r0, r0
        ldi r1, board_state
        add r1, r0, r1
        add r1, r0, r1
        ldw r1, r1


        shr r5, r5, 1 
        move r5, r7
        or r1, r7, r7
        stw r4, r7
        br check_button_hor

    check_down_hor:
        ldi r3, 0b1000
        and r2,r3,r7
        tst r7
        beq check_reverse_hor

        # проверка на границы
        ldi r3, y_hor_st
        ldw r3, r3

        ldi r2, 9
        cmp r2, r3
        beq check_button_hor

        inc r3
        ldi r2, y_hor_st
        stw r2, r3
        #-----------------

        ldi r0, y_hor_st
        ldw r0, r0
        ldi r1, board_state
        add r1, r0, r1
        add r1, r0, r1
        dec r1
        dec r1
        ldw r1, r2
        stw r4, r2

        inc r1
        inc r1

        ldw r1, r1
        
        move r5, r7
        or r1, r7, r7
        
        inc r4
        inc r4
        stw r4, r7
        br check_button_hor

    check_reverse_hor:
        ldi r3, 0b10000
        and r2,r3,r7
        tst r7
        beq check_place_hor
        ldi r7, y_hor_st
        ldw r7, r7

        ldi r6, board_state
        add r6, r7, r6
        add r6, r7, r6
        ldw r6, r6

        stw r4,r6

        br check_button_ver
        
    check_place_hor:
        ldi r3, 0b100000
        and r2, r3, r7        
        tst r7
        beq check_button_hor

        # Подготовка к вызову функции проверки
        ldi r0, y_hor_st
        ldw r0, r0            
        move r5, r1           

        jsr check_placement   
        
        tst r2                
        bne check_button_hor  

        # --- ЕСЛИ МОЖНО СТАВИТЬ (УСПЕХ) ---

        # 1. Записываем корабль в массив board_state
        ldi r3, board_state
        add r0, r3, r3
        add r0, r3, r3        

        ldw r3, r1            # ИСПРАВЛЕНО: читаем из адреса r3 в регистр r1
        or r5, r1, r1         
        stw r3, r1            
        
        # 2. Передвигаем указатель на следующий размер корабля
        ldi r0, pointer_len_ship
        ldw r0, r1            # ИСПРАВЛЕНО: читаем из адреса r0 в регистр r1
        inc r1
        inc r1
        stw r0, r1

        # 3. Выравниваем стек
        pop r7

        br return

    check_button_ver:
    #r0 - y
    #r1 - x

    ldi r0, 0xff68 # координата y
    ldi r1, 0b1000000000 # координата x


    # заполняем начальные координаты
    ldi r2, x_ver
    stw r2, r1
    ldi r2, y_ver
    stw r2, r0

    ldi r1, 0

    ldi r0, x_ver_st
    stw r0, r1

    ldi r0, y_ver_st
    stw r0, r1


    pop r7
    push r7

    ldi r1, -1 # заполняем нижюю координату
    add r1, r7, r1
    ldi r0, y_ver_fn
    stw r0, r1
    #---------------------------


    print_shipp:
    pop r7
    push r7

    move r7, r6

    ldi r0, y_ver
    ldw r0,r0

    ldi r2, y_ver_st # нужна для сохранения уже поставленых суден
    ldw r2, r2
    dec r2


    ldi r1, x_ver
    ldw r1, r1
    print_ship:
    ldi r3, 2
    add r0, r3,r0
    inc r2

    ldi r3, board_state
    add r3, r2, r3
    add r3, r2, r3
    ldw r3, r3

    or r1, r3, r3

    stw r0, r3

    dec r6
    tst r6
    bne print_ship


    button_ver:

    ldi r5, 0xff80
    ldb r5, r5 # получили кнопку


    # детектор фронта----------
    ldi r3, prev_btn_state 
    ldb r3, r2
    stb r3, r5

    not r2, r2

    and r2, r5, r2
    #--------------------------

    check_left_ver:
        ldi r3, 1
        and r2,r3,r7
        tst r7
        beq check_up_ver

        # проверка на границы
        ldi r0, x_ver_st
        ldw r0, r0

        tst r0
        beq button_ver

        dec r0
        ldi r1, x_ver_st
        stw r1, r0
        #---------------------

        ldi r0, x_ver
        ldw r0, r1

        shl r1, r1, 1
        stw r0, r1
        br print_shipp
        

    check_up_ver:
        ldi r3, 0b10
        and r2,r3,r7
        tst r7
        beq check_right_ver

        # проверка на границы
        ldi r0, y_ver_st
        ldw r0, r0

        tst r0
        beq button_ver

        dec r0
        ldi r1, y_ver_st
        stw r1, r0

        ldi r0, y_ver_fn
        ldw r0, r1
        dec r1
        stw r0, r1
        #---------------------

        ldi r1, y_ver
        ldw r1, r0

        ldi r3, y_ver_fn
        ldw r3, r3
        inc r3

        ldi r5, board_state
        add r5, r3, r5
        add r5, r3, r5
        
        ldw r5, r5

        pop r7
        push r7

        move r0, r4
        add r4, r7, r4
        add r4, r7, r4
        stw r4, r5      

        dec r0
        dec r0

        stw r1, r0

        br print_shipp


    check_right_ver:
        ldi r3, 0b100
        and r2,r3,r7
        tst r7
        beq check_down_ver

        # проверка на границы
        ldi r0, x_ver_st
        ldw r0, r0

        ldi r1, 9
        cmp r0, r1
        beq button_ver

        inc r0
        ldi r1, x_ver_st
        stw r1, r0
        #---------------------

        ldi r0, x_ver
        ldw r0, r1

        shr r1, r1, 1
        stw r0, r1

        br print_shipp

    check_down_ver:
        ldi r3, 0b1000
        and r2, r3, r7
        tst r7
        beq check_reverse_ver

        # проверка на границы
        ldi r0, y_ver_fn
        ldw r0, r0

        ldi r1, 9
        cmp r1, r0
        beq button_ver

        inc r0
        ldi r1, y_ver_fn
        stw r1, r0

        ldi r0, y_ver_st
        ldw r0, r1
        inc r1
        stw r0, r1
        #---------------------

        ldi r3, y_ver_st
        ldw r3, r3
        dec r3

        ldi r5, board_state
        add r5, r3, r5
        add r5, r3, r5

        ldw r5, r5

        ldi r1, y_ver
        ldw r1, r0
        
        # Стираем верхнюю палубу корабля (она находится по адресу r0 + 2)
        ldi r3, 2
        add r0, r3, r4   # Записываем во временный регистр r4 адрес (r0 + 2)
        stw r4, r5       # Стираем старую верхнюю палубу
        
        # Сдвигаем базовую координату y вниз на 1 шаг (на 2 байта)
        add r0, r3, r0   # r0 = r0 + 2

        stw r1, r0

        br print_shipp

    check_reverse_ver:
        ldi r3, 0b10000
        and r2,r3,r7
        tst r7
        beq check_place_ver

        pop r7
        push r7

        move r7, r6

        ldi r0, y_ver
        ldw r0,r0

        ldi r2, y_ver_st # нужна для сохранения уже поставленых суден
        ldw r2, r2
        dec r2

        del_ship:
        ldi r3, 2
        add r0, r3,r0
        inc r2

        ldi r3, board_state
        add r3, r2, r3
        add r3, r2, r3
        ldw r3, r3

        stw r0, r3

        dec r6
        tst r6
        bne del_ship

        br return

    check_place_ver:
        ldi r3, 0b100000
        and r2, r3, r7        
        tst r7
        beq  button_ver

        #r0 - координата y клетки проверяемой
        #r5 и r1 - маска для ряда 
        
        # Подготовка к вызову функции проверки

        pop r3 # размер корабля
        push r3
        ldi r4, 0
        loop:
        dec r3
        ldi r0, y_ver_st
        ldw r0, r0  
        ldi r1, x_ver
        ldw r1, r1                 

        add r0, r3, r0
        jsr check_placement   
        or r2, r4, r4
        tst r4                
        bne button_ver
        tst r3
        bne loop

        # --- ЕСЛИ МОЖНО СТАВИТЬ (УСПЕХ) ---

        # 1. Записываем корабль в массив board_state
        ldi r0, y_ver_st
        ldw r0, r0

        pop r1
        push r1

    loop2:
        dec r1                # уменьшаем счетчик палуб (r1)
        add r0, r1, r2        # r2 = Y базовый (r0) + смещение (r1) = текущий ряд
        
        # Считаем точный адрес в памяти: r3 = board_state + r2 * 2
        ldi r3, board_state
        add r2, r3, r3        # r3 = board_state + Y
        add r2, r3, r3        # r3 = board_state + Y * 2

        ldw r3, r6            # Читаем текущее состояние строки с доски (по адресу r3) в r6
        
        ldi r4, x_ver         # Загружаем АДРЕС переменной маски
        ldw r4, r4            # Читаем САМУ МАСКУ из памяти в r4!

        or r4, r6, r6         # Накладываем маску (r4) на строку доски (r6)

        stw r3, r6            # Записываем обновленную строку (r6) ОБРАТНО по адресу (r3)
        
        tst r1
        bne loop2             # Крутим цикл, пока r1 не станет равен 0

        # 2. Передвигаем указатель на следующий размер корабля
        ldi r0, pointer_len_ship
        ldw r0, r1            
        inc r1
        inc r1
        stw r0, r1

        # 3. Выравниваем стек
        pop r7

    br return
    #--------------------------------------------------

end.