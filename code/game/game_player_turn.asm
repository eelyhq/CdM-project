rsect game_player_turn

# include constants.asm
bot_ship_count: ext
board_state_fire_bot: ext
x_hor_st: ext
y_hor_st: ext
board_state_hit_bot: ext
board_state_bot: ext
pointer_hit_matrix_arr: ext
pointer_miss_matrix_arr: ext
pointer_miss_arr: ext
board_state_miss_bot: ext
pointer_hit_arr: ext
player_ship_count: ext
bot_state: ext
hit_start_x: ext
hit_start_y: ext
target_dir: ext
board_state_miss: ext
curr_hit_x: ext
curr_hit_y: ext
prev_btn_state: ext
board_state_hit: ext
board_state: ext

# include game_kill_end.asm
check_kill_or_end: ext
bot_hit: ext
player_win: ext

player_hit>
    # check bot's amount ships
    ldi r0, bot_ship_count
    ldw r0, r0
    tst r0
    beq player_win

    ldi r5, 0b1000000000000 # mask

    ldi r4, 0xff00 # first line 

    ldi r1, board_state_fire_bot

    ldw r1, r1                        
    move r5, r7 # in r5 there is mask
    or r1, r7, r7
    stw r4, r7 
    shr r5, r5, 3

    # save start coords 
    ldi r1, 0
    ldi r0, x_hor_st
    stw r0, r1
    ldi r0, y_hor_st
    stw r0, r1

    pop r7
    push r7
    #--------------------------------------------

    check_button_fire:
        ldi r0, 0xff80
        ldb r0, r1

        # edge detector ----------
        ldi r3, prev_btn_state 
        ldb r3, r2
        stb r3, r1

        not r2, r2

        and r2, r1, r2
        
        #--------------------------

        check_left_fire:
            # left button
            ldi r3, 1
            and r2, r3, r7
            tst r7
            beq check_up_fire

            # field boundary check
            ldi r3, x_hor_st
            ldw r3, r3
            tst r3
            beq check_button_fire
            
            # x--;
            dec r3
            ldi r2, x_hor_st
            stw r2, r3  

            # Redraw
            ldi r0, y_hor_st
            ldw r0, r0
            ldi r1, board_state_fire_bot
            add r1, r0, r1
            add r1, r0, r1
            ldw r1, r1      # r1 = bg

            shl r5, r5, 1   # Move left 
            move r1, r7     # Copy background 
            or r5, r7, r7   # r7 = bg + cursor
            shl r7, r7, 3   # Shift every bit by 3 bits for matrix 0xff00
            stw r4, r7      
            br check_button_fire

        check_up_fire:
            # up button
            ldi r3, 0b10
            and r2, r3, r7
            tst r7
            beq check_right_fire

            # field boundary check
            ldi r3, y_hor_st
            ldw r3, r3
            tst r3
            beq check_button_fire

            # delete the cursor from the old line
            ldi r0, board_state_fire_bot
            add r0, r3, r0
            add r0, r3, r0
            ldw r0, r7      # Get the clean background from the old row
            shl r7, r7, 3   # Shift for matrix 8070
            stw r4, r7      # Draw the clean background (erase the cursor)

            # 2. Update coordinates and screen pointer
            dec r3
            ldi r2, y_hor_st
            stw r2, r3      # Save the new Y
            dec r4
            dec r4          # Move the screen pointer (r4) up one row

            # 3. Draw the cursor on the new row
            ldi r0, board_state_fire_bot
            add r0, r3, r0
            add r0, r3, r0
            ldw r0, r7      # r7 = new row background
            or r5, r7, r7   # Add the cursor
            shl r7, r7, 3   # Shift for matrix 8070
            stw r4, r7      # Draw on screen
            br check_button_fire

        check_right_fire:
            ldi r3, 0b100
            and r2,r3,r7
            tst r7
            beq check_down_fire

            # boundary check
            ldi r3, x_hor_st
            ldw r3, r3
            ldi r2, 9
            cmp r2, r3
            beq check_button_fire

            inc r3
            ldi r2, x_hor_st
            stw r2, r3

            # Redraw
            ldi r0, y_hor_st
            ldw r0, r0
            ldi r1, board_state_fire_bot
            add r1, r0, r1
            add r1, r0, r1
            ldw r1, r1      # r1 = background

            shr r5, r5, 1   # Move the cursor right
            move r1, r7
            or r5, r7, r7   # Merge background and cursor
            shl r7, r7, 3   # Shift by 3 for screen 8070
            stw r4, r7      # Draw
            br check_button_fire

        check_down_fire:
            ldi r3, 0b1000
            and r2,r3,r7
            tst r7
            beq check_fire

            # boundary check
            ldi r3, y_hor_st
            ldw r3, r3
            ldi r2, 9
            cmp r2, r3
            beq check_button_fire

            #  Erase the cursor from the old row
            ldi r0, board_state_fire_bot
            add r0, r3, r0
            add r0, r3, r0
            ldw r0, r7      
            shl r7, r7, 3   
            stw r4, r7      

            # Update coordinates 
            inc r3
            ldi r2, y_hor_st
            stw r2, r3      # Save the new Y
            inc r4
            inc r4          

            # Draw cursor on the new row
            ldi r0, board_state_fire_bot
            add r0, r3, r0
            add r0, r3, r0
            ldw r0, r7      
            or r5, r7, r7   
            shl r7, r7, 3   
            stw r4, r7      
            br check_button_fire

        check_fire:
            ldi r3, 0b100000
            and r2, r3, r7        
            tst r7
            beq check_button_fire

            # check if player already shoot in this field
            ldi r1, y_hor_st
            ldw r1, r1

            ldi r0, board_state_hit_bot 
            add r0, r1, r0
            add r0, r1, r0
            ldw r0, r0

            and r0, r5, r0

            tst r0
            bne check_button_fire

            ldi r0, board_state_miss_bot
            add r0, r1, r0
            add r0, r1, r0
            ldw r0, r0

            and r0, r5, r0
            tst r0
            bne check_button_fire
            # -------

            ldi r0, x_hor_st   # r0 - x
            ldw r0, r0

            move r1, r7       # r7 = Y (needed for recording hits)

            ldi r2, board_state_bot
            add r2, r1, r2
            add r2, r1, r2
            ldw r2, r2        # Load the bot row (row = board_state_bot[y])

            # shift to x
            tst r0
            bz shift_fire_row_to_x_done
            shift_fire_row_to_x:
                shl r2, r2, 1
                dec r0
                tst r0
                bne shift_fire_row_to_x
            shift_fire_row_to_x_done:
            
            ldi r0, 0
            stw r4, r0

            ldi r0, 0b1000000000
            and r0, r2, r0    # HIT CHECK (sets the Z flag)
            
            beq miss          # if there is no ship (Z=1), jump to miss

            hit:
                ldi r3, 0xff14  
                add r3, r7, r3
                add r3, r7, r3    # r3 = hit screen address (shifted 2 left)

                # board_state_hit_bot[y] |= cursor_mask;
                ldi r6, board_state_hit_bot
                add r6, r7, r6
                add r6, r7, r6    # r6 = hit memory addess

                ldw r6, r4        # Read previous hits from memory
                or r4, r5, r4     # Overlay the new hit (using the standard mask r5)
                stw r6, r4        # Store back to memory

                shl r4, r4, 2     # Shift the whole row 2 left for matrix 
                stw r3, r4        # Draw on the hit matrix

                # Check for kill / game end
                ldi r0, y_hor_st
                ldw r0, r0
                ldi r1, x_hor_st
                ldw r1, r1
                ldi r2, board_state_bot

                ldi r3, pointer_hit_matrix_arr
                ldi r4, 0xff14
                stw r3, r4
                ldi r3, pointer_miss_matrix_arr
                ldi r4, 0xff2a
                stw r3, r4 

                ldi r3, pointer_miss_arr
                ldi r4, board_state_miss_bot
                stw r3, r4 

                ldi r3, pointer_hit_arr
                ldi r4, board_state_hit_bot
                stw r3, r4 

                jsr check_kill_or_end


                br player_hit   # Return to polling (do not reset the cursor)

                miss:
                    ldi r3, 0xff2a
                    add r3, r7, r3
                    add r3, r7, r3    # r3 = miss screen address (no shift)

                    ldi r6, board_state_miss_bot
                    add r6, r7, r6
                    add r6, r7, r6

                    ldw r6, r4        # Read previous misses
                    or r4, r5, r4     # Add the new one
                    stw r6, r4        # Store in memory
                    stw r3, r4        # Draw on screen (10-cell matrix, no shift needed)

            br bot_hit

end.
