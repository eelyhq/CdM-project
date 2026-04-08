asect 0
main: ext               # Declare labels
default_handler: ext    # as external

# Interrupt vector table (IVT)
# Place a vector to program start and map 
# all internal exceptions to default_handler
dc main, 0              # Startup/Reset vector
dc default_handler, 0   # Unaligned SP
dc default_handler, 0   # Unaligned PC
dc default_handler, 0   # Invalid instruction
dc default_handler, 0   # Double fault
align 0x80              # Reserve space for the rest 
                        # of IVT

# Exception handlers section
rsect exc_handlers

# This handler halts processor
default_handler>
    halt
# ------------

# Main program section
rsect main

# include write_tty.asm
write_ship_generation: ext
write_fight: ext

# include enemy_ships.asm
generate_enemy_ships: ext

# include player_ships.asm
player_ships_replacement: ext

# include game.asm
game: ext

main>
ldi r0, 0x7000   
stsp r0

# CREATE FIELDS-------------------------------
jsr write_ship_generation # write "Ship generation..." in tty
jsr generate_enemy_ships # generate enemy field

ldi r0, 0xffc2
stb r0,r0

jsr player_ships_replacement # player ships placement
#---------------------------------------------

jsr write_fight # write "fight!" in tty
jsr game # start game

end.
