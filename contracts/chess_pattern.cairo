from starkware.cairo.common.alloc import alloc

from contracts.structs import (Pattern, Square)

from contracts.chess_utils import in_range

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

# Use side_flag = -1 for pawn moves, side_flag = 1 in all other cases
func pattern_next_square (pattern: Pattern, square: Square, side_flag: felt) -> (next_square: Square):
    alloc_locals
    tempvar old_col = square.col
    tempvar old_row = square.row

    local next_square : Square = Square (row = square.row + pattern.row_var * side_flag, col = square.col + pattern.col_var)

    tempvar var_col = pattern.col_var
    tempvar var_row = pattern.row_var
    tempvar new_col = next_square.col
    tempvar new_row = next_square.row

    let (square_within_range) = in_range (next_square)
    if square_within_range == 1:
        return (next_square = next_square)
    end
    return (next_square = Square(row = 8, col = 8))
end

func add_pattern (list: Pattern*, list_size: felt, pattern: Pattern) -> (new_size: felt):
    assert([list + list_size * Pattern.SIZE]) = pattern
    return(new_size = list_size + 1)
end

func add_pattern_blind (list: Pattern*, list_size: felt, pattern: Pattern):
    assert([list + list_size * Pattern.SIZE]) = pattern
    return()
end

func get_pattern (piece: felt) -> (pattern: Pattern*, pattern_size: felt):
    
    tempvar rook_condition = ((WRook - piece) * (BRook - piece)) + 1
    if rook_condition == 1:
        let (pattern, pattern_size) = get_rook_pattern()
        return (pattern, pattern_size)
    end
    tempvar knight_condition = ((WKnight - piece) * (BKnight - piece)) + 1
    if knight_condition == 1:
        let (pattern, pattern_size) = get_knight_pattern()
        return (pattern, pattern_size)
    end
    tempvar bishop_condition = ((WBishop - piece) * (BBishop - piece)) + 1
    if bishop_condition == 1:
        let (pattern, pattern_size) = get_bishop_pattern()
        return (pattern, pattern_size)
    end
    tempvar king_condition = ((WKing - piece) * (BKing - piece)) + 1
    if king_condition == 1:
        let (pattern, pattern_size) = get_king_pattern()
        return (pattern, pattern_size)
    end
    tempvar pawn_condition = ((WPawn - piece) * (BPawn - piece)) + 1
    if pawn_condition == 1:
        let (pattern, pattern_size) = get_pawn_pattern()
        return (pattern, pattern_size)
    end
    let (pattern, pattern_size) = get_queen_pattern()
    return (pattern, pattern_size)
end

func get_queen_pattern () -> (queen_pattern: Pattern*, queen_pattern_size: felt):
    alloc_locals
    
    let (local queen_pattern : Pattern*) = alloc()

    let queen_pattern_1 : Pattern = Pattern (col_var = 1, row_var = -1, type = 1)
    let queen_pattern_2 : Pattern = Pattern (col_var = 1, row_var = 1, type = 1)
    let queen_pattern_3 : Pattern = Pattern (col_var = -1, row_var = 1, type = 1)
    let queen_pattern_4 : Pattern = Pattern (col_var = -1, row_var = -1, type = 1)
    let queen_pattern_5 : Pattern = Pattern (col_var = 1, row_var = 0, type = 1)
    let queen_pattern_6 : Pattern = Pattern (col_var = 0, row_var = 1, type = 1)
    let queen_pattern_7 : Pattern = Pattern (col_var = -1, row_var = 0, type = 1)
    let queen_pattern_8 : Pattern = Pattern (col_var = 0, row_var = -1, type = 1)

    add_pattern_blind(queen_pattern, 0, queen_pattern_1)
    add_pattern_blind(queen_pattern, 1, queen_pattern_2)
    add_pattern_blind(queen_pattern, 2, queen_pattern_3)
    add_pattern_blind(queen_pattern, 3, queen_pattern_4)
    add_pattern_blind(queen_pattern, 4, queen_pattern_5)
    add_pattern_blind(queen_pattern, 5, queen_pattern_6)
    add_pattern_blind(queen_pattern, 6, queen_pattern_7)
    add_pattern_blind(queen_pattern, 7, queen_pattern_8)

    tempvar queen_pattern_size = 8

    return(queen_pattern = queen_pattern, queen_pattern_size = queen_pattern_size)
end



func get_bishop_pattern () -> (bishop_pattern: Pattern*, bishop_pattern_size: felt):
    alloc_locals
    
    let (local bishop_pattern : Pattern*) = alloc()

    let bishop_pattern_1 : Pattern = Pattern (col_var = 1, row_var = -1, type = 1)
    let bishop_pattern_2 : Pattern = Pattern (col_var = 1, row_var = 1, type = 1)
    let bishop_pattern_3 : Pattern = Pattern (col_var = -1, row_var = 1, type = 1)
    let bishop_pattern_4 : Pattern = Pattern (col_var = -1, row_var = -1, type = 1)

    add_pattern_blind(bishop_pattern, 0, bishop_pattern_1)
    add_pattern_blind(bishop_pattern, 1, bishop_pattern_2)
    add_pattern_blind(bishop_pattern, 2, bishop_pattern_3)
    add_pattern_blind(bishop_pattern, 3, bishop_pattern_4)

    tempvar bishop_pattern_size = 4

    return(bishop_pattern = bishop_pattern, bishop_pattern_size = bishop_pattern_size)
end

func get_rook_pattern () -> (rook_pattern: Pattern*, rook_pattern_size: felt):
    alloc_locals
    
    let (local rook_pattern : Pattern*) = alloc()

    let rook_pattern_1 : Pattern = Pattern (col_var = 0, row_var = 1, type = 1)
    let rook_pattern_2 : Pattern = Pattern (col_var = 1, row_var = 0, type = 1)
    let rook_pattern_3 : Pattern = Pattern (col_var = 0, row_var = -1, type = 1)
    let rook_pattern_4 : Pattern = Pattern (col_var = -1, row_var = 0, type = 1)

    add_pattern_blind(rook_pattern, 0, rook_pattern_1)
    add_pattern_blind(rook_pattern, 1, rook_pattern_2)
    add_pattern_blind(rook_pattern, 2, rook_pattern_3)
    add_pattern_blind(rook_pattern, 3, rook_pattern_4)

    tempvar rook_pattern_size = 4

    return(rook_pattern = rook_pattern, rook_pattern_size = rook_pattern_size)
end

func get_knight_pattern () -> (knight_pattern: Pattern*, knight_pattern_size: felt):
    alloc_locals
    
    let (local knight_pattern : Pattern*) = alloc()

    let knight_pattern_1 : Pattern = Pattern (col_var = 1, row_var = -2, type = 0)
    let knight_pattern_2 : Pattern = Pattern (col_var = 2, row_var = -1, type = 0)
    let knight_pattern_3 : Pattern = Pattern (col_var = 2, row_var = 1, type = 0)
    let knight_pattern_4 : Pattern = Pattern (col_var = 1, row_var = 2, type = 0)
    let knight_pattern_5 : Pattern = Pattern (col_var = -1, row_var = 2, type = 0)
    let knight_pattern_6 : Pattern = Pattern (col_var = -2, row_var = 1, type = 0)
    let knight_pattern_7 : Pattern = Pattern (col_var = -2, row_var = -1, type = 0)
    let knight_pattern_8 : Pattern = Pattern (col_var = -1, row_var = -2, type = 0)

    add_pattern_blind(knight_pattern, 0, knight_pattern_1)
    add_pattern_blind(knight_pattern, 1, knight_pattern_2)
    add_pattern_blind(knight_pattern, 2, knight_pattern_3)
    add_pattern_blind(knight_pattern, 3, knight_pattern_4)
    add_pattern_blind(knight_pattern, 4, knight_pattern_5)
    add_pattern_blind(knight_pattern, 5, knight_pattern_6)
    add_pattern_blind(knight_pattern, 6, knight_pattern_7)
    add_pattern_blind(knight_pattern, 7, knight_pattern_8)

    tempvar knight_pattern_size = 8

    return(knight_pattern = knight_pattern, knight_pattern_size = knight_pattern_size)
end

func get_king_pattern () -> (king_pattern: Pattern*, king_pattern_size: felt):
    alloc_locals
    
    let (local king_pattern : Pattern*) = alloc()

    let king_pattern_1 : Pattern = Pattern (col_var = 1, row_var = -1, type = 0)
    let king_pattern_2 : Pattern = Pattern (col_var = 1, row_var = 0, type = 0)
    let king_pattern_3 : Pattern = Pattern (col_var = 1, row_var = 1, type = 0)
    let king_pattern_4 : Pattern = Pattern (col_var = 0, row_var = 1, type = 0)
    let king_pattern_5 : Pattern = Pattern (col_var = -1, row_var = 1, type = 0)
    let king_pattern_6 : Pattern = Pattern (col_var = -1, row_var = 0, type = 0)
    let king_pattern_7 : Pattern = Pattern (col_var = -1, row_var = -1, type = 0)
    let king_pattern_8 : Pattern = Pattern (col_var = 0, row_var = -1, type = 0)
    let king_pattern_9 : Pattern = Pattern (col_var = 2, row_var = 0, type = 4)
    let king_pattern_10 : Pattern = Pattern (col_var = -2, row_var = 0, type = 5)

    add_pattern_blind(king_pattern, 0, king_pattern_1)
    add_pattern_blind(king_pattern, 1, king_pattern_2)
    add_pattern_blind(king_pattern, 2, king_pattern_3)
    add_pattern_blind(king_pattern, 3, king_pattern_4)
    add_pattern_blind(king_pattern, 4, king_pattern_5)
    add_pattern_blind(king_pattern, 5, king_pattern_6)
    add_pattern_blind(king_pattern, 6, king_pattern_7)
    add_pattern_blind(king_pattern, 7, king_pattern_8)
    add_pattern_blind(king_pattern, 8, king_pattern_9)
    add_pattern_blind(king_pattern, 9, king_pattern_10)

    tempvar king_pattern_size = 10

    return(king_pattern = king_pattern, king_pattern_size = king_pattern_size)
end

func get_pawn_pattern () -> (pawn_pattern: Pattern*, pawn_pattern_size: felt):
    alloc_locals

    let (local pawn_pattern : Pattern*) = alloc()

    let pawn_pattern_1 : Pattern = Pattern (col_var = 1, row_var =-1, type = 3)
    let pawn_pattern_2 : Pattern = Pattern (col_var = 0, row_var =-1, type = 0)
    let pawn_pattern_3 : Pattern = Pattern (col_var = -1, row_var =-1, type = 3)
    let pawn_pattern_4 : Pattern = Pattern (col_var = 0, row_var =-2, type = 2)
    add_pattern_blind(pawn_pattern, 0, pawn_pattern_1)
    add_pattern_blind(pawn_pattern, 1, pawn_pattern_2)
    add_pattern_blind(pawn_pattern, 2, pawn_pattern_3)
    add_pattern_blind(pawn_pattern, 3, pawn_pattern_4)
    tempvar pawn_pattern_size = 4

    return(pawn_pattern = pawn_pattern, pawn_pattern_size = pawn_pattern_size)
end
