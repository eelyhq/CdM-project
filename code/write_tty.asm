rsect write_tty

# include constants.asm
gen_array: ext
fight_word: ext
bad_placement: ext
bot_word: ext
player_word: ext
win_word: ext
place_array: ext
pointer_len_ship: ext

# include logic files
refresh_placement_tty: ext
exit: ext

write_bot>
    push r0
    push r1
    push r2
    push r3
    ldi r0, 0xffc0
    ldi r1, bot_word
    ldi r2, 3
write_bot_label:
    tst r2
    beq write_bot_label_done
    ldb r1, r3
    stb r0, r3
    inc r1
    dec r2
    br write_bot_label
write_bot_label_done:
    pop r3
    pop r2
    pop r1
    pop r0 
    rts

write_player> 
    push r0
    push r1
    push r2
    push r3
    ldi r0, 0xffc0
    ldi r1, player_word
    ldi r2, 6
write_player_label:
    tst r2
    beq write_player_label_done
    ldb r1, r3
    stb r0, r3
    inc r1
    dec r2
    br write_player_label
write_player_label_done:
    pop r3
    pop r2
    pop r1
    pop r0 
    rts

write_win> 
    push r0
    push r1
    push r2
    push r3
    ldi r0, 0xffc0
    ldi r2, 4
    ldi r1, win_word
write_bot_win_label:
    tst r2
    beq write_bot_win_label_done
    ldb r1, r3
    stb r0, r3
    inc r1
    dec r2
    br write_bot_win_label
write_bot_win_label_done:
    pop r3
    pop r2
    pop r1
    pop r0 
    rts

write_space> 
    push r0
    push r1
    ldi r1, 32   # space
    ldi r0, 0xffc0
    stb r0, r1
    pop r1
    pop r0
    rts

write_bad_placement> 
    push r0
    push r1
    push r2
    push r3

    # restore base inscription and go to new line
    jsr refresh_placement_tty
    jsr print_newline

    # print error
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

    pop r3
    pop r2
    pop r1
    pop r0
    rts

print_place_your_ship>
    push r0
    push r1
    push r2
    push r3
    push r6
    
    ldi r6, pointer_len_ship
    ldw r6, r6
    ldb r6, r6      # get  current ship size

    ldi r0, place_array
    ldi r1, 11
    ldi r2, 0xffc0
    
print_place_text_first:   # print "Place your "
    ldb r0, r3
    stb r2, r3
    inc r0
    dec r1
    tst r1
    bne print_place_text_first

    ldi r3, 48   # ascii '0'
    add r6, r3, r3  
    stb r2, r3

    ldi r1, 11
print_place_text_second:  # print "-deck ship"
    ldb r0, r3
    stb r2, r3
    inc r0
    dec r1
    tst r1
    bne print_place_text_second

    pop r6
    pop r3
    pop r2
    pop r1
    pop r0
    rts

write_ship_generation>
    push r0
    push r1
    push r2
    push r3

    ldi r0, 0xffc0    
    ldi r1, gen_array 
    ldi r3, 18        
write_ship_generation_loop:      
    ldb  r1, r2                  
    stb r0, r2                   
    inc r1                       
    dec r3                       
    tst r3                       
    bnz write_ship_generation_loop   

    pop r3
    pop r2
    pop r1
    pop r0
    rts

write_fight> 
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
    push r0
    ldi r0, 0xffc2
    stb r0,r0
    pop r0
    rts

print_newline>
    push r0
    push r1
    ldi r0, 0xffc0
    ldi r1, 10      # ASCII \n
    stb r0, r1
    pop r1
    pop r0
    rts

end.