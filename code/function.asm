rsect function

rand>
    # GENERATED X AND Y COORDS OF SHIP (0-9)
    # return X -> r5, Y -> r6

    ldi r2, 0xff82 # generator 
    # generate start coordinates (X, Y)
    ldb r2, r5 # random value X -> r5
    ldb r2, r6 # random value Y -> r6 

    ldi r2, 0x000f  # bit mask
    and r5, r2, r5  # X & 0x00f -> r5
    and r6, r2, r6  # Y & 0x00f -> r6

    # MOD functions
    ldi r0, 10 # for MOD 
    mod10X: # X = X % 10 -> r5
        cmp r5, r0
        blt mod10Y 
        sub r5, r0, r5
        br mod10X

    mod10Y: # Y = Y % 10 -> r6 
        cmp r6, r0
        blt rand_func_exit
        sub r6, r0, r6
        br mod10Y

    rand_func_exit: 
        rts

exit> 
    # for exit, break and other
    rts

end.
