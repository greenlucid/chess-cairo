from starkware.cairo.common.alloc import alloc

from contracts.structs import Setting

from contracts.chess_setting import get_piece_in_square

# WORKING WITH THE BOARD
# Constructing a board (array of 64 felts) out of a number of settings
func board_loader (settings: Setting*, settings_size: felt) -> (board: felt*):
    alloc_locals

    let (local board) = alloc()
    load_settings_into_board (settings, settings_size, board, 64) 

    return (board = board)
end

# Recursive function for filling the array board with pieces as described by a particular setting. All other squares are zeros.
func load_settings_into_board (settings: Setting*, settings_size: felt, board: felt*, board_size: felt):
    # Exit condition
    if board_size == 0:
        return ()
    end
    # Defining ptr for index clarity
    let board_ptr = board_size - 1
    # Retrieves the piece corresponding to the current square
    let (current_piece) = get_piece_in_square(settings, settings_size, board_ptr)
    # Setting the piece in the correspnding place of the board array
    assert ([board + board_ptr]) = current_piece
    # Recursive call: keeps descending until every index in board is asserted
    load_settings_into_board (settings, settings_size, board, board_size - 1)
    return ()
end

# Here you can see one of the fundamental problems of this project. It's easy to calculate the index starting
# with the square coordinates: board_index = col + row * 8, but it's not easy to do it efficently the other
# way around in Cairo. Ok, maybe you could use a function with 64 dws or using some division or bitwise construction...
# but it's not clear at all that those approachess will win against simple math computations.
# Some heavy testing needed, probably.  
func get_square_of_piece (board: felt*, board_index: felt, piece: felt) -> (square_index: felt):
    if board_index == -1:
        return(64)
    end
    if [board + board_index] == piece:
        return (square_index = board_index)
    end
    let (square_index) = get_square_of_piece (board, board_index - 1, piece)
    return (square_index = square_index)
end
