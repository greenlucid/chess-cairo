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

    let (result) = is_legal_move(board, move)

    return(is_legal = result)
end

func advance_positions{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        positions: felt*, move: felt)->(resulting_position: felt*):
    alloc_locals
    let (local result) = alloc()

    return(resulting_position = result)
end

# Function returns the result of the game:
# pending: 0
# white checkmate: 1
# black checkmate: 2
# draw: 3 (stalemate, insufficient material) 
func calculate_result{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(
        state: State)->(result: felt):
    return(result = 0)
end
    