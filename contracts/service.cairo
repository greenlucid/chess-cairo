from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.alloc import alloc

from contracts.core import (
    is_legal_move,
    make_move,
    calculate_status
)

from contracts.chess_utils import get_square

from contracts.structs import (
    State,
    Move,
    Meta,
    Square
)

func check_legality{bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(
        state : State, move : Move) -> (is_legal : felt):
    alloc_locals
    let (local passant_square : Square) = get_square(state.passant + 16 + 24 * state.active_color)
    let meta : Meta = Meta(active_color = state.active_color, castling_K = state.castling_K, castling_Q = state.castling_Q,
        castling_k = state.castling_k, castling_q = state.castling_q, passant = passant_square) 
    let board : felt* = state.positions
    let (result) = is_legal_move(board, meta, move)
    
    return(is_legal = result)
end

func advance_positions{bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(
        state : State, move : Move)->(resulting_position : felt*):
    alloc_locals
    let (local passant_square : Square) = get_square(state.passant + 16 + 24 * state.active_color)
    let meta : Meta = Meta (active_color = state.active_color, castling_K = state.castling_K, castling_Q = state.castling_Q,
        castling_k = state.castling_k, castling_q = state.castling_q, passant = passant_square) 
    let board : felt* = state.positions
    let (local result : felt*) = make_move(board, move, meta)
    return(resulting_position = result)
end

func calculate_result{bitwise_ptr : BitwiseBuiltin*, range_check_ptr}(
        state : State)->(result : felt):
    alloc_locals
    let (local passant_square : Square) = get_square(state.passant + 16 + 24 * state.active_color)
    let meta : Meta = Meta (active_color = state.active_color, castling_K = state.castling_K, castling_Q = state.castling_Q,
        castling_k = state.castling_k, castling_q = state.castling_q, passant = passant_square) 
    let board : felt* = state.positions
    let (status) = calculate_status(board, meta)

    return(result = status)
end