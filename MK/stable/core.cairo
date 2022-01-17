from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and, bitwise_xor
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.serialize import serialize_word

from chess_utils import get_pattern_word
from chess_utils import different_color
from chess_utils import same_color
from chess_utils import piece_color
from chess_utils import get_final_square
from chess_utils import code_to_move
from chess_utils import sq_coord
from chess_utils import get_binary_word
from chess_utils import board_overflow

const king_pattern = 305419888
const bishop_pattern = 17767
const knight_pattern = 2309737967
const rook_pattern = 4896
const white_pawn_pattern = 1046
const black_pawn_pattern = 1319
const queen_pattern = 320882023
const empty_square = -1


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

# WARNING: the recursive vector only contains a couple of checks... many more needed to make it functional. This is just to test the recursion.
# PLANING: To add special moves (pawns, castle, en passant capture) and the checking of legal positions (king's safety first!)

func calculate_white_board{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, board_index: felt, moves: felt*) -> (size_board_moves: felt):
    alloc_locals
    if board_index == 64:
        return(0)
    end
    let (current_pattern, current_pattern_index) = pattern_of([board+board_index])
    let (local size_this) = calculate_white_moves(board, moves, current_pattern, current_pattern_index, board_index, board_index)
    let (size_next) = calculate_white_board(board, board_index+1, moves + size_this)
    return(size_this + size_next)    
end

func calculate_white_moves{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, pattern: felt, index: felt, initial_sq: felt, ref_sq: felt)->(size: felt):
    alloc_locals
    if index == -1:
        return(0)
    end
    # Get current word
    let (current_word) = get_pattern_word(pattern, index)
    # 
    let (local final_sq) = get_final_square(current_word, ref_sq)

    # Calculate recursive parameters
    let (stop_flag, new_ref_sq, save_flag) = recursive_white_vector(board, moves, final_sq, initial_sq, index)
    tempvar move_rep = initial_sq*256 + final_sq*4
    if save_flag == 1:
        assert [moves] = move_rep    
    end
    # Send recursive parameters
    let(size_res) = calculate_white_moves(board, moves+save_flag, pattern, index-stop_flag, initial_sq, new_ref_sq)
    # Recursive call
    return(size_res + save_flag)
end

func recursive_white_vector{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, final_square: felt, initial_square: felt, pattern_index: felt)->(stop_flag: felt, new_final_sq: felt, save_flag: felt):
    alloc_locals
    let (local final_x, final_y) = sq_coord(final_square)
    tempvar move_rep = initial_square*100 + final_square
    if final_square == 64:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
    end
    let (this_color) = piece_color([board+initial_square])
    if this_color != 1:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
    end    
    # Pawn moves
    if [board+initial_square] == WPawn:
        if pattern_index == 1:
            if [board+final_square] == 0:
                let (final_x, final_y) = sq_coord(final_square)
                if final_y != 4:
                    return(stop_flag=0, new_final_sq=final_square, save_flag=1)
                else:
                    return(stop_flag=1, new_final_sq=final_square, save_flag=1)
                end
            else:
                return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
            end
        else:
            let (WPdifferent) = different_color(board, initial_square, final_square)
            if WPdifferent == 1:
                return(stop_flag=1, new_final_sq=initial_square, save_flag=1)
            else:
                return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
            end
        end
    end

    # Only one square in these cases:
    
    if [board+initial_square] == WKnight:
        let (sameWN) = same_color(board, initial_square, final_square)
        if sameWN == 1:
            return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
        else:
            return(stop_flag=1, new_final_sq=initial_square, save_flag=1)
        end
    end
    if [board+initial_square] == WKing:
        let (sameWK) = same_color(board, initial_square, final_square)
        if sameWK == 1:
            return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
        else:
            return(stop_flag=1, new_final_sq=initial_square, save_flag=1)
        end
    end
    if [board+initial_square] == BKnight:
        let (sameBN) = same_color(board, initial_square, final_square)
        if sameBN == 1:
            return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
        else:
            return(stop_flag=1, new_final_sq=initial_square, save_flag=1)
        end
    end
    if [board+initial_square] == BKing:
        let (sameBK) = same_color(board, initial_square, final_square)
        if sameBK == 1:
            return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
        else:
            return(stop_flag=1, new_final_sq=initial_square, save_flag=1)
        end
    end
    # ALL OTHER CASES
    let (same) = same_color(board, initial_square, final_square)
    if same == 1:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
    end
    let (different) = different_color(board, initial_square, final_square)
    if different == 1:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=1)
    end
    return(stop_flag=0, new_final_sq=final_square, save_flag=1)
end

# NOT MOVING, BUT ATTACKING SQUARES, FOR WHITE
func calculate_white_attack{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, board_index: felt, moves: felt*) -> (size_board_moves: felt):
    alloc_locals
    if board_index == 64:
        return(0)
    end
    let (current_pattern, current_pattern_index) = pattern_of([board+board_index])
    let (local size_this) = calculate_white_attacking_moves(board, moves, current_pattern, current_pattern_index, board_index, board_index)
    let (size_next) = calculate_white_attack(board, board_index+1, moves + size_this)
    return(size_this + size_next)    
end

# FOR WHOEVER REACHES THIS POINT: Yeap, as of this very moment, the code seems very redundant. Horrible.
# But I'm not sure if this is the biggest issue, really. Anyway, it's all recursive... once it starts to
# it will be horrible anyway. Ok, I'm not very experienced on this matter :) Any comments welcome.
func calculate_white_attacking_moves{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, pattern: felt, index: felt, initial_sq: felt, ref_sq: felt)->(size: felt):
    alloc_locals
    if index == -1:
        return(0)
    end
    # Get current word
    let (current_word) = get_pattern_word(pattern, index)
    # 
    let (local final_sq) = get_final_square(current_word, ref_sq)

    # Calculate recursive parameters
    let (stop_flag, new_ref_sq, save_flag) = recursive_white_attacking_vector(board, moves, final_sq, initial_sq, index)
    tempvar move_rep = initial_sq*256 + final_sq*4
    if save_flag == 1:
        assert [moves] = move_rep    
    end
    # Send recursive parameters
    let(size_res) = calculate_white_attacking_moves(board, moves+save_flag, pattern, index-stop_flag, initial_sq, new_ref_sq)
    # Recursive call
    return(size_res + save_flag)
end

func recursive_white_attacking_vector{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, final_square: felt, initial_square: felt, pattern_index: felt)->(stop_flag: felt, new_final_sq: felt, save_flag: felt):
    alloc_locals
    let (local final_x, final_y) = sq_coord(final_square)
    tempvar move_rep = initial_square*100 + final_square
    if final_square == 64:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
    end
    let (this_color) = piece_color([board+initial_square])
    if this_color != 1:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
    end    
    # Pawn moves
    if [board+initial_square] == WPawn:
        if pattern_index != 1:
            return(stop_flag=1, new_final_sq=initial_square, save_flag=1)
        else:
            return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
        end
    end

    # Only one square in these cases:
    if [board+initial_square] == WKnight:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=1)
    end
    if [board+initial_square] == WKing:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=1)
    end
    if [board+initial_square] == BKnight:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=1)
    end
    if [board+initial_square] == BKing:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=1)
    end
    # ALL OTHER CASES
    let (same) = same_color(board, initial_square, final_square)
    if same == 1:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=1)
    end
    let (different) = different_color(board, initial_square, final_square)
    if different == 1:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=1)
    end
    return(stop_flag=0, new_final_sq=final_square, save_flag=1)
end

# FROM THE BLACK SIDE ---------------------------------------------------------------------
func calculate_black_board{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, board_index: felt, moves: felt*) -> (size_board_moves: felt):
    alloc_locals
    if board_index == 64:
        return(0)
    end
    let (current_pattern, current_pattern_index) = pattern_of([board+board_index])
    let (local size_this) = calculate_black_moves(board, moves, current_pattern, current_pattern_index, board_index, board_index)
    let (size_next) = calculate_black_board(board, board_index+1, moves + size_this)
    return(size_this + size_next)    
end

func calculate_black_moves{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, pattern: felt, index: felt, initial_sq: felt, ref_sq: felt)->(size: felt):
    alloc_locals
    if index == -1:
        return(0)
    end
    # Get current word
    let (current_word) = get_pattern_word(pattern, index)
    # 
    let (local final_sq) = get_final_square(current_word, ref_sq)

    # Calculate recursive parameters
    let (stop_flag, new_ref_sq, save_flag) = recursive_black_vector(board, moves, final_sq, initial_sq, index)
    tempvar move_rep = initial_sq*256 + final_sq*4
    if save_flag == 1:
        assert [moves] = move_rep    
    end
    # Send recursive parameters
    let(size_res) = calculate_black_moves(board, moves+save_flag, pattern, index-stop_flag, initial_sq, new_ref_sq)
    # Recursive call
    return(size_res + save_flag)
end

func recursive_black_vector{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, final_square: felt, initial_square: felt, pattern_index: felt)->(stop_flag: felt, new_final_sq: felt, save_flag: felt):
    alloc_locals
    let (local final_x, final_y) = sq_coord(final_square)
    tempvar move_rep = initial_square*100 + final_square
    if final_square == 64:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
    end
    let (this_color) = piece_color([board+initial_square])

    if this_color != 2:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
    end    

    # Black pawn is moving forward
    if [board+initial_square] == BPawn:
        if pattern_index == 2:
            if [board+final_square] == 0:
                let (final_x, final_y) = sq_coord(final_square)
                if final_y != 3:
                    return(stop_flag=0, new_final_sq=final_square, save_flag=1)
                else:
                    return(stop_flag=1, new_final_sq=final_square, save_flag=1)
                end
            else:
                return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
            end
        else:
            let (BPdifferent) = different_color(board, initial_square, final_square)
            if BPdifferent == 1:
                return(stop_flag=1, new_final_sq=initial_square, save_flag=1)
            else:
                return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
            end
        end
    end
    # Only one square in these cases:
    
    if [board+initial_square] == WKnight:
        let (sameWN) = same_color(board, initial_square, final_square)
        if sameWN == 1:
            return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
        else:
            return(stop_flag=1, new_final_sq=initial_square, save_flag=1)
        end
    end
    if [board+initial_square] == WKing:
        let (sameWK) = same_color(board, initial_square, final_square)
        if sameWK == 1:
            return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
        else:
            return(stop_flag=1, new_final_sq=initial_square, save_flag=1)
        end
    end
    if [board+initial_square] == BKnight:
        let (sameBN) = same_color(board, initial_square, final_square)
        if sameBN == 1:
            return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
        else:
            return(stop_flag=1, new_final_sq=initial_square, save_flag=1)
        end
    end
    if [board+initial_square] == BKing:
        let (sameBK) = same_color(board, initial_square, final_square)
        if sameBK == 1:
            return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
        else:
            return(stop_flag=1, new_final_sq=initial_square, save_flag=1)
        end
    end

    # ALL OTHER CASES
    let (same) = same_color(board, initial_square, final_square)
    if same == 1:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
    end
    let (different) = different_color(board, initial_square, final_square)
    if different == 1:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=1)
    end
    return(stop_flag=0, new_final_sq=final_square, save_flag=1)
end

# NOT MOVING, BUT ATTACKING SQUARES, FOR BLACK
func calculate_black_attack{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, board_index: felt, moves: felt*) -> (size_board_moves: felt):
    alloc_locals
    if board_index == 64:
        return(0)
    end
    let (current_pattern, current_pattern_index) = pattern_of([board+board_index])
    let (local size_this) = calculate_black_attacking_moves(board, moves, current_pattern, current_pattern_index, board_index, board_index)
    let (size_next) = calculate_black_attack(board, board_index+1, moves + size_this)
    return(size_this + size_next)    
end

func calculate_black_attacking_moves{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, pattern: felt, index: felt, initial_sq: felt, ref_sq: felt)->(size: felt):
    alloc_locals
    if index == -1:
        return(0)
    end
    # Get current word
    let (current_word) = get_pattern_word(pattern, index)
    # 
    let (local final_sq) = get_final_square(current_word, ref_sq)

    # Calculate recursive parameters
    let (stop_flag, new_ref_sq, save_flag) = recursive_black_attacking_vector(board, moves, final_sq, initial_sq, index)
    tempvar move_rep = initial_sq*256 + final_sq*4
    if save_flag == 1:
        assert [moves] = move_rep    
    end
    # Send recursive parameters
    let(size_res) = calculate_black_attacking_moves(board, moves+save_flag, pattern, index-stop_flag, initial_sq, new_ref_sq)
    # Recursive call
    return(size_res + save_flag)
end

func recursive_black_attacking_vector{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, final_square: felt, initial_square: felt, pattern_index: felt)->(stop_flag: felt, new_final_sq: felt, save_flag: felt):
    alloc_locals
    let (local final_x, final_y) = sq_coord(final_square)
    tempvar move_rep = initial_square*100 + final_square
    if final_square == 64:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
    end
    let (this_color) = piece_color([board+initial_square])
    if this_color != 2:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
    end    
    # Pawn moves
    if [board+initial_square] == BPawn:
        if pattern_index != 2:
            return(stop_flag=1, new_final_sq=initial_square, save_flag=1)
        else:
            return(stop_flag=1, new_final_sq=initial_square, save_flag=0)
        end
    end

    # Only one square in these cases:
    if [board+initial_square] == WKnight:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=1)
    end
    if [board+initial_square] == WKing:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=1)
    end
    if [board+initial_square] == BKnight:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=1)
    end
    if [board+initial_square] == BKing:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=1)
    end
    # ALL OTHER CASES
    let (same) = same_color(board, initial_square, final_square)
    if same == 1:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=1)
    end
    let (different) = different_color(board, initial_square, final_square)
    if different == 1:
        return(stop_flag=1, new_final_sq=initial_square, save_flag=1)
    end
    return(stop_flag=0, new_final_sq=final_square, save_flag=1)
end

# Hardcoded pattern dictionary
func pattern_of{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(piece: felt)->(pattern: felt, pattern_length: felt):
    if piece == WRook:
        return(pattern = rook_pattern, pattern_length = 3)
    end
    if piece == WKnight:
        return(pattern = knight_pattern, pattern_length = 7)
    end
    if piece == WBishop:
        return(pattern = bishop_pattern, pattern_length = 3)
    end
    if piece == WQueen:
        return(pattern = queen_pattern, pattern_length = 7)
    end
    if piece == WKing:
        return(pattern = king_pattern, pattern_length = 7)
    end
    if piece == WPawn:
        return(pattern = white_pawn_pattern, pattern_length = 2)
    end
    if piece == BRook:
        return(pattern = rook_pattern, pattern_length = 3)
    end
    if piece == BKnight:
        return(pattern = knight_pattern, pattern_length = 7)
    end
    if piece == BBishop:
        return(pattern = bishop_pattern, pattern_length = 3)
    end
    if piece == BQueen:
        return(pattern = queen_pattern, pattern_length = 7)
    end
    if piece == BKing:
        return(pattern = king_pattern, pattern_length = 7)
    end
    if piece == BPawn:
        return(pattern = black_pawn_pattern, pattern_length = 2)
    end
    return(pattern = 0, pattern_length = -1)
end

# MOVING PIECES
func make_move {output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, new_board: felt*, move: felt):
    alloc_locals
    let (local fin_y) = get_binary_word(move, 5, 3)
    let (local fin_x) = get_binary_word(move, 2, 3)
    let (local ini_y) = get_binary_word(move, 11, 3)
    let (local ini_x) = get_binary_word(move, 8, 3)
    let initial_square = ini_y*8+ini_x
    let final_square = fin_y*8+fin_x
    let piece_moving = [board+initial_square]
    calculate_new_move_board(board, new_board, 63, initial_square, final_square, piece_moving)

    return()
end

func calculate_new_move_board{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, new_board: felt*, index: felt,  initial_square: felt, final_square: felt, piece_moving: felt):
    if index == -1:
        return()
    end
    if index == initial_square:
        assert [new_board+index] = 0
    else:
        if index == final_square:
            assert [new_board+index] = piece_moving
        else:
            assert [new_board+index] =  [board+index]    
        end
    end
    calculate_new_move_board(board, new_board, index-1, initial_square, final_square, piece_moving)
    return()
end

func en_passant{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, moves_size: felt, en_passant_code: felt, side_to_move: felt)->(new_size: felt):
    # en_passant_code must signal the column (0-7) of the pawn that just moved to the fourth rank
    if side_to_move == 0:
        let size_res_1 = en_passant_right_white(board, moves, moves_size, en_passant_code)
        let size_res_2 = en_passant_left_white(board, moves, size_res_1, en_passant_code)
    else:
        let size_res_1 = en_passant_right_black(board, moves, moves_size, en_passant_code)
        let size_res_2 = en_passant_left_black(board, moves, size_res_1, en_passant_code)
    end
    return(new_size=size_res_2)
end

func en_passant_right_white{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, moves_size: felt, en_passant_code: felt)->(new_size: felt):
    let (right_row_exists, not_used) = board_overflow(en_passant_code + 1, 0)
    if right_row_exists == 1:
        tempvar right_pawn_exists = 25 + en_passant_code
        if [board+left_pawn_exists] == WPawn:
            [moves+moves_size+1] = (en_passant_code+1)*2048+3*256+en_passant_code*32+4*2
            return (new_size = moves_size+1)
        end
    end
    return (new_size = moves_size)
end

func en_passant_left_white{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, moves_size: felt, en_passant_code: felt)->(new_size: felt):
    let (left_row_exists, not_used) = board_overflow(en_passant_code - 1, 0)
    if left_row_exists == 1:
        tempvar left_pawn_exists = 23 + en_passant_code
        if [board+left_pawn_exists] == WPawn:
            [moves+moves_size+1] = (en_passant_code-1)*2048+3*256+en_passant_code*32+2*4
            return (new_size = moves_size+1)
        end
    end
    return (new_size = moves_size)
end

# ················ CAREFUL HERE UNTESTED TERRITORY ························································
# STILL UNTESTED: EN PASSANT CAPTURES
func en_passant_right_black{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, moves_size: felt, en_passant_code: felt)->(new_size: felt):
    let (right_row_exists, not_used) = board_overflow(en_passant_code + 1, 0)
    if right_row_exists == 1:
        tempvar right_pawn_exists = 33 + en_passant_code
        if [board+left_pawn_exists] == BPawn:
            [moves+moves_size+1] = (en_passant_code+1)*2048+3*256+en_passant_code*32+4*2
            return (new_size = moves_size+1)
        end
    end
    return (new_size = moves_size)
end

func en_passant_left_black{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, moves_size: felt, en_passant_code: felt)->(new_size: felt):
    let (left_row_exists, not_used) = board_overflow(en_passant_code - 1, 0)
    if left_row_exists == 1:
        tempvar left_pawn_exists = 31 + en_passant_code
        if [board+left_pawn_exists] == BPawn:
            [moves+moves_size+1] = (en_passant_code-1)*2048+4*256+en_passant_code*32+5*4
            return (new_size = moves_size+1)
        end
    end
    return (new_size = moves_size)
end

# WORK IN PROGRESS: CASTLING AND PROMOTING
func castle_white{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, attacking_moves: felt*, moves_size: felt, castle_code: felt)->(new_size: felt):
    tempvar free_short_castle_squares = [board+62] * [board+61] + 1
    serialize_word(free_short_castle_squares)
    if free_short_castle_squares == 1:

    end

    return(new_size = 1)
end