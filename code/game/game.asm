rsect game

# include constants.asm
player_hit: ext
bot_hit: ext

game>
    # Main game loop: player hit, bot hit... 
    loop:
        jsr player_hit
        tst r0
        bne loop  # if r0 != 0: player_hit again

        jsr bot_hit
    br loop

end.
