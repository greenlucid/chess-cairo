from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.pow import pow

from src.state import (
    State
)

from src.bit_helper import (
    bits_at,
    bit_at
)

func decode_pos{
        bitwise_ptr : BitwiseBuiltin*, range_check_ptr
        }(encoded_state : felt, arr : felt*, offset : felt, size : felt) -> (offset : felt):
    if size == 0:
        return (offset=offset)
    end
    
    let (bit) = bit_at(el=encoded_state, offset=offset)
    # there's no piece.
    if bit == 0:
        assert [arr] = 0
        # maybe this needs to be local, test later
        let (new_offset) = decode_pos(encoded_state, arr+1, offset+1, size-1)
        return (offset=new_offset)
    end
    # else, it's a piece. pieces take 5 spaces.
    let (bits) = bits_at(el=encoded_state, offset=offset, size=5)
    assert [arr] = bits
    let (new_offset) = decode_pos(encoded_state, arr+1, offset+5, size-1)
    return (offset=new_offset)
end

func decode_active_color{
        bitwise_ptr : BitwiseBuiltin*, range_check_ptr
        }(encoded_state : felt, offset : felt) -> (active_color : felt):
    let (bit) = bit_at(el=encoded_state, offset=offset)
    return (color=bit)
end

func decode_state{
        bitwise_ptr : BitwiseBuiltin*, range_check_ptr
        }(encoded_state : felt) -> (state : State):
    alloc_locals
    let (positions) = alloc()
    let (local pos_offset) = decode_pos(encoded_state, arr=positions, offset=0, size=64)
    # offsets are not variable from this point, so they are hardcoded as magic numbers
    let (local active_color) = bit_at(encoded_state, pos_offset) # 1 bit
    let (local castling_K) = bit_at(encoded_state, pos_offset+1) # 1 bit
    let (local castling_Q) = bit_at(encoded_state, pos_offset+2) # 1 bit
    let (local castling_k) = bit_at(encoded_state, pos_offset+3) # 1 bit
    let (local castling_q) = bit_at(encoded_state, pos_offset+4) # 1 bit
    let (local passant) = bits_at(encoded_state, pos_offset+5, size=4) # 4 bits
    let (local halfmove_clock) = bits_at(encoded_state, pos_offset+9, size=7) # 7 bits
    let (local fullmove_clock) = bits_at(encoded_state, pos_offset+16, size=13) # 13 bits

    local state : State = State(positions, active_color, castling_K, castling_Q,
        castling_k, castling_q, passant, halfmove_clock, fullmove_clock)

    return (state=state)
end