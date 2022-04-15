%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.math import (
    assert_nn,
    assert_lt,
    assert_le,
    assert_nn_le,
    assert_not_equal,
    assert_not_zero
)

from starkware.starknet.common.syscalls import (
    get_caller_address
)

from structs import State
from advance_state import advance_state

from decoder import decode_state

from encoder import (
    encode_state,
    encode_board_state
)

from service import (
    check_legality,
    calculate_result
)

from chess_utils import parse_move

const WHITE = 0
const BLACK = 1
const GOVERNOR = 2

@storage_var
func players(i : felt) -> (address : felt):
end

@storage_var
func initial_state() -> (state : felt):
end

@storage_var
func moves(i : felt) -> (move : felt):
end

const PENDING = 0
const WHITE_WIN = 1
const BLACK_WIN = 2
const DRAW = 3

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

# Helper funcs

func state_advancer{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        bitwise_ptr : BitwiseBuiltin*, range_check_ptr
        }(state : State, curr : felt, remain : felt) -> (final_state : State):
    if remain == 0:
        return (final_state=state)
    end
    alloc_locals
    let (enc_move) = moves.read(curr)
    let (move) = parse_move(enc_move)
    # this is a struct so it may break
    let (next_state) = advance_state(state, move)
    let (final_state) = state_advancer(next_state, curr+1, remain-1)
    return (final_state=final_state)
end

func actual_state{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        bitwise_ptr : BitwiseBuiltin*, range_check_ptr}() -> (state : State):
    alloc_locals
    let (encoded_state) = initial_state.read()
    let (first_state) = decode_state(encoded_state)
    let (n) = n_moves()
    let (state) = state_advancer(first_state, curr=0, remain=n)
    return (state=state)
end

func assert_sender_is{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(color : felt) -> ():
    let (sender) = get_caller_address()
    let (player) = players.read(color)
    assert player = sender
    return ()
end

func assert_pending{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}() -> ():
    let (current_finality) = finality.read()
    assert current_finality = PENDING
    return ()
end

func other_player(player : felt) -> (other : felt):
    if player == WHITE:
        return (other=BLACK)
    end
    if player == BLACK:
        return (other=WHITE)
    end
    return (other=GOVERNOR)
end

func regular_player_asserts{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(as_player : felt) -> ():
    assert_pending()
    assert_sender_is(as_player)
    assert_not_equal(as_player, GOVERNOR)
    return ()
end

# So, you don't actually need to store how many moves there are.
# The move 0x0 is illegal. Just iterate until you find a zero
func move_counter{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(i : felt) -> (count : felt):
    alloc_locals
    let (move) = moves.read(i)
    if move == 0:
        return (count=i)
    end
    let (count) = move_counter(i+1)
    return (count=count)
end

# VIEW FUNCS

@view
func get_player{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(i : felt) -> (player : felt):
    let (player) = players.read(i)
    return (player=player)
end

@view
func current_state{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        bitwise_ptr : BitwiseBuiltin*, range_check_ptr}() -> (state : felt):
    alloc_locals
    let (state) = actual_state()
    let (encoded_state) = encode_state(state)
    return (state=encoded_state)
end

@view
func n_moves{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}() -> (count : felt):
    let (count) = move_counter(i=0)
    return (count=count)
end

# Use this (with n calls) to see the game history in frontend
@view
func move_at{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(i : felt) -> (move : felt):
    let (move) = moves.read(i)
    return (move)
end
 
@view
func get_finality{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}() -> (finality : felt):
    let (status) = finality.read()
    return (finality=status)
end

# EXTERNALS

@external
func make_move{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        bitwise_ptr : BitwiseBuiltin*, range_check_ptr
        }(enc_move : felt, as_player : felt) -> ():
    alloc_locals
    regular_player_asserts(as_player)
    let (local state) = actual_state()
    assert as_player = state.active_color

    let (local move) = parse_move(enc_move)
    let (legality) = check_legality(state, move)
    assert legality = 1

    let (move_count) = n_moves()
    moves.write(move_count, enc_move)
    return ()
end

@external
func write_result{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        bitwise_ptr : BitwiseBuiltin*, range_check_ptr
        }() -> ():
    alloc_locals
    let (current_finality) = finality.read()
    assert current_finality = 0

    let (local state) = actual_state()
    let (local result) = calculate_result(state)
    finality.write(result)
    return ()
end

# For when finality is known due to external factors. e.g. timeout
@external
func force_finality{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(forced_finality : felt) -> ():
    alloc_locals
    assert_pending()
    assert_sender_is(GOVERNOR)
    assert_nn_le(forced_finality, 3)
    finality.write(forced_finality)
    return ()
end

@external
func surrender{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(as_player : felt) -> ():
    alloc_locals
    regular_player_asserts(as_player)
    if as_player == 0: 
        # white surrendered
        finality.write(BLACK_WIN)
        return ()
    end
    # black surrendered
    finality.write(WHITE_WIN)
    return ()
end

@external
func offer_draw{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(as_player : felt) -> ():
    alloc_locals
    regular_player_asserts(as_player)
    # check if other player already offered
    let (other) = other_player(as_player)
    let (move_count) = move_counter(i=0)
    # drawing at move 0 is banned
    assert_not_zero(move_count)
    let (other_offer) = draw_offer.read(other)
    if move_count == other_offer:
        # both sides just agreed to a draw.
        finality.write(DRAW)
        return ()
    end
    # that means caller is first to propose draw this turn.
    draw_offer.write(as_player, move_count)
    return ()
end

@external
func draw_threefold_repetition{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        bitwise_ptr : BitwiseBuiltin*, range_check_ptr
        }(as_player : felt, a : felt, b : felt) -> ():
    alloc_locals
    regular_player_asserts(as_player)
    # assert 0 <= a < b; b < c; (with c being current move)
    let (c) = move_counter(i=0)
    assert_nn(a)
    assert_lt(a, b)
    assert_lt(b, c)

    let (encoded_state) = initial_state.read()
    let (first_state) = decode_state(encoded_state)
    let (state_a) = state_advancer(state=first_state, curr=0, remain=a)
    let (local fa) = encode_board_state(state_a)
    let (state_b) = state_advancer(state=first_state, curr=0, remain=b)
    let (local fb) = encode_board_state(state_b)
    let (state_c) = state_advancer(state=first_state, curr=0, remain=c)
    let (local fc) = encode_board_state(state_c)

    assert fa = fb
    assert fb = fc
    finality.write(DRAW)
    return ()
end

@external
func draw_fifty_moves{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        bitwise_ptr : BitwiseBuiltin*, range_check_ptr
        }(as_player : felt) -> ():
    regular_player_asserts(as_player)
    let (state) = actual_state()
    # assert that state.halfmove_clock is >= 100
    let halfmove_clock = state.halfmove_clock
    assert_le(100, halfmove_clock)
    finality.write(DRAW)
    return ()
end

@constructor
func constructor{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*,
        range_check_ptr}(_white : felt, _black : felt, _governor : felt, _initial_state : felt):
    players.write(WHITE, _white)
    players.write(BLACK, _black)
    players.write(GOVERNOR, _governor)
    initial_state.write(_initial_state)
    return ()
end
