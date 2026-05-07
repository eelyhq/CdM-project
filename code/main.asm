asect 0 

main: ext 
default_handler: ext 
button_isr: ext

# --- Interrupt vector table (IVT) ---
dc main, 0              # 0x00: Startup/Reset vector 
dc default_handler, 0   # 0x04: Unaligned SP 
dc default_handler, 0   # 0x08: Unaligned PC 
dc default_handler, 0   # 0x0C: Invalid instruction 
dc default_handler, 0   # 0x10: Double fault 

align 0x20              #  Interrupt vector
dc button_isr, 0        

# --- Exception handlers section ---
rsect exc_handlers

# dependencies for Interrupt:
player_placement_done: ext
draw: ext
player_placement_step: ext

default_handler> 
    halt

button_isr>
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5
    push r6
    push r7

    # checking, did the player place all the ships
    ldi r0, player_placement_done
    ldw r0, r0
    tst r0
    bnz isr_end_label

    # do movement or placeing player ship
    jsr player_placement_step 

isr_end_label:
    pop r7
    pop r6
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rti 

# --- Main program section ---
rsect main

# dependencies for main program:
player_placement_done: ext
enemy_generation_done: ext
draw: ext

write_ship_generation: ext 
write_fight: ext
generate_enemy_ships: ext
player_ships_replacement_init: ext 
game: ext
clear_tty: ext
refresh_placement_tty: ext

main> 
    ldi r0, 0xFEFE
    stsp r0

    # reset flags
    ldi r0, 0
    ldi r1, player_placement_done
    stw r1, r0
    ldi r1, enemy_generation_done
    stw r1, r0

    jsr player_ships_replacement_init

    # enable Interrupts
    ei
    
    # bot generates ships in the background
    jsr generate_enemy_ships 
    
    # go there, when bot placed all ships
    di  
    ldi r0, 1
    ldi r1, enemy_generation_done
    stw r1, r0
    jsr refresh_placement_tty  
    ei

# waiting for player place all his ships
wait_player_loop:
    ldi r0, player_placement_done
    ldw r0, r0
    tst r0
    bnz game_ready  

    # if player doesn't place ships yet, wait interrupt
    wait
    br wait_player_loop

# main game
game_ready:
    di 
    jsr draw
    jsr write_fight 
    jsr game 
    halt
end.