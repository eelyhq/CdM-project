rsect player_ships_horizontal

# include constants.asm
board_state: ext
pointer_len_ship: ext
x_hor_st: ext
y_hor_st: ext
x_hor_fn: ext
prev_btn_state: ext
check_button_ver: ext
return: ext

# include replacement.asm
check_placement: ext

# include write_tty.asm
write_bad_placement: ext

bad_placement_ship_hor: 
    jsr write_bad_placement 
    br check_button_hor

check_button_hor>
    # Horizontal placement mode
    # r4 is the screen row pointer, r5 is the ship mask

    ldi r0, 0xff80
    ldb r0, r1

    # Edge detector
    ldi r3, prev_btn_state
    ldb r3, r2
    stb r3, r1

    not r2, r2
    and r2, r1, r2

    check_left_hor:
        ldi r3, 1
        and r2, r3, r7
        tst r7
        beq check_up_hor

        # x == 0, so left is blocked.
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

        # Redraw preview.
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
        and r2, r3, r7
        tst r7
        beq check_right_hor

        # y == 0, so up is blocked.
        ldi r3, y_hor_st
        ldw r3, r3
        tst r3
        beq check_button_hor

        dec r3
        ldi r2, y_hor_st
        stw r2, r3

        # Redraw preview.
        ldi r0, y_hor_st
        ldw r0, r0

        ldi r1, board_state # r1 = board_state
        add r1, r0, r1
        add r1, r0, r1

        # go to old row (where ship was before)
        inc r1
        inc r1

        # r2 = board_state[old_y]
        ldw r1, r2

        # screen[old_y] = clean row
        stw r4, r2

        # go back to new row
        dec r1
        dec r1

        # r1 = board_state[new_y]
        ldw r1, r1
        move r5, r7 # r7 = ship mask
        or r1, r7, r7 # r7 = board_state[new_y] | ship

        dec r4
        dec r4
        stw r4, r7

        # loop again
        br check_button_hor
        dec r4
        dec r4
        stw r4, r7
        br check_button_hor

    check_right_hor:
        # right button (2 bit)
        ldi r3, 0b100
        and r2, r3, r7
        tst r7
        beq check_down_hor

        # x == 9: right blocked
        ldi r3, x_hor_fn
        ldw r3, r3
        ldi r2, 9
        cmp r2, r3
        beq check_button_hor

        inc r3
        ldi r2, x_hor_fn # x_hor_fn += 1
        stw r2, r3

        ldi r2, x_hor_st # x_hor_st += 1
        ldw r2, r3
        inc r3
        stw r2, r3

        # REDRAW PREVIEW
        # Like left
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
        # check down (3 bit)
        ldi r3, 0b1000
        and r2, r3, r7
        tst r7
        beq check_reverse_hor

        # y == 9: down blocked
        ldi r3, y_hor_st
        ldw r3, r3
        ldi r2, 9
        cmp r2, r3
        beq check_button_hor

        inc r3
        ldi r2, y_hor_st
        stw r2, r3

        # REDRAW PREVIEW
        # like up
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
        # go vertical mode 
        # reverse button (4 bit)
        ldi r3, 0b10000
        and r2, r3, r7
        tst r7
        beq check_place_hor

        ldi r7, y_hor_st
        ldw r7, r7

        # get cur row
        ldi r6, board_state
        add r6, r7, r6
        add r6, r7, r6
        ldw r6, r6

        stw r4, r6
        br check_button_ver # go to vertical

    check_place_hor:
        ldi r3, 0b100000
        and r2, r3, r7
        tst r7
        beq check_button_hor

        # check the ship before commit
        ldi r0, y_hor_st
        ldw r0, r0
        move r5, r1 # r1 - mask

        jsr check_placement
        tst r2
        bne bad_placement_ship_hor # bad

        # OK 
        # Commit ship to board_state
        ldi r3, board_state
        add r0, r3, r3
        add r0, r3, r3

        ldw r3, r1
        or r5, r1, r1
        stw r3, r1

        # Move to the next ship size
        ldi r0, pointer_len_ship
        ldw r0, r1
        inc r1
        inc r1
        stw r0, r1

        pop r7
        br return

end.
