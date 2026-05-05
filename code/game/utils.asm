rsect utils

# include constants.asm
bot_ship_count: ext
player_ship_count: ext

# include write_tty.asm
clear_tty: ext
write_player: ext
write_space: ext
write_win: ext
write_bot: ext

check_player_win>
    push r0

    # check bot's amount ships
    ldi r0, bot_ship_count
    ldw r0, r0
    tst r0 
    bne player_not_win  # if bot_sips_count == 0: player_win
    
    # if win
    jsr player_win
    halt

    # if not win
    player_not_win:
        pop r0
        rts

check_bot_win> 
    push r0

    ldi r0, player_ship_count
    ldw r0, r0
    tst r0
    bne bot_not_win   # player_ship_count == 0: bot_win

    # if bot win
    jsr bot_win 
    halt

    # if not win
    bot_not_win: 
        pop r0
        rts

bot_win: 
    jsr clear_tty
    jsr write_bot
    
    jsr write_space

    jsr write_win
    rts

player_win:
    jsr clear_tty
    jsr write_player
    
    jsr write_space

    jsr write_win
    rts
    
end.
