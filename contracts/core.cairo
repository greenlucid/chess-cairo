# CHESS CAIRO CORE
# Here is where the chess logic is hardcoded, through the calculate_moves and it's sister claculate_attacks functions.
# Both implement some sort of "guided" recursivity. The Pattern struct provides the directions of movement for every piece
# plus some extra info that helps the guidance_vector guide the recursive function.
# For example: the main recursive function receives a board, an initial square and a pattern and calculates the final square.
# Then, it sends this info to the guidance_vector constructor, who decides if the move should be saved, if the search should
# follow the same pattern, and so on.

from starkware.cairo.common.alloc import alloc

from contracts.structs import (
    Square,
    Pattern,
    Move,
    Recursive_Vector,
    Meta,
    Setting
)

from contracts.chess_utils import (
    in_range,
    compare_square_content,
    square_content,
    board_index,
    get_side_flag,
    get_promotion_flag,
    change_active_color,
    check_final_square
)

from contracts.chess_moves import (
    add_move,
    add_move_blind,
    serialize_move,
    add_moves_lists
)

from contracts.chess_board import (
    board_loader,
    get_square_of_piece
)

from contracts.chess_setting import (
    add_setting,
    add_setting_blind
)

from contracts.chess_pattern import (
    get_pattern,
    pattern_next_square
)

from contracts.chess_moves import contains_move

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

func calculate_raw_moves (board: felt*, col: felt, row: felt, meta: Meta) -> (moves_list: Move*, moves_list_size: felt):
    alloc_locals
    let (local moves_list : Move*) = alloc()
    tempvar board_index = col + row * 8
    if board_index == 64:
        return (moves_list, 0)
    end

    tempvar temp_col = col + 1
    local new_col : felt
    local new_row : felt
    if temp_col == 8:
        new_col = 0
        new_row = row + 1
    else:
        new_col = col + 1
        new_row = row
    end
    let (local moves_list, moves_list_size) = calculate_raw_moves (board, new_col, new_row, meta)
    let (ref_square_content) = square_content (board, Square(row, col))
    tempvar ref_square_piece_color = ref_square_content - 1
    tempvar active_color = meta.active_color 
    if ref_square_piece_color == active_color:
        let (local current_moves_list : Move*, current_moves_list_size: felt) = calculate_moves_wrapper (board, meta, Square(row, col))
        add_moves_lists (moves_list, moves_list_size, current_moves_list, current_moves_list_size, 0)
        return (moves_list, moves_list_size + current_moves_list_size)
    end
    return (moves_list, moves_list_size)
end

func calculate_moves_wrapper (board: felt*, meta: Meta, square: Square) -> (moves_list: Move*, moves_list_size: felt):
    alloc_locals
    
    let (local moves_list : Move*) = alloc()
    let (square_index) = board_index(square)
    tempvar current_piece = [board + square_index]
    let (current_square_content) = square_content(board, square)

    if current_square_content == 0:
        add_move_blind (moves_list, 0, Move (square, square, 0))
        return (moves_list = moves_list, moves_list_size = 0)
    end
    if current_square_content == 3:
        return (moves_list = moves_list, moves_list_size = 0)
    end
    let (pattern : Pattern*, pattern_size: felt) = get_pattern(current_piece)
    let (moves_list_size) = calculate_moves (moves_list, board, meta, pattern, pattern_size, square, square)    
    
    return(moves_list = moves_list, moves_list_size = moves_list_size)
end

func calculate_moves (
        moves_list: Move*, board: felt*, meta: Meta, pattern: Pattern*, pattern_size: felt,
        initial_square: Square, reference_square: Square) -> (moves_size: felt):
    alloc_locals

    if pattern_size == 0:
        return(0)
    end    

    # Initialization stage: get index, next evaluated square and guidance vector
    let (initial_square_index) = board_index(initial_square)
    tempvar initial_square_piece = [board + initial_square_index]
    tempvar pattern_index = (pattern_size - 1) * Pattern.SIZE
    let (side_flag) = get_side_flag(initial_square_piece)
    let next_square : Square = pattern_next_square([pattern + pattern_index], reference_square, side_flag)
    let (guidance_vector : Recursive_Vector) = get_guidance_vector (board, meta, [pattern + pattern_index], initial_square, next_square)

    # Operational stage: conditional save move and special moves
    # Save_condition
    tempvar save_condition = guidance_vector.save_flag
    if save_condition == 1:
        assert [moves_list] = Move (initial_square, next_square, 0)
    end
    # Castling conditions
    tempvar castle_K_condition = guidance_vector.castle_k_flag * meta.castling_K * (meta.active_color + 1)

    if castle_K_condition == 1:
        assert [moves_list] = Move(Square(row = 7, col = 4), Square(row = 7, col = 6), 0)
    end
    tempvar castle_Q_condition = guidance_vector.castle_q_flag * meta.castling_Q * (meta.active_color + 1)
    if castle_Q_condition == 1:
        assert [moves_list + castle_K_condition] = Move(Square(row = 7, col = 4), Square(row = 7, col = 2), 0)
    end
    tempvar castle_k_condition = guidance_vector.castle_k_flag * meta.castling_k * (meta.active_color)
    if castle_k_condition == 1:
        assert [moves_list] = Move(Square(row = 0, col = 4), Square(row = 0, col = 6), 0)
    end
    tempvar castle_q_condition = guidance_vector.castle_q_flag * meta.castling_q * (meta.active_color)
    if castle_q_condition == 1:
        assert [moves_list + castle_k_condition] = Move(Square(row = 0, col = 4), Square(row = 0, col = 2), 0)
    end
    # Promoting conditions
    tempvar promotion_condition = guidance_vector.promotion_flag
    if promotion_condition == 1:
        assert [moves_list + Move.SIZE] = Move (initial_square, next_square, 1)
        assert [moves_list + Move.SIZE * 2] = Move (initial_square, next_square, 2)
        assert [moves_list + Move.SIZE * 3] = Move (initial_square, next_square, 3)
    end

    # Recursive stage: parametrize iteration
    tempvar stop_flag = guidance_vector.stop_flag
    let new_reference_square : Square = guidance_vector.new_reference_square
    tempvar size_added = save_condition + castle_K_condition + castle_Q_condition + castle_k_condition + castle_q_condition + promotion_condition * 3

    # Iterate:
    let (moves_size) = calculate_moves(moves_list + size_added * Move.SIZE , board,
        meta, pattern, pattern_size - stop_flag, initial_square, new_reference_square)

    return(moves_size = moves_size + size_added)
end

func get_guidance_vector(
        board: felt*, meta: Meta, pattern: Pattern, initial_square: Square, final_square: Square) -> (guidance_vector: Recursive_Vector):
    alloc_locals

    let (final_square_in_range) = in_range (final_square)
    tempvar pattern_type = pattern.type
    tempvar active_color = meta.active_color
    # Out of bounds
    if final_square_in_range == 0:
        let guidance_vector : Recursive_Vector = Recursive_Vector (stop_flag = 1, save_flag = 0, castle_k_flag = 0, castle_q_flag = 0,
            promotion_flag = 0, new_reference_square = initial_square)
        return(guidance_vector = guidance_vector)
    end
    # Calculate variables to construct conditions
    let (local initial_square_index) = board_index(initial_square)
    let (local final_square_index) = board_index(final_square)
    tempvar initial_square_piece = [board + initial_square_index]
    tempvar final_square_piece = [board + final_square_index]
    let (final_square_content) = compare_square_content (initial_square_piece, final_square_piece)
    # Same color pieces
    if final_square_content == 1:
        let guidance_vector : Recursive_Vector = Recursive_Vector (stop_flag = 1, save_flag = 0, castle_k_flag = 0, castle_q_flag = 0,
            promotion_flag = 0, new_reference_square = initial_square)
        return(guidance_vector = guidance_vector)
    end   
    tempvar constling_pattern_condition = (pattern_type - 4) * (pattern_type - 5) + 1
    if constling_pattern_condition == 1:
        # Checking white castling kingside
        tempvar white_castle_k_condition = (pattern_type - 3)
        if white_castle_k_condition == 1:
            let (castling_allowed) = castling_K_allowed(board, meta)
            if castling_allowed == 1:
                let guidance_vector : Recursive_Vector = Recursive_Vector (stop_flag = 1, save_flag = 0, castle_k_flag = 1, castle_q_flag = 0,
                    promotion_flag = 0, new_reference_square = initial_square)
                return(guidance_vector = guidance_vector)
            end
        end        
        # Checking white castling queenside
        tempvar white_castle_q_condition = (pattern_type - 4) * (active_color + 1) * ([board + 59] + 1) * ([board + 58] + 1) * ([board + 56] - 15) * ([board + 60] - 19)
        if white_castle_q_condition == 1:
            let (castling_allowed) = castling_Q_allowed(board, meta)
            if castling_allowed == 1:          
                let guidance_vector : Recursive_Vector = Recursive_Vector (stop_flag = 1, save_flag = 0, castle_k_flag = 0, castle_q_flag = 1,
                    promotion_flag = 0, new_reference_square = initial_square)
                return(guidance_vector = guidance_vector)
            end
        end    
        # Checking black castling kingside
        tempvar black_castle_k_condition = (pattern_type - 3) * (active_color) * ([board + 6] + 1) * ([board + 5] + 1) * ([board + 7] - 23) * ([board + 4] - 27)
        if black_castle_k_condition == 1:
            let (castling_allowed) = castling_k_allowed(board, meta)
            if castling_allowed == 1:
                let guidance_vector : Recursive_Vector = Recursive_Vector (stop_flag = 1, save_flag = 0, castle_k_flag = 1, castle_q_flag = 0,
                    promotion_flag = 0, new_reference_square = initial_square)
                return(guidance_vector = guidance_vector)
            end
        end        
        # Checking black castling queenside
        tempvar black_castle_q_condition = (pattern_type - 4) * (active_color) * ([board + 3] + 1) * ([board + 2] + 1) * ([board] - 23) * ([board + 4] - 27)
        if black_castle_q_condition == 1:
            let (castling_allowed) = castling_q_allowed(board, meta)
            if castling_allowed == 1:         
                let guidance_vector : Recursive_Vector = Recursive_Vector (stop_flag = 1, save_flag = 0, castle_k_flag = 0, castle_q_flag = 1,
                    promotion_flag = 0, new_reference_square = initial_square)
                return(guidance_vector = guidance_vector)
            end
        end
        let guidance_vector : Recursive_Vector = Recursive_Vector (stop_flag = 1, save_flag = 0, castle_k_flag = 0, castle_q_flag = 0,
            promotion_flag = 0, new_reference_square = initial_square)
        return(guidance_vector = guidance_vector)
    end   
    # THE PAWN MOVES
    tempvar piece_is_pawn = (initial_square_piece - WPawn) * (initial_square_piece - BPawn) + 1
    if piece_is_pawn == 1:
        tempvar final_square_relative_row_prom = final_square.row * (final_square.row - 7) + 1
        let (promotion_flag) = get_promotion_flag(final_square_relative_row_prom)
        # Only capture : pattern.type = 3, final_square = 0 (enemy piece) - Only for pawns
        tempvar only_capture = (pattern_type - 2) * (final_square_content + 1) 
        if only_capture == 1:
            let guidance_vector : Recursive_Vector = Recursive_Vector (stop_flag = 1, save_flag = 1, castle_k_flag = 0, castle_q_flag = 0,
                promotion_flag = promotion_flag, new_reference_square = initial_square)
            return(guidance_vector = guidance_vector)
        end
        # Only move 1 : pattern.type = 0, final_square = 4 (empty) - Only for pawns
        tempvar only_move_1 = (pattern_type + 1) * (final_square_content - 3)
        if only_move_1 == 1:
            let guidance_vector : Recursive_Vector = Recursive_Vector (stop_flag = 1, save_flag = 1, castle_k_flag = 0, castle_q_flag = 0,
                promotion_flag = promotion_flag, new_reference_square = initial_square)
            return(guidance_vector = guidance_vector)
        end
        # Only move 2 : pattern.type = 2, middle_square = 4, final_square = 4 (empty) - Only for pawns
        tempvar only_move_2 = (pattern_type - 1) * (final_square_content - 3)
        if only_move_2 == 1:
            tempvar middle_square_row = (initial_square.row + final_square.row)/2
            let (middle_square_index) = board_index(Square(middle_square_row, initial_square.col))
            let only_2_move_middle_sq = [board + middle_square_index]
            if only_2_move_middle_sq == 0:
                let guidance_vector : Recursive_Vector = Recursive_Vector (stop_flag = 1, save_flag = 1, castle_k_flag = 0, castle_q_flag = 0,
                    promotion_flag = promotion_flag, new_reference_square = initial_square)
                return(guidance_vector = guidance_vector)
            end
        end
        # Checking first if the pawn is on the fifth (relative) row, so en passant is possible
        tempvar initial_square_relative_row = initial_square.row - active_color 
        if initial_square_relative_row == 3:
            let (en_passant_square_index) = board_index(meta.passant)
            tempvar en_passant_col = meta.passant.col
            tempvar initial_square_row = initial_square.row
            tempvar en_passant_capture_content = [board + initial_square.row * 8 + en_passant_col]
            tempvar en_passant_capture_content_is_pawn = (en_passant_capture_content - BPawn) * (en_passant_capture_content - WPawn) + 1
            tempvar en_passant_condition = (en_passant_capture_content_is_pawn) * (final_square_index - en_passant_square_index + 1)
            if en_passant_condition == 1:
                let guidance_vector : Recursive_Vector = Recursive_Vector (stop_flag = 1, save_flag = 1, castle_k_flag = 0, castle_q_flag = 0,
                    promotion_flag = 0, new_reference_square = initial_square)
                return(guidance_vector = guidance_vector)
            end
        end
        let guidance_vector : Recursive_Vector = Recursive_Vector (stop_flag = 1, save_flag = 0, castle_k_flag = 0, castle_q_flag = 0,
            promotion_flag = 0, new_reference_square = initial_square)
        return(guidance_vector = guidance_vector)
    end
    # Regular capture
    if final_square_content == 0:
        let guidance_vector : Recursive_Vector = Recursive_Vector (stop_flag = 1, save_flag = 1, castle_k_flag = 0, castle_q_flag = 0,
            promotion_flag = 0, new_reference_square = initial_square)
        return(guidance_vector = guidance_vector)
    end       
    # Short reach pattern (type = 0)
    if pattern_type == 0:
        let guidance_vector : Recursive_Vector = Recursive_Vector (stop_flag = 1, save_flag = 1, castle_k_flag = 0, castle_q_flag = 0,
            promotion_flag = 0, new_reference_square = initial_square)
        return(guidance_vector = guidance_vector)
    end
    # Empty square
    let guidance_vector : Recursive_Vector = Recursive_Vector (stop_flag = 0, save_flag = 1, castle_k_flag = 0, castle_q_flag = 0,
        promotion_flag = 0, new_reference_square = final_square)
    return(guidance_vector = guidance_vector)
end

# CALCULATE ATTACKS -----------------------------------------------------------------------------------------------------
# CALCULATE ATTACKS -----------------------------------------------------------------------------------------------------
# CALCULATE ATTACKS -----------------------------------------------------------------------------------------------------
# CALCULATE ATTACKS -----------------------------------------------------------------------------------------------------

# This function using "col: felt, row: felt" as parameters is the result of the asimetry square<>board_index, plus
# plus the incompetence of the programer. (Mr. Krug). TODO: Review the whole logic of chess cairo for a second refactoring.
func calculate_all_attacks (board: felt*, col: felt, row: felt, meta: Meta) -> (moves_list: Move*, moves_list_size: felt):
    alloc_locals
    let (local moves_list : Move*) = alloc()
    tempvar board_index = col + row * 8
    if board_index == 64:
        return (moves_list, 0)
    end

    tempvar temp_col = col + 1
    local new_col : felt
    local new_row : felt
    if temp_col == 8:
        new_col = 0
        new_row = row + 1
    else:
        new_col = col + 1
        new_row = row
    end
    let (local moves_list, moves_list_size) = calculate_all_attacks (board, new_col, new_row, meta)
    let (ref_square_content) = square_content (board, Square(row, col))
    tempvar ref_square_piece_color = ref_square_content - 1
    tempvar active_color = meta.active_color
    
    if ref_square_piece_color == active_color:
        let (local current_moves_list : Move*, current_moves_list_size: felt) = calculate_attacks_wrapper (board, meta, Square(row, col))
        add_moves_lists (moves_list, moves_list_size, current_moves_list, current_moves_list_size, 0)
        return (moves_list, moves_list_size + current_moves_list_size)
    end
    return (moves_list, moves_list_size)
end

func calculate_attacks_wrapper (board: felt*, meta: Meta, square: Square) -> (moves_list: Move*, moves_list_size: felt):
    alloc_locals
    
    let (local moves_list : Move*) = alloc()
    let (square_index) = board_index(square)
    tempvar current_piece = [board + square_index]
    let (current_square_content) = square_content(board, square)

    if current_square_content == 0:
        add_move_blind (moves_list, 0, Move (square, square, 0))
        return (moves_list = moves_list, moves_list_size = 0)
    end
    if current_square_content == 3:
        return (moves_list = moves_list, moves_list_size = 0)
    end
    let (pattern : Pattern*, pattern_size: felt) = get_pattern(current_piece)
    let (moves_list_size) = calculate_attacks (moves_list, board, meta, pattern, pattern_size, square, square)    
    
    return(moves_list = moves_list, moves_list_size = moves_list_size)
end

func calculate_attacks (
        moves_list: Move*, board: felt*, meta: Meta, pattern: Pattern*, pattern_size: felt,
        initial_square: Square, reference_square: Square) -> (moves_size: felt):
    alloc_locals

    if pattern_size == 0:
        return(0)
    end    

    # Initialization stage: get index, next evaluated square and guidance vector
    let (initial_square_index) = board_index(initial_square)
    tempvar initial_square_piece = [board + initial_square_index]
    tempvar pattern_index = (pattern_size - 1) * Pattern.SIZE
    let (side_flag) = get_side_flag(initial_square_piece)
    let next_square : Square = pattern_next_square([pattern + pattern_index], reference_square, side_flag)
    let (guidance_vector : Recursive_Vector) = get_attacks_guidance_vector (board, meta, [pattern + pattern_index], initial_square, next_square)

    # Operational stage: conditional save move and special moves
    # Save_condition
    tempvar save_condition = guidance_vector.save_flag
    if save_condition == 1:
        assert [moves_list] = Move (initial_square, next_square, 0)
    end

    # Recursive stage: parametrize iteration
    tempvar stop_flag = guidance_vector.stop_flag
    let new_reference_square : Square = guidance_vector.new_reference_square
    tempvar size_added = save_condition

    # Iterate:
    let (moves_size) = calculate_attacks (moves_list + size_added * Move.SIZE , board,
        meta, pattern, pattern_size - stop_flag, initial_square, new_reference_square)



    return(moves_size = moves_size + size_added)
end

func get_attacks_guidance_vector(
        board: felt*, meta: Meta, pattern: Pattern, initial_square: Square, final_square: Square) -> (guidance_vector: Recursive_Vector):
    alloc_locals

    let (final_square_in_range) = in_range (final_square)
    tempvar pattern_type = pattern.type
    tempvar active_color = meta.active_color
    # Out of bounds
    if final_square_in_range == 0:
        let guidance_vector : Recursive_Vector = Recursive_Vector (stop_flag = 1, save_flag = 0, castle_k_flag = 0, castle_q_flag = 0,
            promotion_flag = 0, new_reference_square = initial_square)
        return(guidance_vector = guidance_vector)
    end
    # Calculate variables to construct conditions
    let (local initial_square_index) = board_index(initial_square)
    let (local final_square_index) = board_index(final_square)
    tempvar initial_square_piece = [board + initial_square_index]
    tempvar final_square_piece = [board + final_square_index]
    let (final_square_content) = compare_square_content (initial_square_piece, final_square_piece)
    # Same color pieces
    if final_square_content == 1:
        let guidance_vector : Recursive_Vector = Recursive_Vector (stop_flag = 1, save_flag = 1, castle_k_flag = 0, castle_q_flag = 0,
            promotion_flag = 0, new_reference_square = initial_square)
        return(guidance_vector = guidance_vector)
    end   
    # THE PAWN MOVES
    tempvar piece_is_pawn = (initial_square_piece - WPawn) * (initial_square_piece - BPawn) + 1
    if piece_is_pawn == 1:
        # Only capture : pattern.type = 3, final_square = 0 (enemy piece) - Only for pawns
        tempvar only_capture = pattern_type - 2
        if only_capture == 1:
            let guidance_vector : Recursive_Vector = Recursive_Vector (stop_flag = 1, save_flag = 1, castle_k_flag = 0, castle_q_flag = 0,
                promotion_flag = 0, new_reference_square = initial_square)
            return(guidance_vector = guidance_vector)
        end
        let guidance_vector : Recursive_Vector = Recursive_Vector (stop_flag = 1, save_flag = 0, castle_k_flag = 0, castle_q_flag = 0,
            promotion_flag = 0, new_reference_square = initial_square)
        return(guidance_vector = guidance_vector)
    end
    # Regular capture
    if final_square_content == 0:
        let guidance_vector : Recursive_Vector = Recursive_Vector (stop_flag = 1, save_flag = 1, castle_k_flag = 0, castle_q_flag = 0,
            promotion_flag = 0, new_reference_square = initial_square)
        return(guidance_vector = guidance_vector)
    end       
    # Short reach pattern (type = 0)
    if pattern_type == 0:
        let guidance_vector : Recursive_Vector = Recursive_Vector (stop_flag = 1, save_flag = 1, castle_k_flag = 0, castle_q_flag = 0,
            promotion_flag = 0, new_reference_square = initial_square)
        return(guidance_vector = guidance_vector)
    end
    if pattern_type == 4:
        let guidance_vector : Recursive_Vector = Recursive_Vector (stop_flag = 1, save_flag = 0, castle_k_flag = 0, castle_q_flag = 0,
            promotion_flag = 0, new_reference_square = initial_square)
        return(guidance_vector = guidance_vector)
    end
    if pattern_type == 5:
        let guidance_vector : Recursive_Vector = Recursive_Vector (stop_flag = 1, save_flag = 0, castle_k_flag = 0, castle_q_flag = 0,
            promotion_flag = 0, new_reference_square = initial_square)
        return(guidance_vector = guidance_vector)
    end
    # Empty square
    let guidance_vector : Recursive_Vector = Recursive_Vector (stop_flag = 0, save_flag = 1, castle_k_flag = 0, castle_q_flag = 0,
        promotion_flag = 0, new_reference_square = final_square)
    return(guidance_vector = guidance_vector)
end

func make_move(board: felt*, move: Move, meta: Meta) -> (new_board: felt*):
    alloc_locals

    let (new_board: felt*) = alloc()
    let (initial_square_board_index) = board_index(move.origin)
    tempvar current_piece = [board + initial_square_board_index]
    local final_piece : felt
    tempvar final_row = move.dest.row
    tempvar promotion_condition_1 = (current_piece - WPawn) * (current_piece - BPawn) + 1
    tempvar promotion_condition_2 = (final_row - 7) * final_row + 1
    tempvar promotion_condition = promotion_condition_1 * promotion_condition_2
    tempvar promoting_piece = move.extra
    tempvar active_color = meta.active_color
    tempvar colored_promoting_piece = promoting_piece + active_color * 8 + 16    
    if promotion_condition == 1:
        final_piece = colored_promoting_piece
    else:
        final_piece = current_piece
    end
    tempvar initial_square_board_index = move.origin.col + move.origin.row * 8
    tempvar final_square_board_index = move.dest.col + move.dest.row * 8
    calculate_new_board (board, new_board, 63, initial_square_board_index, final_square_board_index, final_piece)

    let (serialized_move) = serialize_move(move)

    if serialized_move == 47670:
        let (local extra_board : felt*) = alloc()
        calculate_new_board (new_board, extra_board, 63, 63, 61, WRook)
        return (new_board = extra_board)
    end
    if serialized_move == 47270:
        let (local extra_board : felt*) = alloc()
        calculate_new_board (new_board, extra_board, 63, 56, 59, WRook)
        return (new_board = extra_board)
    end
    if serialized_move == 40600:
        let (local extra_board : felt*) = alloc()
        calculate_new_board (new_board, extra_board, 63, 7, 5, BRook)
        return (new_board = extra_board)
    end
    if serialized_move == 40200:
        let (local extra_board : felt*) = alloc()
        calculate_new_board (new_board, extra_board, 63, 0, 3, BRook)
        return (new_board = extra_board)
    end

    return(new_board = new_board)
end

func calculate_new_board (board: felt*, new_board: felt*, board_index: felt, 
        initial_square_index: felt, final_square_index: felt, piece: felt):
    if board_index == -1:   
        return()
    end
    calculate_new_board(board, new_board, board_index - 1, initial_square_index, final_square_index, piece)
    if board_index == initial_square_index:
        assert [new_board + board_index] = 0
    else:
        if board_index == final_square_index:
            assert [new_board + board_index] = piece
        else:
            assert [new_board + board_index] =  [board + board_index]    
        end
    end
    return ()
end

func filter_legal_moves (
        raw_moves_list: Move*, raw_moves_list_size: felt, board: felt*,
        meta: Meta) -> (legal_moves_list: Move*, legal_moves_list_size: felt):
    alloc_locals
    let (local legal_moves_list : Move*) = alloc()

    if raw_moves_list_size == 0:
        return(legal_moves_list = legal_moves_list, legal_moves_list_size = 0)
    end
    # Recursive call
    let (legal_moves_list, legal_moves_list_size) = filter_legal_moves (raw_moves_list, raw_moves_list_size - 1, board, meta)
    # Get current move
    let current_move : Move = [raw_moves_list + (raw_moves_list_size - 1) * Move.SIZE]

    tempvar board_index = current_move.origin.col + current_move.dest.row * 8
    tempvar current_piece = [board + board_index]

    # Make the move
    let (local new_board : felt*) = make_move (board, current_move, meta)

    # Get counterattacks
    let (local new_active_color) = change_active_color(meta.active_color)

    let new_meta : Meta = Meta (new_active_color, meta.castling_K, meta.castling_Q, meta.castling_k, meta.castling_q, meta.passant)
    let (attack_list, attack_list_size) = calculate_all_attacks (new_board, 0, 0, new_meta)

    # Check if king is attacked
    tempvar colored_king = WKing + meta.active_color * 8 
    let (kings_square) = get_square_of_piece (new_board, 63, colored_king)
    let (king_is_attacked) = check_final_square (attack_list, attack_list_size, kings_square)

    tempvar add_move = -1 * (king_is_attacked - 1)

    if add_move == 1:
        add_move_blind (legal_moves_list, legal_moves_list_size, current_move)
        return (legal_moves_list, legal_moves_list_size + 1)
    end

    # If is not (legal move) add current_move to legal_moves_list and return
    return (legal_moves_list, legal_moves_list_size)
end

func calculate_legal_moves (board: felt*, meta: Meta) -> (legal_moves_list: Move*, legal_moves_list_size: felt):
    alloc_locals

    let (raw_moves_list : Move*) = alloc()
    let (raw_moves_list, raw_moves_list_size) = calculate_raw_moves (board, 0, 0, meta)
    let (legal_moves_list, legal_moves_list_size) = filter_legal_moves (raw_moves_list, raw_moves_list_size, board, meta)
    
    return (legal_moves_list, legal_moves_list_size)
end

func is_legal_move (board: felt*, meta: Meta, move: Move) -> (is_legal: felt):
    alloc_locals

    let (local new_board : felt*) = make_move (board, move, meta)

    # Get counterattacks
    let (new_active_color) = change_active_color(meta.active_color)

    let new_meta : Meta = Meta (new_active_color, meta.castling_K, meta.castling_Q, meta.castling_k, meta.castling_q, meta.passant)
    let (attack_list, attack_list_size) = calculate_all_attacks (new_board, 0, 0, new_meta)

    let (moves_list, moves_list_size) = calculate_moves_wrapper(board, meta, move.origin)
    let (is_in_moves_list) = contains_move (moves_list, moves_list_size, move)
    if is_in_moves_list == 0:
        return (is_legal = 0)
    end

    # Check if king is attacked
    tempvar colored_king = WKing + meta.active_color * 8 
    let (kings_square) = get_square_of_piece (new_board, 63, colored_king)
    let (king_is_attacked) = check_final_square (attack_list, attack_list_size, kings_square)

    let (serialized_move) = serialize_move(move)

    let (initial_square_color) = square_content (board, move.origin)

    # Check if active color and the piece moving are both white / black
    if meta.active_color == 0:
        if initial_square_color != 1:
            return (is_legal = 0)
        end
    end

    if meta.active_color == 1:    
        if initial_square_color != 2:
            return (is_legal = 0)
        end
    end

    tempvar initial_square_board_index = move.origin.col + move.origin.row * 8
    tempvar current_piece = [board + initial_square_board_index]

    tempvar white_promotion_cond = (current_piece - WPawn + 1) * (move.origin.row)
    if white_promotion_cond != 1:
        if move.extra != 0:
            return (is_legal = 0)
        end
    end

    tempvar black_promotion_cond = (current_piece - BPawn + 1) * (move.origin.row - 5)
    if current_piece != 29:
        if move.origin.row != 6:
            if move.extra != 0:
                return (is_legal = 0)
            end
        end
    end

    if serialized_move == 47670:
        let (castling_allowed) = castling_K_allowed(board, meta)
        if castling_allowed == 1:
            return (is_legal = 1)
        else:
            return (is_legal = 0)
        end
    end
    if serialized_move == 47270:
        let (castling_allowed) = castling_Q_allowed(board, meta)
        if castling_allowed == 1:
            return (is_legal = 1)
        else:
            return (is_legal = 0)
        end
    end
    if serialized_move == 40600:
        let (castling_allowed) = castling_k_allowed(board, meta)
        if castling_allowed == 1:
            return (is_legal = 1)
        else:
            return (is_legal = 0)
        end
    end
    if serialized_move == 40200:
        let (castling_allowed) = castling_q_allowed(board, meta)
        if castling_allowed == 1:
            return (is_legal = 1)
        else:
            return (is_legal = 0)
        end
    end
    tempvar is_legal = 1 - king_is_attacked 

    return (is_legal = is_legal)
end

# Returns 1 if the square is attacked
func is_in_check(board: felt*, square: Square, meta: Meta) -> (square_is_attacked: felt):
    alloc_locals

    let (local new_active_color) = change_active_color(meta.active_color)
    let new_meta : Meta = Meta (new_active_color, meta.castling_K, meta.castling_Q, meta.castling_k, meta.castling_q, meta.passant)
    let (attack_list, attack_list_size) = calculate_all_attacks (board, 0, 0, new_meta)
    local tested_square_index = square.col + square.row * 8
    let (local tested_square) = get_square_of_piece (board, 63, tested_square_index)

    let (square_is_attacked) = check_final_square (attack_list, attack_list_size, tested_square_index)

    return(square_is_attacked = square_is_attacked)
end

# The following four functions check the conditions for every sort of castling. They are needed in more than one context,
# so they are in separated functions.
func castling_K_allowed(board: felt*, meta: Meta) -> (castling_allowed: felt):
    alloc_locals

    tempvar active_color = meta.active_color
    tempvar general_condition = (active_color + 1) * ([board + 60] - 19) * ([board + 61] + 1) * ([board + 62] + 1) * ([board + 63] - 15)
    let (local no_check_on_e1) = is_in_check (board, Square(7, 4), meta)
    let (local no_check_on_f1) = is_in_check (board, Square(7, 5), meta)
    let (local no_check_on_g1) = is_in_check (board, Square(7, 6), meta)
    tempvar castling_allowed = (1 - no_check_on_e1) * (1 - no_check_on_f1) * (1 - no_check_on_g1) * general_condition

    return (castling_allowed = castling_allowed)
end

func castling_Q_allowed(board: felt*, meta: Meta) -> (castling_allowed: felt):
    alloc_locals
    
    tempvar active_color = meta.active_color
    tempvar general_condition = (active_color + 1) * ([board + 59] + 1) * ([board + 58] + 1) * ([board + 56] - 15) * ([board + 60] - 19)
    let (no_check_on_e1) = is_in_check (board, Square (7, 4), meta)
    let (no_check_on_d1) = is_in_check (board, Square (7, 3), meta)
    let (no_check_on_c1) = is_in_check (board, Square (7, 2), meta)
    tempvar castling_allowed = (1 - no_check_on_e1) * (1 - no_check_on_d1) * (1 - no_check_on_c1) * general_condition

    return (castling_allowed = castling_allowed)
end

func castling_k_allowed(board: felt*, meta: Meta) -> (castling_allowed: felt):
    alloc_locals
    
    tempvar active_color = meta.active_color
    tempvar general_condition = (active_color) * ([board + 6] + 1) * ([board + 5] + 1) * ([board + 7] - 23) * ([board + 4] - 27)
    let (no_check_on_e8) = is_in_check (board, Square (0, 4), meta)
    let (no_check_on_f8) = is_in_check (board, Square (0, 5), meta)
    let (no_check_on_g8) = is_in_check (board, Square (0, 6), meta)
    tempvar castling_allowed = (1 - no_check_on_e8) * (1 - no_check_on_f8) * (1 - no_check_on_g8) * general_condition

    return (castling_allowed = castling_allowed)
end

func castling_q_allowed(board: felt*, meta: Meta) -> (castling_allowed: felt):
    alloc_locals
    
    tempvar active_color = meta.active_color
    tempvar general_condition = (active_color) * ([board + 3] + 1) * ([board + 2] + 1) * ([board] - 23) * ([board + 4] - 27)
    let (no_check_on_e8) = is_in_check (board, Square (0, 4), meta)
    let (no_check_on_d8) = is_in_check (board, Square (0, 3), meta)
    let (no_check_on_c8) = is_in_check (board, Square (0, 2), meta)
    tempvar castling_allowed = (1 - no_check_on_e8) * (1 - no_check_on_d8) * (1 - no_check_on_c8) * general_condition

    return (castling_allowed = castling_allowed)
end

# Function that return the result of the game:
# pending: 0
# white checkmate: 1
# black checkmate: 2
# stalemate: 3 
func calculate_status (board: felt*, meta: Meta) -> (status: felt):
    alloc_locals

    tempvar active_color = meta.active_color
    # Get counterattacks
    let (local new_active_color) = change_active_color(active_color)    
    let new_meta : Meta = Meta (new_active_color, meta.castling_K, meta.castling_Q, meta.castling_k, meta.castling_q, meta.passant)
    let (attack_list, attack_list_size) = calculate_all_attacks (board, 0, 0, new_meta)

    # Check if king is attacked
    tempvar colored_king = WKing + active_color * 8 
    let (kings_square) = get_square_of_piece (board, 63, colored_king)
    let (king_is_attacked) = check_final_square (attack_list, attack_list_size, kings_square)

    let (local legal_moves_list: Move*) = alloc()
    let (legal_moves_list, legal_moves_list_size) = calculate_legal_moves (board, meta)

    tempvar white_checkmated = king_is_attacked * (legal_moves_list_size + 1) * (active_color + 1)
    if white_checkmated == 1:
        return (status = 2)
    end

    tempvar black_checkmated = king_is_attacked * (legal_moves_list_size + 1) * (active_color)
    if black_checkmated == 1:
        return (status = 1)
    end

    tempvar white_stalemated = (king_is_attacked + 1) * (legal_moves_list_size + 1) * (active_color + 1)
    if white_stalemated == 1:
        return (status = 3)
    end

    tempvar black_stalemated = (king_is_attacked + 1) * (legal_moves_list_size + 1) * (active_color)
    if black_stalemated == 1:
        return (status = 3)
    end    

    return(status = 0)
end
