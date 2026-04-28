# Here is some functions 

# include constants.asm
board_state: ext

rsect functions

check_placement> # universal func for check, can ship place there
    
    push r3
    push r4
    push r5
    push r6

    # 1. make wide mask for check diagonales and left and right cell
    move r1, r5           
    move r1, r6
    shl r6, r6, 1         
    or r5, r6, r5
    move r1, r6
    shr r6, r6, 1         
    or r5, r6, r5         

    # 2. check current row
    ldi r3, board_state
    add r0, r3, r4
    add r0, r4, r4        # r4 = address curr row
    
    ldw r4, r6            
    and r6, r5, r6
    bne placement_error   

    # 3. check row higher
    tst r0
    beq skip_up_check     

    dec r4
    dec r4                
    ldw r4, r6            
    and r6, r5, r6
    bne placement_error
    inc r4
    inc r4                

skip_up_check:
    # 4. check row lower
    ldi r6, 9
    cmp r0, r6
    beq skip_down_check   

    inc r4
    inc r4                
    ldw r4, r6            
    and r6, r5, r6
    bne placement_error

skip_down_check:
    ldi r2, 0             # code of success
    br end_placement_check

placement_error:
    ldi r2, 1             # code of error (collision)

end_placement_check:
    # restore registers
    pop r6
    pop r5
    pop r4
    pop r3
    rts

check_field> # сheck the cell itself
    tst r2
    bz end_loop5   
    loop5:
    shr r0, r0, 1 
    dec r2
    tst r2
    bne loop5
    end_loop5:

    ldi r2, 1

    and r2, r0, r0

    rts

end.
