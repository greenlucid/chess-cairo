%lang starknet

%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin

from contracts.state import {
    State
}

from contracts.decoder import {
    decode_state
}

from contracts.encoder import {
    encode_state
}

@storage_var
func white() -> (address : felt):
end

@storage_var
func black() -> (address : felt):
end

@storage_var
func arbitrator() -> (address : felt):
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
func make_move(move : felt) -> ():
    let (current_finality) = finality.read()
    assert current_finality == 0
    let (state) = actual_state()
    # TODO Get active_color. Depending on the color, get an address.
    # and validate that msg.sender is that address
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
    # todo verify sender is arbitrator
    let (current_finality) = finality.read()
    assert current_finality == 0
    finality.write(forced_finality)
    return ()
end

@external
func surrender() -> ():
    let (current_finality) = finality.read()
    assert current_finality == 0
    # see sender.
    # check if sender is white
    # if so, finality <- 2
    # otherwise, check if sender is black
    # if so, finality <- 1
    # otherwise
    # finality <- 0 (status quo)
    return ()
end

@external
func offer_draw() -> ():
    # big todo. this will need a storage_var flag somewhere.
    return ()
end

@external
func draw_threefold_repetition(a : felt, b : felt, c : felt) -> ():
    # big todo. wrote something about how to do this, but lost it.
    let (current_finality) = finality.read()
    assert current_finality == 0
    # assert sender is black or white
    # assert a < b; b < c; c < n_moves
    # let f be a func to get encoded x, that is rightshifted by enough bits
    # to get all bits except the clocks
    # assert f(a) == f(b); f(b) == f(c)

    finality.write(3)
    return ()
end

@external
func draw_fifty_moves() -> ():
    let (current_finality) = finality.read()
    assert current_finality == 0
    # assert that sender is black or white
    let (state) = actual_state()
    # assert that state.halfmove_clock is >= 100
    finality.write(3)
    return ()
end

# constructed with white, black, arbiter, initial_state to storage.
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(_white : felt, _black : felt, _arbitrator : felt, _initial_state : felt):
    white.write(_white)
    black.write(_black)
    arbitrator.write(_arbitrator)
    initial_state.write(_initial_state)
    return ()
end

# TODOS
# make func for "a is b, is c, or none?", useful for a few funcs
# actually, be careful. what if white and black are the exact same?
# then you can't call surrender. (but again, why would you surrender against yourself?)
# just to deal with that case, make sender use an arg to explain who they are.