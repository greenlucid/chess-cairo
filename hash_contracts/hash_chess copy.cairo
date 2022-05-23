# Makes more sense to start from scratch

from starkware.cairo.common.hash_state import hash_init, hash_update 
from starkware.cairo.common.cairo_builtins import HashBuiltin

struct Game:
    member hash_state : felt
    member result : felt
end

@storage_var
func game_count() -> (count : felt):
end

@storage_var
func games(i : felt) -> (game : Game):
end

## Todo:
## we will drop encoding and decoding the state in this way
## we will instead treat it as an array of 72 elements.
## reason being, it takes ~60 bitwise ops to decode (~700 gas).
## plus a bunch of steps.
## whereas it could take 72 pedersens instead (<10 gas).

@external
func create_game{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(_white : felt, _black : felt,
        _governor : felt, _initial_state_len : felt,
        _initial_state : felt*) -> (game_id : felt):
    alloc_locals
    ### Create an array encoding the state
    let (state) = alloc()
    # Players
    assert [state] = _white
    assert [state + 1] = _black
    assert [state + 2] = _governor
    # [Number of states, initial state]
    assert [state + 3] = 1
    assert [state + 4] = _initial_state
    # Draw offering of white and black
    assert [state + 5] = 0
    assert [state + 6] = 0

    ### Create the hash

    let (hash_state_ptr) = hash_init()
    let (hash_state_ptr) = hash_update{hash_ptr=pedersen_ptr}(hash_state_ptr, state, 7) # len is 7
    let hash_state = hash_state_ptr.current_hash

    ### Create the game

    let (local game_id) = game_count.read()

    # todo emit event of the game

    let game = Game(hash_state=hash_state, result=0)

    games.write(game_id, game)
    game_count.write(game_id + 1)

    return (game_id=game_id)
end
