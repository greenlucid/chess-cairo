%builtins output bitwise

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and, bitwise_xor
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.serialize import serialize_word

const word_lenght = 5

const king_pattern = 1144132807
# For queen_pattern just use bishop_pattern and rook_pattern 
const bishop_pattern = 136391
const knight_pattern = 284889069007
const rook_pattern = 35904
# Still needed pattern for black and white pawns

# Here the codes for the pieces:

const WRook = 16
const WKnight = 17
const WBishop = 18 
const WQueen = 19
const WKing = 20
const WPawn = 21 
const BRook = 24 
const BKnight = 25
const BBishop = 26
const BQueen = 27
const BKing = 28
const BPawn = 29
const a8 = 0
const b8 = 1
const c8 = 2
const d8 = 3
const e8 = 4
const f8 = 5
const g8 = 6
const h8 = 7
const a7 = 8
const b7 = 9
const c7 = 10
const d7 = 11
const e7 = 12
const f7 = 13
const g7 = 14
const h7 = 15
const a6 = 16
const b6 = 17
const c6 = 18
const d6 = 19
const e6 = 20
const f6 = 21
const g6 = 22
const h6 = 23
const a5 = 24
const b5 = 25
const c5 = 26
const d5 = 27
const e5 = 28
const f5 = 29
const g5 = 30
const h5 = 31
const a4 = 32
const b4 = 33
const c4 = 34
const d4 = 35
const e4 = 36
const f4 = 37
const g4 = 38
const h4 = 39
const a3 = 40
const b3 = 41
const c3 = 42
const d3 = 43
const e3 = 44
const f3 = 45
const g3 = 46
const h3 = 47
const a2 = 48
const b2 = 49
const c2 = 50
const d2 = 51
const e2 = 52
const f2 = 53
const g2 = 54
const h2 = 55
const a1 = 56
const b1 = 57
const c1 = 58
const d1 = 59
const e1 = 60
const f1 = 61
const g1 = 62
const h1 = 63
# 
# THIS IS THE MAIN RECURSIVE FUNCTION - 
# It reads the pattern, word by word, to know in which direction to calculate. 
# Every word = 5 bits, it defines the direction - see function code_to_move (ok, notation is not unified, lots of tests) to see correspondence
# The initial_sq (square) is always the same once you call the function - the ref_sq (reference square) is the last square considered
# as final, or the initial square in case the stop_flag has been passed as 1 (because a trajectory has been compeleted)
# The index is the position in the pattern.

# WARNING: the recursive_vector only contains a couple of checks... many more needed to make it functional. This is just to test the recursion.
# PLANING: To add special moves (pawns, castle, en passant capture) and the checking of legal positions (king's safety first!)
func calculate_moves{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, pattern: felt, index: felt, initial_sq: felt, ref_sq: felt)->(size: felt):
    alloc_locals
    if index == -1:
        return(0)
    end
    # Get current word
    let (current_word) = get_word(pattern, index)
    # 
    let (local final_sq) = get_final_square(current_word, ref_sq)

    # Calculate recursive parameters
    let (stop_flag, new_ref_sq, save_flag) = recursive_vector(board, moves, final_sq, initial_sq)

    # Send recursive parameters
    let(size_res) = calculate_moves(board, moves+save_flag, pattern, index-stop_flag, initial_sq, new_ref_sq)
    # Recursive call
    return(size_res + save_flag)
end

func recursive_vector{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, final_square: felt, initial_square: felt)->(stop_flag: felt, new_final_sq: felt, save_flag: felt):
    tempvar move_rep = initial_square*100 + final_square
    if final_square == 64:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
    end
    # Only one square in these cases:
    if [board+initial_square] == WKnight:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
    end
    if [board+initial_square] == WKnight:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
    end
    if [board+initial_square] == BKnight:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
    end
    if [board+initial_square] == BKing:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
    end
    let (same) = same_color(board, initial_square, final_square)
    if same == 1:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
    end
    let (different) = different_color(board, initial_square, final_square)
    if different == 1:
        tempvar move_rep = initial_square*100 + final_square
        assert [moves] = move_rep
        return(stop_flag=1, new_final_sq=initial_square, save_flag=1)
    end
    tempvar move_rep = initial_square*100 + final_square
    assert [moves] = move_rep
    return(stop_flag=0, new_final_sq=final_square, save_flag=1)
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

func different_color{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, initial_square: felt, final_square: felt) -> (diff: felt):
    alloc_locals
    let (local attacking_color) = piece_color([board+initial_square])
    let (local final_color) = piece_color([board+final_square])
    let (local inv_final_color) = invert_color(final_color)
    if attacking_color == inv_final_color:
        return(diff=1)
    end
    return(diff=0)
end
func invert_color{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        initial_color: felt)->(final_color: felt):
    if initial_color == 1:
        return(final_color=2)
    end
    if initial_color == 2:
        return(final_color=1)
    end
    return(final_color=0)
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
func get_word{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(pattern: felt, index: felt) -> (word: felt):
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
    let (word_in_code) = bitwise_and(pattern, word_in_index)
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

func get_dict_code(square: felt, piece: felt) -> (picece_in_board: felt):
    tempvar code = square * 256 + piece
    return(code)
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

func show_moves{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(list_of_moves: felt*, size: felt):
    if size == 0:
        return()
    end
    show_moves(list_of_moves+1, size-1)
    serialize_word([list_of_moves])
    return()
end

# THE MAIN FUNCTION - Here you can include some pieces in the board, using the dictionary.
func main{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}():
    alloc_locals
    let (local dict) = alloc()
    let (local board) = alloc()
    let (local moves1) = alloc()
    let (local moves2) = alloc()
    # Here we should include a moves: felt* to load the moves (by now, take a look at the final squares in the console
    let (code1) = get_dict_code(d4, WBishop)
    let (code2) = get_dict_code(b6, BKnight)
    let (code3) = get_dict_code(g7, WQueen)
    
    assert [dict] = code1
    assert [dict+1] = code2
    assert [dict+2] = code3
    
    board_loader(board, 63,dict, 3, 0)

    let (d4_size) = calculate_moves(board, moves1, bishop_pattern, 3, d4, d4)
    show_moves(moves1, d4_size)

    let (g7_size) = calculate_moves(board, moves2, bishop_pattern, 3, g7, g7)
    show_moves(moves2, g7_size)

    return()
end

# NEXT: KNIGHT MOVES NOT BEING RECORDED - CONFLICT AROUND FINAL SQUARE OF SAME COLOR OR NOT (SAME WIHT KING)
# ALSO: PAWN MOVES
# ALSO: SPECIAL MOVES