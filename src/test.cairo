%builtins output range_check bitwise 

from src.decoder import (
    decode_state
)
from src.encoder import encode_state
from src.state import State
from src.service import (
    check_legality,
    calculate_result
)
from src.advance_state import (
    advance_state
)

from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin

func serialize_array{output_ptr: felt*}(arr : felt*, size : felt) -> ():
    if size == 0:
        return ()
    end
    let pos = [arr]
    serialize_word(pos)
    serialize_array(arr+1, size-1)
    return ()
end

func serialize_state{output_ptr: felt*}(state : State) -> ():
    serialize_array(state.positions, 64)
    serialize_word(11111111111111111111111111111111)
    serialize_word(state.active_color)
    serialize_word(state.castling_K)
    serialize_word(state.castling_Q)
    serialize_word(state.castling_k)
    serialize_word(state.castling_q)
    serialize_word(state.passant)
    serialize_word(state.halfmove_clock)
    serialize_word(state.fullmove_clock)
    return ()
end

# Don't run this test if you don't know what you're doing
# 2 million steps (4 GB ram, minutes of computation)
func main{output_ptr : felt*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}():
    alloc_locals
    const encoding = 0x633adf359c77bdef7bde8000000056b5ad6b5ac2329d25183e0000040000000
    serialize_word(encoding)
    let (local state) = decode_state(encoding)
    serialize_state(state)
    serialize_word(6666666666666666666666666666666)
    let (local reencoding) = encode_state(state)
    serialize_word(reencoding)
    serialize_word(222222222222222222222222222222222)
    # Test legality
    const move_e4 = 13456
    const move_e2_to_f4 = 13460
    const move_e4_alt = 13457 # like, "promotion"
    let (local legality) = check_legality(state, move_e4)
    let (local legality_2) = check_legality(state, move_e2_to_f4)
    let (local legality_3) = check_legality(state, move_e4_alt)
    serialize_word(legality) # expect 1
    serialize_word(legality_2) # expect 0
    serialize_word(legality_3) # expect 0
    # Test advance state after e4
    serialize_word(777777777777777777777777777777777777777777)
    serialize_word(777777777777777777777777777777777777777777)
    let (local next_state) = advance_state(state, move_e4)
    serialize_state(next_state)
    # Test encoding this new state
    serialize_word(777777777777777777777777777777777777777777)
    serialize_word(777777777777777777777777777777777777777777)
    let (local reencoding_2) = encode_state(next_state)
    serialize_word(reencoding_2)
    # Test finality of the game
    serialize_word(777777777777777777777777777777777777777777)
    serialize_word(777777777777777777777777777777777777777777)
    let (local finality) = calculate_result(next_state)
    serialize_word(finality)
    return ()
end
