rsect game

# include constants.asm
player_hit: ext
bot_hit: ext
first_shooter: ext   

game>
    # Check who won the draw to decide who goes first
    ldi r0, first_shooter
    ldw r0, r1
    tst r1
    beq loop    # If first_shooter == 1, bot shoots first. Jump to bot_turn.
    
    # If first_shooter == 0, player shoots first. Fall through to player_turn.

    jsr bot_hit
    
    loop:

    jsr player_hit
    tst r0
    bne loop  # if r0 != 0: player_hit again
    jsr bot_hit
    br loop

end.