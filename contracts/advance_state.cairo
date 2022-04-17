from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.alloc import alloc

from contracts.structs import (
    State,
    Move,
    Square
)

from contracts.bit_helper import bits_at

from contracts.chess_utils import (
    encode_move,
    point_to_felt
)

from contracts.service import advance_positions

const WHITE = 0
const BLACK = 1

const WHITE_PAWN = 21
const BLACK_PAWN = 29

const NO_PASSANT = 8

const a8 = 0
const e8 = 4
const h8 = 7
const a1 = 56
const e1 = 60
const h1 = 63

func advance_active_color(prev_active_color : felt) -> (next_active_color : felt):
    if prev_active_color == WHITE:
        return (next_active_color=BLACK)
    end
    return (next_active_color=WHITE)
end

# About castlings
# no need to check who's moving
# if the origin contained a piece that was of the "other side"
# then that castling wasn't possible anyway
# just check if the move is of a certain origin
func advance_castling_K(prev_castling : felt, origin : felt) -> (next_castling : felt):
    if origin == a1:
        return (next_castling=0)
    end
    if origin == e1:
        return (next_castling=0)
    end
    return (next_castling=prev_castling)
end

func advance_castling_Q(prev_castling : felt, origin : felt) -> (next_castling : felt):
    if origin == e1:
        return (next_castling=0)
    end
    if origin == h1:
        return (next_castling=0)
    end
    return (next_castling=prev_castling)
end

func advance_castling_k(prev_castling : felt, origin : felt) -> (next_castling : felt):
    if origin == a8:
        return (next_castling=0)
    end
    if origin == e8:
        return (next_castling=0)
    end
    return (next_castling=prev_castling)
end

func advance_castling_q(prev_castling : felt, origin : felt) -> (next_castling : felt):
    if origin == e8:
        return (next_castling=0)
    end
    if origin == h8:
        return (next_castling=0)
    end
    return (next_castling=prev_castling)
end

func advance_passant{
        bitwise_ptr : BitwiseBuiltin*, range_check_ptr
        }(prev_positions : felt*, move : Move, enc_origin : felt) -> (next_passant : felt):
    alloc_locals
    # check if piece in origin is pawn
    let piece = [prev_positions+enc_origin]
    if piece == WHITE_PAWN:
        jmp distance_check
    end
    if piece == BLACK_PAWN:
        jmp distance_check
    end
    return (next_passant=NO_PASSANT)
    distance_check:
    local distance = move.origin.row - move.dest.row
    if distance == 2:
        jmp considered_passant
    end
    if distance == -2:
        jmp considered_passant
    end
    return (next_passant=NO_PASSANT)

    considered_passant:
    # move is OOOOOODDDDDDEE (6 origin, 6 dest, 2 extra)
    # 14 total. 251 - 14 -> 237
    # you want to get the col, each point has 3 bits (RRRCCC)
    # so col is in bits [240, 242]
    let col = move.origin.col
    return (next_passant=col)
end

func was_move_irreversible{
        bitwise_ptr : BitwiseBuiltin*, range_check_ptr
        }(prev_positions : felt*, move : Move) -> (reply : felt):
    alloc_locals
    let (enc_origin) = point_to_felt(move.origin)
    let piece = [prev_positions + enc_origin]
    # is it pawn?
    if piece == WHITE_PAWN:
        return (reply=1)
    end
    if piece == BLACK_PAWN:
        return (reply=1)
    end

    # is it taking a piece?
    let (enc_dest) = point_to_felt(move.dest)
    let landing = [prev_positions + enc_dest]
    if landing == 0:
        return (reply=0)
    end
    # then, it took a piece
    return (reply=1)
end

func advance_halfmove_clock{
        bitwise_ptr : BitwiseBuiltin*, range_check_ptr
        }(prev_positions : felt*, move : Move, prev_clock : felt) -> (next_clock : felt):
    let (irreversible) = was_move_irreversible(prev_positions, move)
    if irreversible == 1:
        return (next_clock=0)
    end
    # check if it's the maximum value. if so, don't increment.
    # in the future, how about putting more (like 1000) instead? it could be interesting for computers
    # playing against themselves
    if prev_clock == 100:
        return (next_clock=100)
    end
    return (next_clock=prev_clock+1)
end

func advance_fullmove_clock(prev_active_color : felt, prev_clock : felt) -> (next_clock : felt):
    if prev_clock == 8191:
        return (prev_clock) # prevents overflow. treat this as Infinity
    end
    if prev_active_color == 1:
        return (prev_clock + 1)
    end
    return (prev_clock)
end


func advance_state{
        bitwise_ptr : BitwiseBuiltin*, range_check_ptr
        }(state : State, move : Move) -> (next_state : State):
    alloc_locals
    let (local next_positions) = advance_positions(state=state, move=move)
    let (local next_active_color) = advance_active_color(state.active_color)
    let (local enc_origin) = point_to_felt(move.origin)
    let (local next_castling_K) = advance_castling_K(state.castling_K, enc_origin)
    let (local next_castling_Q) = advance_castling_Q(state.castling_Q, enc_origin)
    let (local next_castling_k) = advance_castling_k(state.castling_k, enc_origin)
    let (local next_castling_q) = advance_castling_q(state.castling_q, enc_origin)
    let (local next_passant) = advance_passant(state.positions, move, enc_origin)
    let (local next_halfmove_clock) = advance_halfmove_clock(state.positions, move, state.halfmove_clock)
    let (local next_fullmove_clock) = advance_fullmove_clock(state.active_color, state.fullmove_clock)

    local next_state : State = State(positions=next_positions, active_color=next_active_color,
        castling_K=next_castling_K, castling_Q=next_castling_Q, castling_k=next_castling_k, castling_q=next_castling_q,
        passant=next_passant, halfmove_clock=next_halfmove_clock, fullmove_clock=next_fullmove_clock)
    
    return (next_state=next_state)
end
