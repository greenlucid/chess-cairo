%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.pow import pow

from contracts.state import {
    State
}

from contracts.bit_helper import {
    append_bits
}

func encode_pos(encoded_state : felt, offset : felt, arr : felt*, size : felt) -> (encoded_state : felt, offset : felt):
    alloc_locals
    if size == 0:
        return (encoded_state, offset)
    end

    let tile = [arr]
    # tile is empty
    if tile == 0:
        # encoded_state starts as 0x0, there is nothing to add.
        let (local returned_state, local offset) = encode_pos(encoded_state, offset+1, arr+1, size-1)
        return (encoded_state=returned_state, offset=offset)
    end
    # else, tile contains a piece
    let (new_encoded_state) = append_bits(pre=encoded_state, offset, el=tile, size=5)
    let (local returned_state, local offset) = encode_pos(new_encoded_state, offset+5, arr+1, size-1)
    return (encoded_state=returned_state, offset=offset)
end

func encode_state(state : State) -> (encoded_state : felt):
    alloc_locals
    # state.pos prob doesn't exist, figure this out
    let (local pos_state, local pos_offset) = encode_pos(encoded_state=0, offset=0, arr=state.pos, size=64)
    # offsets are not variable from this point, so they are hardcoded as magic numbers
    let (local active_color_state) = append_bits(pre=pos_state, pos_offset, state.active_color, size=1)
    let (local castling_K_state) = append_bits(pre=active_color_state, pos_offset+1, state.castling_K, size=1)
    let (local castling_Q_state) = append_bits(pre=castling_K_state, pos_offset+2, state.castling_Q, size=1)
    let (local castling_k_state) = append_bits(pre=castling_Q_state, pos_offset+3, state.castling_k, size=1)
    let (local castling_q_state) = append_bits(pre=castling_k_state, pos_offset+4, state.castling_q, size=1)
    let (local passant_state) = append_bits(pre=castling_q_state, pos_offset+5, state.passant, size=4)
    let (local halfmove_state) = append_bits(pre=passant_state, pos_offset+9, state.halfmove_clock, size=7)
    let (local fullmove_state) = append_bits(pre=halfmove_state, pos_offset+16, state.fullmove_clock, size=13)

    return (encoded_state=fullmove_state)
end