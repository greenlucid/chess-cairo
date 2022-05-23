# Makes more sense to start from scratch
%lang starknet

from starkware.cairo.common.hash_state import hash_init, hash_update, hash_update_single
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.alloc import alloc

from hash_contracts.decoder import get_latest_fen
from contracts.service import (
    check_legality,
    calculate_result
)
from starkware.starknet.common.syscalls import (
    get_caller_address
)

const PENDING = 0
const WHITE_WIN = 1
const BLACK_WIN = 2
const DRAW = 3

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

### This function doesn't validate the state
func create_game{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(state_len : felt, state : felt*) -> (game_id : felt):
    
    alloc_locals

    ### Create hash of the game

    # First felt is game_id
    let (local game_id) = game_count.read()
    let (hash_state_ptr) = hash_init()
    let (hash_state_ptr) = hash_update_single{hash_ptr=pedersen_ptr}(hash_state_ptr, game_id)
    # The rest is the state passed as array
    let (hash_state_ptr) = hash_update{hash_ptr=pedersen_ptr}(hash_state_ptr, state, state_len)
    let hash_state = hash_state_ptr.current_hash

    ### Create the game

    # todo emit event of the game

    let game = Game(hash_state=hash_state, result=0)

    games.write(game_id, game)
    game_count.write(game_id + 1)

    return (game_id=game_id)
end

func write_result{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*,
        range_check_ptr}(game_id : felt, state_len : felt, state : felt*) -> (result : felt):
    alloc_locals
    let (current_fen) =  get_latest_fen(state_len, state)
    let (local result) = calculate_result(current_fen)
    let (game) = games.read(game_id)
    let game = Game(hash_state=game.hash_state, result=result)
    games.write(game_id, game)
    return (result)
end

func force_result{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*,
        range_check_ptr}(game_id : felt, game : Game, state : felt*, action : felt*) -> (result : felt):
    alloc_locals
    # assert this is governor
    let (sender) = get_caller_address()
    assert [state + 3] = sender

    let forced_result = [action + 1]

    let game = Game(hash_state=game.hash_state, result=forced_result)
    games.write(game_id, game)
    return (forced_result)
end

# Action types
const CREATE_GAME = 0
const MOVE = 1
const SURRENDER = 2
const OFFER_DRAW = 3
const FORCE_THREEFOLD_DRAW = 4
const FORCE_FIFTY_MOVES_DRAW = 5
const WRITE_RESULT = 6
const FORCE_RESULT = 7

@external
func act{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        bitwise_ptr : BitwiseBuiltin*, range_check_ptr
        }(state_len : felt, state : felt*,
        action_len : felt, action : felt*) -> (response_len : felt, response : felt*):
    alloc_locals

    local action_type = [action]

    if action_type == CREATE_GAME:
        let (game_id) = create_game(state_len, state)
        let (result) = alloc()
        assert [result] = game_id
        return (1, result)
    end

    ### From this point on, all actions must have correct state
    ### and occur in an unfinalized game.

    local game_id = [state]
    let (local game) = games.read(game_id)
    assert game.result = PENDING
    let (hash_state_ptr) = hash_init()
    let (hash_state_ptr) = hash_update{hash_ptr=pedersen_ptr}(hash_state_ptr, state, state_len)
    let hash_state = hash_state_ptr.current_hash
    assert game.hash_state = hash_state

    ### State and result verified.

    # write_result does not need to assert the player, so it goes first
    if action_type == WRITE_RESULT:
        let (game_result) = write_result(game_id, state_len, state)
        let (action_return) = alloc()
        assert [action_return] = game_result
        return (1, action_return)
    end

    # force result does not need to assert player either 
    if action_type == FORCE_RESULT:
        let (local force_result_response) = force_result(game_id, game, state, action)
        
        let (response) = alloc()
        assert [response] = force_result_response
        return (1, response)
    end

    ### From this point on, all actions require to assert the player

    local as_player = [action + 1]
    let (local sender) = get_caller_address()
    assert sender = [state + 1 + as_player]
    

    ### Unknown action type. Return an array with the error code.
    let (error_result) = alloc()
    assert [error_result] = 666
    return (1, error_result)
end