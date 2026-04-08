rsect write_tty

# include constants.asm
gen_array: ext
fight_word: ext

# include uttils.asm
exit: ext

write_ship_generation>
    # WRITE "Ship generation..."---------------
    ldi r3, 0xffc2
    stb r3, r3

    ldi r0, 0xffc0    # Load destination address 0xffc0 into r0
    ldi r1, gen_array # Load source array address into r1 "Ship generation..."
    ldi r3, 18        # Load loop counter (18 bytes) into r3

    write:            # Loop start label
        ldb  r1, r2       # Load byte from address in r1 (source) into r2
        stb r0, r2        # Store byte from r2 into address in r0 (destination)
        inc r1            # Increment source address pointer
        dec r3            # Decrement loop counter
        tst r3            # Test if counter is zero
    bnz write         # Branch if counter is not zero (continue loop)

    rts
    #----------------------------------------------

write_fight> 
    # WRITE "fight!" in tty
    ldi r0, 0xffc0
    ldi r1, 6
    ldi r2, fight_word

    write_loop:
        tst r1
        beq exit 

        ldb r2, r3
        stb r0, r3
        inc r2
        dec r1
        br write_loop
end.