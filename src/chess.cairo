%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import {
    assert_lt
    assert_le
}

from contracts.state import {
    State
}

from contracts.decoder import {
    decode_state
}

from contracts.encoder import {
    encode_state
    encode_board_state
}

from starkware.starknet.common.syscalls import {
    get_contract_address
}

# 0 is white
# 1 is black
# 2 is governor
@storage_var
func players(color : felt) -> (address : felt):
end

@storage_var
func initial_state() -> (state : felt):
end

@storage_var
func moves(i : felt) -> (move : felt):
end

# Understanding finality:
# To keep things simple, the value of this storage_var is the finality.
# 0 is PENDING, 1 is WHITE_WIN, 2 is BLACK_WIN, 3 is DRAW
@storage_var
func finality() -> (status : felt):
end

# The turn (ply) in which a side offers a draw
# If a side proposes draw and the other side had this flag set at
# the current turn, finalize game as a draw.
# Otherwise, set flag.
# You cannot draw at turn 0.
# Side 0 is white, whereas side 1 is black.
@storage_var
func draw_offer(color : felt) -> (ply : felt):
end

# So, you don't actually need to store how many moves there are.
# You can find this dynamically
# Because the move 0x0 is illegal. So, just iterate until you find a zero
# And when you find it, return that i.
func move_counter(i : felt) -> (count : felt):
    let (move) = moves.read(i)
    if move == 0:
        return (count=i)
    end
    let (count) = move_counter(i+1)
    return (count=count)
end

# Filler funcs. Substitute them when we get the proper funcs

func state_after_move(state : State, move : felt) -> (next_state : State):
    # TODO
    return ()
end

# Helper funcs

func state_advancer(state : State, curr : felt, remain : felt) -> (final_state : State):
    if remain == 0:
        return (final_state=state)
    end
    let (move) = moves.read(curr)
    # this is a struct so it may break
    let (next_state) = state_after_move(state, move)
    let (final_state) = state_advancer(state=next_state, curr+1, remain-1)
    return (final_state=final_state)
end

func actual_state() -> (state : felt):
    let (encoded_state) = initial_state.read()
    let (first_state) = decode_state(encoded_state)
    let (n) = n_moves()
    let (state) = state_advancer(first_state, curr=0, remain=n)
    return (state=state)
end

func assert_sender_is(color : felt) -> ():
    let (sender) = get_contract_address()
    let (governor) = players.read(color)
    assert governor == sender
    return ()
end

func assert_pending() -> ():
    let (current_finality) = finality.read()
    assert current_finality == 0
    return ()
end

func other_player(player : felt) -> (other : felt):
    if player == 0:
        return (other=1)
    end
    if player == 1:
        return (other=0)
    end
    return (other=2)
end 

# VIEW FUNCS

@view
func current_state{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}() -> (state : felt):
    let (state) = actual_state()
    let (encoded_state) = encode_state(state)
    return (state=encoded_state)
end

@view
func n_moves() -> (count : felt):
    let (count) = move_counter(i=0)
    return (count=count)
end

# Use this (with n calls) to see the game history in frontend
@view
func move_at(i : felt) -> (move : felt):
    let (move) = moves.read(i)
    return (move)
end
 
@view
func get_finality() -> (finality : felt):
    let (status) = finality.read()
    return (finality=status)
end

# EXTERNALS

@external
func make_move(move : felt, as_player : felt) -> ():
    alloc_locals
    assert_pending()
    assert_sender_is(as_player)
    let (local state) = actual_state()
    assert as_player == state.active_color
    
    # TODO Get list of possible moves
    # TODO iterate through and check if move is in the list
    # After asserting all this:
    let (move_count) = n_moves()
    moves.write(move_count, move)
    # get the finality of the state after this move, and write it.
    return ()
end

# For when finality is known due to external factors. e.g. timeout
# A cleaner way would be to not have this feature
# let the wrapper contract deal with it, and let chess.cairo be pure.
# this argument could be made to most funcs below.
@external
func force_finality(forced_finality : felt) -> ():
    assert_pending()
    assert_sender_is(2)
    finality.write(forced_finality)
    # todo assert that forced_finality <= 3
    return ()
end

@external
func surrender(as_player : felt) -> ():
    assert_pending()
    assert_sender_is(as_player)
    # governor shouldn't call this
    assert as_player != 2
    if as_player == 0: 
        # white surrendered
        finality.write(2)
        return ()
    end
    # black surrendered
    finality.write(1)
    return ()
end

@external
func offer_draw(as_player : felt) -> ():
    assert_pending()
    assert_sender_is(as_player)
    # governor shouldn't call this
    assert as_player != 2
    # check if other player already offered
    let (other) = other_player(as_player)
    let (move_count) = move_counter(i=0)
    # drawing at move 0 is banned
    assert move_count != 0
    let (other_offer) = draw_offer.read(other)
    if move_count == other_offer:
        # both sides just agreed to a draw.
        finality.write(3)
        return ()
    end
    # that means caller is first to propose draw this turn.
    draw_offer.write(as_player, move_count)
    return ()
end

@external
func draw_threefold_repetition(as_player : felt, a : felt, b : felt, c : felt) -> ():
    alloc_locals
    assert_pending()
    assert_sender_is(as_player)
    # governor shouldn't call this
    assert as_player != 2

    # assert a < b; b < c; c < n_moves
    let (n) = move_counter(i=0)
    assert_lt(a, b)
    assert_lt(b, c)
    assert_lt(c, n)

    let (encoded_state) = initial_state.read()
    let (first_state) = decode_state(encoded_state)
    let (state_a) = state_advancer(state=first_state, curr=0, remain=a)
    let (local fa) = encode_board_state(state_a)
    let (state_b) = state_advancer(state=first_state, curr=0, remain=b)
    let (local fb) = encode_board_state(state_b)
    let (state_c) = state_advancer(state=first_state, curr=0, remain=c)
    let (local fb) = encode_board_state(state_c)

    assert fa == fb
    assert fb == fc
    finality.write(3)
    return ()
end

@external
func draw_fifty_moves(as_player : felt) -> ():
    assert_pending()
    asser_sender_is(as_player)
    # governor shouldn't call this
    assert as_player != 2

    let (state) = actual_state()
    # assert that state.halfmove_clock is >= 100
    let halfmove_clock = state.halfmove_clock
    assert_le(100, halfmove_clock)
    finality.write(3)
    return ()
end

# constructed with white, black, governor, initial_state to storage.
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(_white : felt, _black : felt, _governor : felt, _initial_state : felt):
    players.write(0, _white)
    players.write(1, _black)
    players.write(2, _governor)
    initial_state.write(_initial_state)
    return ()
end
