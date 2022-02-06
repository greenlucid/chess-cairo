# CHESS CAIRO - CORE
# THIS FILE CONTAINS THE FUNCTIONS THAT CALCULATE MOVES AND LEGAL POSITIONS

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and, bitwise_xor
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin

from src.chess_utils import get_pattern_word
from src.chess_utils import different_color
from src.chess_utils import same_color
from src.chess_utils import piece_color
from src.chess_utils import get_final_square
from src.chess_utils import code_to_move
from src.chess_utils import sq_coord
from src.chess_utils import coord_sq
from src.chess_utils import get_binary_word
from src.chess_utils import board_overflow
from src.chess_utils import is_attacked
from src.chess_utils import construct_move
from src.chess_utils import white_king_is_attacked
from src.chess_utils import black_king_is_attacked
from src.chess_utils import get_rep
from src.chess_utils import get_castle_bool
from src.chess_utils import is_move_in_list

from src.chess_utils import (
    parse_move,
    point_to_felt,
    encode_move
)

from src.state import Move

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

# THE BASIC FUNCTION FOR THE SERVICE IS THE ONE THAT EVALUATES IF A GIVEN MOVE IS LEGAL ON A GIVEN BOARD
# Returns 0 if the move is not legal and 1 if it's legal
func is_legal_move{bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(
        board: felt*, castle_code: felt, en_passant_code: felt, move: felt) -> (is_legal: felt):
    alloc_locals

    let (local raw_moves) = alloc()
    # This list of moves is actually never used, so let's call it dummy 
    let (local legal_moves) = alloc()
    # Get the initial square: 6 first bits after truncating 8 bits on the right 
    let (local initial_square) = get_binary_word(move, 8, 6)
    # Get the piece in the initial_square, its color and its pattern
    let square_contains = [board + initial_square]
    let (local side_to_move) = piece_color(square_contains)
    let (local pattern, pattern_length) = pattern_of(square_contains)

    if side_to_move == 0:
        return (is_legal = -1)
    end
    if side_to_move == 1:
        let (raw_moves_size) = calculate_white_piece_moves(board, raw_moves, pattern, pattern_length, initial_square, initial_square)
        let (king_moves_added) = white_castle_legal_wrapper(board, raw_moves, raw_moves_size, castle_code, initial_square)
        let (pawn_moves_added) = white_special_pawn_moves(board, raw_moves, king_moves_added, en_passant_code, initial_square)
        let (legal_moves_size) = discard_non_legal_white_moves(board, raw_moves, pawn_moves_added, legal_moves)
        let (result) = is_move_in_list(legal_moves, legal_moves_size, move)
        return (is_legal= result)
    end
    if side_to_move == 2:
        let (raw_moves_size) = calculate_black_piece_moves(board, raw_moves, pattern, pattern_length, initial_square, initial_square)
        let (king_moves_added) = black_castle_legal_wrapper(board, raw_moves, raw_moves_size, castle_code, initial_square)
        let (pawn_moves_added) = black_special_pawn_moves(board, raw_moves, king_moves_added, en_passant_code, initial_square)        
        let (legal_moves_size) = discard_non_legal_black_moves(board, raw_moves, pawn_moves_added, legal_moves)
        let (result) = is_move_in_list(legal_moves, legal_moves_size, move)
        return (is_legal= result)
    end
    return (is_legal = -1)
end

# 
# FIRST WE HAVE THE RECURSIVE FUNCTIONS THAT CALCULATE THE MOVES - 
# It reads the pattern, word by word, to know in which direction to calculate. 
# Every word = 5 bits, it defines the direction - see function code_to_move (ok, notation is not unified, lots of tests) to see correspondence
# The initial_sq (square) is always the same once you call the function - the ref_sq (reference square) is the last square considered
# as final, or the initial square in case the stop_flag has been passed as 1 (because a trajectory has been compeleted)
# The index is the position in the pattern.

# Legal_moves is the array that will contain the legal moves once the function finishes.
func calculate_white_moves{bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(
        board: felt*, legal_moves: felt*, castle_code: felt,  en_passant_square: felt) -> (legal_moves_size: felt):
    alloc_locals
    let (local raw_moves) = alloc()
    let(raw_moves_size) = calculate_white_raw_moves(board, 0, raw_moves)

    let (cw_add_size) = castle_white(board, raw_moves, raw_moves_size, castle_code)
    tempvar new_size_cw = raw_moves_size + cw_add_size

    let (wp_add_size) = white_promotion(board, raw_moves, new_size_cw, 0)
    tempvar new_size_wp = new_size_cw + wp_add_size
  
    let (ep_new_size) = en_passant_white (board, raw_moves, new_size_wp, en_passant_square)
    tempvar new_size_ep = new_size_wp + ep_new_size    
 
    let (legal_moves_size) = discard_non_legal_white_moves(board, raw_moves, new_size_ep, legal_moves)
    
    return (legal_moves_size = legal_moves_size)
end

# Calculating the moves of all white pieces, including illegal moves and not including special moves
func calculate_white_raw_moves{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, board_index: felt, moves: felt*) -> (size_board_moves: felt):
    alloc_locals
    if board_index == 64:
        return(0)
    end
    let (current_pattern, current_pattern_index) = pattern_of([board+board_index])
    let (local size_this) = calculate_white_piece_moves(board, moves, current_pattern, current_pattern_index, board_index, board_index)
    let (size_next) = calculate_white_raw_moves(board, board_index+1, moves + size_this)
    return(size_this + size_next)    
end

# Calculating the moves of one white piece, including illegal moves
func calculate_white_piece_moves{bitwise_ptr : BitwiseBuiltin*}(
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
    let (stop_flag, new_ref_sq, save_flag) = recursive_white_vector(board, moves, final_sq, initial_sq, current_word)
    tempvar move_rep = initial_sq*256 + final_sq*4
    if save_flag == 1:
        assert [moves] = move_rep    
    end
    # Send recursive parameters
    let(size_res) = calculate_white_piece_moves(board, moves+save_flag, pattern, index-stop_flag, initial_sq, new_ref_sq)
    # Recursive call
    return(size_res + save_flag)
end

# Calculating the vector of parameters (stop_flag, new_final_sq, save_flag) used to guide the recursive func calculate_white_piece_moves
func recursive_white_vector{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, final_square: felt, initial_square: felt, pattern_code: felt)->(stop_flag: felt, new_final_sq: felt, save_flag: felt):
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
        if pattern_code == 1:
            if [board+final_square] == 0:
                let (final_x, final_y) = sq_coord(final_square)
                if final_y == 5:
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
func calculate_white_attack{bitwise_ptr : BitwiseBuiltin*}(
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

func calculate_white_attacking_moves{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, pattern: felt, index: felt, initial_sq: felt, ref_sq: felt)->(size: felt):
    alloc_locals
    if index == -1:
        return(0)
    end
    # Get current word
    let (current_word) = get_pattern_word(pattern, index)
    let (local final_sq) = get_final_square(current_word, ref_sq)

    # Calculate recursive parameters
    let (stop_flag, new_ref_sq, save_flag) = recursive_white_attacking_vector(board, moves, final_sq, initial_sq, current_word)
    tempvar move_rep = initial_sq*256 + final_sq*4
    if save_flag == 1:
        assert [moves] = move_rep    
    end
    # Send recursive parameters
    let(size_res) = calculate_white_attacking_moves(board, moves+save_flag, pattern, index-stop_flag, initial_sq, new_ref_sq)
    # Recursive call
    return(size_res + save_flag)
end

func recursive_white_attacking_vector{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, final_square: felt, initial_square: felt, pattern_code: felt)->(stop_flag: felt, new_final_sq: felt, save_flag: felt):
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
    # Pawn attacks
    if [board+initial_square] == WPawn:
        if pattern_code != 1:
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
func calculate_black_moves{bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(
        board: felt*, legal_moves: felt*, castle_code: felt, en_passant_square: felt) -> (legal_moves_size: felt):
    alloc_locals
    let (local raw_moves) = alloc()
    let(raw_moves_size) = calculate_black_raw_moves(board, 0, raw_moves)

    let (cw_add_size) = castle_black(board, raw_moves, raw_moves_size, castle_code)
    tempvar new_size_cw = raw_moves_size + cw_add_size

    let (wp_add_size) = black_promotion(board, raw_moves, new_size_cw, 0)
    tempvar new_size_wp = new_size_cw + wp_add_size
  
    let (ep_new_size) = en_passant_black (board, raw_moves, new_size_wp, en_passant_square)
    tempvar new_size_ep = new_size_wp + ep_new_size    
 
    let (legal_moves_size) = discard_non_legal_black_moves(board, raw_moves, new_size_ep, legal_moves)
    
    return (legal_moves_size = legal_moves_size)
end

func calculate_black_raw_moves{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, board_index: felt, moves: felt*) -> (size_board_moves: felt):
    alloc_locals
    if board_index == 64:
        return(0)
    end
    let (current_pattern, current_pattern_index) = pattern_of([board+board_index])
    let (local size_this) = calculate_black_piece_moves(board, moves, current_pattern, current_pattern_index, board_index, board_index)
    let (size_next) = calculate_black_raw_moves(board, board_index+1, moves + size_this)
    return(size_this + size_next)    
end

func calculate_black_piece_moves{bitwise_ptr : BitwiseBuiltin*}(
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
    let (stop_flag, new_ref_sq, save_flag) = recursive_black_vector(board, moves, final_sq, initial_sq, current_word)
    tempvar move_rep = initial_sq*256 + final_sq*4
    if save_flag == 1:
        assert [moves] = move_rep    
    end
    # Send recursive parameters
    let(size_res) = calculate_black_piece_moves(board, moves+save_flag, pattern, index-stop_flag, initial_sq, new_ref_sq)
    # Recursive call
    return(size_res + save_flag)
end

func recursive_black_vector{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, final_square: felt, initial_square: felt, pattern_code: felt)->(stop_flag: felt, new_final_sq: felt, save_flag: felt):
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
        if pattern_code == 2:
            if [board+final_square] == 0:
                let (final_x, final_y) = sq_coord(final_square)
                if final_y == 2:
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
func calculate_black_attack{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, board_index: felt, att_moves_array: felt*) -> (size_board_moves: felt):
    alloc_locals
    if board_index == 64:
        return(0)
    end
    let (current_pattern, current_pattern_index) = pattern_of([board+board_index])
    let (local size_this) = calculate_black_attacking_moves(board, att_moves_array, current_pattern, current_pattern_index, board_index, board_index)
    let (size_next) = calculate_black_attack(board, board_index+1, att_moves_array + size_this)
    return(size_this + size_next)    
end

func calculate_black_attacking_moves{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, att_moves_array: felt*, pattern: felt, index: felt, initial_sq: felt, ref_sq: felt)->(size: felt):
    alloc_locals
    if index == -1:
        return(0)
    end
    # Get current word
    let (current_word) = get_pattern_word(pattern, index)
    # 
    let (local final_sq) = get_final_square(current_word, ref_sq)

    # Calculate recursive parameters
    let (stop_flag, new_ref_sq, save_flag) = recursive_black_attacking_vector(board, att_moves_array, final_sq, initial_sq, current_word)
    tempvar move_rep = initial_sq*256 + final_sq*4
    if save_flag == 1:
        assert [att_moves_array] = move_rep    
    end
    # Send recursive parameters
    let(size_res) = calculate_black_attacking_moves(board, att_moves_array+save_flag, pattern, index-stop_flag, initial_sq, new_ref_sq)
    # Recursive call
    return(size_res + save_flag)
end

func recursive_black_attacking_vector{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, final_square: felt, initial_square: felt, pattern_code: felt)->(stop_flag: felt, new_final_sq: felt, save_flag: felt):
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
    # Pawn attacks
    if [board+initial_square] == BPawn:
        if pattern_code != 2:
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
func pattern_of{bitwise_ptr : BitwiseBuiltin*}(piece: felt)->(pattern: felt, pattern_length: felt):
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
func make_move {bitwise_ptr : BitwiseBuiltin*}(
        board : felt*, new_board : felt*, move : Move):
    alloc_locals
    let (local temp_board) = alloc()
    let (local enc_origin) = point_to_felt(move.origin)
    let (local enc_dest) = point_to_felt(move.dest)
    let (local enc_move) = encode_move(move)
    let (final_piece) = resulting_piece([board+enc_origin], move.dest.row, move.extra)
    calculate_new_move_board(board, temp_board, 63, enc_origin, enc_dest, final_piece)
    if enc_move == 15608:
        calculate_new_move_board(temp_board, new_board, 63, h1, f1, WRook) 
        return()
    end
    if enc_move == 15592:
        calculate_new_move_board(temp_board, new_board, 63, a1, d1, WRook) 
        return()
    end
    if enc_move == 1032:
        calculate_new_move_board(temp_board, new_board, 63, a8, d8, BRook) 
        return()
    end
    if enc_move == 1048:
        calculate_new_move_board(temp_board, new_board, 63, h8, f8, BRook) 
        return()
    end
    let white_en_passant_cond = ([board+enc_origin] - 20) * ([board+enc_dest] + 1) * (move.dest.col - move.origin.col) * (move.dest.col - move.origin.col)
    if white_en_passant_cond == 1:
        calculate_new_move_board(temp_board, new_board, 63, move.origin.row*8+move.dest.col, 64, 0)
        return()
    end
    let black_en_passant_cond = ([board+enc_origin] - 28) * ([board+enc_dest] + 1) * (move.dest.col - move.origin.col) * (move.dest.col - move.origin.col)
    if black_en_passant_cond == 1:
        calculate_new_move_board(temp_board, new_board, 63, move.origin.row*8+move.dest.col, 64, 0)
        return()
    end
    calculate_new_move_board(temp_board, new_board, 63, 64, 64, 0) 
    return()
end

func resulting_piece{bitwise_ptr : BitwiseBuiltin*}(
        piece_moving: felt, final_y: felt, extra_info: felt)->(final_piece: felt):
    alloc_locals
    let (local color) = piece_color(piece_moving)
    if color == 1:
        tempvar cond_promo = (piece_moving - 20) * (final_y + 1) 
        if cond_promo == 1:
            return (final_piece = 16 + extra_info)
        end
    end

    if color == 2:
        tempvar cond_promo = (piece_moving - 28) * (final_y -6) 
        if cond_promo == 1:
            return (final_piece = 24 + extra_info)
        end
    end
    return (final_piece=piece_moving)
    end 

func calculate_new_move_board{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, new_board: felt*, index: felt,  initial_square: felt, final_square: felt, piece_moving: felt):
    alloc_locals
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

# EN PASSANT CALCULATIONS FOR WHITE
# This function receives the square where you can take en passant, plus the usual stuff
# and returns, as usual, the size added to the moves array, saving the en passant moves accordingly
func en_passant_white{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, moves_size: felt, en_passant_square: felt)->(add_size: felt):
    alloc_locals
    let (local size_added_1) = en_passant_left_white(board, moves, moves_size, en_passant_square)
    let (local size_added_2) = en_passant_right_white(board, moves, moves_size + size_added_1, en_passant_square)
    
    return (add_size = size_added_1 + size_added_2)
end

func en_passant_left_white{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, moves_size: felt, en_passant_square: felt)->(add_size: felt):
    alloc_locals
    let (local x_ep, y_ep) = sq_coord(en_passant_square)
    let (local new_move) = construct_move(en_passant_square + 7, en_passant_square, 0)
    if y_ep == 2:    
        if x_ep != 0:
            # The + 9 comes from adding a row and a column. The column is not 'h', so you can do it without overflow of the board
            if [board + en_passant_square + 7] == WPawn:
                assert [moves + moves_size] = new_move
                return(add_size = 1)
            end
        end
    end
    return (add_size = 0)
end

func en_passant_right_white{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, moves_size: felt, en_passant_square: felt)->(add_size: felt):
    alloc_locals
    let (local x_ep, y_ep) = sq_coord(en_passant_square)
    let (local new_move) = construct_move(en_passant_square + 9, en_passant_square, 0)
    if y_ep == 2:    
        if x_ep != 7:
            # The + 9 comes from adding a row and a column. The column is not 'h', so you can do it without overflow of the board
            if [board + en_passant_square + 9] == WPawn:
                assert [moves + moves_size] = new_move
                return(add_size = 1)
            end
        end
    end
    return (add_size = 0)
end

# EN PASSANT CALCULATIONS FOR BLACK
# This function receives the square where you can take en passant, plus the usual stuff
# and returns, as usual, the size added to the moves array, saving the en passant moves accordingly
func en_passant_black{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, moves_size: felt, en_passant_square: felt)->(add_size: felt):

    let (size_added_1) = en_passant_left_black(board, moves, moves_size, en_passant_square)
    let (size_added_2) = en_passant_right_black(board, moves, moves_size + size_added_1, en_passant_square)

    return (add_size = size_added_2)
end

func en_passant_left_black{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, moves_size: felt, en_passant_square: felt)->(add_size: felt):
    alloc_locals
    let (x_ep, y_ep) = sq_coord(en_passant_square)
    let (local new_move) = construct_move(en_passant_square - 9, en_passant_square, 0)
    if y_ep == 5:    
        if x_ep != 0:
            # The + 9 comes from adding a row and a column. The column is not 'h', so you can do it without overflow of the board
            if [board + en_passant_square - 9] == BPawn:
                assert [moves + moves_size] = new_move
                return(add_size = 1)
            end
        end
    end
    return (add_size = 0)
end

func en_passant_right_black{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, moves_size: felt, en_passant_square: felt)->(add_size: felt):
    alloc_locals
    let (x_ep, y_ep) = sq_coord(en_passant_square)
    let (local new_move) = construct_move(en_passant_square - 7, en_passant_square, 0)
    if y_ep == 5:    
        if x_ep != 7:
            # The + 9 comes from adding a row and a column. The column is not 'h', so you can do it without overflow of the board
            if [board + en_passant_square - 7] == BPawn:
                assert [moves + moves_size] = new_move
                return(add_size = 1)
            end
        end
    end
    return (add_size = 0)
end

# WORK IN PROGRESS: CASTLING AND PROMOTING
func castle_white{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, moves_size: felt, castle_code: felt)->(add_size: felt):
    alloc_locals
    let (local attacking_moves) = alloc()
    let (local K_code, Q_code, not_used_1, not_used_2) = get_castle_bool(castle_code)
    let (local attacking_moves_size) = calculate_black_attack(board, 0, attacking_moves)
    let (size_added_1) = castle_short_white(board, moves, moves_size, attacking_moves, attacking_moves_size, K_code)
    let (size_added_2) = castle_long_white(board, moves, moves_size + size_added_1, attacking_moves, attacking_moves_size, Q_code)
    return (add_size = size_added_1 + size_added_2)
end

func castle_short_white{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, moves_size: felt, attacking_moves: felt*, attacking_moves_size: felt, castle_code: felt)->(add_size: felt):
    alloc_locals
    tempvar free_f1 = [board+f1] + 1
    tempvar free_g1 = [board+g1] + 1
    let (local in_check) = white_king_is_attacked (attacking_moves, attacking_moves_size, board)
    let (local g1_attacked) = is_attacked(attacking_moves, attacking_moves_size, g1)
    let (local f1_attacked) = is_attacked(attacking_moves, attacking_moves_size, f1)
    let test_castle_cond = free_f1 * free_g1 * (g1_attacked + 1) * (f1_attacked + 1) * castle_code * (in_check + 1)
    if test_castle_cond == 1:
        assert [moves + moves_size] = 15608
        return(add_size = 1)
    end
    return(add_size = 0)
end

func castle_long_white{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, moves_size: felt, attacking_moves: felt*, attacking_moves_size: felt, castle_code: felt)->(add_size: felt):
    alloc_locals
    tempvar free_d1 = [board+d1] + 1
    tempvar free_c1 = [board+c1] + 1
    let (local in_check) = white_king_is_attacked (attacking_moves, attacking_moves_size, board)
    let (local d1_attacked) = is_attacked(attacking_moves, attacking_moves_size, d1)
    let (local c1_attacked) = is_attacked(attacking_moves, attacking_moves_size, c1)
    let test_castle_cond = free_c1 * free_d1 * (d1_attacked + 1) * (c1_attacked + 1) * castle_code * (in_check + 1)
    if test_castle_cond == 1:
        assert [moves + moves_size] = 15592
        return(add_size = 1)
    end
    return(add_size = 0)
end

func castle_black{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, moves_size: felt, castle_code: felt)->(add_size: felt):
    alloc_locals
    let (local attacking_moves) = alloc()
    let (local not_used_1, not_used_2, k_code, q_code) = get_castle_bool(castle_code)
    let (local attacking_moves_size) = calculate_white_attack(board, 0, attacking_moves)    
    let (size_added_1) = castle_short_black(board, moves, moves_size, attacking_moves, attacking_moves_size, k_code)
    let (size_added_2) = castle_long_black(board, moves, moves_size + size_added_1, attacking_moves, attacking_moves_size, q_code)

    return (add_size = size_added_1 + size_added_2)
end

func castle_short_black{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, moves_size: felt, attacking_moves: felt*, attacking_moves_size: felt, castle_code: felt)->(add_size: felt):
    alloc_locals
    tempvar free_g8 = [board + g8] + 1
    tempvar free_f8 = [board + f8] + 1
    let (local in_check) = black_king_is_attacked (attacking_moves, attacking_moves_size, board)
    let (local g8_attacked) = is_attacked(attacking_moves, attacking_moves_size, g8)
    let (local f8_attacked) = is_attacked(attacking_moves, attacking_moves_size, f8)
    let test_castle_cond = free_g8 * free_f8 * (g8_attacked + 1) * (f8_attacked + 1) * castle_code * (in_check + 1)
    if test_castle_cond == 1:
        assert [moves + moves_size] = 1048
        return(add_size = 1)
    end
    return(add_size = 0)
end

func castle_long_black{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, moves_size: felt, attacking_moves: felt*, attacking_moves_size: felt, castle_code: felt)->(add_size: felt):
    alloc_locals
    tempvar free_d8 = [board + d8] + 1
    tempvar free_c8 = [board + c8] + 1
    let (local in_check) = black_king_is_attacked (attacking_moves, attacking_moves_size, board)
    let (local d8_attacked) = is_attacked(attacking_moves, attacking_moves_size, d8)
    let (local c8_attacked) = is_attacked(attacking_moves, attacking_moves_size, c8)
    let test_castle_cond = free_c8 * free_d8 * (d8_attacked + 1) * (c8_attacked + 1) * castle_code * (in_check + 1)
    if test_castle_cond == 1:
        assert [moves + moves_size] = 1032
        return(add_size = 1)
    end
    return(add_size = 0)
end

# Use index = 0. This function detects if there's a promotion (generally with a 0 in the extra info, that means promoting a queen)
# and adds the other three possible promotions (knight, bishop, rook).
func white_promotion{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, moves_size: felt, index: felt)->(new_size: felt):
    alloc_locals
    if index == moves_size:
        return(new_size = 0)
    end
    let (local add_size) = white_promotion(board, moves, moves_size, index+1)
    let current_move = [moves+index]
    let (local ini_y) = get_binary_word(current_move, 11, 3)
    let (local ini_x) = get_binary_word(current_move, 8, 3)
    let (local current_square) = coord_sq(ini_x, ini_y)
    let current_piece = [board+current_square]
    tempvar check_cond =  (current_piece-20) * ini_y 
    if check_cond == 1:
        assert [moves + moves_size + add_size] = current_move + 1
        assert [moves + moves_size + add_size + 1] = current_move + 2
        assert [moves + moves_size + add_size + 2] = current_move + 3
        return (new_size = add_size + 3)
    end
    return(new_size = add_size)
end

# Use index = 0. This function detects if there's a promotion (generally with a 0 in the extra info, that means promoting a queen)
# and adds the other three possible promotions (knight, bishop, rook).
func black_promotion{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, moves_size: felt, index: felt)->(new_size: felt):
    alloc_locals
    if index == moves_size:
        return(new_size = 0)
    end
    let (local add_size) = black_promotion(board, moves, moves_size, index+1)
    let current_move = [moves+index]
    let (local ini_y) = get_binary_word(current_move, 11, 3)
    let (local ini_x) = get_binary_word(current_move, 8, 3)
    let (local current_square) = coord_sq(ini_x, ini_y)
    let current_piece = [board+current_square]
    tempvar check_cond =  (current_piece-20) * ini_y 
    if check_cond == 1:
        assert [moves + moves_size + add_size] = current_move + 1
        assert [moves + moves_size + add_size + 1] = current_move + 2
        assert [moves + moves_size + add_size + 2] = current_move + 3
        return (new_size = add_size + 3)
    end
    return(new_size = add_size)
end

# Creating a new array of moves only with the legal moves, given a board
# 
func discard_non_legal_white_moves{bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(
        board: felt*, moves: felt*, moves_size: felt, new_moves: felt*)->(new_moves_size: felt):
    alloc_locals
    if moves_size == 0:
        return (new_moves_size = 0)
    end
    let (local added_size) = discard_non_legal_white_moves(board, moves, moves_size - 1, new_moves)
    let (local attacking_moves) = alloc()
    let (local new_board) = alloc()
    local enc_move = [moves + moves_size-1]
    let (local this_move) = parse_move(enc_move)
    make_move(board, new_board, this_move)
    let (local_rep) = get_rep([moves + moves_size-1])
    let(local attacking_size) = calculate_black_attack(new_board, 0, attacking_moves)
    let(local is_not_legal_move) = white_king_is_attacked(attacking_moves, attacking_size, new_board)
    if is_not_legal_move == 0:
        assert [new_moves + added_size] = enc_move
        return(new_moves_size = added_size + 1)
    end
    return(new_moves_size = added_size)
end

func discard_non_legal_black_moves{bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(
        board: felt*, moves: felt*, moves_size: felt, new_moves: felt*)->(new_moves_size: felt):
    alloc_locals
    if moves_size == 0:
        return (new_moves_size = 0)
    end
    let (local added_size) = discard_non_legal_black_moves(board, moves, moves_size - 1, new_moves)
    let (local attacking_moves) = alloc()
    let (local new_board) = alloc()
    local enc_move = [moves + moves_size-1]
    let (local this_move) = parse_move(enc_move)
    make_move(board, new_board, this_move)
    let (local_rep) = get_rep([moves + moves_size-1])
    let(local attacking_size) = calculate_white_attack(new_board, 0, attacking_moves)
    let(local is_not_legal_move) = black_king_is_attacked(attacking_moves, attacking_size, new_board)
    if is_not_legal_move == 0:
        assert [new_moves + added_size] = enc_move
        return(new_moves_size = added_size + 1)
    end
    return(new_moves_size = added_size)
end

# Legal Wrappers for king and pawn moves
func white_castle_legal_wrapper{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, moves_size: felt, castle_code: felt, initial_square: felt)->(new_size: felt):
    if [board+initial_square] != WKing:
        return(new_size = moves_size)
    end
    let (cw_add_size) = castle_white(board, moves, moves_size, castle_code)
    tempvar new_size_cw = moves_size + cw_add_size
    return (new_size = new_size_cw)
end

func black_castle_legal_wrapper{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, moves_size: felt, castle_code: felt, initial_square: felt)->(new_size: felt):
    if [board+initial_square] != BKing:
        return(new_size = moves_size)
    end
    let (cw_add_size) = castle_black(board, moves, moves_size, castle_code)
    return (new_size = moves_size + cw_add_size)
end

func white_special_pawn_moves{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, moves_size: felt, en_passant_code: felt, initial_square: felt)->(new_size: felt):
    alloc_locals
    if [board+initial_square] != WPawn:
        return(new_size = moves_size)
    end
    let (local wp_size) = white_promotion(board, moves, moves_size, 0)
    let (local ep_size) = en_passant_white(board, moves, moves_size + wp_size, en_passant_code)
    return(new_size = moves_size + ep_size + wp_size)
end

func black_special_pawn_moves{bitwise_ptr : BitwiseBuiltin*}(
        board: felt*, moves: felt*, moves_size: felt, en_passant_code: felt, initial_square: felt)->(new_size: felt):
    alloc_locals
    if [board+initial_square] != BPawn:
        return(new_size = moves_size)
    end
    let (local wp_size) = black_promotion(board, moves, moves_size, 0)
    let (local ep_size) = en_passant_black(board, moves, moves_size + wp_size, en_passant_code)
    return(new_size = moves_size + ep_size + wp_size)
end

# Functions that return the result of the game:
# pending: 0
# white checkmate: 1
# black checkmate: 2
# stalemate: 3  
func calculate_status{bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(
        board: felt*, side_to_move: felt, castle_code: felt,  en_passant_code: felt)->(status: felt):
    if side_to_move == 0:
        let (result) = calculate_white_status(board, castle_code, en_passant_code)
        return (status=result)
    end
    if side_to_move == 1:
        let (result) = calculate_black_status(board, castle_code, en_passant_code)
        return (status=result)
    end
    return(status = -1)
end

func calculate_white_status{bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(
        board: felt*, castle_code: felt, en_passant_code: felt) -> (status: felt):
    alloc_locals
    let (local moves) = alloc()
    let (local black_attacking_moves) = alloc()
    let (moves_size) = calculate_white_moves(board, moves, castle_code, en_passant_code)
    let (black_attacking_moves_size) = calculate_black_attack(board, 0, black_attacking_moves)
    let (king_attacked) = white_king_is_attacked(black_attacking_moves, black_attacking_moves_size, board)
    tempvar mate_condition = king_attacked * (moves_size + 1)
    tempvar stalemate_condition = (king_attacked + 1) * (moves_size + 1)
    if mate_condition == 1:
        return (status = 1)
    end
    if stalemate_condition == 1:
        return (status = 3)
    end
    return (status = 0)
end

func calculate_black_status{bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(
        board: felt*, castle_code: felt, en_passant_code: felt) -> (status: felt):
    alloc_locals
    let (local moves) = alloc()
    let (local white_attacking_moves) = alloc()
    let (local moves_size) = calculate_black_moves(board, moves, castle_code, en_passant_code)
    let (local white_attacking_moves_size) = calculate_white_attack(board, 0, white_attacking_moves)
    let (local king_attacked) = black_king_is_attacked(white_attacking_moves, white_attacking_moves_size, board)
    tempvar mate_condition = king_attacked * (moves_size + 1)
    tempvar stalemate_condition = (king_attacked + 1) * (moves_size + 1)
    if mate_condition == 1:
        return (status = 2)
    end
    if stalemate_condition == 1:
        return (status = 3)
    end
    return (status = 0)
end