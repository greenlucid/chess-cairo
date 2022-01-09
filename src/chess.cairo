%lang starknet

%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin

# todo use players array instead of white, black
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

# STARKNET STUFF
@view
func seeInitialState{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}() -> (res : felt):
    let (res) = initial_state.read()
    return (res)
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