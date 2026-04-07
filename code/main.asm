asect 0
main: ext               # Declare labels
default_handler: ext    # as external

# Interrupt vector table (IVT)
# Place a vector to program start and map 
# all internal exceptions to default_handler
dc main, 0              # Startup/Reset vector
dc default_handler, 0   # Unaligned SP
dc default_handler, 0   # Unaligned PC
dc default_handler, 0   # Invalid instruction
dc default_handler, 0   # Double fault
align 0x80              # Reserve space for the rest 
                        # of IVT

# Exception handlers section
rsect exc_handlers

# This handler halts processor
default_handler>
    halt
# ------------

# Main program section
rsect main

# Include constants.asm
fight_word: ext 
win_word: ext   
bot_word: ext   
player_word: ext
bot_ship_count: ext
player_ship_count: ext
retry_count: ext
pointer_miss_matrix_arr: ext
pointer_hit_matrix_arr: ext
pointer_miss_arr: ext
pointer_hit_arr: ext
curr_hit_x: ext 
curr_hit_y: ext 
bot_state: ext  
hit_start_x: ext 
hit_start_y: ext 
target_dir: ext 
board_state_miss: ext
board_state_hit: ext
num_player_dec: ext
num_bot_dec: ext
place_array: ext
y_min: ext      
y_max: ext      
ship_mask: ext  
pointer_len_ship: ext
board_state_hit_bot: ext
board_state_miss_bot: ext
board_state_fire_bot: ext
board_state_bot: ext
board_state: ext
prev_btn_state: ext 
y_ver_fn: ext
x_ver_st: ext
y_ver_st: ext
x_hor_fn: ext
x_hor_st: ext
y_hor_st: ext
x_ver: ext
y_ver: ext
gen_array: ext
ships_array: ext
# -----

# include replacement.asm
check_placement: ext
check_field: ext
# ----

# include write_tty.asm
write_ship_generation: ext

main>
ldi r0, 0x7000   
stsp r0

jsr write_ship_generation

# СОЗДАНИЕ ПОЛЕЙ--------------------------------
# GENERATE ENEMY'S SHIPS----------------    
    ldi r1, ships_array  # pointer to array with size of ships 
    ldi r3, 10 # amount of ships 

    rand:
        ldi r0, 10 # for MOD 

        # if r3 == 0: break
        tst r3
        bz exit 
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
    bnz rand# if this square is not free: generate again


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

#------------------------------

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
exit: # end generation enemy's ships
#######################################################

ldi r0, 0xffc2
stb r0,r0

#######################################################
# PLAYER SHIPS PLACEMENT
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
    beq fin

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

fin:

ldi r0, 0xffc0
ldi r1, 6
ldi r2, fight_word

loop30:
tst r1
beq end_loop30
ldb r2, r3
stb r0, r3
inc r2
dec r1
br loop30
end_loop30:

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
end.
