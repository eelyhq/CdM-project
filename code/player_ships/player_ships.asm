rsect player_ships_replacement

# include constants.asm
ships_array: ext
pointer_len_ship: ext
place_array: ext
board_state: ext
x_hor_st: ext
y_hor_st: ext
x_hor_fn: ext
y_hor_fn: ext
prev_btn_state: ext
x_ver: ext
x_ver_st: ext
y_ver: ext
y_ver_st: ext
y_ver_fn: ext

# include replacement.asm
check_placement: ext

# include functions.asm
exit: ext

# include write_tty.asm
clear_tty: ext
print_place_your_ship: ext

# include player_ships_horizontal.asm
check_button_hor: ext

player_ships_replacement>
    # ships_array[0] stores the first ship size
    ldi r5, ships_array
    ldi r6, pointer_len_ship
    stw r6, r5

return>
    # Load current ship size
    ldi r6, pointer_len_ship
    ldw r6, r6
    ldb r6, r6

    ldi r0, place_array
    ldi r1, 11    # len before -deck
    ldi r2, 0xffc0 # tty

    jsr clear_tty
    tst r6
    beq exit

    jsr print_place_your_ship   # print "Place your x-deck ship"

    # Build ship mask
    push r6

    ldi r7, 0b0
    ldi r3, 0b1000000000

    # create ship's bit mask
    make_ship:
        or r3, r7, r7
        shr r7, r7, 1
        dec r6
        tst r6
        bne make_ship

        shl r7, r7, 1

        # Show preview ship on the top row
        ldi r4, 0xff6a   # player move matrix

        ldi r1, board_state
        ldw r1, r1
        move r7, r5
        or r1, r7, r7
        stw r4, r7

        ldi r1, 0
        ldi r0, x_hor_st
        stw r0, r1
        ldi r0, y_hor_st
        stw r0, r1

        pop r7
        push r7

        ldi r1, -1
        add r1, r7, r1
        ldi r0, x_hor_fn
        stw r0, r1

        # Horizontal movement is handled in the helper file
        br check_button_hor

end.
