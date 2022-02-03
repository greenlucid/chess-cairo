# CHESS CAIRO SERVICE
from core import is_legal_move

struct State:
    member positions : felt*
    member active_color : felt
    member castling_K : felt
    member castling_Q : felt
    member castling_k : felt
    member castling_q : felt
    member passant : felt
    member halfmove_clock : felt
    member fullmove_clock : felt
end

func check_legality{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        state: State, move: felt) -> (is_legal: felt):
    let castle_code = state.castling_K * 8 + state.castling_Q * 4 + state.castling_k * 2 + state.castling_q
    let en_passant_code = state.passant + 16 + 24 * state.active_color
    let (result) = is_legal_move(state.positions, castle_code, en_passant_code, move)
    
    return(is_legal = result)
end

func advance_positions{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        positions: felt*, move: felt)->(resulting_position: felt*):
    alloc_locals
    let (local result) = alloc()
    make_move(position, result, move)
    return(resulting_position = result)
end

# Function returns the result of the game:
# pending: 0
# white checkmate: 1
# black checkmate: 2
# draw: 3 (stalemate, insufficient material) 
func calculate_result{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        state: State)->(result: felt):
    let castle_code = state.castling_K * 8 + state.castling_Q * 4 + state.castling_k * 2 + state.castling_q
    let en_passant_code = state.passant 
    let side_to_move = state.active_color
    let (status) = calculate_status(state.positions, side_to_move, castle_code,  en_passant_square)

    return(result = status)
end
    