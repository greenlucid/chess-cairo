# LEGAL MOVE TESTER
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.serialize import serialize_word

#from service import check_legality
from chess_utils import get_dict_code
from chess_utils import board_loader
from chess_utils import construct_move
from chess_utils import get_rep
from core import is_legal_move
from core import make_move
from core import calculate_status


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

# Loading a board - Here you can modify the pieces that are on the board
func main{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}():
    alloc_locals

    # LOADING THE BOARD -------------------------------------------------------------
    # The dictionary structure containing the pieces
    let (local dict) = alloc()
    # An array of 64 felt, indicating the pieces on the board. Empty squares are = 0. 
    let (local board) = alloc()

    let (local board_after_move) = alloc()

    # As many words in the dict as pieces you want on the board
    let (word1) = get_dict_code(h8, BKing)
    let (word2) = get_dict_code(g6, WPawn)
    let (word3) = get_dict_code(g7, BPawn)
    let (word4) = get_dict_code(g8, BBishop)

    let (word5) = get_dict_code(c7, WPawn)
    let (word6) = get_dict_code(f1, WKing)
    let (word7) = get_dict_code(a5, WRook)
    let (word8) = get_dict_code(g2, WKnight)

    assert [dict] = word1
    assert [dict+1] = word2
    assert [dict+2] = word3
    assert [dict+3] = word4
    assert [dict+4] = word5
    assert [dict+5] = word6
    assert [dict+6] = word7
    assert [dict+7] = word8

    tempvar numb_pieces = 8
    
    # board_loader loads the board, using the pieces indicated in the dict and filling 
    # the rest of the board with zeros.
    board_loader(board, 63, dict, numb_pieces, 0)

    # TEST
    let (test_move) = construct_move(c7, c8, 3)
    serialize_word(7777777777777)
    serialize_word(test_move)
    let (rep) = get_rep(test_move)
    serialize_word(rep)
    serialize_word(7777777777777)

    let (local test_legal) = is_legal_move(board, 15, b6, test_move)
    serialize_word(test_legal)

    serialize_word(555555555555555555555)
    serialize_word([board+c7])
    serialize_word([board+c8])
    serialize_word(555555555555555555555)

    make_move(board, board_after_move, test_move)

    serialize_word(555555555555555555555)
    serialize_word([board_after_move+c7])
    serialize_word([board_after_move+c8])
    serialize_word(555555555555555555555)

    let (status) = calculate_status(board_after_move, 1, 15,  1)
    serialize_word(status)

    return()
end

# source ~/cairo_venv/bin/activate
# cairo-compile core.cairo --output=core_comp.json
# cairo-run --program=core_comp.json --print_output --print_info --relocate_prints --layout=all