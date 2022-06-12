from starkware.cairo.common.alloc import alloc

from contracts.structs import Move

func add_moves_lists (
        moves_list_1: Move*, moves_list_1_size: felt, moves_list_2: Move*, moves_list_2_size: felt, index: felt):
    alloc_locals
    let (local moves_list : Move*) = alloc()
    if index == moves_list_2_size:
        return()
    end
    add_move_blind(moves_list_1, moves_list_1_size + index, [moves_list_2 + index * Move.SIZE])
    add_moves_lists(moves_list_1, moves_list_1_size, moves_list_2, moves_list_2_size, index + 1)
    return()
end

func add_move (moves_list: Move*, moves_list_size: felt, move: Move) -> (new_size: felt):
    assert [moves_list + moves_list_size * Move.SIZE] = move
    return (new_size = moves_list_size + 1)
end

# When you have set in stone the list you want to generate, just use this and don't forget to have your own counter.
func add_move_blind (moves_list: Move*, moves_list_size: felt, move: Move):
    assert [moves_list + moves_list_size * Move.SIZE] = move
    return ()
end

# Good for comparing moves.
func serialize_move (move: Move) -> (serialized_move: felt):
    tempvar serialized_move = move.origin.col * 10000 + move.origin.row * 1000 + move.dest.col * 100 + move.dest.row * 10 + move.extra
    return (serialized_move = serialized_move)
end 

func contains_move (moves_list: Move*, moves_size: felt, ref_move: Move) -> (contains : felt):
    if moves_size == 0:
        return (contains = 0)
    end
    let current_move = [moves_list + (moves_size - 1) * Move.SIZE]
    let (current_serial) = serialize_move(current_move)
    let (reference_serial) = serialize_move(ref_move)
    if current_serial == reference_serial:
        return (contains = 1)
    end
    let (contains) = contains_move (moves_list, moves_size - 1, ref_move)
    return (contains = contains)
end
