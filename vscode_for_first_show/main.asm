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


asect 0x0dc
fight_word> dc "fight!"


asect 0x0dd0
win_word> dc "win!"

asect 0x0de0
bot_word> dc "bot"

asect 0x0df0
player_word> dc "player"

asect 0x0e0e
bot_ship_count> dc 10
asect 0x0e12
player_ship_count> dc 10

asect 0x0e16
retry_count> dc 0

asect 0x0e18
pointer_miss_matrix_arr> dc 0 # указатель на адрес матрицы с миссами

asect 0x0e1a
pointer_hit_matrix_arr> dc 0 # указатель на адрес матрицы с хитами


asect 0x0e1c
pointer_miss_arr> dc 0 # указатель на массив с хитами, нужен, чтобы функция провреки убийства работала и с ботом и игроком

asect 0x0e20
pointer_hit_arr> dc 0 # указатель на массив с хитами, нужен, чтобы функция провреки убийства работала и с ботом и игроком

asect 0x0e24
curr_hit_x>    dc 0  # X клетки, от которой шагаем сейчас
asect 0x0e26
curr_hit_y>    dc 0  # Y клетки, от которой шагаем сейчас
asect 0x0e28
bot_state> dc 0      # 0 = Ищет (рандом), 1 = Нашел, ищет направление, 2 = Бьет по линии
asect 0x0e2a
hit_start_x> dc 0    # X первого попадания по текущему кораблю
asect 0x0e2c
hit_start_y> dc 0    # Y первого попадания
asect 0x0e2e
target_dir> dc 0     # Направление: 0-Вверх, 1-Вправо, 2-Вниз, 3-Влево

asect 0x0e30
board_state_miss> 
    dc 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

asect 0x0e50
board_state_hit>
    dc 0, 0, 0, 0, 0, 0, 0, 0, 0, 0


asect 0x0e6c
num_player_dec>
    dc 20


asect 0x0e6e
num_bot_dec>
    dc 20


asect 0x0e70  # массив с надписью Place your -deck ship
place_array>
    dc "Place your -deck ship", 0

asect 0x0e90
y_min>
    dc 0

asect 0x0e92
y_max>
    dc 0

asect 0x0e94
ship_mask>
    dc 0, 0

asect 0x0e98
pointer_len_ship>
    dc 0

asect 0x0ea0
board_state_hit_bot: 
    dc 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

asect 0x0ee0
board_state_miss_bot: 
    dc 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

asect 0x0f10
board_state_fire_bot: 
    dc 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

asect 0x0f40
board_state_bot: 
    dc 0, 0, 0, 0, 0, 0, 0, 0, 0, 0


asect 0x0f70
board_state: 
    dc 0, 0, 0, 0, 0, 0, 0, 0, 0, 0


asect 0x0fa0
prev_btn_state: dc 0


asect 0x0fa2
y_ver_fn: dc 0


# координаты начальной точки корабля
asect 0x0fa4
x_ver_st: dc 0

asect 0x0fa6
y_ver_st: dc 0


# координаты конечной точки корабля
asect 0x0fa8
x_hor_fn: dc 0


# координаты начальной точки корабля
asect 0x0faa
x_hor_st: dc 0

asect 0x0fac
y_hor_st: dc 0



asect 0x0fae
x_ver: dc 0

asect 0x0fb0
y_ver: dc 0

asect 0x1000  # массив с надписью Ship generation..
gen_array>
    dc "Ship generation..", 0
    

asect 0x10ef  # массив с размерами кораблей
ships_array>
    dc 4
    dc 3
    dc 3
    dc 2
    dc 2
    dc 2
    dc 1
    dc 1
    dc 1
    dc 1



# Main program section
rsect main

main>

ldi r0, 0x7000   # 1. Загружаем нужный адрес в обычный регистр r0
stsp r0

br beg
# Универсальная функция проверки места на доске
# Вызывать через: jsr check_placement
# Универсальная функция проверки места на доске
# Вызывать через: jsr check_placement
check_placement:
    # Сохраняем значения регистров
    push r3
    push r4
    push r5
    push r6

    # --- ШАГ 1: Делаем "широкую" маску для проверки диагоналей ---
    move r1, r5           
    move r1, r6
    shl r6, r6, 1         
    or r5, r6, r5
    move r1, r6
    shr r6, r6, 1         
    or r5, r6, r5         

    # --- ШАГ 2: Проверка текущего ряда (Y) ---
    ldi r3, board_state
    add r0, r3, r4
    add r0, r4, r4        # r4 = адрес текущего ряда
    
    ldw r4, r6            # ИСПРАВЛЕНО: читаем из адреса r4 в регистр r6
    and r6, r5, r6
    bne placement_error   

    # --- ШАГ 3: Проверка ряда ВЫШЕ (Y - 1) ---
    tst r0
    beq skip_up_check     

    dec r4
    dec r4                
    ldw r4, r6            # ИСПРАВЛЕНО
    and r6, r5, r6
    bne placement_error
    inc r4
    inc r4                

skip_up_check:

    # --- ШАГ 4: Проверка ряда НИЖЕ (Y + 1) ---
    ldi r6, 9
    cmp r0, r6
    beq skip_down_check   

    inc r4
    inc r4                
    ldw r4, r6            # ИСПРАВЛЕНО
    and r6, r5, r6
    bne placement_error

skip_down_check:
    ldi r2, 0             # Код успеха
    br end_placement_check

placement_error:
    ldi r2, 1             # Код ошибки (коллизия)

end_placement_check:
    # Восстанавливаем регистры
    pop r6
    pop r5
    pop r4
    pop r3
    rts

check_field:
   
    tst r2
    bz end_loop5   # Если сдвигать не надо (r2=0), перепрыгиваем цикл
    loop5:
    shr r0, r0, 1 
    dec r2
    tst r2
    bne loop5
    end_loop5:

    ldi r2, 1

    and r2, r0, r0

    rts
beg:


start:

    # НАПИСАНИЕ "Ship generation..."---------------

    ldi r0, 0x800c
    ldi r1, gen_array
    ldi r3, 18

    write:
    ldb  r1, r2
    stb r0, r2
    inc r1
    dec r3
    tst r3
    bnz write



    #----------------------------------------------
    ldi r0, 0x7000   # 1. Загружаем нужный адрес в обычный регистр r0
    stsp r0          # 2. Специальной командой переносим значение из r0 в sp 



# # СОЗДАНИЕ ПОЛЕЙ--------------------------------


# # ГЕНЕРАЦИЯ КОРАБЛЕЙ ПРОТИВНИКА-----------------    

    ldi r1, ships_array  # указатель на массив с размерами кораблей
    ldi r3, 10 # счетчик для необходимого кол-ва кораблей

    rand:
    ldi r0, 10 # для модуля
    tst r3
    bz exit # все, расставили

    ldi r2, 0x800a

    ldb r2, r5 # сгенерированное число X
    
    ldb r2, r6 # сгенерированное число Y

    ldi r2, 0x000f
    and r5, r2, r5
    and r6, r2, r6

#------------------------------
    mod10X:# остаток для координаты X
    
    cmp r5, r0

    blt mod10Y # взяли остаток на 10

    sub r5, r0, r5

    br mod10X
    

    mod10Y: # остаток для координаты Y

    cmp r6, r0

    blt good # взяли остаток на 10

    sub r6, r0, r6

    br mod10Y
    
    # r5 - X
    # r6 - Y
    # r1 - указатель на массив с размерами кораблей
    # r3 - кол-во кораблей оставшееся
#------------------------------

    good:
    
    ldi r2, 0x800a
    
    ldb r2, r4 # число для направления четное - по горизонтали, нечет - по вертикали

    ldi r7, 1

    # ldi r5, 0
    # ldi r6, 0

    and r7, r4, r4

    tst r4
    bz horizontal
    br vertical 


#------------------------------
    vertical:
    ldw r1, r4 # загружаем в регистр 4 размер корабля

      
    # проверка, выйдет ли корабль за пределы поля
    

    check_vert:
    move r6, r2 # скопировали начальную точку

    ldi r7, 10
    add r2, r4, r2
    cmp r2, r7
    bgt rand #значит вышли за пределы
 
    # не вышли за предел
    # ДЛЯ ПОЛУЧЕНИЯ НОМЕРА КЛЕТКИ НУЖНО MOVE X -> r0, Y -> r2. РЕЗУЛЬТАТ В r7

    # проверка самой клетки---------

    # move r5, r0
    # move r6, r2
    # jsr get_cell_index

    ldi r0, board_state_bot
    add r0, r6, r0
    add r0, r6, r0
    ldw r0, r0 # в r0 - битовая строка

    ldi r2, 9

    sub r2, r5, r2 # в r2 сдвиг необходимый влево

    jsr check_field


    # ldi r0, 0x3000
    # add r0, r7, r0
    # ldb r0, r7
    tst r0
    bnz rand
    #-------------------------------

    # проверка клетки справа--------
    # проверка на край
    ldi r7, 9
    cmp r5, r7
    beq next1
    #-----------------

    # ldi r7, 1

    # add r5, r7, r0 # x + 1 -> r0
    # move r6, r2 # y -> r2
    
    # jsr get_cell_index # r7 - клетка справа  


    
    ldi r0, board_state_bot
    add r0, r6, r0
    add r0, r6, r0
    ldw r0, r0 # в r0 - битовая строка

    ldi r2, 9

    sub r2, r5, r2 # в r2 сдвиг необходимый

    dec r2 # так как правую клетку проверяем

    jsr check_field




    # ldi r0, 0x3000
    # add r0, r7, r0
    # ldb r0, r7

    tst r0
    bnz rand
    #-------------------------------- 

    next1:

    # проверка клетки слева--------
    # проверка на край
    ldi r7, 0
    cmp r5, r7
    beq next2
    #-----------------

    # ldi r7, 1

    # sub r5, r7, r0 # x - 1 -> r0
    # move r6, r2 # y -> r2
    
    # jsr get_cell_index # r7 - клетка слева  


    ldi r0, board_state_bot
    add r0, r6, r0
    add r0, r6, r0
    ldw r0, r0 # в r0 - битовая строка

    ldi r2, 9

    sub r2, r5, r2 # в r2 сдвиг необходимый влево

    inc r2 # так как левую клетку проверяем
    
    jsr check_field



    # ldi r0, 0x3000
    # add r0, r7, r0
    # ldb r0, r7
    tst r0 
    bnz rand
    #-------------------------------- 

    next2:

    # проверка клетки сверху--------
    # проверка на край
    ldi r7, 0
    cmp r6, r7
    beq next3
    #-----------------

    # ldi r7, 1

    # sub r6, r7, r2 # y - 1 -> r2
    # move r5, r0 # x -> r3
    
    # jsr get_cell_index # r7 - клетка сверху  
    

    ldi r0, board_state_bot
    add r0, r6, r0
    add r0, r6, r0
    dec r0
    dec r0
    ldw r0, r0 # в r0 - битовая строка

    ldi r2, 9

    sub r2, r5, r2 # в r2 сдвиг необходимый влево

    jsr check_field


    # ldi r0, 0x3000
    # add r0, r7, r0
    # ldb r0, r7
    tst r0
    bnz rand
    #-------------------------------- 

    next3:

    # проверка клетки снизу--------
    # проверка на край
    ldi r7, 9
    cmp r6, r7
    beq next4
    #-----------------

    # ldi r7, 1

    # add r6, r7, r2 # y + 1 -> r2
    # move r5, r0 # x -> r3
    
    # jsr get_cell_index # r7 - клетка снизу 


    ldi r0, board_state_bot
    add r0, r6, r0
    add r0, r6, r0
    inc r0
    inc r0
    ldw r0, r0 # в r0 - битовая строка

    ldi r2, 9

    sub r2, r5, r2 # в r2 сдвиг необходимый влево
    jsr check_field
    
    # ldi r0, 0x3000
    # add r0, r7, r0
    # ldb r0, r7
    tst r0 
    bnz rand
    #-------------------------------- 

    next4:

    # проверка клетки справа сверху--------
    # проверка на край
    ldi r7, 9
    cmp r5, r7
    beq next5
    ldi r7, 0
    cmp r6, r7
    beq next5
    #-----------------

    # ldi r7, 1

    # add r5, r7, r0 # x + 1 -> r0
    # sub r6, r7, r2 # y - 1 -> r2
    
    # jsr get_cell_index # r7 - клетка справа    
    

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




    # ldi r0, 0x3000
    # add r0, r7, r0
    # ldb r0, r7
    tst r0
    bnz rand
    #-------------------------------- 

    next5:

    # проверка клетки слева сверху--------
    # проверка на край
    ldi r7, 0
    cmp r5, r7
    beq next6
    cmp r6, r7
    beq next6
    #-----------------

    # ldi r7, 1

    # sub r5, r7, r0 # x - 1 -> r0
    # sub r6, r7, r2 # y - 1 -> r2
    
    # jsr get_cell_index # r7 - клетка справа  


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



    # ldi r0, 0x3000
    # add r0, r7, r0
    # ldb r0, r7
    tst r0
    bnz rand
    #-------------------------------- 

    next6:

    # проверка клетки справа снизу--------
    # проверка на край
    ldi r7, 9
    cmp r5, r7
    beq next7
    cmp r6, r7
    beq next7
    #-----------------

    # ldi r7, 1

    # add r5, r7, r0 # x + 1 -> r0
    # add r6, r7, r2 # y + 1-> r2
    
    # jsr get_cell_index # r7 - клетка справа    
    
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





    # ldi r0, 0x3000
    # add r0, r7, r0
    # ldb r0, r7
    tst r0
    bnz rand
    #-------------------------------- 

    next7:

    # проверка клетки слева снизу--------
    # проверка на край
    ldi r7, 0
    cmp r5, r7
    beq next8
    ldi r7, 9
    cmp r6, r7
    beq next8
    #-----------------

    # ldi r7, 1

    # sub r5, r7, r0 # x - 1 -> r0
    # add r6, r7, r2 # y + 1 -> r2
    
    # jsr get_cell_index # r7 - клетка справа  


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


    # ldi r0, 0x3000
    # add r0, r7, r0
    # ldb r0, r7
    tst r0
    bnz rand
    #-------------------------------- 

    next8:
    dec r4

    tst r4
    
    bz place_ship

    inc r6
    br check_vert

    place_ship:

    ldw r1, r4
    inc r6
    sub r6, r4, r6 # вернули начальную координату y


    place:

    tst r4

    bz done

    ldi r0, board_state_bot
    add r0, r6, r0
    add r0, r6, r0

    ldw r0, r0

    ldi r2, 0b1000000000

    move r5, r7 

    loop14:
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

    dec r3
    inc r1
    inc r1
    br rand

#------------------------------

    horizontal:
    ldw r1, r4 # загружаем в регистр 4 размер корабля

      
    # проверка, выйдет ли корабль за пределы поля
    
    # move r4, r6  #скопировали размер корабля

    check_horizont:
    move r5, r2 # скопировали начальную точку

    ldi r7, 10
    add r2, r4, r2
    cmp r2, r7
    bgt rand #значит вышли за пределы
 
    # не вышли за предел
    # ДЛЯ ПОЛУЧЕНИЯ НОМЕРА КЛЕТКИ НУЖНО MOVE X -> r0, Y -> r2. РЕЗУЛЬТАТ В r7

    # проверка самой клетки---------

    ldi r0, board_state_bot
    add r0, r6, r0
    add r0, r6, r0
   
    ldw r0, r0 # в r0 - битовая строка

    ldi r2, 9

    sub r2, r5, r2 # в r2 сдвиг необходимый влево

    
    jsr check_field


    tst r0
    bnz rand
    #-------------------------------

    # проверка клетки справа--------
    # проверка на край
    ldi r7, 9
    cmp r5, r7
    beq next9
    #-----------------

    
    ldi r0, board_state_bot
    add r0, r6, r0
    add r0, r6, r0
    ldw r0, r0 # в r0 - битовая строка

    ldi r2, 9

    sub r2, r5, r2 # в r2 сдвиг необходимый влево

    dec r2
    jsr check_field
 
    tst r0 
    bnz rand
    #-------------------------------- 

    next9:

    # проверка клетки слева--------
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
    
#-----------------------------------------------
exit:

ldi r0, 0x800e

stb r0,r0



# РИСОВАНИЕ ДВУХ ПОЛЕЙ--------------------------

# ldi r1, 0x8034   # Указатель на начало поля в памяти (откуда читаем)
# ldi r4, board_state_bot   # Указатель на массив адресов матрицы (куда пишем)
# ldi r6, 10       # Счетчик рядов (10 штук)


# print_row:
#     ldw r4, r0
#     stw r1, r0
#     inc r1
#     inc r1
#     inc r4
#     inc r4
#     dec r6 
#     tst r6 
#     bne print_row


#-----------------------------------------------







# РАСПОЛОЖЕИЕ КОРАБЛЕЙ ИГРОКА 

ldi r5, ships_array # получаем размер корабля в р6
ldi r6, pointer_len_ship
stw r6, r5

return:
ldi r6, pointer_len_ship
ldw r6, r6
ldb r6, r6

ldi r0, place_array
ldi r1, 11
ldi r2, 0x800c

# надпись---------
ldi r3, 0x800e
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

ldi r4, 0x8034 # адрес первой строки

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

ldi r0, 0x8048
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

ldi r0, 0x8032 # координата y
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

ldi r5, 0x8048
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

    # --- ЕСЛИ МОЖНО СТАВИТЬ ---

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

ldi r0, 0x800c
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

ldi r4, 0x8070 # адрес первой строки

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

ldi r0, 0x8048
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
    shl r7, r7, 3   # Сдвигаем ВСЁ на 3 бита для матрицы 0x8070
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
    and r0, r2, r0    
    

    beq miss          # Если корабля нет (Z=1), прыгаем в промах

    hit:
    ldi r3, 0x805c  
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
    ldi r4, 0x805c
    stw r3, r4
    ldi r3, pointer_miss_matrix_arr
    ldi r4, 0x8016
    stw r3, r4 

    ldi r3, pointer_miss_arr
    ldi r4, board_state_miss_bot
    stw r3, r4 

    ldi r3, pointer_hit_arr
    ldi r4, board_state_hit_bot
    stw r3, r4 

    br player_hit   # Возвращаемся к опросу (не сбрасываем курсор)

    miss:
    ldi r3, 0x8016
    add r3, r7, r3
    add r3, r7, r3    # r3 = адрес экрана промахов (без сдвига)

    ldi r6, board_state_miss_bot
    add r6, r7, r6
    add r6, r7, r6

    ldw r6, r4        # Читаем старые промахи
    or r4, r5, r4     # Добавляем новый
    stw r6, r4        # Сохраняем в память
    stw r3, r4        # Выводим на экран (матрица 10 клеток, сдвиг не нужен)

   br player_hit

    
    

player_win:

end.