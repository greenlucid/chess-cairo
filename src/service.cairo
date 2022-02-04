from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.alloc import alloc

from src.core import (
    is_legal_move,
    make_move,
    calculate_status
)

from src.state import State

func check_legality{bitwise_ptr : BitwiseBuiltin*}(
        state : State, move : felt) -> (is_legal : felt):
    let castle_code = state.castling_K * 8 + state.castling_Q * 4 + state.castling_k * 2 + state.castling_q
    let en_passant_code = state.passant + 16 + 24 * state.active_color
    let (result) = is_legal_move(state.positions, castle_code, en_passant_code, move)
    
    return(is_legal = result)
end

func advance_positions{bitwise_ptr : BitwiseBuiltin*}(
        positions : felt*, move : felt)->(resulting_position : felt*):
    alloc_locals
    let (local result) = alloc()
    make_move(positions, result, move)
    return(resulting_position = result)
end

func calculate_result{bitwise_ptr : BitwiseBuiltin*}(
        state : State)->(result : felt):
    let castle_code = state.castling_K * 8 + state.castling_Q * 4 + state.castling_k * 2 + state.castling_q
    let en_passant_code = state.passant + 16 + 24 * state.active_color 
    let side_to_move = state.active_color
    let (status) = calculate_status(state.positions, side_to_move, castle_code, en_passant_code)

    return(result = status)
end
    