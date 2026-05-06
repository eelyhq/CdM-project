rsect enemy_ships

# include constants.asm
ships_array: ext
board_state_bot: ext

# include enemy_ships_helpers.asm
enemy_ship_try_vertical: ext
enemy_ship_try_horizontal: ext
rand: ext
exit: ext

generate_enemy_ships>
    # r1 pointer ships_array, r3 counts how many ships are place
    ldi r1, ships_array
    ldi r3, 10

generate_enemy_ships_loop: # main generate loop
    tst r3 # if r3 == 0: exit, it means, that all ships already placed
    bz exit

    jsr rand

    # generate random val (0 or 1)
    ldi r2, 0xff82
    ldb r2, r4 # r4 - rand value

    ldi r7, 1
    and r7, r4, r4   # rand_value & 1; r4 = 1 or r4 = 0

    # load the current ship size from ships_array into r2
    ldw r1, r2

    tst r4
    bz generate_enemy_ship_horizontal # choose ship orientation based on random value
    br generate_enemy_ship_vertical

generate_enemy_ship_vertical:
    # r5: X coord 
    # r6: Y coord
    # r2: size of ship

    # try to place the current ship vertically. r0 = 0 means success
    jsr enemy_ship_try_vertical
    tst r0
    bnz generate_enemy_ships_loop # regenerate ship

    # advance to the next ship size after a successful placement
    dec r3   # ships_count -= 1
    inc r1   # pointer_ship_array += 1 (2 bytes)
    inc r1
    br generate_enemy_ships_loop # generate next ship

generate_enemy_ship_horizontal:
    # r5: X coord 
    # r6: Y coord
    # r2 size of ship

    # Try to place the current ship horizontally. r0 = 0 means success.
    jsr enemy_ship_try_horizontal
    tst r0
    bnz generate_enemy_ships_loop # regenerate

    # advance to the next ship size after a successful placement
    dec r3   # ships_count -= 1
    inc r1   # pointer_ship_array += 1 (2 bytes)
    inc r1
    br generate_enemy_ships_loop

end.
