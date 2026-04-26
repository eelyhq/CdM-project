rsect game_bot_turn

# include constants.asm
bot_state: ext
hit_start_x: ext
hit_start_y: ext
target_dir: ext
curr_hit_x: ext
curr_hit_y: ext
board_state_miss: ext
board_state_hit: ext
board_state: ext
pointer_hit_matrix_arr: ext
pointer_miss_matrix_arr: ext
pointer_miss_arr: ext
board_state_miss_bot: ext
pointer_hit_arr: ext
retry_count: ext      

# include game_kill_end.asm
check_kill_or_end: ext
player_hit: ext

# include utils.asm
check_bot_win: ext

bot_hit>
    jsr check_bot_win

    # ----------------------------------------------------
    # FIX: We MUST reset retry_count! 
    # If we don't, the bot can get trapped in an infinite 
    # loop bouncing between walls/misses in State 1 and 2!
    # ----------------------------------------------------
    ldi r0, 0
    ldi r1, retry_count
    stw r1, r0

    normal_bot_flow:
    # ----------------------------------------------------
    # FIX: FAIL-SAFE COUNTER
    # If the bot checks all 4 directions and they are all 
    # blocked, it forces state 0 to break the infinite loop.
    # ----------------------------------------------------
    ldi r0, retry_count
    ldw r0, r1              
    inc r1
    stw r0, r1

    ldi r2, 6
    cmp r1, r2               
    bgt force_state_0_global 
    br continue_bot_flow

    force_state_0_global:
    ldi r2, 0
    ldi r5, bot_state
    stw r5, r2
    br generate_random_cell

    continue_bot_flow:
    ldi r0, bot_state
    ldw r0, r0
    tst r0 
    beq generate_random_cell 

    ldi r1, 1
    cmp r1, r0
    beq search_from_start # State 1

    # State 2
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
    beq direction_blocked     
    dec r1
    br candidate_cell_ready

    dir1:
    ldi r2, 9
    cmp r2, r0
    beq direction_blocked
    inc r0
    br candidate_cell_ready

    dir2:
    ldi r2, 9
    cmp r2, r1
    beq direction_blocked
    inc r1
    br candidate_cell_ready

    dir3:
    tst r0              
    beq direction_blocked
    dec r0
    br candidate_cell_ready

    direction_blocked:
    br handle_miss_without_write   # Change direction if we hit a wall

    generate_random_cell:
    
    generate_x:
    ldi r2, 0xff82
    ldw r2, r0     # generated x
    ldi r2, 0x000f
    and r2, r0, r0 # take the first 4 bits (0-15)
    
    ldi r3, 10
    cmp r3, r0     # (10 - X)
    bgt generate_y # If 10 > X (meaning X is 0-9), X is good! Move to Y.
    br generate_x  # If X >= 10, reroll X!

    generate_y:
    ldi r2, 0xff82
    ldw r2, r1     # generated y
    ldi r2, 0x000f
    and r2, r1, r1 # take the first 4 bits (0-15)
    
    ldi r3, 10
    cmp r3, r1     # (10 - Y)
    bgt check_parity # If 10 > Y (meaning Y is 0-9), Y is good!
    br generate_y  # If Y >= 10, reroll Y!

    check_parity:
    # --- 50% CHECKERBOARD STRATEGY ---
    # Check parity: Is (X + Y) an even number?
    add r0, r1, r2            # r2 = X + Y
    ldi r3, 1
    and r3, r2, r2            # r2 = (X + Y) & 1
    tst r2
    bne generate_random_cell  # If r2 == 1 (ODD), reroll completely!
    
    br candidate_cell_ready


    # --- STEP HOP IF THE CELL IS OCCUPIED (State 0) ---
    advance_scan_cursor:
    ldi r2, 3
    add r0, r2, r0      # x = x + 3 
    
    ldi r2, 10
    cmp r2, r0          # (10 - X)
    bgt candidate_cell_ready  # FIX: if 10 > X (X < 10), DO NOT change Y!
    
    # If X >= 10, wrap X around and increment Y
    ldi r2, 10
    sub r0, r2, r0      # x = x - 10
    
    inc r1              # y = y + 1
    
    ldi r2, 10
    cmp r2, r1          # (10 - Y)
    bgt candidate_cell_ready  # if 10 > Y, check the cell
    
    ldi r1, 0           # Otherwise (end of board): y = 0
    br candidate_cell_ready            
     

    candidate_cell_ready:
    # --- GENERATE MASK (shared by all checks and writes) ---
    ldi r4, 0b1000000000
    move r0, r3 # r3 = X coordinate
    build_fire_mask:
    tst r3
    beq build_fire_mask_done
    shr r4, r4, 1
    dec r3
    br build_fire_mask
    build_fire_mask_done:
    # Now r4 contains the ideal shot mask

    # Check misses
    ldi r2, board_state_miss
    add r1, r2, r2
    add r1, r2, r2
    ldw r2, r3 
    and r4, r3, r3 # mask & miss row
    tst r3
    beq check_hit_arr   # If 0 -> no miss here, check hits

    # If we already shot here (miss):
    ldi r2, bot_state
    ldw r2, r2
    tst r2
    beq advance_scan_cursor  # State 0 -> move right!
    br handle_miss_without_write   # State 1/2 -> change direction

    check_hit_arr:
    ldi r2, board_state_hit
    add r1, r2, r2
    add r1, r2, r2
    ldw r2, r3 
    and r4, r3, r3 # mask & hit row
    tst r3
    beq candidate_has_ship           # If 0 -> the cell is completely clean

    # IF WE ALREADY HIT HERE:
    ldi r2, bot_state
    ldw r2, r2
    tst r2
    beq advance_scan_cursor  # State 0 -> move right!

    ldi r3, 1
    cmp r2, r3
    beq handle_miss_without_write  # State 1 -> direction blocked, change it

    # State 2 -> Skip already destroyed cell!
    ldi r3, curr_hit_x
    stw r3, r0
    ldi r3, curr_hit_y
    stw r3, r1
    br apply_direction

    candidate_has_ship:
    ldi r2, board_state
    add r1, r2, r2
    add r1, r2, r2
    ldw r2, r3 
    and r4, r3, r3 # mask & ships
    tst r3
    beq handle_miss           # No ship -> write miss!

    hit2:
    # --- UPDATE BOT STATE ---
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

    # --- WRITE HIT TO SCREEN (mask is already ready in r4) ---
    ldi r2, 0xff56
    add r1, r2, r2
    add r1, r2, r2     

    ldi r5, board_state_hit
    add r1, r5, r5
    add r1, r5, r5

    ldw r5, r6      # Read previous hits
    or r4, r6, r6   # r6 = previous hits | new mask (r4)
    stw r5, r6      # Store back to memory

    move r4, r5     # IMPORTANT: put the mask in r5 for check_kill_or_end
    move r6, r3     # Put the whole row in r3 for the screen
    shl r3, r3, 3   # Shift for matrix 8086
    stw r2, r3      # Draw the hit on screen

    # Swap X and Y before kill check (the function expects r0=Y, r1=X)
    move r0, r4
    move r1, r0
    move r4, r1

    # Check whether the ship was killed
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

    jsr check_bot_win

    br normal_bot_flow

    # --- LOGIC FOR "DEAD-END" MISSES ---
    handle_miss_without_write:
    ldi r2, bot_state
    ldw r2, r2
    ldi r5, 1
    cmp r5, r2
    beq advance_direction_no_write
    ldi r5, 2
    cmp r5, r2
    bne normal_bot_flow
    br reverse_direction_no_write

    advance_direction_no_write:
    ldi r2, target_dir
    ldw r2, r5
    inc r5
    ldi r6, 0b11
    and r5, r6, r5     
    stw r2, r5
    br normal_bot_flow  

    reverse_direction_no_write:
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

    # --- LOGIC FOR NORMAL MISSES ---
    handle_miss:
    ldi r2, bot_state
    ldw r2, r2
    ldi r5, 1
    cmp r5, r2
    beq advance_direction  
    ldi r5, 2
    cmp r5, r2
    bne write_miss_record 

    reverse_direction: 
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
    br write_miss_record   

    advance_direction:
    ldi r2, target_dir
    ldw r2, r5
    inc r5
    ldi r6, 0b11
    and r5, r6, r5     
    stw r2, r5

    write_miss_record:
    # Write miss
    ldi r2, 0xff40
    add r1, r2, r2
    add r1, r2, r2
    
    ldi r5, board_state_miss
    add r1, r5, r5
    add r1, r5, r5

    ldw r5, r6
    or r4, r6, r3   # r3 = previous misses | mask (r4)
    stw r5, r3      # store in memory

    shl r3, r3, 2   # Shift 2 left for bot misses (0xff40)
    stw r2, r3      # Draw on screen

    rts

end.