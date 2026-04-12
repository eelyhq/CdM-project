rsect player_ships_vertical

# include constants.asm
board_state: ext
x_ver: ext
x_ver_st: ext
y_ver: ext
y_ver_st: ext
y_ver_fn: ext
prev_btn_state: ext
pointer_len_ship: ext
return: ext

# include replacement.asm
check_placement: ext
check_reverse_ver: ext
check_place_ver: ext

check_button_ver>
    # r0 - y, r1 - x, r7 - current ship size

    ldi r0, 0xff68 
    ldi r1, 0b1000000000 

    # init ship's coordinates.
    ldi r2, x_ver
    stw r2, r1
    ldi r2, y_ver
    stw r2, r0

    ldi r1, 0
    ldi r0, x_ver_st
    stw r0, r1
    ldi r0, y_ver_st
    stw r0, r1

    pop r7
    push r7

    # y_ver_fn = y_ver_st + ship_size - 1
    ldi r1, -1
    add r1, r7, r1
    ldi r0, y_ver_fn
    stw r0, r1

    # Render the ship line and wait for player input
    print_shipp:
        pop r7
        push r7

        move r7, r6

        ldi r0, y_ver
        ldw r0,r0

        ldi r2, y_ver_st # start row for already placed ships
        ldw r2, r2
        dec r2

        ldi r1, x_ver
        ldw r1, r1

    print_ship:
        ldi r3, 2
        add r0, r3,r0
        inc r2

        ldi r3, board_state
        add r3, r2, r3
        add r3, r2, r3
        ldw r3, r3

        or r1, r3, r3

        stw r0, r3

        dec r6
        tst r6
        bne print_ship

button_ver>
    ldi r5, 0xff80
    ldb r5, r5 # read buttons

    # Edge detector.
    ldi r3, prev_btn_state
    ldb r3, r2
    stb r3, r5

    not r2, r2
    and r2, r5, r2

    check_left_ver:
        ldi r3, 1
        and r2,r3,r7
        tst r7
        beq check_up_ver

        # if x == 0: skip
        ldi r0, x_ver_st
        ldw r0, r0
        tst r0
        beq button_ver

        dec r0
        ldi r1, x_ver_st
        stw r1, r0

        ldi r0, x_ver
        ldw r0, r1
        shl r1, r1, 1
        stw r0, r1
        br print_shipp

    check_up_ver:
        ldi r3, 0b10
        and r2,r3,r7
        tst r7
        beq check_right_ver

        # if y == 0: skip
        ldi r0, y_ver_st
        ldw r0, r0
        tst r0
        beq button_ver

        dec r0
        ldi r1, y_ver_st
        stw r1, r0

        ldi r0, y_ver_fn
        ldw r0, r1
        dec r1
        stw r0, r1

        ldi r1, y_ver
        ldw r1, r0

        ldi r3, y_ver_fn
        ldw r3, r3
        inc r3

        ldi r5, board_state
        add r5, r3, r5
        add r5, r3, r5
        ldw r5, r5

        pop r7
        push r7

        move r0, r4
        add r4, r7, r4
        add r4, r7, r4
        stw r4, r5

        dec r0
        dec r0
        stw r1, r0

        br print_shipp

    check_right_ver:
        ldi r3, 0b100
        and r2,r3,r7
        tst r7
        beq check_down_ver

        # if x == 9: skip
        ldi r0, x_ver_st
        ldw r0, r0

        ldi r1, 9
        cmp r0, r1
        beq button_ver

        inc r0
        ldi r1, x_ver_st
        stw r1, r0

        ldi r0, x_ver
        ldw r0, r1
        shr r1, r1, 1
        stw r0, r1

        br print_shipp

    check_down_ver:
        ldi r3, 0b1000
        and r2, r3, r7
        tst r7
        beq check_reverse_ver

        # if y == 9: skip
        ldi r0, y_ver_fn
        ldw r0, r0

        ldi r1, 9
        cmp r1, r0
        beq button_ver

        inc r0
        ldi r1, y_ver_fn
        stw r1, r0

        ldi r0, y_ver_st
        ldw r0, r1
        inc r1
        stw r0, r1

        # Refresh the cells touched by the ship after moving down.
        ldi r3, y_ver_st
        ldw r3, r3
        dec r3

        ldi r5, board_state
        add r5, r3, r5
        add r5, r3, r5

        ldw r5, r5

        ldi r1, y_ver
        ldw r1, r0

        ldi r3, 2
        add r0, r3, r4
        stw r4, r5

        add r0, r3, r0

        stw r1, r0

        br print_shipp

end.
