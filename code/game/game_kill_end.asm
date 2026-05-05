rsect game_kill_end

# include constants.asm
board_state: ext
ship_mask: ext
y_min: ext
y_max: ext
pointer_hit_arr: ext
pointer_hit_matrix_arr: ext
pointer_miss_matrix_arr: ext
pointer_miss_arr: ext
bot_state: ext
bot_ship_count: ext
player_ship_count: ext

# include write_tty.asm
clear_tty: ext
write_bot: ext
write_player: ext
write_win: ext
write_space: ext

check_kill_or_end>
    # r5 = ship mask
    # r0 = ship y coordinate
    # r1 = ship x coordinate
    # r2 = ship state array

    # Check whether the ship is horizontal
    add r0, r2, r4
    add r0, r4, r4
    ldw r4, r4 # ship state

    # Find the left boundary
    ldi r3, 0 # number of left shifts

    left:
    tst r1 
    blt left_scan_done # no more cells to the left

    and r4, r5, r6 # r6 = ship exists in this cell
    tst r6
    beq left_scan_done # no ship in this cell

    ldi r6, ship_mask
    ldw r6, r7 # load temp storage for current mask
    or r5, r7, r7 # remember the hit position
    stw r6, r7 # store it

    shl r5, r5, 1 # shift left
    inc r3 # increase shift count
    br left

    # Find the right boundary
    left_scan_done:
    restore_left_shift: # restore shift
    tst r3 
    beq restore_left_shift_done
    shr r5, r5, 1
    dec r3
    br restore_left_shift
    restore_left_shift_done:

    right:
    ldi r6, 9 # edge check
    cmp r1, r6
    bgt right_scan_done # no more cells to the right

    and r4, r5, r6 # r6 = ship exists in this cell
    tst r6
    beq right_scan_done # no ship in this cell

    ldi r6, ship_mask
    ldw r6, r7 # load temp storage for current mask
    or r5, r7, r7 # remember the hit position
    stw r6, r7 # store it

    shr r5, r5, 1 # shift right
    inc r3 # increase shift count
    br right

    right_scan_done:
    restore_right_shift: # restore shift
    tst r3 
    beq restore_right_shift_done
    shl r5, r5, 1
    dec r3
    br restore_right_shift
    restore_right_shift_done:

    # Check whether the ship is horizontal; if so, ship_mask has more than one bit
    ldi r3, ship_mask
    ldw r3, r3

    # ship_mask always has one bit in the same place as r5, but if there are more,
    # then the ship is horizontal. If r5 and ship_mask match, the ship is single-cell or vertical.
    cmp r3, r5
    bne horizontal_kill_check # ship is vertical, so check for kill

    # Check vertical or single-cell ship
    ldi r3, 0 # number of upward shifts

    # Find the upper boundary
    up:
    tst r0
    blt up_scan_done

    add r0, r2, r4
    add r0, r4, r4
    ldw r4, r4 # ship state
    and r4, r5, r6 # r6 = ship exists in this cell

    tst r6
    beq up_scan_done

    ldi r6, y_min
    stw r6, r0
    inc r3
    dec r0
    br up

    up_scan_done:
    restore_up_shift: # restore Y
    tst r3 
    beq restore_up_shift_done
    inc r0
    dec r3
    br restore_up_shift
    restore_up_shift_done:

    down:
    ldi r6, 9 # edge check
    cmp r0, r6
    bgt down_scan_done # no more cells below

    add r0, r2, r4
    add r0, r4, r4
    ldw r4, r4 # ship state
    and r4, r5, r6 # r6 = ship exists in this cell

    tst r6
    beq down_scan_done

    ldi r6, y_max
    stw r6, r0
    inc r3
    inc r0
    br down

    down_scan_done:
    restore_down_shift: # restore Y
    tst r3 
    beq restore_down_shift_done
    dec r0
    dec r3
    br restore_down_shift
    restore_down_shift_done:

    br vertical_kill_check

    horizontal_kill_check: 
    ldi r4, pointer_hit_arr
    ldw r4, r4
    add r4, r0, r4
    add r4, r0, r4
    ldw r4, r4 # load hit ships

    and r4, r3, r4 # ship mask AND hit deck cells
    cmp r4, r3 # if not equal, the ship is not yet sunk
    bne cleanup_and_return

    # Ship is sunk; if this was the bot's turn, reset its state to 0
    ldi r1, pointer_hit_matrix_arr
    ldw r1, r1
    ldi r4, 0xff56
    cmp r1, r4
    bne dec_count_ship_bot # not the bot's turn

    ldi r6, player_ship_count # decrement player ship count
    ldw r6, r4
    dec r4
    stw r6, r4

    ldi r1, bot_state
    ldi r4, 0
    stw r1, r4
    br build_horizontal_aoe

    dec_count_ship_bot:
    ldi r6, bot_ship_count # decrement bot ship count
    ldw r6, r4
    dec r4
    stw r6, r4

    build_horizontal_aoe:
    ldi r1, pointer_miss_matrix_arr
    ldw r1, r1
    add r1, r0, r1
    add r1, r0, r1

    ldi r4, pointer_miss_arr
    ldw r4, r4
    add r4, r0, r4
    add r4, r0, r4

    ldw r4, r7

    shl r3, r6, 1 # paint to the left of the ship
    or r3, r6, r3
    shr r3, r6, 1 # paint to the right of the ship
    or r3, r6, r3

    or r7, r3, r7 # merge with already painted cells
    stw r4, r7 # apply it in RAM

    # --- DYNAMIC SHIFT 1 (CURRENT HORIZONTAL ROW) ---
    move r7, r2
    ldi r5, pointer_miss_matrix_arr
    ldw r5, r5
    push r6
    ldi r6, 0xff40
    cmp r5, r6
    pop r6
    bne skip_horizontal_matrix_shift_1
    shl r2, r2, 2  # Shift by 2 if this is the bot matrix (80a2)
    skip_horizontal_matrix_shift_1:
    stw r1, r2 # draw on screen

    push r5
    ldi r5, 9
    cmp r0, r5
    pop r5
    bge skip_horizontal_bottom # Если корабль на 9-й строке, ореол вниз не рисуем!

    inc r4 # paint below the ship
    inc r4
    inc r1
    inc r1

    ldw r4, r7
    or r7, r3, r7
    stw r4, r7 # apply it in RAM

    # --- DYNAMIC SHIFT 2 (ROW BELOW HORIZONTAL SHIP) ---
    move r7, r2
    ldi r5, pointer_miss_matrix_arr
    ldw r5, r5
    push r6
    ldi r6, 0xff40
    cmp r5, r6
    pop r6
    bne skip_horizontal_matrix_shift_2
    shl r2, r2, 2
    skip_horizontal_matrix_shift_2:
    stw r1, r2 # draw on screen

    dec r4
    dec r4
    dec r1
    dec r1

    skip_horizontal_bottom:

    tst r0
    beq skip_horizontal_top # Если корабль на 0-й строке, ореол вверх не рисуем!

    dec r4 # paint above the ship
    dec r4
    dec r1
    dec r1

    ldw r4, r7
    or r7, r3, r7
    stw r4, r7 # apply it in RAM

    # --- DYNAMIC SHIFT 3 (ROW ABOVE HORIZONTAL SHIP) ---
    move r7, r2
    ldi r5, pointer_miss_matrix_arr
    ldw r5, r5
    push r6
    ldi r6, 0xff40
    cmp r5, r6
    pop r6
    bne skip_horizontal_matrix_shift_3
    shl r2, r2, 2
    skip_horizontal_matrix_shift_3:
    stw r1, r2 # draw on screen

    skip_horizontal_top:
    br cleanup_and_return

    vertical_kill_check:
    # Check whether the ship is killed
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
    scan_vertical_cells:
    cmp r4, r6
    bgt mark_ship_as_sunk

    inc r1
    inc r1

    ldw r1, r7
    inc r4

    and r7, r5, r7 
    tst r7
    beq cleanup_and_return
    br scan_vertical_cells

    mark_ship_as_sunk:
    # Ship is sunk; if this was the bot's turn, reset its state to 0
    ldi r4, pointer_hit_matrix_arr
    ldw r4, r4
    ldi r6, 0xff56
    cmp r4, r6
    bne dec_count_ship_bot2 # not the bot's turn

    ldi r6, player_ship_count # decrement player ship count
    ldw r6, r4
    dec r4
    stw r6, r4

    ldi r6, bot_state
    ldi r4, 0
    stw r6, r4

    br build_vertical_aoe       # IMPORTANT FIX: do not decrement the bot again

    dec_count_ship_bot2:
    ldi r6, bot_ship_count # decrement bot ship count
    ldw r6, r4
    dec r4
    stw r6, r4

    build_vertical_aoe:
    # Build the halo
    ldi r4, y_min
    ldw r4, r4
    ldi r6, y_max
    ldw r6, r6

    shl r5, r7, 1 # build halo
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

    tst r4 # r4 - это y_min
    beq skip_vertical_top

    # Build halo one cell above
    dec r7
    dec r7
    dec r1
    dec r1
    ldw r7, r2 # state one cell above
    or r2, r5, r3 # merge

    # --- DYNAMIC SHIFT 1 (ROW ABOVE VERTICAL SHIP) ---
    move r3, r2
    ldi r0, pointer_miss_matrix_arr
    ldw r0, r0
    push r6
    ldi r6, 0xff40
    cmp r0, r6
    pop r6
    bne skip_vertical_matrix_shift_1
    shl r2, r2, 2  # Shift by 2 if this is the bot matrix (80a2)
    skip_vertical_matrix_shift_1:
    stw r1, r2 # draw on screen
    stw r7, r3 # RAM: halo one cell above

    # Возвращаем указатели обратно на y_min
    inc r7 
    inc r7
    inc r1 
    inc r1

    skip_vertical_top:

    ldw r7, r2 # state of the current cell (y_min)
    or r2, r5, r3 # merge

    # --- DYNAMIC SHIFT 2 (FIRST VERTICAL DECK) ---
    move r3, r2
    ldi r0, pointer_miss_matrix_arr
    ldw r0, r0
    push r6
    ldi r6, 0xff40
    cmp r0, r6
    pop r6
    bne skip_vertical_matrix_shift_2
    shl r2, r2, 2
    skip_vertical_matrix_shift_2:
    stw r1, r2 # draw on screen
    stw r7, r3 # RAM: y_min halo drawn

    scan_vertical_body:
    cmp r4, r6
    beq single_cell_ship # single-cell ship or only one cell left

    inc r4 
    inc r7
    inc r7
    inc r1
    inc r1

    ldw r7, r2 
    or r2, r5, r3 # merge

    # --- DYNAMIC SHIFT 3 (VERTICAL SHIP BODY) ---
    move r3, r2
    ldi r0, pointer_miss_matrix_arr
    ldw r0, r0
    push r6
    ldi r6, 0xff40
    cmp r0, r6
    pop r6
    bne skip_vertical_matrix_shift_3
    shl r2, r2, 2
    skip_vertical_matrix_shift_3:
    stw r1, r2 # draw on screen
    stw r7, r3 # RAM

    br scan_vertical_body

    single_cell_ship:
    push r5
    ldi r5, 9
    cmp r6, r5 # r6 - y_max
    pop r5
    bge skip_vertical_bottom

    inc r7 
    inc r7
    inc r1 
    inc r1

    ldw r7, r2 # state of the cell below
    or r2, r5, r3 # merge

    # --- DYNAMIC SHIFT 4 (ROW BELOW VERTICAL SHIP) ---
    move r3, r2
    ldi r0, pointer_miss_matrix_arr
    ldw r0, r0
    push r6
    ldi r6, 0xff40
    cmp r0, r6
    pop r6
    bne skip_vertical_matrix_shift_4
    shl r2, r2, 2
    skip_vertical_matrix_shift_4:
    stw r1, r2 # draw on screen
    stw r7, r3 # RAM

    skip_vertical_bottom:

    cleanup_and_return:
    ldi r0, ship_mask
    ldi r1, 0
    stw r0, r1
    rts
        
end.