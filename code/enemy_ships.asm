rsect enemy_ships

# include constants.asm
ships_array: ext
board_state_bot: ext

# include replacement
check_field: ext

# include uttils
exit: ext

generate_enemy_ships>
# GENERATE ENEMY'S SHIPS----------------    
    ldi r1, ships_array  # pointer to array with size of ships 
    ldi r3, 10 # amount of ships 

    rand:
        ldi r0, 10 # for MOD 

        # if r3 == 0: break
        tst r3
        bz exit # end generate 
        # ---

        ldi r2, 0xff82 # generator 
        # generate start coordinates (X, Y)
        ldb r2, r5 # random value X -> r5
        ldb r2, r6 # random value Y -> r6 

        ldi r2, 0x000f  # bit mask
        and r5, r2, r5  # X & 0x00f -> r5
        and r6, r2, r6  # Y & 0x00f -> r6
#---------

    # MOD functions
    mod10X: # X = X % 10 -> r5
        cmp r5, r0
        blt mod10Y 
        sub r5, r0, r5
        br mod10X

    mod10Y: # Y = Y % 10 -> r6 
        cmp r6, r0
        blt good 
        sub r6, r0, r6
        br mod10Y
#---------

    good: # block for selecting orientation (vertical or horizontal)
        ldi r2, 0xff82 # generator
        ldb r2, r4 # random value -> r2

        ldi r7, 1
        and r7, r4, r4 # r4 = r4 % 2 

        tst r4 # if r4 == 0 horizontal else vertical
        bz horizontal
        br vertical 
#--------

    vertical:
    ldw r1, r4 # load size of current ship  
      
    check_vert:
        move r6, r2 # copy Y to r2 

        ldi r7, 10 # r7 is vertical size (size of field 10x10)
        add r2, r4, r2 # r2 (Y_end) = Y_start + size_of_ship
        cmp r2, r7 # compare 10 and Y_end
        bgt rand # if Y_end > 10: generate again  

    # ДЛЯ ПОЛУЧЕНИЯ НОМЕРА КЛЕТКИ НУЖНО MOVE X -> r0, Y -> r2. РЕЗУЛЬТАТ В r7

    # check the first square (X, Y) 
        ldi r0, board_state_bot
        add r0, r6, r0
        add r0, r6, r0
        ldw r0, r0 # в r0 is bit string

        ldi r2, 9

        sub r2, r5, r2 # в r2 сдвиг необходимый влево

        jsr check_field

        tst r0
        bnz rand # if this square is not free: generate again
    #-----------

    # check right square-------
    # check last square of field
    ldi r7, 9 # max coordinate
    cmp r5, r7 # compare X and max 

    # If we are at the right edge, there's no cell to the right to check
    beq next1 # if x == max: check next 
    # else:

    ldi r0, board_state_bot
    add r0, r6, r0
    add r0, r6, r0
    ldw r0, r0 # в r0 - bit string

    ldi r2, 9 # max index
    sub r2, r5, r2 # r2 = 9 - X_coord
    dec r2 # because check right square 

    jsr check_field
    tst r0
    bnz rand # if this square is not free: generate again


    next1:
        # check left (X-1, Y)--------
        # проверка на край
        ldi r7, 0
        cmp r5, r7
        beq next2
        #-----------------

        ldi r0, board_state_bot
        add r0, r6, r0
        add r0, r6, r0
        ldw r0, r0 # r0 is bit string 

        ldi r2, 9
        sub r2, r5, r2 # r2 = 9 - X_coord 
        inc r2 # because left 
        
        jsr check_field
        tst r0 
        bnz rand# if this square is not free: generate again
        #-------

    next2:
        # check up square (X, Y - 1)--------
        # проверка на край
        ldi r7, 0
        cmp r6, r7
        beq next3
        #-----------------

        ldi r0, board_state_bot
        add r0, r6, r0
        add r0, r6, r0
        dec r0
        dec r0
        ldw r0, r0 # в r0 - битовая строка

        ldi r2, 9

        sub r2, r5, r2 # в r2 сдвиг необходимый влево

        jsr check_field

        tst r0
        bnz rand
        #-------------------------------- 

    next3:
        # check down (X, Y+1)--------
        # проверка на край
        ldi r7, 9
        cmp r6, r7
        beq next4
        #-----------------

        ldi r0, board_state_bot
        add r0, r6, r0
        add r0, r6, r0
        inc r0
        inc r0
        ldw r0, r0 # в r0 - битовая строка

        ldi r2, 9

        sub r2, r5, r2 # в r2 сдвиг необходимый влево
        jsr check_field
        
        tst r0 
        bnz rand
        #-------------------------------- 

    next4:
        # check top-right diagonal square (x+1, y+1)--------
        # проверка на край
        ldi r7, 9
        cmp r5, r7
        beq next5
        ldi r7, 0
        cmp r6, r7
        beq next5
        #-----------------

        ldi r0, board_state_bot
        add r0, r6, r0
        add r0, r6, r0
        dec r0
        dec r0
        ldw r0, r0 # в r0 - битовая строка

        ldi r2, 9

        sub r2, r5, r2 # в r2 сдвиг необходимый влево

        dec r2
        jsr check_field

        tst r0
        bnz rand
        #-------------------------------- 

    next5:
        # Check top-left diagonal square (X-1, Y-1) --------
        # проверка на край
        ldi r7, 0
        cmp r5, r7
        beq next6
        cmp r6, r7
        beq next6
        #-----------------

        ldi r0, board_state_bot
        add r0, r6, r0
        add r0, r6, r0
        dec r0
        dec r0
        ldw r0, r0 # в r0 - битовая строка

        ldi r2, 9

        sub r2, r5, r2 # в r2 сдвиг необходимый влево

        inc r2
    jsr check_field

        tst r0
        bnz rand
        #-------------------------------- 

    next6:
        # check bottom-right diagonal square (X + 1, Y + 1)--------
        # проверка на край
        ldi r7, 9
        cmp r5, r7
        beq next7
        cmp r6, r7
        beq next7
        #-----------------

        ldi r0, board_state_bot
        add r0, r6, r0
        add r0, r6, r0
        inc r0
        inc r0
        ldw r0, r0 # в r0 - битовая строка

        ldi r2, 9

        sub r2, r5, r2 # в r2 сдвиг необходимый влево

        dec r2
        jsr check_field

        tst r0
        bnz rand
        #-------------------------------- 

    next7:
        # check bottom-left diagonal square (X - 1, Y + 1)
        # проверка на край
        ldi r7, 0
        cmp r5, r7
        beq next8
        ldi r7, 9
        cmp r6, r7
        beq next8
        #-----------------

        ldi r0, board_state_bot
        add r0, r6, r0
        add r0, r6, r0
        inc r0
        inc r0
        ldw r0, r0 # в r0 - битовая строка

        ldi r2, 9

        sub r2, r5, r2 # в r2 сдвиг необходимый влево

        inc r2
        jsr check_field


        tst r0
        bnz rand
        #-------------------------------- 

    next8:
        dec r4 # r4 is the size of current ship. size--;
        # if size == 0: place_ship
        tst r4
        bz place_ship
        # else:

        inc r6 # if size > 0: check next segment of ship
        br check_vert

        # ????
        place_ship:
            ldw r1, r4
            inc r6
            sub r6, r4, r6 # вернули начальную координату y

    place:
        # this block of code set bits in field 

        # check size
        tst r4 # if size == 0: done
        bz done

        # get bit string
        ldi r0, board_state_bot
        add r0, r6, r0
        add r0, r6, r0
        ldw r0, r0 # r0 - bit string

        ldi r2, 0b1000000000 # mask
        move r5, r7 # r5 -> r7 (X -> r7) 

        loop14:
            # make right bit mask in r2 
            tst r7
            beq q 

            shr r2, r2, 1 
            dec r7
            
            br loop14

            q:
                or r0, r2, r2
                ldi r0, board_state_bot 
                add r0, r6, r0
                add r0, r6, r0

                stw r0, r2

                dec r4
                inc r6
            br place

    done:
        dec r3 # ships_amount--
        # ship_array_pointer++
        inc r1 
        inc r1
        br rand # go to generate next ship

    horizontal:
    ldw r1, r4 # size of ship -> r4 
      
    check_horizont:
        move r5, r2 # start point

        ldi r7, 10
        add r2, r4, r2
        cmp r2, r7
        bgt rand # out of field
    
        # ДЛЯ ПОЛУЧЕНИЯ НОМЕРА КЛЕТКИ НУЖНО MOVE X -> r0, Y -> r2. РЕЗУЛЬТАТ В r7

        # check cell ---------
        # get bit string
        ldi r0, board_state_bot
        add r0, r6, r0
        add r0, r6, r0
        ldw r0, r0 # в r0 bit string 

        ldi r2, 9
        sub r2, r5, r2  
        
        jsr check_field

        tst r0
        bnz rand # if r0 != 0: rand again
    #-----

        # -Check the starting cell (X, Y)-------
        ldi r7, 9
        cmp r5, r7
        beq next9
        #-----------------

        ldi r0, board_state_bot
        add r0, r6, r0
        add r0, r6, r0
        ldw r0, r0 # в r0 bit string

        ldi r2, 9 # max coord
        sub r2, r5, r2  

        dec r2
        jsr check_field
    
        tst r0 
        bnz rand # if can not replace generate again
        #-------------------------------- 

    next9:
        # --------
        # проверка на край
        ldi r7, 0
        cmp r5, r7
        beq next10
        #-----------------

        ldi r0, board_state_bot
        add r0, r6, r0
        add r0, r6, r0
        ldw r0, r0 # в r0 - битовая строка

        ldi r2, 9

        sub r2, r5, r2 # в r2 сдвиг необходимый влево

        inc r2
        jsr check_field

        tst r0
        bnz rand
        #-------------------------------- 

    next10:
        # проверка клетки сверху--------
        # проверка на край
        ldi r7, 0
        cmp r6, r7
        beq next11
        #-----------------

        ldi r0, board_state_bot
        add r0, r6, r0
        add r0, r6, r0
        dec r0
        dec r0
        ldw r0, r0 # в r0 - битовая строка

        ldi r2, 9

        sub r2, r5, r2 # в r2 сдвиг необходимый влево

        jsr check_field

        tst r0
        bnz rand
        #-------------------------------- 

    next11:
        # проверка клетки снизу--------
        # проверка на край
        ldi r7, 9
        cmp r6, r7
        beq next12
        #-----------------

        ldi r0, board_state_bot
        add r0, r6, r0
        add r0, r6, r0
        inc r0
        inc r0
        ldw r0, r0 # в r0 - битовая строка

        ldi r2, 9

        sub r2, r5, r2 # в r2 сдвиг необходимый влево

        jsr check_field

        tst r0 
        bnz rand
        #-------------------------------- 

    next12:
        # проверка клетки справа сверху--------
        # проверка на край
        ldi r7, 9
        cmp r5, r7
        beq next13
        ldi r7, 0
        cmp r6, r7
        beq next13
        #-----------------


        ldi r0, board_state_bot
        add r0, r6, r0
        add r0, r6, r0
        dec r0
        dec r0
        ldw r0, r0 # в r0 - битовая строка

        ldi r2, 9

        sub r2, r5, r2 # в r2 сдвиг необходимый влево

        dec r2
        jsr check_field

        tst r0 
        bnz rand
        #-------------------------------- 

    next13:
        # проверка клетки слева сверху--------
        # проверка на край
        ldi r7, 0
        cmp r5, r7
        beq next14
        cmp r6, r7
        beq next14
        #-----------------

        
        ldi r0, board_state_bot
        add r0, r6, r0
        add r0, r6, r0
        dec r0
        dec r0
        ldw r0, r0 # в r0 - битовая строка

        ldi r2, 9

        sub r2, r5, r2 # в r2 сдвиг необходимый влево

        inc r2
        jsr check_field

        tst r0 
        bnz rand
        #-------------------------------- 

    next14:
        # проверка клетки справа снизу--------
        # проверка на край
        ldi r7, 9
        cmp r5, r7
        beq next15
        cmp r6, r7
        beq next15
        #-----------------
        
        ldi r0, board_state_bot
        add r0, r6, r0
        add r0, r6, r0
        inc r0
        inc r0
        ldw r0, r0 # в r0 - битовая строка

        ldi r2, 9

        sub r2, r5, r2 # в r2 сдвиг необходимый влево

        dec r2
        jsr check_field
    
        
    
        tst r0 
        bnz rand
        #-------------------------------- 

    next15:
        # проверка клетки слева снизу--------
        # проверка на край
        ldi r7, 0
        cmp r5, r7
        beq next16
        ldi r7, 9
        cmp r6, r7
        beq next16
        #-----------------
    
        ldi r0, board_state_bot
        add r0, r6, r0
        add r0, r6, r0
        inc r0
        inc r0
        ldw r0, r0 # в r0 - битовая строка

        ldi r2, 9

        sub r2, r5, r2 # в r2 сдвиг необходимый влево

        inc r2
        jsr check_field
        

        tst r0 
        bnz rand
        #-------------------------------- 

    next16:
        dec r4
        tst r4
        bz place_ship_hor

        inc r5
        br check_horizont

        place_ship_hor:

        ldw r1, r4
        inc r5
        sub r5, r4, r5 # вернули начальную координату x

        place_hor:
        tst r4
        bz done_hor

        # 1. Читаем текущую строку в r0
        ldi r0, board_state_bot
        add r0, r6, r0
        add r0, r6, r0
        ldw r0, r0

        # 2. Формируем битовую маску для текущего X (r5)
        ldi r2, 0b1000000000
        move r5, r7 
        
        tst r7
        beq skip_shift_hor
        loop_shift_hor:
        shr r2, r2, 1 
        dec r7
        bne loop_shift_hor
        skip_shift_hor:
        
        # 3. Накладываем маску на строку доски
        or r0, r2, r2
        
        # 4. Записываем обратно в память бота
        ldi r0, board_state_bot 
        add r0, r6, r0
        add r0, r6, r0
        stw r0, r2

        # 5. Переходим к следующей клетке (сдвигаемся по X)
        dec r4
        inc r5
        br place_hor

        done_hor:
            dec r3         # Уменьшаем счетчик оставшихся кораблей
            inc r1
            inc r1         # Сдвигаем указатель на следующий размер
            br rand        # Генерируем следующий
end.