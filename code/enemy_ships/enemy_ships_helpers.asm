rsect enemy_ships_helpers

# include constants.asm
board_state_bot: ext

# include replacement.asm
check_field: ext

# try to place a vertical ship of size r4
# on success returns r0 = 0, on failure returns r0 = 1
# try to place a vertical ship of size r4
# on success returns r0 = 0, on failure returns r0 = 1
enemy_ship_try_vertical>
    # r5: X coord 
    # r6: Y coord
    # r2: size of ship
    push r6
    push r2    

    # reject ships that run beside the bottom edge
    move r2, r4   # r4 = r2 - ship len
    ldi r0, 10
    add r6, r4, r2  # r2 = Y + len
    cmp r2, r0
    bgt enemy_ship_vert_fail # it means, that ship lower then low border

    # check each segment and validate vertical ship
    move r4, r7 # len ship

    enemy_ship_try_vertical_loop:
        jsr enemy_ship_check_segment
        tst r0
        bnz enemy_ship_vert_fail

        dec r7
        tst r7
        bz enemy_ship_vert_success

        inc r6  # Y += 1
        br enemy_ship_try_vertical_loop

    enemy_ship_vert_success:
        # restore the original Y and place the ship
        pop r4       
        pop r0
        move r0, r6
        jsr enemy_ship_place_vertical
        ldi r0, 0
        rts

    enemy_ship_vert_fail:
        pop r4      
        pop r0
        ldi r0, 1
        rts

# try to place a horizontal ship of size r4
# on success returns r0 = 0, on failure returns r0 = 1
enemy_ship_try_horizontal>
    # r5: X coord 
    # r6: Y coord
    # r2: size of ship
    push r5
    push r2     

    # reject ships that would run beside the right edge
    move r2, r4
    ldi r0, 10
    add r5, r4, r2
    cmp r2, r0
    bgt enemy_ship_try_horizontal_fail

    # walk through each segment and validate the whole horizontal ship
    move r4, r7

    enemy_ship_try_horizontal_loop:
        jsr enemy_ship_check_segment
        tst r0
        bnz enemy_ship_try_horizontal_fail

        dec r7
        tst r7
        bz enemy_ship_try_horizontal_success

        inc r5
        br enemy_ship_try_horizontal_loop

    enemy_ship_try_horizontal_success:
        # Restore the original X and place the ship.
        pop r4       
        pop r0
        move r0, r5
        jsr enemy_ship_place_horizontal
        ldi r0, 0
        rts

    enemy_ship_try_horizontal_fail:
        pop r4      
        pop r0
        ldi r0, 1
        rts

# helpers func  
# load the board row for the current Y coordinate into r0
enemy_ship_load_row:
    ldi r0, board_state_bot
    add r0, r6, r0    # r6 - Y coord
    add r0, r6, r0
    ldw r0, r0
    rts

# check one cell on the bot board using X in r5 and Y in r6
enemy_ship_check_current_cell:
    # r5 - X 
    # r6 - Y
    # return r0 (1 - conflict, 0 - allow)

    jsr enemy_ship_load_row
    ldi r2, 9
    sub r2, r5, r2
    jsr check_field
    rts

# validate the current ship segment and all neighboring cells
enemy_ship_check_segment:
    # r5 - X 
    # r6 - Y
    # return r0 (1 - conflict, 0 - allow)

    # check (x, y)
    jsr enemy_ship_check_current_cell
    tst r0
    bnz enemy_ship_check_segment_fail

    # if x == 9: skip right neighbor
    ldi r0, 9   # max x
    cmp r5, r0  # cmp max_x and current_x
    beq enemy_ship_check_segment_skip_right

    # check (x+1, y)
    inc r5
    jsr enemy_ship_check_current_cell
    dec r5
    tst r0
    bnz enemy_ship_check_segment_fail

    enemy_ship_check_segment_skip_right:
        # if x == 0: skip left neighbor
        ldi r0, 0
        cmp r5, r0
        beq enemy_ship_check_segment_skip_left 

        # check (x - 1, y)
        dec r5
        jsr enemy_ship_check_current_cell
        inc r5
        tst r0
        bnz enemy_ship_check_segment_fail

    enemy_ship_check_segment_skip_left:
        # if y == 0: skip upper neighbor
        ldi r0, 0
        cmp r6, r0
        beq enemy_ship_check_segment_skip_up 

        # check (x, y - 1)
        dec r6
        jsr enemy_ship_check_current_cell
        inc r6
        tst r0
        bnz enemy_ship_check_segment_fail

    enemy_ship_check_segment_skip_up:
        # if y == 9: skip lower neighbor
        ldi r0, 9
        cmp r6, r0
        beq enemy_ship_check_segment_skip_down

        # check (x, y + 1)
        inc r6
        jsr enemy_ship_check_current_cell
        dec r6
        tst r0
        bnz enemy_ship_check_segment_fail

    enemy_ship_check_segment_skip_down:
        # if x == 9 or y == 0: skip top-right diagonal
        ldi r0, 9
        cmp r5, r0
        beq enemy_ship_check_segment_skip_top_right
        ldi r0, 0
        cmp r6, r0
        beq enemy_ship_check_segment_skip_top_right

        # check (x+1, y-1)
        inc r5
        dec r6
        jsr enemy_ship_check_current_cell
        inc r6
        dec r5
        tst r0
        bnz enemy_ship_check_segment_fail

    enemy_ship_check_segment_skip_top_right:
        # if x == 0 or y == 0: skip top-left diagonal
        ldi r0, 0
        cmp r5, r0
        beq enemy_ship_check_segment_skip_top_left
        cmp r6, r0
        beq enemy_ship_check_segment_skip_top_left

        # check (x-1, y-1)
        dec r5
        dec r6
        jsr enemy_ship_check_current_cell
        inc r6
        inc r5
        tst r0
        bnz enemy_ship_check_segment_fail

    enemy_ship_check_segment_skip_top_left:
        # if x == 9 or y == 9: skip bottom-right diagonal
        ldi r0, 9
        cmp r5, r0
        beq enemy_ship_check_segment_skip_bottom_right
        cmp r6, r0
        beq enemy_ship_check_segment_skip_bottom_right

        # check (x+1, y+1)
        inc r5
        inc r6
        jsr enemy_ship_check_current_cell
        dec r6
        dec r5
        tst r0
        bnz enemy_ship_check_segment_fail

    enemy_ship_check_segment_skip_bottom_right:
        # if x == 0 or y == 9: skip bottom-left diagonal
        ldi r0, 0
        cmp r5, r0
        beq enemy_ship_check_segment_skip_bottom_left
        ldi r0, 9
        cmp r6, r0
        beq enemy_ship_check_segment_skip_bottom_left

        # check (x-1, y+1)
        dec r5
        inc r6
        jsr enemy_ship_check_current_cell
        dec r6
        inc r5
        tst r0
        bnz enemy_ship_check_segment_fail

    enemy_ship_check_segment_skip_bottom_left:
        ldi r0, 0
        rts

    enemy_ship_check_segment_fail:
        ldi r0, 1
        rts

# build a bit mask for the current X coordinate
enemy_ship_build_mask_from_x:
    push r3

    # bit mask 
    ldi r2, 0b1000000000
    move r5, r3

    # if x == 0: mask done 
    tst r3
    beq enemy_ship_build_mask_done 

    enemy_ship_build_mask_loop:
        # create mask
        shr r2, r2, 1
        dec r3
        bne enemy_ship_build_mask_loop

    enemy_ship_build_mask_done:
        pop r3
        rts

# set the current cell bit in board_state_bot
enemy_ship_write_current_cell:
    # load the row, build the mask, and store the updated row back
    jsr enemy_ship_load_row
    jsr enemy_ship_build_mask_from_x
    or r0, r2, r2

    ldi r0, board_state_bot
    add r0, r6, r0
    add r0, r6, r0
    stw r0, r2
    rts

# write a vertical ship from the current start point
enemy_ship_place_vertical:
    # r7 - ship length 
    move r4, r7

    enemy_ship_place_vertical_loop:
        tst r7
        bz enemy_ship_place_vertical_done

        # write one segment, then move one row down
        jsr enemy_ship_write_current_cell

        dec r7
        inc r6     # Y += 1
        br enemy_ship_place_vertical_loop

    enemy_ship_place_vertical_done:
        rts

# write a horizontal ship from the current start point
enemy_ship_place_horizontal:
    # r7 - ship length 
    move r4, r7

    enemy_ship_place_horizontal_loop:
        tst r7
        bz enemy_ship_place_horizontal_done

        # write one segment, then move one column right
        jsr enemy_ship_write_current_cell

        dec r7
        inc r5    # X += 1
        br enemy_ship_place_horizontal_loop

    enemy_ship_place_horizontal_done:
        rts

rand>
    # GENERATED X AND Y COORDS OF SHIP (0-9)
    # return X -> r5, Y -> r6

    ldi r2, 0xff82 # generator 
    # generate start coordinates (X, Y)
    ldb r2, r5 # random value X -> r5
    ldb r2, r6 # random value Y -> r6 

    ldi r2, 0x000f  # bit mask
    and r5, r2, r5  # X & 0x00f -> r5
    and r6, r2, r6  # Y & 0x00f -> r6

    # MOD functions
    ldi r0, 10 # for MOD 
    mod10X: # X = X % 10 -> r5
        cmp r5, r0
        blt mod10Y 
        sub r5, r0, r5
        br mod10X

    mod10Y: # Y = Y % 10 -> r6 
        cmp r6, r0
        blt rand_func_exit
        sub r6, r0, r6
        br mod10Y

    rand_func_exit: 
        rts

exit> 
    # for exit, break and other
    rts


end.
