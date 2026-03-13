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

asect 0x1000  # массив с размерами кораблей
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
    br start

get_cell_index:
    # 1. ПРОЛОГ (Сохраняем регистры)
    # Функция будет использовать r3 для вычислений. 
    # Чтобы не испортить r3 основной программе, прячем его в стек.
    push r3 

    # 2. ТЕЛО ФУНКЦИИ
    # Нам нужно умножить Y (r6) на 10. Умножения нет, делаем через сдвиги: Y*8 + Y*2
    shl r2, r7, 3    # r7 = Y * 8  (сдвиг влево на 3 бита)
    shl r2, r3, 1    # r3 = Y * 2  (сдвиг влево на 1 бит)
    
    add r7, r3, r7   # r2 = (Y * 8) + (Y * 2) = Y * 10
    
    # Теперь прибавляем X (r0)
    add r7, r0, r7   # r2 = Y * 10 + X

    # 3. ЭПИЛОГ (Восстанавливаем регистры)
    # Достаем r3 из стека. Теперь r3 такой же, каким был до вызова функции!
    pop r3

    # 4. ВОЗВРАТ
    rts              # Возвращаемся туда, откуда вызвали эту функцию

start:
    ldi r0, 0x7000   # 1. Загружаем нужный адрес в обычный регистр r0
    stsp r0          # 2. Специальной командой переносим значение из r0 в sp 

    ldi r0, 0x8004  # ИСТОЧНИК ДАННЫХ: Клавиатура (Адрес 8004)
    ldi r1, 0x8005  # ИСТОЧНИК СТАТУСА: Клавиатура avail (Адрес 8)
    ldi r4, 0x8000  # ПРИЕМНИК: Экран TTY 1 (Адрес 8000)
    ldi r3, 1       # Маска
    

# СОЗДАНИЕ ПОЛЕЙ--------------------------------

# --- КОНСТАНТЫ ---
# 0 = Пусто (вода)
# 1 = Корабль
# 2 = Промах
# 3 = Попадание 
#-------------------

init_game:
    # 1. Очищаем поле ИГРОКА (заполняем нулями от 0x2000 до 0x2063)
    ldi r0, 0x2000   # r0 хранит ТЕКУЩИЙ адрес (начинаем с начала поля)
    ldi r1, 100      # r1 это счетчик цикла (нам нужно 100 клеток)
    ldi r2, 0        # r2 это значение "Вода" (0)

loop_clear_player:
    stb r0, r2       # Записываем 0 в память по адресу из r0
    add r0, 1       # Увеличиваем адрес на 1 (переход к след. клетке)
    sub r1, 1       # Уменьшаем счетчик оставшихся клеток
    bnz loop_clear_player # Если r1 не ноль, повторяем цикл

    # 2. Очищаем поле ВРАГА (заполняем нулями от 0x3000 до 0x3063)
    ldi r0, 0x3000   # r0 теперь указывает на начало поля врага
    ldi r1, 100      # Снова заряжаем счетчик на 100

loop_clear_enemy:
    stb r0, r2       # Пишем 0
    add r0, 1       # Адрес + 1
    sub r1, 1       # Счетчик - 1
    bnz loop_clear_enemy  # Повторяем, пока не заполним все 100 клеток
#-------------------------------------------------

# ГЕНЕРАЦИЯ КОРАБЛЕЙ ПРОТИВНИКА-----------------    

    ldi r1, ships_array  # указатель на массив с размерами кораблей
    ldi r3, 10 # счетчик для необходимого кол-ва кораблей

    rand:
    ldi r0, 10 # для модуля
    tst r3
    bz exit # все, расставили

    ldi r2, 0x800a

    ldb r2, r5 # сгенерированное число X

    ldb r2, r6 # сгенерированное число Y


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
    
    # move r4, r6  #скопировали размер корабля

    check_vert:
    move r6, r2 # скопировали начальную точку

    ldi r7, 10
    add r2, r4, r2
    cmp r2, r7
    bge rand #значит вышли за пределы
 
    # не вышли за предел
    # ДЛЯ ПОЛУЧЕНИЯ НОМЕРА КЛЕТКИ НУЖНО MOVE X -> r0, Y -> r2. РЕЗУЛЬТАТ В r7

    # проверка самой клетки---------
    move r5, r0
    move r6, r2
    jsr get_cell_index

    ldi r0, 0x3000
    add r0, r7, r0
    ldb r0, r7
    tst r7
    bnz rand
    #-------------------------------

    # проверка клетки справа--------
    # проверка на край
    ldi r7, 9
    cmp r5, r7
    beq next1
    #-----------------

    ldi r7, 1

    add r5, r7, r0 # x + 1 -> r0
    move r6, r2 # y -> r2
    
    jsr get_cell_index # r7 - клетка справа    
    
    ldi r0, 0x3000
    add r0, r7, r0
    ldb r0, r7
    tst r7 
    bnz rand
    #-------------------------------- 

    next1:

    # проверка клетки слева--------
    # проверка на край
    ldi r7, 0
    cmp r5, r7
    beq next2
    #-----------------

    ldi r7, 1

    sub r5, r7, r0 # x - 1 -> r0
    move r6, r2 # y -> r2
    
    jsr get_cell_index # r7 - клетка слева  

    ldi r0, 0x3000
    add r0, r7, r0
    ldb r0, r7
    tst r7 
    bnz rand
    #-------------------------------- 

    next2:

    # проверка клетки сверху--------
    # проверка на край
    ldi r7, 0
    cmp r6, r7
    beq next3
    #-----------------

    ldi r7, 1

    sub r6, r7, r2 # y - 1 -> r2
    move r5, r0 # x -> r3
    
    jsr get_cell_index # r7 - клетка сверху  
    
    ldi r0, 0x3000
    add r0, r7, r0
    ldb r0, r7
    tst r7 
    bnz rand
    #-------------------------------- 

    next3:

    # проверка клетки снизу--------
    # проверка на край
    ldi r7, 9
    cmp r6, r7
    beq next4
    #-----------------

    ldi r7, 1

    add r6, r7, r2 # y + 1 -> r2
    move r5, r0 # x -> r3
    
    jsr get_cell_index # r7 - клетка снизу 
    
    ldi r0, 0x3000
    add r0, r7, r0
    ldb r0, r7
    tst r7 
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

    ldi r7, 1

    add r5, r7, r0 # x + 1 -> r0
    sub r6, r7, r2 # y - 1-> r2
    
    jsr get_cell_index # r7 - клетка справа    
    
    ldi r0, 0x3000
    add r0, r7, r0
    ldb r0, r7
    tst r7 
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

    ldi r7, 1

    sub r5, r7, r0 # x - 1 -> r0
    sub r6, r7, r2 # y - 1 -> r2
    
    jsr get_cell_index # r7 - клетка справа    

    ldi r0, 0x3000
    add r0, r7, r0
    ldb r0, r7
    tst r7 
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

    ldi r7, 1

    add r5, r7, r0 # x + 1 -> r0
    add r6, r7, r2 # y + 1-> r2
    
    jsr get_cell_index # r7 - клетка справа    
    
    ldi r0, 0x3000
    add r0, r7, r0
    ldb r0, r7
    tst r7 
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

    ldi r7, 1

    sub r5, r7, r0 # x - 1 -> r0
    add r6, r7, r2 # y + 1 -> r2
    
    jsr get_cell_index # r7 - клетка справа    

    ldi r0, 0x3000
    add r0, r7, r0
    ldb r0, r7
    tst r7 
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
    move r5, r0
    move r6, r2
    tst r4

    bz done
    
    jsr get_cell_index

    ldi r0, 0x3000

    add r7, r0, r7

    ldi r0, 1
    stb r7, r0

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
    bge rand #значит вышли за пределы
 
    # не вышли за предел
    # ДЛЯ ПОЛУЧЕНИЯ НОМЕРА КЛЕТКИ НУЖНО MOVE X -> r0, Y -> r2. РЕЗУЛЬТАТ В r7

    # проверка самой клетки---------
    move r5, r0
    move r6, r2
    jsr get_cell_index

    ldi r0, 0x3000
    add r0, r7, r0
    ldb r0, r7
    tst r7
    bnz rand
    #-------------------------------

    # проверка клетки справа--------
    # проверка на край
    ldi r7, 9
    cmp r5, r7
    beq next9
    #-----------------

    ldi r7, 1

    add r5, r7, r0 # x + 1 -> r0
    move r6, r2 # y -> r2
    
    jsr get_cell_index # r7 - клетка справа    
    
    ldi r0, 0x3000
    add r0, r7, r0
    ldb r0, r7
    tst r7 
    bnz rand
    #-------------------------------- 

    next9:

    # проверка клетки слева--------
    # проверка на край
    ldi r7, 0
    cmp r5, r7
    beq next10
    #-----------------

    ldi r7, 1

    sub r5, r7, r0 # x - 1 -> r0
    move r6, r2 # y -> r2
    
    jsr get_cell_index # r7 - клетка слева  

    ldi r0, 0x3000
    add r0, r7, r0
    ldb r0, r7
    tst r7 
    bnz rand
    #-------------------------------- 

    next10:

    # проверка клетки сверху--------
    # проверка на край
    ldi r7, 0
    cmp r6, r7
    beq next11
    #-----------------

    ldi r7, 1

    sub r6, r7, r2 # y - 1 -> r2
    move r5, r0 # x -> r3
    
    jsr get_cell_index # r7 - клетка сверху  
    
    ldi r0, 0x3000
    add r0, r7, r0
    ldb r0, r7
    tst r7 
    bnz rand
    #-------------------------------- 

    next11:

    # проверка клетки снизу--------
    # проверка на край
    ldi r7, 9
    cmp r6, r7
    beq next12
    #-----------------

    ldi r7, 1

    add r6, r7, r2 # y + 1 -> r2
    move r5, r0 # x -> r3
    
    jsr get_cell_index # r7 - клетка снизу 
    
    ldi r0, 0x3000
    add r0, r7, r0
    ldb r0, r7
    tst r7 
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

    ldi r7, 1

    add r5, r7, r0 # x + 1 -> r0
    sub r6, r7, r2 # y - 1-> r2
    
    jsr get_cell_index # r7 - клетка справа    
    
    ldi r0, 0x3000
    add r0, r7, r0
    ldb r0, r7
    tst r7 
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

    ldi r7, 1

    sub r5, r7, r0 # x - 1 -> r0
    sub r6, r7, r2 # y - 1 -> r2
    
    jsr get_cell_index # r7 - клетка справа    

    ldi r0, 0x3000
    add r0, r7, r0
    ldb r0, r7
    tst r7 
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

    ldi r7, 1

    add r5, r7, r0 # x + 1 -> r0
    add r6, r7, r2 # y + 1-> r2
    
    jsr get_cell_index # r7 - клетка справа    
    
    ldi r0, 0x3000
    add r0, r7, r0
    ldb r0, r7
    tst r7 
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

    ldi r7, 1

    sub r5, r7, r0 # x - 1 -> r0
    add r6, r7, r2 # y + 1 -> r2
    
    jsr get_cell_index # r7 - клетка справа    

    ldi r0, 0x3000
    add r0, r7, r0
    ldb r0, r7
    tst r7 
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
    move r5, r0
    move r6, r2
    tst r4

    bz done_hor
    
    jsr get_cell_index

    ldi r0, 0x3000

    add r7, r0, r7

    ldi r0, 1
    stb r7, r0

    dec r4
    inc r5
    br place_hor

    done_hor:

    dec r3
    inc r1
    inc r1
    br rand
    
#-----------------------------------------------
exit:
# РИСОВАНИЕ ДВУХ ПОЛЕЙ--------------------------

    ldi r4, 0x8000  # ПРИЕМНИК: Экран TTY 1 (Адрес 8000)
        
    ldi r5, 10 # для рисования звезд в одной полосе
    ldi r6, 10 # звезды в рядах
    ldi r7, 42 # аски звезды
    ldi r3, 10 # аски перевода строк
    ldi r0, 32 # аски для пробела
    ldi r2, 2  # чтобы вывести на 2 монитора поле
    
    ldi r1, 0x2fff
    print_row:
        print_coloumn:
        inc r1
        
        
        ldb r1, r7

        

        tst r7 

        beq print_star

        print_hash:
        ldi r7, 35 # аски решетки
        br print

        print_star:
        ldi r7, 46 # аски звезды

        print:
        stb r4, r7
        stb r4, r0
        dec r5
        tst r5
        bnz print_coloumn
    ldi r5, 10 # для рисования звезд в одной полосе
    stb r4, r3
    dec r6
    tst r6
    bnz print_row
    
    # ldi r4, 0x8002
    # ldi r5, 10 
    # ldi r6, 10
    # dec r2
    # tst r2
    # bnz print_row
#-----------------------------------------------




# poll_keyboard:
#     ldb r1, r2       # Читаем статус (из 8005)
#     and r3, r2       
#     bz poll_keyboard 
    
#     ldb r0, r2       # Читаем саму букву (из 8004)
#     stb r4, r2       # Пишем букву на Экран 1 (в 8000)
#     br poll_keyboard



end.



