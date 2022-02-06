#CHESS CAIRO UTILS
# FROM ALL THE HORRIBLE PRACTICES IN THIS CODE, I know the worst is probably this annoying "moves, moves_size" thing.
# Hopefully I find soon the time to refactor everything with a struct.

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from src.bit_helper import bits_at

# CONSTANT VALUES FOR CHESS CAIRO
# Lenght of the pattern
const word_lenght = 4
# Value of the pieces
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

# -----------------------------------------------------------------
# BOARD LOADER - USING DICTIONARY
# Loads Board of board_size size, using the dict dictionary
func board_loader{bitwise_ptr : BitwiseBuiltin*}(
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

# -----------------------------------------------------------------
# DICTIONARY STRUCTURE 
# Return value (8 bits) based on key (8 bits)
func eight_bit_dict{bitwise_ptr : BitwiseBuiltin*}(dict: felt*, dict_size: felt, key:felt) -> (res:felt):
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

# Returns the input truncating 8 bit on the right
func truncate_eight_bit{bitwise_ptr : BitwiseBuiltin*}(input: felt)->(res:felt):
    let (input_last_eight_bit) = bitwise_and(input, 0xFF)
    tempvar input_minus_last_eight_bit = input - input_last_eight_bit
    tempvar res1 = input_minus_last_eight_bit / 0x100
    return (res=res1) 
end

# Aditional function to calculate codes while populating the board
func get_dict_code(square: felt, piece: felt) -> (picece_in_board: felt):
    tempvar code = square * 256 + piece
    return(code)
end
# END OF DICTIONARY STRUCTURE 
# -----------------------------------------------------------------


# VARIOUS FUNCs USED ON THE CORE ..................................
# Checks if a piece is trying to jump 1 or 2 rows/columns off the board
func board_overflow{bitwise_ptr : BitwiseBuiltin*}(x:felt, y:felt)->(ov:felt, no: felt):
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

# Returns the coordinates of a square given in linear codification (0-> 0,0 (a8); 63-> 7,7 (h1); 17-> 2,1)
# Notice that in this codification, the number of the square contains naturally the row in the first 3 bits
# and the column in the last threee bits. Ex: b6 = 17, in binary: 010001; or 010 and 001, which are (2, 1).
func sq_coord {bitwise_ptr : BitwiseBuiltin*}(square: felt) -> (x: felt, y:felt):
    let (x) = bitwise_and(square, 0x7)
    tempvar dif = square - x 
    let y = dif / 0x8
    return(x=x, y=y)
end

# Returns the linear codification (0-> 0,0 (a8); 63-> 7,7 (h1)) of a square given in coordinates
func coord_sq {bitwise_ptr : BitwiseBuiltin*}(x: felt, y:felt) -> (square: felt):
    alloc_locals
    let (ov, no) = board_overflow(x, y)
    let new_y = y * 0x8
    tempvar res = 64*ov + (new_y + x)*no
    return (square=res)
end

# SOME FUNCTIONS TO DEAL WITH THE PATTERN
# The Pattern of movement of a piece is the list of directions in which a piece can move.
# Ex: bishop moves in the directions (+1, +1), (+1, -1), (-1, +1), (-1, -1).
# The pattern contains words (or codes) of 4 bits that indicates those directions. See func code_to_move.
# The following func extracts the word (or code) in the position (index) of the (pattern) given.
func get_pattern_word{bitwise_ptr : BitwiseBuiltin*}(pattern: felt, index: felt) -> (word: felt):
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
# Maybe this func should be replaced with the builtin.
func binpow {bitwise_ptr : BitwiseBuiltin*}(pow: felt)->(res:felt):
    if pow == 0:
        return(res=1)
    else:
        let(res1) = binpow(pow-1)
        tempvar result = res1 * 2
    end
    return(res = result)
end

# -----------------------------------------------------------------
# -----------------------------------------------------------------
# -----------------------------------------------------------------
# FUNCTIONS ASSISTING THE CORE

# SOME USEFUL FUNCTIONS RELATED WITH COLORS
func same_color{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, initial_square: felt, final_square: felt) -> (same: felt):
    alloc_locals
    let (local attacking_color) = piece_color([board+initial_square])
    let (local final_color) = piece_color([board+final_square])
    if attacking_color == final_color:
        return(same=1)
    end
    return(same=0)
end

func different_color{bitwise_ptr : BitwiseBuiltin*}(
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
func invert_color{bitwise_ptr : BitwiseBuiltin*}(
        initial_color: felt)->(final_color: felt):
    if initial_color == 1:
        return(final_color=2)
    end
    if initial_color == 2:
        return(final_color=1)
    end
    return(final_color=0)
end

# returns 0 = no piece, 1 = white piece, 2 = black piece
func piece_color {bitwise_ptr : BitwiseBuiltin*}(rep: felt) -> (res:felt):
    let (res1) = bitwise_and(rep, 0x8)
    tempvar is_black = res1/0x8
    let (res2) = bitwise_and(rep, 0x10)
    tempvar is_piece = res2/0x10
    return(res = is_black + is_piece)
end

# DEALING WITH SQUARES AND MOVES
func get_final_square {bitwise_ptr : BitwiseBuiltin*}(move_code: felt, initial_sq: felt)->(final_square:felt):
    alloc_locals
    let (local x, y) = sq_coord(initial_sq)
    let (x_d, y_d) = code_to_move(move_code)
    let final_x = x+x_d
    let final_y = y+y_d
    let (final_square) = coord_sq(final_x, final_y)
    return (final_square=final_square)
end

# Receives the code or word in a pattern (5 bits) and returns the variations in x and y 
func code_to_move {bitwise_ptr : BitwiseBuiltin*}(code: felt) -> (x_var: felt, y_var:felt):
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
    if code == -1:
        return(x_var=0, y_var=0)
    end
    return(0,0)
end

# Returns 1 if square is the final square of any of the moves given. 
func is_attacked{bitwise_ptr : BitwiseBuiltin*}(
        moves: felt*, size: felt, square: felt) -> (res: felt):
    alloc_locals
    if size == 0:
        return(res=0)
    end
    # Transform from compress rep (a3 = 3-a = 5-0 = 101000) to board rep (a3 = row * 8 + column) 
    let (local fin_y) = get_binary_word([moves+size-1], 5, 3)
    let (local fin_x) = get_binary_word([moves+size-1], 2, 3)
    tempvar final_square = fin_y * 8 + fin_x
    if square == final_square:
        return(res= 1)
    end
    let (result) = is_attacked(moves, size - 1, square)
    return(res=result)
end

# Returns 1 if the final square of any of the moves given is = 20 (WKing). 
func white_king_is_attacked{bitwise_ptr : BitwiseBuiltin*}(
        black_attacking_moves: felt*, black_attacking_moves_size: felt, board: felt*) -> (res: felt):
    alloc_locals
    if black_attacking_moves_size == 0:
        return(res=0)
    end
    # Transform from compress rep (a3 = 3-a = 5-0 = 101000) to board rep (a3 = row * 8 + column) 
    let (local fin_y) = get_binary_word([black_attacking_moves+black_attacking_moves_size-1], 5, 3)
    let (local fin_x) = get_binary_word([black_attacking_moves+black_attacking_moves_size-1], 2, 3)
    tempvar final_square = fin_y * 8 + fin_x
    if [board + final_square] == 20:
        return(res= 1)
    end
    let (result) = white_king_is_attacked(black_attacking_moves, black_attacking_moves_size - 1, board)
    return(res=result)
end

# Returns 1 if the final square of any of the moves given is = 28 (BKing). 
func black_king_is_attacked{bitwise_ptr : BitwiseBuiltin*}(
        white_attacking_moves: felt*, white_attacking_moves_size: felt, board: felt*) -> (res: felt):
    alloc_locals
    if white_attacking_moves_size == 0:
        return(res=0)
    end
    # Transform from compress rep (a3 = 3-a = 5-0 = 101000) to board rep (a3 = row * 8 + column) 
    let (local fin_y) = get_binary_word([white_attacking_moves+white_attacking_moves_size-1], 5, 3)
    let (local fin_x) = get_binary_word([white_attacking_moves+white_attacking_moves_size-1], 2, 3)
    tempvar final_square = fin_y * 8 + fin_x
    if [board + final_square] == 28:
        return(res= 1)
    end
    let (result) = black_king_is_attacked(white_attacking_moves, white_attacking_moves_size - 1, board)
    return(res=result)
end

# CAIRO VISUAL REPRESENTATION OF MOVE, similar to normal chess notation, but starting on a8, with coordenates - FOR CONSOLE
# Example: f1 to c4 -> f=5, f1=57, c=2, c4 = 24, the move is: 57240 (the last zero is for promoting anotations)
func get_rep{bitwise_ptr : BitwiseBuiltin*}(move: felt)->(rep: felt):
    alloc_locals
    let (local fin_y) = get_binary_word(move, 5, 3)
    let (local fin_x) = get_binary_word(move, 2, 3)
    let (local ini_y) = get_binary_word(move, 11, 3)
    let (local ini_x) = get_binary_word(move, 8, 3)
    let (local extra) = get_binary_word(move, 0, 2)

    return(rep = ini_x*10000 + ini_y*1000 + fin_x*100 + fin_y*10 + extra)
end

# SMALL LIB FOR CODIFICATION

# SOME FUNCTIONS TO DEAL WITH THE PATTERN 
func get_binary_word{bitwise_ptr : BitwiseBuiltin*}(
        binary_tape: felt, binary_index: felt, binary_word_length: felt) -> (word: felt):
    alloc_locals
    # WORD CALCULATION: Get 2^(bit+1) - Example 4 bits word: 10000
    let (local bin_word_pow) = binpow(binary_word_length)
    # INDEX CALCULATION: Get the bin position for the bit-th word - Ex: 4 bits word, index 2: result 9
    let word_index = binary_index
    # Get the corresponding power of two for that bin_index - Ex: 2^9
    let (bin_index) = binpow(word_index)
    # Set the word in the index - Ex: 111100000000
    let word_in_index = bin_index * (bin_word_pow - 1)
    # CALCULATE WORD IN THE CODE
    let (word_in_code) = bitwise_and(binary_tape, word_in_index)
    # Eliminate zeros on the right
    let word = word_in_code / bin_index
    # Return the value
    return(word=word)
end

func put_binary_word{bitwise_ptr : BitwiseBuiltin*}(
        binary_tape: felt, binary_index: felt, binary_word_length: felt, binary_word: felt) -> (new_tape: felt):
    alloc_locals
    let (local binary_word_room) = binpow(binary_word_length)
    let (local binary_index_power) = binpow(binary_index)
    let binary_rest = bitwise_and(binary_tape, binary_index-1)
    let truncated_tape = binary_tape - binary_rest 

    let make_room_in_tape = truncated_tape * binary_word_room * binary_index 
    let new_binary_word_index = binary_word * binary_index_power

    return(new_tape = make_room_in_tape + new_binary_word_index + binary_rest)
end

# From castle code to booleans for evert possible castling option
func get_castle_bool{bitwise_ptr : BitwiseBuiltin*}(
        castle_code: felt)->(K_code: felt, Q_code: felt, k_code: felt, q_code: felt):
    alloc_locals
    let (local K_code) = get_binary_word(castle_code, 3, 1)
    let (local Q_code) = get_binary_word(castle_code, 2, 1)
    let (local k_code) = get_binary_word(castle_code, 1, 1)
    let (local q_code) = get_binary_word(castle_code, 0, 1)
    return(K_code= K_code, Q_code= Q_code, k_code= k_code, q_code= q_code)
end

func is_move_in_list{bitwise_ptr : BitwiseBuiltin*}(
        moves: felt*, moves_size: felt, move: felt) -> (is_move_in_list: felt):
    alloc_locals
    if moves_size == 0:
        return(is_move_in_list = 0)
    end
    #Recursive call
    let (local result) = is_move_in_list(moves, moves_size - 1, move)
    let current_move = [moves+ moves_size - 1]
    if current_move == move:
        return(is_move_in_list = 1)
    end
    return(is_move_in_list = result)
end

# Move (as saved in the moves array) constructor, using original square, final square and extra info
func construct_move(
        original_square: felt, final_square: felt, extra_info: felt)-> (move: felt):
    tempvar result = original_square * 256 + final_square * 4 + extra_info
    return (move = result)
end

func dissect_move{
        bitwise_ptr : BitwiseBuiltin*, range_check_ptr
        }(move : felt) -> (origin : felt, dest : felt, extra : felt):
    alloc_locals
    let (local origin) = bits_at(el=move, offset=237, size=6)
    let (local dest) = bits_at(el=move, offset=243, size=6)
    let (local extra) = bits_at(el=move, offset=249, size=2)
    return (origin, dest, extra)
end