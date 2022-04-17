%builtins output range_check bitwise 

from contracts.decoder import (
    decode_state
)
from contracts.encoder import encode_state
from contracts.structs import State
from contracts.service import (
    check_legality,
    calculate_result
)
from contracts.advance_state import (
    advance_state
)
from contracts.chess_utils import (
    parse_move
)
from contracts.chess_console_utils import show_state

from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin

func main{output_ptr : felt*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}():
    alloc_locals
    # encoding - decoding
    const encoding = 0x633adf359c77bdef7bde8000000056b5ad6b5ac2329d25183e0000040000000
    let (local state) = decode_state(encoding)
    let (local reencoding) = encode_state(state)
    %{
        print(f'encoding: {ids.encoding}')
        print(f'reencoding: {ids.reencoding}')
    %}

    # legality
    const enc_move_e4 = 13456
    let (local move_e4) = parse_move(enc_move_e4)

    let (local legality) = check_legality(state, move_e4)
    %{
        print(f'legality of e4: {ids.legality}')
    %}

    show_state(state)

    # Test advance state after e4
    let (local next_state) = advance_state(state, move_e4)
    show_state(next_state)

    # Test encoding this new state
    let (local reencoding_2) = encode_state(next_state)
    %{
        print(f'reencoding2: {ids.reencodisrc.ng_2}')
    %}

    # Test result of the state
    let (local finality) = calculate_result(next_state)
    %{
        print(f'finality: {ids.finality}')
    %}

    return ()
end
