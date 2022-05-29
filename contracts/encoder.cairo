from starkware.cairo.common.alloc import alloc

from contracts.structs import (
    State,
    Move,
    Meta,
    Square
)

func copy_array(a : felt*, b : felt*, len : felt) -> ():
    if len == 0:
        return ()
    end
    assert [a] = [b]
    copy_array(a + 1, b + 1, len - 1)
    return ()
end


### encode fen_state onto array of 72 felts
func fen_to_array(fen_state : State) -> (fen_arr : felt*):
    alloc_locals
    let (local fen_arr) = alloc()
    ### Asserting positions (long)
    assert [fen_arr + 0] = [fen_state.positions + 0]
    assert [fen_arr + 1] = [fen_state.positions + 1]
    assert [fen_arr + 2] = [fen_state.positions + 2]
    assert [fen_arr + 3] = [fen_state.positions + 3]
    assert [fen_arr + 4] = [fen_state.positions + 4]
    assert [fen_arr + 5] = [fen_state.positions + 5]
    assert [fen_arr + 6] = [fen_state.positions + 6]
    assert [fen_arr + 7] = [fen_state.positions + 7]
    assert [fen_arr + 8] = [fen_state.positions + 8]
    assert [fen_arr + 9] = [fen_state.positions + 9]
    assert [fen_arr + 10] = [fen_state.positions + 10]
    assert [fen_arr + 11] = [fen_state.positions + 11]
    assert [fen_arr + 12] = [fen_state.positions + 12]
    assert [fen_arr + 13] = [fen_state.positions + 13]
    assert [fen_arr + 14] = [fen_state.positions + 14]
    assert [fen_arr + 15] = [fen_state.positions + 15]
    assert [fen_arr + 16] = [fen_state.positions + 16]
    assert [fen_arr + 17] = [fen_state.positions + 17]
    assert [fen_arr + 18] = [fen_state.positions + 18]
    assert [fen_arr + 19] = [fen_state.positions + 19]
    assert [fen_arr + 20] = [fen_state.positions + 20]
    assert [fen_arr + 21] = [fen_state.positions + 21]
    assert [fen_arr + 22] = [fen_state.positions + 22]
    assert [fen_arr + 23] = [fen_state.positions + 23]
    assert [fen_arr + 24] = [fen_state.positions + 24]
    assert [fen_arr + 25] = [fen_state.positions + 25]
    assert [fen_arr + 26] = [fen_state.positions + 26]
    assert [fen_arr + 27] = [fen_state.positions + 27]
    assert [fen_arr + 28] = [fen_state.positions + 28]
    assert [fen_arr + 29] = [fen_state.positions + 29]
    assert [fen_arr + 30] = [fen_state.positions + 30]
    assert [fen_arr + 31] = [fen_state.positions + 31]
    assert [fen_arr + 32] = [fen_state.positions + 32]
    assert [fen_arr + 33] = [fen_state.positions + 33]
    assert [fen_arr + 34] = [fen_state.positions + 34]
    assert [fen_arr + 35] = [fen_state.positions + 35]
    assert [fen_arr + 36] = [fen_state.positions + 36]
    assert [fen_arr + 37] = [fen_state.positions + 37]
    assert [fen_arr + 38] = [fen_state.positions + 38]
    assert [fen_arr + 39] = [fen_state.positions + 39]
    assert [fen_arr + 40] = [fen_state.positions + 40]
    assert [fen_arr + 41] = [fen_state.positions + 41]
    assert [fen_arr + 42] = [fen_state.positions + 42]
    assert [fen_arr + 43] = [fen_state.positions + 43]
    assert [fen_arr + 44] = [fen_state.positions + 44]
    assert [fen_arr + 45] = [fen_state.positions + 45]
    assert [fen_arr + 46] = [fen_state.positions + 46]
    assert [fen_arr + 47] = [fen_state.positions + 47]
    assert [fen_arr + 48] = [fen_state.positions + 48]
    assert [fen_arr + 49] = [fen_state.positions + 49]
    assert [fen_arr + 50] = [fen_state.positions + 50]
    assert [fen_arr + 51] = [fen_state.positions + 51]
    assert [fen_arr + 52] = [fen_state.positions + 52]
    assert [fen_arr + 53] = [fen_state.positions + 53]
    assert [fen_arr + 54] = [fen_state.positions + 54]
    assert [fen_arr + 55] = [fen_state.positions + 55]
    assert [fen_arr + 56] = [fen_state.positions + 56]
    assert [fen_arr + 57] = [fen_state.positions + 57]
    assert [fen_arr + 58] = [fen_state.positions + 58]
    assert [fen_arr + 59] = [fen_state.positions + 59]
    assert [fen_arr + 60] = [fen_state.positions + 60]
    assert [fen_arr + 61] = [fen_state.positions + 61]
    assert [fen_arr + 62] = [fen_state.positions + 62]
    assert [fen_arr + 63] = [fen_state.positions + 63]
    ### Assert other data
    assert [fen_arr + 64] = fen_state.active_color
    assert [fen_arr + 65] = fen_state.castling_K
    assert [fen_arr + 66] = fen_state.castling_Q
    assert [fen_arr + 67] = fen_state.castling_k
    assert [fen_arr + 68] = fen_state.castling_q
    assert [fen_arr + 69] = fen_state.passant
    assert [fen_arr + 70] = fen_state.halfmove_clock
    assert [fen_arr + 71] = fen_state.fullmove_clock

    return (fen_arr)
end

### func append_felt, that takes a state felt, and a fen_state:
### - update fen_counter
### - encode the fen_state, and append the array to the end
### - set both drawing flags to 0
func append_fen(state_len : felt, state : felt*, fen_state : State) ->
        (new_state_len : felt, new_state : felt*):
    alloc_locals
    let (local new_state) = alloc()
    # game id, players and governor
    assert [new_state + 0] = [state + 0]
    assert [new_state + 1] = [state + 1]
    assert [new_state + 2] = [state + 2]
    assert [new_state + 3] = [state + 3]
    # draw requests go back to zero
    assert [new_state + 4] = 0
    assert [new_state + 5] = 0
    # fen count increases
    assert [new_state + 6] = [state + 6] + 1
    # to get the len of state array, remove 7 initial metadatas
    tempvar fen_array_len = state_len - 7
    copy_array(state + 7, new_state + 7, fen_array_len)

    # append last fen. it has len 72
    let (local last_fen_array) = fen_to_array(fen_state)
    copy_array(last_fen_array, new_state + state_len, 72)
    let new_state_len = state_len + 72

    return (new_state_len, new_state)
end
