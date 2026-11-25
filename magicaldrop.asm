################# CSC258 Assembly Final Project ###################
# This file contains my implementation of Magical Drop.
#
# Student 1: Maria Eduarda Melo Queiroz, 1012152796
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       4
# - Unit height in pixels:      4
# - Display width in pixels:    128
# - Display height in pixels:   128
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

##############################################################################
# Mutable Data
##############################################################################
# Game Board: 7 columns x 14 rows x 4 bytes per bubble = 392
# 0 = black (empty)
# 1 = red
# 2 = green
# 3 = blue
# 4 = yellow
                            # Board game possible coodinates:
board: .space 392               # X: [3, 9]
                                # Y: [3, 16]

# By default, player starts at column 3
player_col: .word 3

# Number of bubbles the user is carrying and their colour
held_colour: .word 0
held_count: .word 0

# Number of user keyboard inputs
key_count: .word 0

bubble_colours:
  .word 0x00000000          # 0 = black
  .word 0x00ff0000          # 1 = red
  .word 0x0000ff00          # 2 = green
  .word 0x000000ff          # 3 = blue 
  .word 0x00ffff00          # 4 = yellow

##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
main:
  # Initialize the game
  jal init_board             # Initializes all board cells to 0
  jal generate_random_rows   # Generates first 5 rows and stores their colours in memory

  # Draws playing board grey boarder
  li $a0 2                   # - $a0 = The X coordinate of the top-left corner of the rectangle
  li $a1 2                   # - $a1 = The Y coordinate of the top-left corner of the rectangle
  li $a2 9                   # - $a2 = The width of the rectangle
  li $a3 16                  # - $a3 = The height of the rectangle
  li $t5 0xD3D3D3            # - $t5 = set colour to grey

  jal draw_rect              # Draws grey outline

  # Draws plating board black background
  li $a0 3                   # - $a0 = The X coordinate of the top-left corner of the rectangle
  li $a1 3                   # - $a1 = The Y coordinate of the top-left corner of the rectangle
  li $a2 7                   # - $a2 = The width of the rectangle
  li $a3 14                  # - $a3 = The height of the rectangle
  li $t5 0                   # - $t5 = set colour to black

  jal draw_rect              # Draws black background

  jal draw_bubbles           # Draws the starter 5 random rows of bubbles

  jal draw_player            # Draw player at start position


game_loop:
  lw $t0, ADDR_KBRD                        # Load keyboard address
  lw $t1, 0($t0)                           # Checks keyboard status register to see whether a key was pressed

  beq $t1, $zero, no_key                   # While no keyboard input, go to no_key

  lw $t2, 4($t0)                           # Given we passed the branch statement, a key has been pressed
                                           # Check keyboard data register for ASCII value of pressed key_count
                                            
  beq $t2, 0x71, quit_game                 # If keyboard input was "q", quit game                  ASCII for "q" = 0x71

  beq $t2, 0x61, handle_left               # If keyboard input was "a", move player to the left    ASCII for "a" = 0x61
   
  beq $t2, 0x64, handle_right              # If keyboard input was "d", move player to the right   ASCII for "d" = 0x64

  beq $t2, 0x73, handle_grab               # If keyboard input was "s", handle the grab function   ASCII for "s" = 0x73

  beq $t2, 0x77, handle_throw              # If keyboard input was "w", throw bubbles              ASCII for "w" = 0x77


   # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	# 4. Sleep
    # 5. Go back to Step 1
   j game_loop

##############################################################################
# Quit and Sleep Functions
##############################################################################
  quit_game:
    li $v0, 10 
    syscall

  no_key:           # While no key is pressed, program sleeps
    li $v0, 32
    li $a0, 16
    syscall
    j game_loop

##############################################################################
# Game Functions
##############################################################################
#
# Initiates the board in memory function
#
init_board:
  la $t0, board               # $t0 = starting memory adress for top left of the board
  li $t1, 98                  # Acts as a counter from 98

# Set all 98 board cells to black
init_loop:
  beq $t1, 0, init_done       # If $t1 = 0, jump to init_done
  
  sw $zero, 0($t0)            # set the current board cell to 0

  addi $t0, $t0, 4            # Set memory adress + 4
  addi $t1, $t1, -1           # Decreases counter by 1
  j init_loop

init_done:
  jr $ra                      # Jumps back to where the function was called          



#
# The rectangle drawing function
#
# - $t0 = The location in memory of the top-left corner of the bitmap
# - $a0 = The X coordinate of the top-left corner of the rectangle
# - $a1 = The Y coordinate of the top-left corner of the rectangle
# - $a2 = The width of the rectangle
# - $a3 = The height of the rectangle
draw_rect:
  lw $t0, ADDR_DSPL               # $t0 = base address for display

# start the row-drawing loop
row_drawing_loop_start:
  add $t1, $a0, $zero             # store the X coordinate input into $t1
  add $t2, $a1, $zero             # store the Y coordinate input into $t2
  add $t3, $a2, $zero             # store the length of the line into $t3
  beq $a3, $zero, row_drawing_loop_end    # if the height parameter is zero, then exit the loop
  
  addi $sp, $sp, -4               # move the stack pointer to the next empty location in memory
  sw $ra, 0($sp)                  # push the return address register onto the stack
  jal draw_line                   # draw a line at the current X and Y coordinates
  lw $ra, 0($sp)                  # pop the return address register from the stack
  addi $sp, $sp, 4                # move the stack pointer to the top element of the stack
  
  addi $a3, $a3, -1               # reduce the height parameter by 1
  addi $a1, $a1, 1                # increase the Y coordinate by 1
  j row_drawing_loop_start        # jump to the start of the loop
 
 # end the row-drawing loop
row_drawing_loop_end:
  jr $ra                         # return to the calling program



#
# The line drawing function
#
draw_line:
  # - $t0 = The location in memory of the top-left corner of the bitmap
  # - $t1 = The X coordinate of the start of the line
  # - $t2 = The Y coordinate of the start of the line
  # - $t3 = The length of the line
  # - $t5 = The colour of the line
  # - $t8 = The location in memory for the current pixel being drawn

  # calculate the horizontal offset from the leftmost column
  sll $t1, $t1, 2             # multiply $t1 by 4 to get the horizontal offset in bytes
  
  # calculate the vertical offset from the first row
  sll $t2, $t2,  7            # multiply $t2 by 128 to get the vertical offset in bytes
  add $t8, $t0, $t1           # add the horizontal offset to $t0, store in $t8
  add $t8, $t8, $t2           # add the vertical offset to $t8

line_loop_start:
  beq $t3, $zero, line_loop_end       # check to see if we've reached the end of the line
  addi $t3, $t3, -1                   # decrement the loop variable (the length of the line)
  sw $t5, 0($t8)                      # store a pixel in the current location in memory.
  addi $t8, $t8, 4                    # move to the next pixel in the line.
  j line_loop_start                   # jump to the start of the line-drawing loop

line_loop_end:
  jr $ra                      # return to the calling program



#
# Generates random bubbles function
#
generate_random_rows:
  la $t0, board              # Adress of the first cell in the board
  li $t1, 35                 # Generate 35 random bubbles

random_loop:
  beq $t1, $zero, random_done

  li $v0, 42                 # Generates random number
  li $a0, 0                 
  li $a1, 4                  # Possible results: 0, 1, 2, 3
  syscall                    # Result is in $a0

  addi $t2, $a0, 1           # Add 1 to convert to 1, 2, 3, 4
  sw $t2, 0($t0)             # Store colour in current board cell

  addi $t0, $t0, 4           # Goes to next cell
  addi $t1, $t1, -1          # Decreases counter by 1   

  j random_loop

random_done:
  jr $ra



#
# Draw bubbles functions
# (Gets colour from memory and draws into the bitmap display)
#
draw_bubbles:
  la $t0, board                    # Board array address
  lw $t1, ADDR_DSPL                # Bitmap display address
  
                                   # Equation to find the pixel in the bitmap display 
                                   # (x, y) = 4(y * 32 + x) 
  addi $t1, $t1, 396               # (3, 3) = 4(3 * 32 + 3) = 396

  la $t6, bubble_colours           # Colour lookup table
  li $t2, 14                       # Number of rows

draw_bubble_row:
  beq $t2, $zero, bubbles_done
  li $t3, 7                        # Seven columns per row

draw_bubble_col:
  beq $t3, $zero, next_bubble_row     # When $t3 = 0, switch to next row

  lw $t4, 0($t0)                   # Read bubble value from memory ($t0)
  sll $t7, $t4, 2                  # Multiply by 4 for colour offset (shift left by 2)
  add $t8, $t6, $t7                # Address of corresponding colour
  lw $t5, 0($t8)                   # Load RGB colour into $t5
      
  sw $t5, 0($t1)                   # Draw bubble on display from $t5
      
  addi $t0, $t0, 4                 # Next board cell
  addi $t1, $t1, 4                 # Next display unit
  addi $t3, $t3, -1                # One fewer column to draw
  j draw_bubble_col     
     
next_bubble_row:     
  addi $t1, $t1, 100               # Start of next display row (each row has 128 pixels, we walked 7 pixels, so 7*4=28,
                                   # to get to the line we do 128 - 28 = 100)
  addi $t2, $t2, -1                # One fewer row to draw
  j draw_bubble_row   
   
bubbles_done:
  jr $ra


#
# Function that handles all the code necessary to move the character to the left
#
handle_left:
  jal erase_player
  jal erase_held_bubbles
  jal move_player_left
  jal draw_player
  jal draw_held_bubbles
  j action_finished



#
# Function that handles all the code necessary to move the character to the rigth
#
handle_right:
  jal erase_player
  jal erase_held_bubbles
  jal move_player_right
  jal draw_player
  jal draw_held_bubbles
  j action_finished



#
# Function that moves player to the left
#
move_player_left:
  lw $t0, player_col                            # Loads player position on the game board

  beq $t0, $zero, move_player_left_done         # Check if player position in on the left limit

  addi $t0, $t0, -1                             # Move player to the left
  sw $t0, player_col                            # Saves new position in memory

move_player_left_done:
  jr $ra



#
# Function that moves player to the right
#
move_player_right:
  lw $t0, player_col                            # Loads player position on the game board

  li $t1, 6
  beq $t0, $t1, move_player_right_done          # Check if player position in on the right limit

  addi $t0, $t0, 1                              # Move player to the right
  sw $t0, player_col                            # Saves new position in memory

move_player_right_done:
  jr $ra



#
# Funtion to erase player
#
erase_player:
  lw $t0, player_col
  addi $t0, $t0, 579       # Find player_col location relative to memory 
  sll $t0, $t0, 2  
                           #  Offset = 4(y * 32 + x), where x = player_col + 3 and y = 18 
                           #  4(18 * 32 + 3 + player_col)
                           #  4(579 + player_col)

  lw $t3, ADDR_DSPL        # Load display base address
  add $t3, $t3, $t0        # Calculate players memory address
  sw $zero, 0($t3)         # Paint player's position black = 0x00000000

  jr $ra                   # Return



#
# Function to draw player
#
draw_player:
  lw $t0, player_col
  addi $t0, $t0, 579       # Find player_col location relative to memory 
  sll $t0, $t0, 2  
                           #  Offset = 4(y * 32 + x), where x = player_col + 3 and y = 18 
                           #  4(18 * 32 + 3 + player_col)
                           #  4(579 + player_col)

  li $t1, 0x00ffffff       # $t1 = colour white

  lw $t3, ADDR_DSPL        # Load display base address
  add $t3, $t3, $t0        # Calculate players memory address
  sw $t1, 0($t3)           # Paint player's position white 

  jr $ra                   # Return


#
# Handles functionally of a player grabbing bubbles
#
handle_grab:
  jal grab_bubbles
  jal draw_bubbles
  jal draw_held_bubbles
  j action_finished



grab_bubbles:
  la $t0, board             # Starting address of board
  lw $t1, player_col        # Player column (0-6)

  # Offset = 4(13 * 7 + player_col)      because game board has 14 rows and 7 columns
  #        = 364 + 4 * player_col

  sll $t1, $t1, 2           # Multiply player_col by 4
  addi $t1, $t1, 364        # Add 364 to 4*player_col
  add $t0, $t0, $t1         # Set $t0 to address of bottom of player's column

  li $t2, 14                # 14 rows to look for first coloured pixel

  # Search upwards until finding a non-black pixel


#
# Funciton to find first bubble to grab
#
find_bottom_bubble:
  beq $t2, $zero, grab_done        # No rows left

  lw $t3, 0($t0)                   # Read current bubble
  bne $t3, $zero, check_colour     # Check until pixel is not black
  
  addi $t0, $t0, -28               # Move up one row
  addi $t2, $t2, -1                # One fewer row remaining
  
  j find_bottom_bubble


check_colour:
  lw $t4, held_colour

  beq $t4, $zero, set_held_colour
  bne $t3, $t4, grab_done

  j grab_chain


set_held_colour:
  sw $t3, held_colour


grab_chain:
  beq $t2, $zero, grab_done

  # Check if player is already holding 3 bubbles
  lw $t5, held_count           # get number of held bubbles
  slti $t6, $t5, 2             # is held_count < 2
  beq $t6, $zero, grab_done

  lw $t3, 0($t0)               # Read current bubble
  lw $t4, held_colour          # Read held colour
  bne $t3, $t4, grab_done      # Stop if colours are different
  
  # Else, colours are the same
  sw $zero, 0($t0)             # Remove bubble from board (set the pixel to black)
  
  lw $t5, held_count
  addi $t5, $t5, 1             # Increase held count
  sw $t5, held_count
  
  addi $t0, $t0, -28           # Move to the next bubble above
  addi $t2, $t2, -1            # Drecrease row counter by 1
  j grab_chain

grab_done:
  jr $ra


# gotta remember to reset hel_count after throwing bubbles



#
# Function to draw collected bubbles under player
#
draw_held_bubbles:
  lw $t0, player_col
  addi $t0, $t0, 611                 # Position of first held bubble ==> (player_col + 611)
  sll $t0, $t0, 2                    # Convert to byte offset ==> 4(player_col + 611)
          
  lw $t1, ADDR_DSPL                  # $t1 = display address
  add $t1, $t1, $t0                  # Address of first held bubble
          
  lw $t2, held_count                 # $t2 = Number of collected bubbles
  beq $t2, $zero, held_draw_done     # if held_count = 0, return

  # Get RGB colour corresponding to held_colour
  lw $t3, held_colour
  sll $t3, $t3, 2                    # Colour table offset ==> multiply by 4
          
  la $t4, bubble_colours             # Access colour table
  add $t4, $t4, $t3                  # Select right colour
  lw $t5, 0($t4)                     # $t5 = RGB value of held colour

held_draw_loop:
  beq $t2, $zero, held_draw_done     # if held_count = 0, return

  sw $t5, 0($t1)                     # Draw current bubble
          
  addi $t1, $t1, 128                 # Move one screen row down
  addi $t2, $t2, -1                  # Decrease the held_count value by 1

  j held_draw_loop

held_draw_done:
  jr $ra


  
#
# Erase the three possible held-bubble positions
#
erase_held_bubbles:
  lw $t0, player_col
  addi $t0, $t0, 611           # Position of first held bubble ==> (player_col + 611)
  sll $t0, $t0, 2              # Convert to byte offset ==> 4(player_col + 611)

  lw $t1, ADDR_DSPL
  add $t1, $t1, $t0        # Address of first held bubble

  li $t2, 3                # Maximum holding capacity

erase_held_loop:
  beq $t2, $zero, erase_held_done

  sw $zero, 0($t1)         # Paint black = 0x0

  addi $t1, $t1, 128       # Go to next row
  addi $t2, $t2, -1        # Decrease held_count by 1

  j erase_held_loop

erase_held_done:
  jr $ra



#
# Function to count keyboard actions and advance rows every 10 inputs
#
action_finished:
  lw $t0, key_count              # Load current key count
  addi $t0, $t0, 1               # Increase by 1
      
  li $t1, 10                     # $t1 = 10
  bne $t0, $t1, save_count       # If key_count +1 != 10, save and continue
      
  # else, key_count = 10, therefore counter reached 10      
  sw $zero, key_count            # Reset counter to 0
      
  jal advance_row                # Push existing bubbles down
  jal draw_bubbles               # Redraw the board
      
  j game_loop      
      
save_count:      
  sw $t0, key_count              # Store updated count into memory
  j game_loop
  

  
#
# Fuction for push existing bubbles down by one row
#
advance_row:
  la $t0, board

  # Last cell in game board = 4((14 * 7) - 1)
  #                         = 4(98 - 1)
  #                         = 388
  addi $t0, $t0, 388       # Address of last board cell

  li $t1, 91               # 13 rows * 7 columns

shift_loop:
  beq $t1, $zero, check_bottom_init

  lw $t2, -28($t0)         # Get bubble from row above
  sw $t2, 0($t0)           # Copy it into current row

  addi $t0, $t0, -4        # Move to previous cell
  addi $t1, $t1, -1        # Decrease remaining cells

  j shift_loop



#
# Function for checking if any bubble has reached the bottom row
#
check_bottom_init:
  la $t0, board           # Load board address
  addi $t0, $t0, 364      # Address for the start of row 13
  li $t1, 7               # $t1 = 7  ==>  number of bottom-row cells to check

check_bottom_loop:
  beq $t1, $zero, fill_top_row    # All 7 cells checked ==> jump to fill_top_row

  lw $t2, 0($t0)                  # Read current bottom-row cell
  bne $t2, $zero, game_over       # If current cell contains a bubble, end game

  addi $t0, $t0, 4
  addi $t1, $t1, -1
  j check_bottom_loop

game_over:
  jal draw_bubbles            # Display final board state
  li $v0, 10              # End game for now
  syscall
################################################################
# CAN IMPLEMENT PROPER GAME OVER INTERFACE HERE !!
################################################################

#
# Function to generate a new row of 7 random bubbles
#
fill_top_row:
  la $t0, board           # Start of row 0
  li $t1, 7               # Seven bubbles

fill_top_loop:
  beq $t1, $zero, advance_done

  li $v0, 42              # Random number syscall
  li $a0, 0               
  li $a1, 4               # Generates random number from 0 to 3
  syscall
  
  addi $t2, $a0, 1        # Convert to colour IDs 1 to 4
  sw $t2, 0($t0)          # Store new bubble in memory
  
  addi $t0, $t0, 4        # Next cell in row
  addi $t1, $t1, -1       # Decrease counter

    j fill_top_loop

advance_done:
    jr $ra

  

#
# Function for handeling throwing bubbles
#
handle_throw:
                                  # Attempt to throw held bubbles into the current column.
  jal throw_bubbles               # throw_bubbles returns $v0 = 1 if successful,
                                  # or $v0 = 0 if the throw was unsuccessful.

  beq $v0, $zero, throw_redraw    # Checks for matches and remove them from board
                                  # If $v0 = 0, skip match detection and jump directly to throw_redraw.

  jal check_vertical_match        # Only reaches this line if $v0 = 1
                                  # Checks whether at least 3 consecutive bubbles of the same colour are stacked vertically.
                                  # If true, remove them from game board


throw_redraw:
  jal draw_bubbles
  jal erase_held_bubbles
  jal draw_held_bubbles
  jal check_bottom_after_throw

  j action_finished



#
# Function for throwing held bubbles into player's column
#
throw_bubbles:
  li $v0, 0                    # Default value for throw unsuccessful (used for checking for same colour collision)
  lw $t0, held_count           # $t0 = held_count, possible values: 0, 1, 2, 3
  beq $t0, $zero, throw_done   # No bubbles to throw
 
  lw $t1, held_colour          # Colour being thrown

  # Find first cell in player's column (row 0)
  la $t2, board
  lw $t3, player_col
  sll $t3, $t3, 2             # Multiply column by 4
  add $t2, $t2, $t3           # Address of top cell

  li $t4, 14                  # Number of rows available


#
# Search downward for first empty cell
#
find_throw_spot:
  beq $t4, $zero, throw_done  # Column is full

  lw $t5, 0($t2)              # Read current bubble
  beq $t5, $zero, check_throw_space    # If current cell is empty, stop, else, move down one row

  addi $t2, $t2, 28           # Move down one row
  addi $t4, $t4, -1           # One fewer row available
  j find_throw_spot


#
# Check whether all held bubbles fit
#
check_throw_space:
  slt $t6, $t4, $t0           # Checks whether the available space is smaller than the number of bubbles being thrown 
                              # Returns 0 or 1
                              
  bne $t6, $zero, throw_done  # Cancel if not enough space


#
# Place held bubbles into the board
#
place_held_loop:
  beq $t0, $zero, throw_complete

  sw $t1, 0($t2)              # Store bubble colour

  addi $t2, $t2, 28           # Move to next row
  addi $t0, $t0, -1           # One fewer bubble to place

  j place_held_loop


#
# Reset holding variables after successful throw
#
throw_complete:
  sw $zero, held_count
  sw $zero, held_colour
  li $v0, 1                  # Throw successful (used for checking for same colour collision)

throw_done:
  jr $ra

  
#
# Check bottom row after throwing
# If there are bubbles in the last row, game over 
#
check_bottom_after_throw:
  la $t0, board
  addi $t0, $t0, 364         # First cell of row 13  (byte offset: 4(13*7 + 0))
  li $t1, 7                  # Seven columns

check_throw_bottom_loop:
  beq $t1, $zero, check_throw_bottom_done

  lw $t2, 0($t0)
  bne $t2, $zero, game_over

  addi $t0, $t0, 4
  addi $t1, $t1, -1
  j check_throw_bottom_loop

check_throw_bottom_done:
  jr $ra


#
# Function to check for a vertical match in player's column
#
check_vertical_match:
  la $t0, board             # $t0 = board base address
  lw $t1, player_col        # $t1 = Current player column [0, 6]

  sll $t1, $t1, 2           # Account for column byte offset (multiply by 4)
  addi $t0, $t0, 364        # Start at row 13
  add $t0, $t0, $t1         # Bottom cell of player's column

  li $t2, 14                # Rows remaining to search


#
# Fucntion to find bottom-most bubble to later analyse it
#
match_find_bottom:
  beq $t2, $zero, match_done       # If no rows remaining to check, go back to game 

  lw $t3, 0($t0)                   # Read current cell
  bne $t3, $zero, match_start      # If cureent bubbles is not black, go to match_start

  addi $t0, $t0, -28               # Move up one row
  addi $t2, $t2, -1                # Decrese the number of rows remaining to check

  j match_find_bottom


#
# Save match colour and bottom position
#
match_start:
  add $t4, $t3, $zero             # Copies the bubble's colour into $t4
  add $t5, $t0, $zero             # Copies the bottom bubble's memory address into $t5
  add $t8, $t2, $zero             # $t8 = current row position (for animation)
  li $t6, 0                       # Initialize $t6 to be match counter. Set $t6 = 0

#
# Function to count consecutive bubbles of the same colour. Start from bottom bubble and move up
#
match_count_loop:
  beq $t2, $zero, match_evaluate  # If colours differ, stop counting and check whether at least 3 bubbles match

  lw $t3, 0($t0)                  # Read current bubble colour [0, 4]
  bne $t3, $t4, match_evaluate    # Loops while current bubbles has the same colour as matching stack
                                  # Otherwise, check whether at least 3 bubbles match

  addi $t6, $t6, 1                # Increase match counter
  addi $t0, $t0, -28              # Move up one row
  addi $t2, $t2, -1               # Decrese the number of rows remaining to check

  j match_count_loop


# Checks whether at least 3 bubbles match
# If fewer than 3 bubbles match, nothing is going to be deleted
# Otherwise, proceed to match_remove_loop
match_evaluate:
  slti $t7, $t6, 3              # $t6 = match_count; Is match_count < 3?
  bne $t7, $zero, match_done    # If $t7 is fewer than 3 match, skip removal
                                # Otherwise, continue to match_remove_loop

 # Calculate bitmap address of bottom matching bubble
  lw $t9, ADDR_DSPL

  addi $t8, $t8, 2         # Convert saved row to screen Y
  sll $t8, $t8, 7          # Y * 128 bytes

  add $t9, $t9, $t8        # Add vertical offset
  add $t9, $t9, $t1        # Add player column offset
  addi $t9, $t9, 12        # Board starts at X = 3

#
# Flash matching bubbles white
#
match_flash_init:
  add $t7, $t6, $zero      # Copy match count
  add $t8, $t9, $zero      # Copy bottom bubble display address
  li $t3, 0x00ffffff       # $t3 = white flash colour

match_flash_loop:
  beq $t7, $zero, match_flash_done

  sw $t3, 0($t8)           # Paint current matched bubble white

  addi $t8, $t8, -128      # Move up one display row
  addi $t7, $t7, -1        # One fewer bubble to flash

  j match_flash_loop

 match_flash_done:
  li $v0, 32               # Sleep syscall
  li $a0, 150              # Display white flash for 150 ms
  syscall 

#
# Function to remove all matching bubbles
#
match_remove_loop:
  beq $t6, $zero, match_done

  sw $zero, 0($t5)         # Remove bubble from board array
  sw $zero, 0($t9)         # Erase bubble from Bitmap Display

  addi $t5, $t5, -28       # Move up one row
  addi $t9, $t9, -128      # Move up one display row
  addi $t6, $t6, -1        # Decrease bubbles remaining

  j match_remove_loop

match_done:
    jr $ra












  
  











  
  










