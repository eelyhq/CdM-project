asect 0x0dc0

# string constants
fight_word>               dc "fight!"
align 2
win_word>                 dc "win!"
align 2
bot_word>                 dc "bot"
align 2
player_word>              dc "player"
align 2
place_array>              dc "Place your -deck ship", 0       # array with the string place your -deck ship
align 2
gen_array>                dc "Ship generation...", 0          # array with the string ship generation
align 2
bad_placement>            dc "Bad placement! Try again", 0
align 2
draw_choice>              dc "Your choice: ", 0
align 2
stone>                    dc "stone", 0
align 2
scissors>                 dc "scissors", 0
align 2
paper>                    dc "paper", 0
align 2
confirm_message>          dc " Click the check mark to confirm your choice.", 0
align 2
msg_tie>                  dc "Tie! Choose again."             # length 18
align 2
msg_p1_win>               dc "You win! You shoot first."      # length 25
align 2
msg_bot_win>              dc "Bot wins! Bot shoots first."    # length 27
align 2
msg_bot_chose>            dc "Bot: "
align 2
hello_message>            dc "Hello, welcome to the game Battleship. First, we'll draw lots. Choose your choice: stone, paper, or scissors."
align 2

# pointers
pointer_miss_matrix_arr>  dc 0                                # pointer to the miss matrix address
pointer_hit_matrix_arr>   dc 0                                # pointer to the hit matrix address
pointer_miss_arr>         dc 0                                # pointer to the miss array, needed for the kill check function to work with both bot and player
pointer_hit_arr>          dc 0                                # pointer to the hit array, needed for the kill check function to work with both bot and player
pointer_len_ship>         dc 0

# game settings
bot_ship_count>           dc 10
player_ship_count>        dc 10
retry_count>              dc 0
num_player_dec>           dc 20
num_bot_dec>              dc 20
current_selection>        dc 0xffff
current_player>           dc 0
p1_choice>                dc 0
p2_choice>                dc 0
first_shooter>            dc 0
prev_btn_state>           dc 0

# flags
player_placement_done>    dc 0
player_placement_mode>    dc 0                                # horizontal = 0, vertical = 1
enemy_generation_done>    dc 0                                # generating = 0, ready = 1

# bot state
bot_state>                dc 0                                # state: searches randomly = 0, found and searches for direction = 1, hits along the line = 2
target_dir>               dc 0                                # direction: up = 0, right = 1, down = 2, left = 3
curr_hit_x>               dc 0                                # x coordinate of the current cell we step from
curr_hit_y>               dc 0                                # y coordinate of the current cell we step from
hit_start_x>              dc 0                                # x coordinate of the first hit on the current ship
hit_start_y>              dc 0                                # y coordinate of the first hit

# coordinates
y_min>                    dc 0
y_max>                    dc 0
y_ver_fn>                 dc 0
x_ver_st>                 dc 0                                # coordinates of the ship start point
y_ver_st>                 dc 0
x_hor_fn>                 dc 0                                # coordinates of the ship end point
x_hor_st>                 dc 0                                # coordinates of the ship start point
y_hor_st>                 dc 0
x_ver>                    dc 0
y_ver>                    dc 0

# arrays
ship_mask>                dc 0, 0
ships_array>              dc 4, 3, 3, 2, 2, 2, 1, 1, 1, 1     # array of ship sizes

# board states
board_state_miss>         dc 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
board_state_hit>          dc 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
board_state_hit_bot>      dc 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
board_state_miss_bot>     dc 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
board_state_fire_bot>     dc 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
board_state_bot>          dc 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
board_state>              dc 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

end.