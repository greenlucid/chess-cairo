%builtins output bitwise

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and, bitwise_xor
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.serialize import serialize_word

const word_lenght = 5

const king_pattern = 1144132807
const bishop_pattern = 136391
const knight_pattern = 284889069007
const rook_pattern = 35904

# test_pattern is the one used in test
const test_pattern = 136391
const test_square = 35
const test_pattern_lenght = 3

# THIS IS THE MAIN RECURSIVE FUNCTION - 
# It reads the pattern, word by word, to know in which direction to calculate. 
# Every word = 5 bits, it defines the direction - see function code_to_move (ok, notation is not unified, lots of tests) to see correspondence
# The initial_sq (square) is always the same once you call the function - the ref_sq (reference square) is the last square considered
# as final, or the initial square in case the stop_flag has been passed as 1 (because a trajectory has been compeleted)
# The index is the position in the pattern.
# Still a number of things needed: the moves should go to a felt*.
# The next funtion, recursive vector, is actually who does the calculations to know what parameters to send to the next instance of keep_reading
# The board is loaded with a couple of functions in the bottom. The dictionary contains 16 bits references: 8 bits for the square -> 8 for piece
# The board is loaded empty in case of an empty dictionary
# Here the codes for the pieces:
#	White Rook - WR : 10000 16 10
#	White Knight - WN : 10001 17 11
#	White Bishop - WB : 10010 18 12
#	White Queen - WQ : 10011 19 13
#	White King - WK : 10100 20 14
#	White Pawn - WP : 10101 21 15
#	Black Rook - BR : 11000 24 16
#	Black Knight - BN : 11001 25 17
#	Black Bishop - BB : 11010 26 18
#	Black Queen - BQ : 11011 27 19
#	Black King - BK : 11100 28 1A
#	Black Pawn - BP : 11101 29 1B
# 
# WARNING: the recursive_vector only contains a couple of checks... many more needed to make it functional. This is just to test the recursion.
# PLANING: To add special moves (pawns, castle, en passant capture) and the checking of legal positions (king's safety first!)
func keep_reading{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, index: felt, initial_sq: felt, ref_sq: felt):
    alloc_locals
    if index == -1:
        return()
    end
    # Get current word
    let (current_word) = get_word(index)
    # 
    let (local final_sq) = get_final_square(current_word, ref_sq)
    # Any Actions here
    let (stop_flag, new_ref_sq) = recursive_vector(board, final_sq, initial_sq)
    serialize_word(final_sq)
    # Calculate recursive parameters
    keep_reading(board, index-stop_flag, initial_sq, new_ref_sq)
    # Recursive call
    return()
end

func recursive_vector{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, final_square: felt, initial_square: felt)->(stop_flag: felt, new_final_sq: felt):
    if final_square == 64:
        return(stop_flag=1, new_final_sq=initial_square)
    end
    if [board+initial_square] == 17:
        return(stop_flag=1, new_final_sq=initial_square)
    end
    let (same) = same_color(board, initial_square, final_square)
    if same == 1:
        return(stop_flag=1, new_final_sq=initial_square)
    end
    return(stop_flag=0, new_final_sq=final_square)
end


# SOME USEFUL FUNCTIONS RELATED WITH COLORS
func same_color{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, initial_square: felt, final_square: felt) -> (same: felt):
    alloc_locals
    let (local attacking_color) = piece_color([board+initial_square])
    let (local final_color) = piece_color([board+final_square])
    if attacking_color == final_color:
        return(same=1)
    end
    return(same=0)
end

func invert_color{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        initial_color: felt)->(final_color: felt):
    if initial_color == 1:
        return(final_color=2)
    end
    return(final_color=1)
end

func piece_color {output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(rep: felt) -> (res:felt):
    let (res1) = bitwise_and(rep, 0x8)
    tempvar bit1 = res1/0x8
    let (res2) = bitwise_and(rep, 0x10)
    tempvar bit2 = res2/0x10
    return(res = bit1 + bit2)
end

# DEALING WITH SQUARES AND MOVES
func get_final_square {output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(move_code: felt, initial_sq: felt)->(final_square:felt):
    alloc_locals
    let (local x, y) = sq_coord(initial_sq)
    let (x_d, y_d) = code_to_move(move_code)
    let final_x = x+x_d
    let final_y = y+y_d
    let (final_square) = coord_sq(final_x, final_y)
    return (final_square=final_square)
end

func board_overflow{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(x:felt, y:felt)->(ov:felt, no: felt):
    if x == -1:
        return(ov=1, no=0)
    end
    if x == -2:
        return(ov=1, no=0)
    end
    if x == 8:
        return(ov=1, no=0)
    end
    if x == 9:
        return(ov=1, no=0)
    end
    if y == -1:
        return(ov=1, no=0)
    end
    if y == -2:
        return(ov=1, no=0)
    end
    if y == 8:
        return(ov=1, no=0)
    end
    if y == 9:
        return(ov=1, no=0)
    end
    return(ov=0, no=1)
end

# Receives the code or word in a pattern (5 bits) and returns the variations in x and y 
func code_to_move {output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(code: felt) -> (x_var: felt, y_var:felt):
    # ifs listed in the same order than the introductory comment
    if code == 4:
        return(x_var=-1, y_var=-1)
    end 
    if code == 1:
        return(x_var=0, y_var=-1)
    end 
    if code == 6:
        return(x_var=1, y_var=-1)
    end 
    if code == 3:
        return(x_var=1, y_var=0)
    end 
    if code == 7:
        return(x_var=1, y_var=1)
    end 
    if code == 2:
        return(x_var=0, y_var=1)
    end 
    if code == 5:
        return(x_var=-1, y_var=1)
    end 
    if code == 0:
        return(x_var=-1, y_var=0)
    end
    # Knight jumps:
    if code == 12:
        return(x_var=-1, y_var=-2)
    end 
    if code == 9:
        return(x_var=1, y_var=-2)
    end 
    if code == 14:
        return(x_var=2, y_var=-1)
    end 
    if code == 11:
        return(x_var=2, y_var=1)
    end 
    if code == 15:
        return(x_var=1, y_var=2)
    end 
    if code == 10:
        return(x_var=-1, y_var=2)
    end 
    if code == 13:
        return(x_var=-2, y_var=1)
    end 
    if code == 8:
        return(x_var=-2, y_var=-1)
    end
    return(0,0)
end

# Returns the coordinates of a square given in linear codification (0-> a1, 63->h8)
func sq_coord {bitwise_ptr : BitwiseBuiltin*}(square: felt) -> (x: felt, y:felt):
    let (x) = bitwise_and(square, 0x7)
    tempvar dif = square - x 
    let y = dif / 0x8
    return(x=x, y=y)
end

# Returns the linear codification (0-> a1, 63->h8) of a square given in coordinates
func coord_sq {output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(x: felt, y:felt) -> (square: felt):
    alloc_locals
    let (ov, no) = board_overflow(x, y)
    let new_y = y * 0x8
    tempvar res = 64*ov + (new_y + x)*no
    return (square=res)
end

# SOME FUNCTIONS TO DEAL WITH THE PATTERN 
func get_word{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(index: felt) -> (word: felt):
    alloc_locals
    # WORD CALCULATION: Get 2^(bit+1) - Example 4 bits word: 10000
    let (local bin_word_pow) = binpow(word_lenght)
    # INDEX CALCULATION: Get the bin position for the bit-th word - Ex: 4 bits word, index 2: result 9
    let word_index = index * word_lenght
    # Get the corresponding power of two for that bin_index - Ex: 2^9
    let (bin_index) = binpow(word_index)
    # Set the word in the index - Ex: 111100000000
    let word_in_index = bin_index * (bin_word_pow - 1)
    # CALCULATE WORD IN THE CODE
    let (word_in_code) = bitwise_and(test_pattern, word_in_index)
    # Eliminate zeros on the right
    let word = word_in_code / bin_index
    # Return the value
    return(word=word)

end

# Returns 2^pow for a given pow
func binpow {output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(pow: felt)->(res:felt):
    if pow == 0:
        return(res=1)
    else:
        let(res1) = binpow(pow-1)
        tempvar result = res1 * 2
    end
    return(res = result)
end

# -----------------------------------------------------------------
# DICTIONARY STRUCTURE 
# Returns the input truncating 8 bit on the right
func truncate_eight_bit{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(input: felt)->(res:felt):
    let (input_last_eight_bit) = bitwise_and(input, 0xFF)
    tempvar input_minus_last_eight_bit = input - input_last_eight_bit
    tempvar res1 = input_minus_last_eight_bit / 0x100
    return (res=res1) 
end

# Return value based on key
func eight_bit_dict{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(dict: felt*, dict_size: felt, key:felt) -> (res:felt):
    if dict_size == 0:
        return (res=0)
    end
    let (current_key) =  truncate_eight_bit([dict])
    if current_key == key:
        let (value) = bitwise_and([dict], 0xFF)
        return(res=value)
    else:
        let (result) = eight_bit_dict(dict+1, dict_size-1, key)
    end
    return(res=result)
end
# END OF DICTIONARY STRUCTURE 
# -----------------------------------------------------------------

# -----------------------------------------------------------------
# BOARD LOADER - USING DICTIONARY
# Loads Board of board_size size, using the dict dictionary
func board_loader{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, board_size: felt, dict: felt*, dict_size: felt, counter: felt):
    if board_size == -1:  
        return()
    end

    let (value) = eight_bit_dict(dict, dict_size, counter)
    assert([board+counter]) = value
    board_loader(board, board_size-1, dict, dict_size, counter+1) 
    return()
end

# END OF BOARD LOADER 
# -----------------------------------------------------------------


# THE MAIN FUNCTION - Here you can include some pieces in the board, using the dictionary.
# Example: square d5 (35 or 00100011) bishop (18 or 00010010): so a bishop on d5 is 0010001100010010 or 8978)
# Ok, would be good to have a function to convert the information into a code, the time will come for such fruitfull resources.
func main{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}():
    alloc_locals
    let (local dict) = alloc()
    let (local board) = alloc()
    # Here we should include a moves: felt* to load the moves (by now, take a look at the final squares in the console)
    assert [dict] = 4377
    assert [dict+1] = 523
    assert [dict+2] = 8978
    
    board_loader(board, 63,dict, 3, 0)
    keep_reading(board, test_pattern_lenght, test_square, test_square)
    
    return()
end