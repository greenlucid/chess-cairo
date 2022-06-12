# Makes more sense to start from scratch
%lang starknet

from starkware.cairo.common.hash_state import hash_init, hash_update, hash_update_single
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.alloc import alloc

from starkware.starknet.common.syscalls import (
    get_caller_address
)

from starkware.cairo.common.math import (
    assert_nn,
    assert_lt,
    assert_le,
    assert_nn_le,
    assert_not_equal,
    assert_not_zero
)

from contracts.structs import State, Move, Square

from contracts.advance_state import advance_state
from contracts.decoder import get_last_fen, get_n_fen
from contracts.encoder import append_fen, copy_array, fen_to_array
from contracts.service import (
    check_legality,
    calculate_result
)

const PENDING = 0
const WHITE_WIN = 1
const BLACK_WIN = 2
const DRAW = 3

const FEN_COUNT_OFFSET = 6
const FELTS_PER_FEN = 72

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

@event
func create_game_called(game_id : felt, state_len : felt, state : felt*):
end

@event
func move_called(game_id : felt, fen_len : felt, fen : felt*):
end

@event
func surrender_called(game_id : felt, as_player : felt):
end

@event
func offer_draw_called(game_id : felt, as_player : felt):
end

@event
func force_threefold_draw_called(game_id : felt):
end

@event
func force_fifty_moves_draw_called(game_id : felt):
end

@event
func write_result_called(game_id : felt, result : felt):
end

@event
func force_result_called(game_id : felt, result : felt):
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

    let game = Game(hash_state=hash_state, result=0)

    games.write(game_id, game)
    game_count.write(game_id + 1)

    # event
    create_game_called.emit(game_id, state_len, state)

    return (game_id=game_id)
end

func write_result{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*,
        range_check_ptr}(game_id : felt, state_len : felt, state : felt*) -> (result : felt):
    alloc_locals
    let (current_fen) =  get_last_fen(state)
    let (local result) = calculate_result(current_fen)
    let (game) = games.read(game_id)
    let game = Game(hash_state=game.hash_state, result=result)
    games.write(game_id, game)

    # event
    write_result_called.emit(game_id, result)

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

    # event
    force_result_called.emit(game_id, forced_result)

    return (forced_result)
end

func move{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*,
        range_check_ptr}(game_id : felt, game : Game, state_len : felt, state : felt*, action : felt*) -> (is_valid : felt):
    alloc_locals
    let only_check = [action + 2]
    let start_y = [action + 3]
    let start_x = [action + 4]
    let end_y = [action + 5]
    let end_x = [action + 6]
    let extra = [action + 7]
    local move_struct : Move = Move(
        origin=Square(row=start_y, col=start_x),
        dest=Square(row=end_y, col=end_x),
        extra=extra
    )
    let (local fen_state) = get_last_fen(state)
    let (local is_valid) = check_legality(fen_state, move_struct)
    if only_check == 1:
        return (is_valid=is_valid)
    end
    # write it
    assert is_valid = 1
    let (new_fen_state) = advance_state(fen_state, move_struct)
    let (new_state_len, new_state) = append_fen(state_len, state, new_fen_state)

    let (hash_state_ptr) = hash_init()
    let (hash_state_ptr) = hash_update{hash_ptr=pedersen_ptr}(hash_state_ptr, new_state, new_state_len)
    let hash_state = hash_state_ptr.current_hash
    let game = Game(hash_state=hash_state, result=0)
    games.write(game_id, game)

    let (emission_fen) = fen_to_array(new_fen_state)
    move_called.emit(game_id, 72, emission_fen)

    return (is_valid=is_valid)
end

func surrender{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*,
        range_check_ptr}(game_id : felt, as_player : felt, hash_state : felt) -> (result : felt):
    if as_player == 0:
        # white surrender, so it's black win
        let game : Game = Game(hash_state=hash_state, result=BLACK_WIN)
        games.write(game_id, game)
        # event
        surrender_called.emit(game_id, as_player)
        return (BLACK_WIN)
    end

    ## so, as player is black. white win.
    let game : Game = Game(hash_state=hash_state, result=WHITE_WIN)
    games.write(game_id, game)
    # event
    surrender_called.emit(game_id, as_player)
    return (WHITE_WIN)
end

func offer_draw{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*,
        range_check_ptr}(game_id : felt, as_player : felt, state_len : felt,
        state : felt*, hash_state : felt) -> (result : felt):
    alloc_locals
    let other_player = 1 - as_player
    let other_draw_offer = [state + 5 + other_player]
    if other_draw_offer == 1:
        ## write result as a draw and escape
        let game : Game = Game(hash_state=hash_state, result=DRAW)
        games.write(game_id, game)
        return (DRAW)
    end

    ## create new state with the offer
    let (local new_state) = alloc()
    copy_array(state, new_state, 4)
    assert [state + 4 + as_player] = 1
    assert [state + 4 + other_player] = 0
    copy_array(state + 6, new_state + 6, state_len - 6)
    ## hash the state
    let (hash_state_ptr) = hash_init()
    let (hash_state_ptr) = hash_update{hash_ptr=pedersen_ptr}(hash_state_ptr, new_state, state_len)
    let hash_state = hash_state_ptr.current_hash
    let game = Game(hash_state=hash_state, result=PENDING)
    games.write(game_id, game)

    # event
    offer_draw_called.emit(game_id, as_player)

    return (PENDING)
end

func force_threefold_draw{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*,
        range_check_ptr}(a : felt, b : felt, game_id : felt,
        state : felt*, hash_state : felt) -> (result : felt):
    alloc_locals
    # assert 0 <= a < b; b < c; (with c being current move)
    local c = [state + 6] - 1
    assert_nn(a)
    assert_lt(a, b)
    assert_lt(b, c)

    local fen_a_pointer = FEN_COUNT_OFFSET + a * FELTS_PER_FEN
    let fen_b_pointer = FEN_COUNT_OFFSET + b * FELTS_PER_FEN
    let fen_c_pointer = FEN_COUNT_OFFSET + c * FELTS_PER_FEN

    const REPETITION_FELTS = 70 # everything except the two counters
    ## copy array just asserts two arrays.
    copy_array(state + fen_a_pointer, state + fen_b_pointer, REPETITION_FELTS)
    copy_array(state + fen_a_pointer, state + fen_c_pointer, REPETITION_FELTS)
    ## because of transitive relation, fen_b and fen_c are also the same.
    ## write result
    let game = Game(hash_state=hash_state, result=DRAW)
    games.write(game_id, game)

    # event
    force_threefold_draw_called.emit(game_id)

    return (DRAW)
end

func force_fifty_moves_draw{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*,
        range_check_ptr}(game_id : felt, state : felt*, hash_state : felt) -> (result : felt):
    alloc_locals
    let (local fen_state) = get_last_fen(state)
    const FIFTY_MOVE_THRESHOLD = 100
    assert_le(FIFTY_MOVE_THRESHOLD, fen_state.halfmove_clock)
    ## passed the test, write result
    let game = Game(hash_state=hash_state, result=DRAW)
    games.write(game_id, game)

    # event
    force_fifty_moves_draw_called.emit(game_id)

    return (DRAW)
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
        let (create_game_response) = alloc()
        assert [create_game_response] = game_id
        return (1, create_game_response)
    end

    ### From this point on, all actions must have correct state
    ### and occur in an unfinalized game.

    local game_id = [state]
    let (local game) = games.read(game_id)
    assert game.result = PENDING
    let (hash_state_ptr) = hash_init()
    let (hash_state_ptr) = hash_update{hash_ptr=pedersen_ptr}(hash_state_ptr, state, state_len)
    local hash_state = hash_state_ptr.current_hash
    assert game.hash_state = hash_state

    ### State and result verified.

    # write_result does not need to assert the player, so it goes first
    if action_type == WRITE_RESULT:
        let (game_result) = write_result(game_id, state_len, state)
        let (write_result_response) = alloc()
        assert [write_result_response] = game_result
        return (1, write_result_response)
    end

    # force result does not need to assert player either 
    if action_type == FORCE_RESULT:
        let (local force_result_result) = force_result(game_id, game, state, action)
        
        let (force_result_response) = alloc()
        assert [force_result_response] = force_result_result
        return (1, force_result_response)
    end

    ### From this point on, all actions require to assert the player

    local as_player = [action + 1]
    let (local sender) = get_caller_address()
    assert sender = [state + 1 + as_player]
    
    if action_type == MOVE:
        let (local is_valid) = move(game_id, game, state_len, state, action)
        let (move_response) = alloc()
        assert [move_response] = is_valid
        return (1, move_response)
    end

    if action_type == SURRENDER:
        let (surrender_result) = surrender(game_id, as_player, hash_state)
        let (surrender_response) = alloc()
        assert [surrender_response] = surrender_result
        return (1, surrender_response)
    end

    if action_type == OFFER_DRAW:
        let (local offer_draw_result) = offer_draw(game_id, as_player, state_len, state, hash_state)
        let (offer_draw_response) = alloc()
        assert [offer_draw_response] = offer_draw_result
        return (1, offer_draw_response)
    end

    if action_type == FORCE_THREEFOLD_DRAW:
        let a = [action + 2]
        let b = [action + 3]
        let (local threefold_result) = force_threefold_draw(
            a, b, game_id, state, hash_state)
        let (threefold_response) = alloc()
        assert [threefold_response] = threefold_result
        return (1, threefold_response)
    end

    if action_type == FORCE_FIFTY_MOVES_DRAW:
        let (local fifty_result) = force_fifty_moves_draw(game_id, state, hash_state)
        let (fifty_response) = alloc()
        assert [fifty_response] = fifty_result
        return (1, fifty_response)
    end

    ### Unknown action type. Return an array with the error code.
    let (error_result) = alloc()
    assert [error_result] = 666
    return (1, error_result)
end