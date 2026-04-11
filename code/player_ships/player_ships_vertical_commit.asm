rsect player_ships_vertical_commit

# include constants.asm
board_state: ext
x_ver: ext
y_ver: ext
y_ver_st: ext
pointer_len_ship: ext
return: ext
button_ver: ext

# include replacement.asm
check_placement: ext

check_reverse_ver>
    # Reverse key clears the preview.
    ldi r3, 0b10000
    and r2, r3, r7
    tst r7
    beq check_place_ver

    pop r7
    push r7

    move r7, r6

    ldi r0, y_ver
    ldw r0, r0

    ldi r2, y_ver_st # keep already placed ships aligned
    ldw r2, r2
    dec r2

    del_ship:
        # Clear one row, then step down.
        ldi r3, 2
        add r0, r3, r0
        inc r2

        ldi r3, board_state
        add r3, r2, r3
        add r3, r2, r3
        ldw r3, r3

        stw r0, r3

        dec r6
        tst r6
        bne del_ship

        br return

check_place_ver>
    # Confirm button enters commit mode.
    ldi r3, 0b100000
    and r2, r3, r7
    tst r7
    beq button_ver

    # Validate the whole ship before writing.
    pop r3
    push r3
    ldi r4, 0

    check_place_ver_loop:
        dec r3
        ldi r0, y_ver_st
        ldw r0, r0
        ldi r1, x_ver
        ldw r1, r1

        add r0, r3, r0
        jsr check_placement
        or r2, r4, r4
        tst r4
        bne button_ver
        tst r3
        bne check_place_ver_loop

        # Commit ship to board_state.
        ldi r0, y_ver_st
        ldw r0, r0

        pop r1
        push r1

    check_place_ver_commit:
        dec r1
        add r0, r1, r2

        ldi r3, board_state
        add r2, r3, r3
        add r2, r3, r3

        ldw r3, r6

        ldi r4, x_ver
        ldw r4, r4

        or r4, r6, r6

        stw r3, r6

        tst r1
        bne check_place_ver_commit

        # Move to the next ship size.
        ldi r0, pointer_len_ship
        ldw r0, r1
        inc r1
        inc r1
        stw r0, r1

        pop r7
        br return 

end.
