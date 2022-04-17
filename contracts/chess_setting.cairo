from starkware.cairo.common.alloc import alloc

from contracts.structs import Setting

const WRook = 16
const WKnight = 17
const WBishop = 18 
const WQueen = 19
const WKing = 20
const WPawn = 21 
const BRook = 24 
const BKnight = 25
const BBishop = 26
const BQueen = 27
const BKing = 28
const BPawn = 29

# WORKING WITH SETTINGS
func add_setting (list: Setting*, list_size: felt, setting: Setting)->(new_size: felt):
    assert([list + list_size * Setting.SIZE]) = setting
    return(new_size = list_size + 1)
end

# Blind setting
func add_setting_blind (list: Setting*, list_size: felt, setting: Setting):
    assert([list + list_size * Setting.SIZE]) = setting
    return()
end

func add_settings_lists (list: Setting*, list_size: felt, list_to_add: Setting*, list_to_add_size: felt) -> (new_size: felt):
    if list_to_add_size == 0:
        return(new_size = list_size)
    end
    let (new_size) = add_settings_lists(list, list_size, list_to_add, list_to_add_size - 1)
    # Index calculations
    tempvar new_list_index = (list_size  + list_to_add_size - 1) * Setting.SIZE
    tempvar list_to_add_index = (list_to_add_size - 1) * Setting.SIZE
    # Saving new setting in the list
    assert([list + new_list_index]) = [list_to_add + list_to_add_index]
    return(new_size = new_size + 1)
end

# Search Function
# Returns the piece corresponding to a square, according to a given setting, or 0 if not found.
func get_piece_in_square (settings: Setting*, settings_size: felt, board_square: felt) -> (piece: felt):
    # Exit condition
    if settings_size == 0:
        return (piece = 0)
    end
    # Defining ptr for index clarity
    let settings_ptr = settings_size - 1
    # Retriving the setting pointed by settings_ptr
    let current_setting = [settings + Setting.SIZE * settings_ptr]
    # Calculating the corresponding square (lineal)
    let settings_square = current_setting.square
    # Checking correspondence between the reference square and the current square and retrieving the piece in case of success
    tempvar condition = (board_square - settings_square.col - settings_square.row * 8) + 1
    if condition == 1:
        return (piece = current_setting.piece)
    end
    # Else: we keep recursively looking, jumping (descending) to the next element of the settings
    let (piece) = get_piece_in_square (settings, settings_size - 1, board_square)
    return (piece = piece)
end
