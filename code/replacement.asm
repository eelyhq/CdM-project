# Here is some functions 

# include constants.asm
board_state: ext

rsect functions

check_placement>
    # Универсальная функция проверки места на доске
    # Вызывать через: jsr check_placement

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
    ldw r4, r6            
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

check_field>
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

end.