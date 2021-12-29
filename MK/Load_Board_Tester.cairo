%builtins output bitwise

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and, bitwise_xor
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.serialize import serialize_word


# -----------------------------------------------------------------
# DICTIONARY STRUCTURE 
# Returns the input truncating 8 bit on the right
func truncate_eight_bit{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(input: felt)->(res:felt):
    let (input_last_eight_bit) = bitwise_and(input, 0xFF)
    tempvar input_minus_last_eight_bit = input - input_last_eight_bit
    tempvar res1 = input_minus_last_eight_bit / 0x100
    return (res=res1) 
end

# Return value based on key
func eight_bit_dict{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(dict: felt*, dict_size: felt, key:felt) -> (res:felt):
    if dict_size == 0:
        return (res=0)
    end
    let (current_key) =  truncate_eight_bit([dict])
    if current_key == key:
        let (value) = bitwise_and([dict], 0xFF)
        return(res=value)
    else:
        let (result) = eight_bit_dict(dict+1, dict_size-1, key)
    end
    return(res=result)
end
# END OF DICTIONARY STRUCTURE 
# -----------------------------------------------------------------

# -----------------------------------------------------------------
# BOARD LOADER - USING DICTIONARY
# Loads Board of board_size size, using the dict dictionary
func board_loader{output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}(board: felt*, board_size: felt, dict: felt*, dict_size: felt, counter: felt):
    if board_size == -1:  
        return()
    end

    let (value) = eight_bit_dict(dict, dict_size, counter)
    assert([board+counter]) = value
    board_loader(board, board_size-1, dict, dict_size, counter+1) 
    return()
end
# END OF BOARD LOADER 
# -----------------------------------------------------------------

# -----------------------------------------------------------------
# Show array
func show_array{output_ptr : felt*}(array: felt*, size:felt, counter: felt):
    if size == 0:
        return()
    end
    serialize_word([array+counter])
    show_array(array, size-1, counter+1
    return()
end
# -----------------------------------------------------------------

# -----------------------------------------------------------------
# Board Loader Test
func board_loader_test {output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}():
    alloc_locals
    let (local dict) = alloc()
    let (local board) = alloc()
    
    assert [dict] = 263
    assert [dict] = 523
    assert [dict] = 781
    assert [dict] = 1045
    
    board_loader(board, 10,dict, 0)
    show_array(board)
    
    show_array(
    
    return()
end
# -----------------------------------------------------------------

# -----------------------------------------------------------------
# func MAIN 
func board_loader_test {output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}():
    # Call testers here
end
# -----------------------------------------------------------------