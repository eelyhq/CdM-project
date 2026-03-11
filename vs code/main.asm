asect 0
main: ext               
default_handler: ext    

# Убрали ", 0" чтобы каждый вектор занимал ровно 1 слово (2 байта)
dc main                 # 0x00: Startup/Reset vector
dc default_handler      # 0x02: Unaligned SP
dc default_handler      # 0x04: Unaligned PC
dc default_handler      # 0x06: Invalid instruction
dc default_handler      # 0x08: Double fault
align 0x80              

rsect exc_handlers
default_handler>
    halt

rsect main
main>
start:
    ldi r0, 0x8000  # r0 = Адрес для данных (Чтение=Клава, Запись=TTY)
    ldi r1, 0x8001  # r1 = Адрес статуса клавиатуры (Чтение)

poll_keyboard:
    # 1. Проверяем, нажата ли клавиша
    ld r1, r2       # Читаем статус (0x8001) в регистр r2
    tst r2          # Проверяем r2. (Если там 0, флаг Z станет равен 1)
    bz poll_keyboard # Если Z=1 (клавиша не нажата), прыгаем назад и ждем
    
    # 2. Если мы тут, значит клавиша была нажата!
    ld r0, r2       # Читаем саму букву (0x8000) в r2 
                    # ВАЖНО: в этот момент железо само сбросит буфер клавиатуры!

    # 3. Печатаем букву на экран
    st r0, r2       # Пишем эту же букву из r2 обратно по адресу 0x8000 (в TTY)

    # 4. Возвращаемся в начало, чтобы ждать следующую букву
    br poll_keyboard
stop_loop:             
    br stop_loop        
    
end.