rsect draw

prev_btn_state: ext
draw_choice: ext
stone: ext
scissors: ext
paper: ext
confirm_message: ext

current_selection: ext
current_player: ext
p1_choice: ext
p2_choice: ext     
first_shooter: ext     
msg_tie: ext
msg_p1_win: ext
msg_bot_win: ext 
msg_bot_chose: ext
hello_message: ext

draw>

    ldi r0, hello_message
    ldi r1, 109
    ldi r2, 0xffc0

    write_hello:
    ldw r0, r3
    stw r2, r3
    inc r0
    dec r1
    tst r1
    bne write_hello

    # reset selection to 0xffff (no choice made yet) at the start
    ldi r0, current_selection
    ldi r1, 0xffff
    stw r0, r1

    br draw_write
    
    write_draw_choice:
    ldw r3, r6
    stw r5, r6
    inc r3
    dec r4
    tst r4
    bne write_draw_choice
    rts

    write_confirmation_message:
    ldw r3, r6
    stw r5, r6
    inc r3
    dec r4
    tst r4
    bne write_confirmation_message
    rts

    write_result_message:
    ldw r3, r6
    stw r5, r6
    inc r3
    dec r4
    tst r4
    bne write_result_message
    rts

    draw_write:
    ldi r0, 0xff84
    ldw r0, r1

    # edge detector
    ldi r3, prev_btn_state
    ldb r3, r2
    stb r3, r1

    not r2, r2
    and r2, r1, r2

    check_stone_button:
    ldi r3, 0b1000000
    and r3, r2, r3

    tst r3
    beq check_scissors_button

    # save '0' for Stone
    ldi r0, current_selection
    ldi r1, 0
    stw r0, r1

    ldi r5, 0xffc2
    stb r5, r5
    ldi r5, 0xffc0 
    ldi r3, draw_choice
    ldi r4, 13
    
    jsr write_draw_choice
    
    ldi r3, stone
    ldi r4, 5

    write_stone:
    ldw r3, r6
    stw r5, r6
    inc r3
    dec r4
    tst r4
    bne write_stone
    ldi r6, 63
    stw r5, r6

    ldi r5, 0xffc0 
    ldi r3, confirm_message
    ldi r4, 45
    jsr write_confirmation_message
    br draw_write


    check_scissors_button:
    ldi r3, 0b10000000
    and r3, r2, r3

    tst r3
    beq check_paper_button  

    # save '1' for Scissors
    ldi r0, current_selection
    ldi r1, 1
    stw r0, r1

    ldi r5, 0xffc2
    stb r5, r5  
    ldi r5, 0xffc0 
    ldi r3, draw_choice
    ldi r4, 13
    jsr write_draw_choice
    
    ldi r3, scissors
    ldi r4, 8

    write_scissors:
    ldw r3, r6
    stw r5, r6
    inc r3
    dec r4
    tst r4
    bne write_scissors
    ldi r6, 63
    stw r5, r6

    ldi r5, 0xffc0 
    ldi r3, confirm_message
    ldi r4, 45
    jsr write_confirmation_message

    br draw_write


    check_paper_button:
    ldi r3, 0b100000000
    and r3, r2, r3

    tst r3
    beq check_confirm_button

    # save '2' for Paper
    ldi r0, current_selection
    ldi r1, 2
    stw r0, r1

    ldi r5, 0xffc2
    stb r5, r5
    ldi r5, 0xffc0 
    ldi r3, draw_choice
    ldi r4, 13

    jsr write_draw_choice
    
    ldi r3, paper
    ldi r4, 5

    write_paper:
    ldw r3, r6
    stw r5, r6
    inc r3
    dec r4
    tst r4
    bne write_paper
    ldi r6, 63
    ldi r5, 0xffc0 
    stw r5, r6

    ldi r5, 0xffc0 
    ldi r3, confirm_message
    ldi r4, 45
    jsr write_confirmation_message

    br draw_write

    
    check_confirm_button:
    ldi r3, 0b1000000000 
    and r3, r2, r3

    tst r3
    beq draw_write

    # VALIDATION: ensure a choice was actually made
    ldi r0, current_selection
    ldw r0, r1
    ldi r2, 0xffff
    cmp r1, r2
    beq draw_write  # if choice is 0xffff, ignore confirm push
    
    ldi r5, 0xffc2
    stb r5, r5     # clear the tty

    # 1. save player choice
    ldi r0, p1_choice
    stw r0, r1

    # 2. generate bot choice 
    ldi r0, 0xff82
    ldw r0, r1
    
    # fast modulo 3 
    ldi r2, 0xff   # mask to lower 8 bits 
    and r1, r2, r1
mod_loop:
    ldi r2, 3
    cmp r1, r2
    blt mod_done
    sub r1, r2, r1
    br mod_loop
mod_done:
    # r1 now contains bot's choice (0, 1, or 2)
    ldi r0, p2_choice
    stw r0, r1

    # === SHOW BOT CHOICE ON TTY ===
    # print "Bot: "
    ldi r5, 0xffc0
    ldi r3, msg_bot_chose
    ldi r4, 5
    jsr write_result_message

    # determine which word to print based on bot choice
    ldi r0, p2_choice
    ldw r0, r1

    tst r1
    beq bot_chose_stone

    ldi r2, 1
    cmp r1, r2
    beq bot_chose_scissors

    # Bot chose Paper
    ldi r3, paper
    ldi r4, 5
    br print_bot_word

    bot_chose_stone:
        ldi r3, stone
        ldi r4, 5
        br print_bot_word

    bot_chose_scissors:
        ldi r3, scissors
        ldi r4, 8

print_bot_word:
    jsr write_result_message

    # print newline (ASCII 10) so the result text goes to the next line
    ldi r5, 0xffc0
    ldi r6, 10
    stw r5, r6
    # ==============================

    br resolve_draw


    # === WINNER RESOLUTION LOGIC ===
    resolve_draw:
    ldi r0, p1_choice
    ldw r0, r1      # r1 = player Choice
    ldi r0, p2_choice
    ldw r0, r2      # r2 = bot Choice

    # check for a tie
    cmp r1, r2
    beq draw_tie

    # compare combinations
    tst r1
    beq p1_is_stone

    ldi r3, 1
    cmp r1, r3
    beq p1_is_scissors

    # player is Paper (2)
    tst r2          # if bot is stone (0)
    beq p1_wins     # paper beats stone
    br bot_wins     # else Bot is scissors (1), scissors beats paper

    p1_is_stone:
    ldi r3, 1
    cmp r2, r3      # if bot is Scissors (1)
    beq p1_wins     # stone beats scissors
    br bot_wins     # else bot is paper (2), paper beats stone

    p1_is_scissors:
    ldi r3, 2
    cmp r2, r3      # if bot is paper (2)
    beq p1_wins     # scissors beats paper
    br bot_wins     # else bot is stone (0), stone beats scissors


    draw_tie:
    # tie! output message
    ldi r5, 0xffc0 
    ldi r3, msg_tie
    ldi r4, 18
    jsr write_result_message


    # reset selection so user must pick again
    ldi r0, current_selection
    ldi r1, 0xffff
    stw r0, r1
    br draw_write

    p1_wins:
    # output win text
    ldi r5, 0xffc0 
    ldi r3, msg_p1_win
    ldi r4, 25
    jsr write_result_message


    # set shooter flag
    ldi r0, first_shooter
    ldi r1, 0
    stw r0, r1
    br end_draw

    bot_wins:
    # output lose text
    ldi r5, 0xffc0 
    ldi r3, msg_bot_win
    ldi r4, 27
    jsr write_result_message


    # set shooter flag
    ldi r0, first_shooter
    ldi r1, 1
    stw r0, r1
    br end_draw

    end_draw:
    # the winner is stored in 'first_shooter'. exit draw routine
    ldi r5, 0xffc0
    ldi r6, 10
    stw r5, r6
    rts 

end.