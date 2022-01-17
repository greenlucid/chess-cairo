from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.serialize import serialize_word

from core import calculate_white_board
from core import calculate_white_attack
from core import calculate_black_attack
from core import make_move
from core import castle_white
from chess_utils import board_loader
from chess_utils import get_dict_code
from chess_utils import show_moves
from chess_utils import is_attacked
from chess_utils import get_rep
from chess_utils import get_binary_word

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

const king_pattern = 305419888
const bishop_pattern = 17767
const knight_pattern = 2309737967
const rook_pattern = 4896
const white_pawn_pattern = 1046
const black_pawn_pattern = 1319
const queen_pattern = 320882023
const empty_square = -1

# THE MAIN FUNCTION - Here you can include some pieces in the board, using the dictionary.
func main{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}():
    alloc_locals
    let (local dict) = alloc()
    let (local board) = alloc()
    let (local new_board) = alloc()
    let (local moves) = alloc()
    let (local attack_moves) = alloc()
    # Here we should include a moves: felt* to load the moves (by now, take a look at the final squares in the console
    let (code1) = get_dict_code(e8, BKing)
    let (code2) = get_dict_code(e1, WKing)
    let (code3) = get_dict_code(c5, BBishop)
    let (code4) = get_dict_code(d2, WPawn)
    let (code5) = get_dict_code(f4, BPawn)
    let (code6) = get_dict_code(c2, WQueen)
    let (code7) = get_dict_code(a8, BRook) 
    let (code8) = get_dict_code(h1, WRook)    

    assert [dict] = code1
    assert [dict+1] = code2
    assert [dict+2] = code3
    assert [dict+3] = code4
    assert [dict+4] = code5
    assert [dict+5] = code6
    assert [dict+6] = code7
    assert [dict+7] = code8
    
    tempvar numb_pieces = 8
    
    board_loader(board, 63,dict, numb_pieces, 0)

    # let (d4_size) = calculate_moves(board, moves, bishop_pattern, 3, d4, d4)
    # tempvar current_size1 = d4_size
    # #serialize_word(current_size1)
    # let (g7_size) = calculate_moves(board, moves+d4_size, bishop_pattern, 3, g7, g7)
    # tempvar current_size2 = d4_size + g7_size
    # #serialize_word(current_size2)
    # let (b6_size) = calculate_moves(board, moves+d4_size+g7_size, knight_pattern, 7, b6, b6)
    # tempvar current_size3 = d4_size + g7_size + b6_size
    # #serialize_word(current_size3)
    # let (f3_size) = calculate_moves(board, moves+d4_size+g7_size+b6_size, black_pawn_pattern, 2, f3, f3)
    # tempvar current_size4 = d4_size + g7_size + b6_size + f3_size
    # serialize_word(f3_size)
    
    # SAMPLE TEST - CALCULATE MOVES AND ATTACKS IN THE STARTING POSITION FOR WHITE
    let(this_moves_size) = calculate_white_board(board, 0, moves)
    serialize_word(this_moves_size)
    show_moves(moves, this_moves_size)

    serialize_word(591646516541561651631532486532)
    make_move(board, new_board, [moves])
    serialize_word([board+50])
    serialize_word([board+42])

    serialize_word([new_board+50])
    serialize_word([new_board+42])


    # Console Sections Separator
    serialize_word(100000000000000000000000000)

    # Squares attacked by the white pieces
    let(this_attacking_moves_size) = calculate_black_attack(board, 0, attack_moves)
    serialize_word(this_attacking_moves_size)
    show_moves(attack_moves, this_attacking_moves_size)

    castle_white(board, attack_moves, this_attacking_moves_size, 1)

    return()
end

# ALSO: SPECIAL MOVES

# cairo-compile core.cairo --output=core_comp.json
# cairo-run --program=core_comp.json --print_output --print_info --relocate_prints --layout=all