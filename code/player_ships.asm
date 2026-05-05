rsect player_ships_replacement

# include constants.asm
ships_array: ext
pointer_len_ship: ext
board_state: ext
player_placement_done: ext
player_placement_mode: ext
x_hor_st: ext
y_hor_st: ext
x_ver_st: ext
y_ver_st: ext

# include replacement.asm
check_placement: ext

# include write_tty.asm
clear_tty: ext
print_place_your_ship: ext
write_bad_placement: ext

enemy_generation_done: ext
print_newline: ext
write_ship_generation: ext
prev_btn_state: ext

# ==========================================
# initialize, called once, from main
# ==========================================
player_ships_replacement_init>
    ldi r0, ships_array
    ldi r1, pointer_len_ship
    stw r1, r0

    ldi r0, 0
    ldi r1, player_placement_done
    stw r1, r0

    jsr spawn_current_ship
    rts

# ==========================================
# spawn ship
# ==========================================
spawn_current_ship>
    ldi r0, pointer_len_ship
    ldw r0, r0
    ldb r0, r0      # r0 = size of ship
    tst r0
    bnz continue_spawn
    
    # if ships run out
    ldi r0, 1
    ldi r1, player_placement_done
    stw r1, r0
    jsr clear_tty  
    ldi r0, enemy_generation_done
    ldw r0, r0 
    tst r0
    beq write_ship_generation # if bot doesn't finished ship generating, write corresponding inscription
    rts

continue_spawn:
    jsr refresh_placement_tty

    # reset ship to horizontal mode
    ldi r0, 0
    ldi r1, player_placement_mode
    stw r1, r0

    # reset coordinates
    ldi r0, 0
    ldi r1, x_hor_st
    stw r1, r0
    ldi r1, y_hor_st
    stw r1, r0

    jsr draw_preview_hor
    rts

# ==========================================
# writing to TTY
# ==========================================
refresh_placement_tty>
    push r0
    
    jsr clear_tty
    
    # check, are the bot's ships generated
    ldi r0, enemy_generation_done
    ldw r0, r0
    tst r0
    bnz skip_gen_msg
    
    jsr write_ship_generation
    jsr print_newline
    
skip_gen_msg:
    # check, are the player's ships placed
    ldi r0, player_placement_done
    ldw r0, r0
    tst r0
    bnz skip_place_msg
    
    jsr print_place_your_ship
    
skip_place_msg:
    pop r0
    rts

# ==========================================
# player's ship movement
# ==========================================
player_placement_step> 
    ldi r0, 0xff80 
    ldb r0, r2       # read button to r2

    # --- front detector ----------------------------
    ldi r0, prev_btn_state
    ldb r0, r1       # r1 = previous pushed button
    stb r0, r2       # save current button to prev_btn_state
    
    not r1, r1
    and r2, r1, r2   # r2 = curr and ~prev
    tst r2
    bz exit_step     # if prev button = curr -> exit 
    # ---------------------------------------------------

    # read placement mode
    ldi r0, player_placement_mode 
    ldw r0, r0 
    tst r0 
    bz hor_mode 

    jsr handle_ver # if ver mode

exit_step:
    rts 

hor_mode: 
    jsr handle_hor # if hor mode
    rts

# ==========================================
# movement logic (horizontal)
# ==========================================
handle_hor:
    ldi r6, pointer_len_ship
    ldw r6, r6
    ldb r6, r6      # r6 = size of ship

    # --- left ---
    ldi r3, 1
    and r2, r3, r4
    bz check_up_hor
    ldi r0, x_hor_st
    ldw r0, r0
    tst r0
    bz redraw_hor
    dec r0
    ldi r1, x_hor_st
    stw r1, r0
    br redraw_hor

check_up_hor:
    # --- up ---
    ldi r3, 2
    and r2, r3, r4
    bz check_right_hor
    ldi r0, y_hor_st
    ldw r0, r0
    tst r0
    bz redraw_hor
    dec r0
    ldi r1, y_hor_st
    stw r1, r0
    br redraw_hor

check_right_hor:
    # --- right ---
    ldi r3, 4
    and r2, r3, r4
    bz check_down_hor
    ldi r0, x_hor_st
    ldw r0, r0
    add r0, r6, r4  # r4 = x + size = right ship cell
    ldi r5, 10
    cmp r4, r5
    bge redraw_hor # border = 9
    inc r0
    ldi r1, x_hor_st
    stw r1, r0
    br redraw_hor

check_down_hor:
    # --- down ---
    ldi r3, 8
    and r2, r3, r4
    bz check_reverse_hor
    ldi r0, y_hor_st
    ldw r0, r0
    ldi r5, 9
    cmp r0, r5
    bge redraw_hor
    inc r0
    ldi r1, y_hor_st
    stw r1, r0
    br redraw_hor

check_reverse_hor:
    # --- reverse ---
    ldi r3, 16
    and r2, r3, r4
    bz check_place_hor

    # check for exit beyond border
    ldi r0, y_hor_st
    ldw r0, r0
    ldi r6, pointer_len_ship
    ldw r6, r6
    ldb r6, r6      # r6 = size
    add r0, r6, r4  # r4 = y + size
    ldi r5, 10
    cmp r4, r5
    bgt redraw_hor

    ldi r0, 1
    ldi r1, player_placement_mode
    stw r1, r0
    ldi r0, x_hor_st
    ldw r0, r0
    ldi r1, x_ver_st
    stw r1, r0
    ldi r0, y_hor_st
    ldw r0, r0
    ldi r1, y_ver_st
    stw r1, r0
    jsr draw_preview_ver
    rts

check_place_hor:
    # --- commit ---
    ldi r3, 32
    and r2, r3, r4
    bz redraw_hor

    jsr get_hor_mask  # r1 = mask
    ldi r0, y_hor_st
    ldw r0, r0
    jsr check_placement
    tst r2
    bnz bad_placement_hor # if player can't place ship -> write corresponding inscription
    
    # success! write to board_state
    jsr get_hor_mask
    ldi r0, y_hor_st
    ldw r0, r0
    ldi r3, board_state
    add r0, r3, r3
    add r0, r3, r3    # r3 = board_state[y]
    
    ldw r3, r4        # r4 = current state of board_state[y]
    or r4, r1, r4     # r4 = row | mask new ship
    stw r3, r4        # save row to  board_state[y] (in such way, we add ship in board_state array)
    
    # shift pointer to new ship
    ldi r0, pointer_len_ship
    ldw r0, r1
    inc r1
    inc r1
    ldi r2, pointer_len_ship
    stw r2, r1
    jsr spawn_current_ship
    rts

bad_placement_hor:
    jsr write_bad_placement

redraw_hor:
    jsr draw_preview_hor
    rts

# ==========================================
# movement logic (vertical)
# ==========================================
handle_ver:
    ldi r6, pointer_len_ship
    ldw r6, r6
    ldb r6, r6      # r6 = size of ship

    # --- left ---
    ldi r3, 1
    and r2, r3, r4
    bz check_up_ver
    ldi r0, x_ver_st
    ldw r0, r0
    tst r0
    bz redraw_ver
    dec r0
    ldi r1, x_ver_st
    stw r1, r0
    br redraw_ver

check_up_ver:
    # --- up ---
    ldi r3, 2
    and r2, r3, r4
    bz check_right_ver
    ldi r0, y_ver_st
    ldw r0, r0
    tst r0
    bz redraw_ver
    dec r0
    ldi r1, y_ver_st
    stw r1, r0
    br redraw_ver

check_right_ver:
    # --- right ---
    ldi r3, 4
    and r2, r3, r4
    bz check_down_ver
    ldi r0, x_ver_st
    ldw r0, r0
    ldi r5, 9
    cmp r0, r5
    bge redraw_ver
    inc r0
    ldi r1, x_ver_st
    stw r1, r0
    br redraw_ver

check_down_ver:
    # --- down ---
    ldi r3, 8
    and r2, r3, r4
    bz check_reverse_ver
    ldi r0, y_ver_st
    ldw r0, r0
    add r0, r6, r4  # y + size = lower ship cell. it needed to prevent ship movement beyond the borders
    ldi r5, 10
    cmp r4, r5
    bge redraw_ver
    inc r0
    ldi r1, y_ver_st
    stw r1, r0
    br redraw_ver

check_reverse_ver:
    # --- reverse ---
    ldi r3, 16
    and r2, r3, r4
    bz check_place_ver

    # check for exit beyond border
    ldi r0, x_ver_st
    ldw r0, r0
    ldi r6, pointer_len_ship
    ldw r6, r6
    ldb r6, r6      # r6 = size
    add r0, r6, r4  # r4 = x + size
    ldi r5, 10
    cmp r4, r5
    bgt redraw_ver 

    ldi r0, 0
    ldi r1, player_placement_mode # change mode to horizontal
    stw r1, r0
    ldi r0, x_ver_st # copy coordinates 
    ldw r0, r0
    ldi r1, x_hor_st
    stw r1, r0
    ldi r0, y_ver_st
    ldw r0, r0
    ldi r1, y_hor_st
    stw r1, r0
    jsr draw_preview_hor
    rts

check_place_ver:
    # --- commit ---
    ldi r3, 32
    and r2, r3, r4
    bz redraw_ver
    
    jsr get_ver_mask
    push r1
    ldi r0, y_ver_st
    ldw r0, r0
    ldi r4, 0       # mistakes collector
    
ver_check_loop: # we need to check all ships cells, because they situated in different rows
    push r0
    push r1
    push r6
    jsr check_placement
    pop r6
    pop r1
    pop r0
    or r2, r4, r4
    inc r0
    dec r6
    bne ver_check_loop
    
    pop r1
    tst r4 # if r4 != 0, consequently, player can't place ship there
    bnz bad_placement_ver
    
    # success! write to board_state
    ldi r6, pointer_len_ship
    ldw r6, r6
    ldb r6, r6
    ldi r0, y_ver_st
    ldw r0, r0
    
ver_commit_loop: # save ship in board state array
    move r0, r3
    shl r3, r3, 1
    ldi r4, board_state
    add r4, r3, r3    # r3 pointed on board_state[y]
    
    ldw r3, r5        # r5 = current state of  board_state[y]
    or r5, r1, r5     # r5 = rorw | mask of new ship
    stw r3, r5        # save new ship in board_state[y]
    
    inc r0
    dec r6
    bne ver_commit_loop
    
    # shift pointer to next ship length
    ldi r0, pointer_len_ship
    ldw r0, r2
    inc r2
    inc r2
    ldi r3, pointer_len_ship
    stw r3, r2
    jsr spawn_current_ship
    rts
    
bad_placement_ver:
    jsr write_bad_placement
redraw_ver:
    jsr draw_preview_ver
    rts

# ==========================================
# auxiliary functions
# ==========================================

get_hor_mask: # for horizontal ship
    ldi r6, pointer_len_ship 
    ldw r6, r6 
    ldb r6, r6 
    ldi r7, 0 
    ldi r3, 0b1000000000 
mask_loop: # make ships cell based on it's size
    or r3, r7, r7 
    shr r7, r7, 1 
    dec r6 
    bne mask_loop 
    shl r7, r7, 1 # return one extra shift
    ldi r0, x_hor_st 
    ldw r0, r0 
    tst r0 
    bz mask_done 
shift_loop: # shift ship to correct x coordinate 
    shr r7, r7, 1 
    dec r0 
    bne shift_loop 
mask_done: 
    move r7, r1 
    rts

get_ver_mask: # for vertical ship
    ldi r7, 0b1000000000 
    ldi r0, x_ver_st 
    ldw r0, r0 
    tst r0 
    bz v_mask_done 
v_shift_loop: 
    shr r7, r7, 1 
    dec r0 
    bne v_shift_loop 
v_mask_done: 
    move r7, r1 
    rts

# matrix render
draw_preview_hor:
draw_preview_ver:
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5
    push r6

    # full clear matrix 
    ldi r0, 0          #  y = 0
clean_matrix_loop:
    move r0, r2
    shl r2, r2, 1      # r2 = y * 2 

    ldi r3, board_state
    add r3, r2, r3
    ldw r3, r3         # r3 = board_state[y]

    ldi r4, 0xff6a     # player matrix with ships
    add r4, r2, r4
    stw r4, r3         # clear row

    inc r0
    ldi r5, 10
    cmp r0, r5
    blt clean_matrix_loop

    # define ship orientation 
    ldi r0, player_placement_mode
    ldw r0, r0
    tst r0
    bz draw_h_overlay

draw_v_overlay:
    # draw vertical ship
    jsr get_ver_mask
    ldi r6, pointer_len_ship 
    ldw r6, r6 
    ldb r6, r6         # r6 = size 
    ldi r0, y_ver_st 
    ldw r0, r0 
v_overlay_loop: 
    move r0, r2 
    shl r2, r2, 1 
    ldi r4, 0xff6a 
    add r4, r2, r4 

    ldi r3, board_state 
    add r3, r2, r3 
    ldw r3, r3 

    or r3, r1, r5 
    stw r4, r5 

    inc r0 
    dec r6 
    bne v_overlay_loop 
    br finish_draw

draw_h_overlay:
    # draw horizontal ship
    jsr get_hor_mask 
    ldi r0, y_hor_st 
    ldw r0, r0 
    move r0, r2 
    shl r2, r2, 1 
    ldi r4, 0xff6a 
    add r4, r2, r4 

    ldi r3, board_state 
    add r3, r2, r3 
    ldw r3, r3 

    or r3, r1, r5 
    stw r4, r5 

finish_draw:
    pop r6
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rts

end.