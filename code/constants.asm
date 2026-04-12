# Here is constants

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
board_state_miss> dc 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

asect 0x0e50
board_state_hit> dc 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

asect 0x0e6c
num_player_dec> dc 20

asect 0x0e6e
num_bot_dec> dc 20

asect 0x0e70  # массив с надписью Place your -deck ship
place_array> dc "Place your -deck ship", 0

asect 0x0e90
y_min> dc 0

asect 0x0e92
y_max> dc 0

asect 0x0e94
ship_mask> dc 0, 0

asect 0x0e98
pointer_len_ship> dc 0

asect 0x0ea0
board_state_hit_bot> 
    dc 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

asect 0x0ee0
board_state_miss_bot> 
    dc 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

asect 0x0f10
board_state_fire_bot> 
    dc 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

asect 0x0f40
board_state_bot> 
    dc 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

asect 0x0f70
board_state> 
    dc 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

asect 0x0fa0
prev_btn_state> dc 0

asect 0x0fa2
y_ver_fn> dc 0

# координаты начальной точки корабля
asect 0x0fa4
x_ver_st> dc 0

asect 0x0fa6
y_ver_st> dc 0

# координаты конечной точки корабля
asect 0x0fa8
x_hor_fn> dc 0

# координаты начальной точки корабля
asect 0x0faa
x_hor_st> dc 0

asect 0x0fac
y_hor_st> dc 0

asect 0x0fae
x_ver> dc 0

asect 0x0fb0
y_ver> dc 0

asect 0x1000  # массив с надписью Ship generation..
gen_array>
    dc "Ship generation...", 0
    
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

asect 0x2000
bad_placement> 
    dc "Bad placement! Try again", 0
end.
