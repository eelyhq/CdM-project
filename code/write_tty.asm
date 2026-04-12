rsect write_tty

# include constants.asm
gen_array: ext
fight_word: ext
bad_placement: ext

# include function.asm
exit: ext

write_bad_placement> 
    push r3
    push r2
    push r1
    push r0

    ldi r3, 0xffc2
    stb r3, r3

    ldi r0, 0xffc0    
    ldi r1, bad_placement 
    ldi r3, 24        

    write_bad_placement_loop:      
        ldb  r1, r2                
        stb r0, r2                 
        inc r1                     
        dec r3                     
        tst r3                     
    bnz write_bad_placement_loop   

    pop r0
    pop r1
    pop r2
    pop r3
    rts

print_place_your_ship>
    print_place_text_first:   # print "Place your "
        ldb r0, r3
        stb r2, r3
        inc r0
        dec r1
        tst r1
        bne print_place_text_first

        ldi r3, 48   # ascii '0'
        add r6, r3, r3  # ascii current ship len
        stb r2, r3

        ldi r1, 11

    print_place_text_second:  # print "-deck ship"
        ldb r0, r3
        stb r2, r3
        inc r0
        dec r1
        tst r1
        bne print_place_text_second

    rts


write_ship_generation>
    # WRITE "Ship generation..."---------------
    ldi r3, 0xffc2
    stb r3, r3

    ldi r0, 0xffc0    # Load destination address 0xffc0 into r0
    ldi r1, gen_array # Load source array address into r1 "Ship generation..."
    ldi r3, 18        # Load loop counter (18 bytes) into r3

    write_ship_generation_loop:      # Loop start label
        ldb  r1, r2                  # Load byte from address in r1 (source) into r2
        stb r0, r2                   # Store byte from r2 into address in r0 (destination)
        inc r1                       # Increment source address pointer
        dec r3                       # Decrement loop counter
        tst r3                       # Test if counter is zero
    bnz write_ship_generation_loop   # Branch if counter is not zero (continue loop)

    rts
    #----------------------------------------------

write_fight> 
    # WRITE "fight!" in tty
    ldi r0, 0xffc0
    ldi r1, 6
    ldi r2, fight_word

    write_fight_loop:
        tst r1
        beq exit 

        ldb r2, r3
        stb r0, r3
        inc r2
        dec r1
        br write_fight_loop
    rts

clear_tty>
    # clear tty
    push r0
    ldi r0, 0xffc2
    stb r0,r0
    pop r0
    rts

end.
