# VARIOUS FUNCTIONS SERVING OTHER FILES
# There's no clear rationale on why some function be here.
# Basically when you miss the idea where something should be, it ends up here.
# In later versions we will try not only to make it work, but to make it look
# as we know what we are doing. Don't tell Dijkstra.

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin

from contracts.bit_helper import bits_at
from contracts.pow2 import pow2

from contracts.structs import (
    Move,
    Square,
    Setting
)

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

# Checks that the coordinate is not -2, -1, 8 or 9
# 0: out, 1: in
# this makes input range [0, 11] for each col / row so 144 possible results
func in_range(square: Square) -> (in_range: felt):
    tempvar i = (square.row + 2) * 12 + (square.col + 2)
    let (data_address) = get_label_location(in_range_data)
    return ([data_address + i])
    in_range_data:
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 0
    dw 0
    dw 0
    dw 0
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 0
    dw 0
    dw 0
    dw 0
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 0
    dw 0
    dw 0
    dw 0
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 0
    dw 0
    dw 0
    dw 0
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 0
    dw 0
    dw 0
    dw 0
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 0
    dw 0
    dw 0
    dw 0
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 0
    dw 0
    dw 0
    dw 0
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
end

func board_index (square: Square) -> (board_index: felt):
    return (square.col + square.row * 8)
end

# "content" are the values in the board array. this func compares the content (e.g. pieces) of two squares.
# 0: different color, 1: same color, 2: both empty, 3: first empty, 4: second empty, 5: error (at least one code wrong)
func compare_square_content(content_1 : felt, content_2 : felt) -> (compare_square_content : felt):
    if content_1 == 0:
        if content_2 == 0:
            return (2)
        end
        return (3)
    end
    if content_2 == 0:
        return (4)
    end

    # Now both are values between [16, 29], so map it to [0, 13] (14 values)
    # 14 * 14 = 196 dw lines

    let (data_address) = get_label_location(square_compares_data)
    tempvar i = (content_1 - 16) * 14 + (content_2 - 16)
    return ([data_address + i])
    square_compares_data:
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 5
    dw 5
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 5
    dw 5
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 5
    dw 5
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 5
    dw 5
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 5
    dw 5
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 5
    dw 5
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 5
    dw 5
    dw 5
    dw 5
    dw 5
    dw 5
    dw 5
    dw 5
    dw 5
    dw 5
    dw 5
    dw 5
    dw 5
    dw 5
    dw 5
    dw 5
    dw 5
    dw 5
    dw 5
    dw 5
    dw 5
    dw 5
    dw 5
    dw 5
    dw 5
    dw 5
    dw 5
    dw 5
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 5
    dw 5
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 5
    dw 5
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 5
    dw 5
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 5
    dw 5
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 5
    dw 5
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 0
    dw 5
    dw 5
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
end

# 0: empty square, 1: white piece, 2: black piece, 3: error
func square_content (board: felt*, square: Square) -> (square_content: felt):
    let (square_index) = board_index(square)
    tempvar current_piece = [board + square_index]
    
    let (data_address) = get_label_location(square_contents_data)
    return ([data_address + current_piece])
    # This can be [0, 29] inclusive
    square_contents_data:
    dw 0
    dw 3
    dw 3
    dw 3
    dw 3
    dw 3
    dw 3
    dw 3
    dw 3
    dw 3
    dw 3
    dw 3
    dw 3
    dw 3
    dw 3
    dw 3
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 1
    dw 3
    dw 3
    dw 2
    dw 2
    dw 2
    dw 2
    dw 2
    dw 2
end

# Check if a square is the final square of a set of moves - Good for looking for checks.
func check_final_square (moves: Move*, moves_size: felt, square_index: felt) -> (is_final_square: felt):
    if moves_size == 0:
        return (is_final_square = 0)
    end
    let current_move = [moves + (moves_size - 1) * Move.SIZE]
    let current_final_square = current_move.dest
    tempvar final_square_index = current_final_square.row * 8 + current_final_square.col
    tempvar same_square = (final_square_index - square_index) + 1 
    if same_square == 1:
        return(is_final_square = 1)
    end
    let (is_final_square) = check_final_square (moves, moves_size - 1, square_index)
    return (is_final_square = is_final_square)
end

# To calculate black and white moves with the same recursive function you need a flag
# to differenciate white and black pawns, so you go this...
# Specific function to make black pawns run downwards
func get_side_flag (piece: felt) -> (side_flag: felt):
    if piece != BPawn:
        return (side_flag = 1)
    end
    return (side_flag = -1)
end

# More flagging
# Specific funtion to set promotion flag in the guidance vector
func get_promotion_flag (final_square_relative_row_prom: felt) -> (promotion_flag: felt):
    if final_square_relative_row_prom == 1:
        return (promotion_flag = 1)
    end
    return (promotion_flag = 0)
end

func change_active_color (active_color: felt) -> (new_active_color: felt):
    if active_color == 1:
        return (new_active_color = 0)
    end
    return (new_active_color = 1)
end

func get_square{
        bitwise_ptr : BitwiseBuiltin*, range_check_ptr
        }(value : felt) -> (square : Square):
    let (row) = bits_at(el=value, offset=245, size=3)
    return (square = Square(row=row, col=value - row * 8))
end

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

func point_to_felt(point : Square) -> (value : felt):
    tempvar value = point.row * 8 + point.col
    return (value=value)
end

func parse_move{
        bitwise_ptr : BitwiseBuiltin*, range_check_ptr
        }(encoded_move : felt) -> (move : Move):
    alloc_locals
    let (local origin_row) = bits_at(el=encoded_move, offset=237, size=3)
    let (local origin_col) = bits_at(el=encoded_move, offset=240, size=3)
    let (local dest_row) = bits_at(el=encoded_move, offset=243, size=3)
    let (local dest_col) = bits_at(el=encoded_move, offset=246, size=3)
    let (local extra) = bits_at(el=encoded_move, offset=249, size=2)
    local origin : Square = Square(row=origin_row, col=origin_col)
    local dest : Square = Square(row=dest_row, col=dest_col)
    local move : Move = Move(origin=origin, dest=dest, extra=extra)
    return (move=move)
end

func encode_move(move : Move) -> (enc_move : felt):
    tempvar enc_move = move.origin.row * 2048 + move.origin.col * 256 + move.dest.row * 32 + move.dest.col * 4 + move.extra
    return (enc_move=enc_move)
end