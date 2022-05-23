from starkware.cairo.common.alloc import alloc

from contracts.structs import (
    State
)

const N_POSITIONS = 64

func assert_positions(state : felt*, state_pointer : felt, positions : felt*, i : felt) -> ():
    if i == N_POSITIONS:
        return ()
    end
    assert [positions + i] = [state + state_pointer + i]
    assert_positions(state, state_pointer, positions, i + 1)
    return ()
end

const FEN_COUNT_OFFSET = 4
const FELTS_PER_FEN = 72

func get_latest_fen(state_len : felt, state : felt*) -> (fen_state : State):
    alloc_locals
    let fen_count = [state + FEN_COUNT_OFFSET]
    local last_fen_start = FEN_COUNT_OFFSET + FELTS_PER_FEN * fen_count

    let (local positions) = alloc()
    assert_positions(state, last_fen_start, positions, 0)
    tempvar data_start = last_fen_start + N_POSITIONS
    local active_color = [state + data_start]
    local castling_K = [state + data_start + 1]
    local castling_Q = [state + data_start + 2]
    local castling_k = [state + data_start + 3]
    local castling_q = [state + data_start + 4]
    local passant = [state + data_start + 5]
    local halfmove_clock = [state + data_start + 6]
    local fullmove_clock = [state + data_start + 7]

    local fen_state : State = State(positions, active_color, castling_K, castling_Q,
        castling_k, castling_q, passant, halfmove_clock, fullmove_clock)
    return (fen_state)
end