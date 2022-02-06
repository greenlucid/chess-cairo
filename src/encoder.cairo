from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.pow import pow

from src.state import State

from src.bit_helper import (
    append_bits,
    bits_at
)

func encode_pos{
        range_check_ptr
        }(encoded_state : felt, offset : felt, arr : felt*, size : felt) ->
        (encoded_state : felt, offset : felt):
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
    let (new_encoded_state) = append_bits(pre=encoded_state, offset=offset, el=tile, size=5)
    let (local returned_state, local offset) = encode_pos(new_encoded_state, offset+5, arr+1, size-1)
    return (encoded_state=returned_state, offset=offset)
end

func encode_state{
        range_check_ptr
        }(state : State) -> (encoded_state : felt):
    alloc_locals
    # state.pos prob doesn't exist, figure this out
    let (pos_state, local pos_offset) = encode_pos(encoded_state=0, offset=0, arr=state.positions, size=64)
    # offsets are not variable from this point, so they are hardcoded as magic numbers
    let (active_color_state) = append_bits(pre=pos_state, offset=pos_offset, el=state.active_color, size=1)
    let (castling_K_state) = append_bits(pre=active_color_state, offset=pos_offset+1, el=state.castling_K, size=1)
    let (castling_Q_state) = append_bits(pre=castling_K_state, offset=pos_offset+2, el=state.castling_Q, size=1)
    let (castling_k_state) = append_bits(pre=castling_Q_state, offset=pos_offset+3, el=state.castling_k, size=1)
    let (castling_q_state) = append_bits(pre=castling_k_state, offset=pos_offset+4, el=state.castling_q, size=1)
    let (passant_state) = append_bits(pre=castling_q_state, offset=pos_offset+5, el=state.passant, size=4)
    let (halfmove_state) = append_bits(pre=passant_state, offset=pos_offset+9, el=state.halfmove_clock, size=7)
    let (fullmove_state) = append_bits(pre=halfmove_state, offset=pos_offset+16, el=state.fullmove_clock, size=13)

    return (encoded_state=fullmove_state)
end

func encode_board_state{
        bitwise_ptr : BitwiseBuiltin*, range_check_ptr
        }(state: State) -> (encoded_board_state : felt):
    alloc_locals
    let (_, local pos_offset) = encode_pos(encoded_state=0, offset=0, arr=state.positions, size=64)
    let size = pos_offset + 9
    let (encoded_state) = encode_state(state)
    # the total size is pos_offset + 29
    # the size of board state is pos_offset + 9
    # just extract it.
    let (encoded_board_state) = bits_at(el=encoded_state, offset=0, size=size)
    return (encoded_board_state=encoded_board_state)
end