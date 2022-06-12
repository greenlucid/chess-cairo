from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.bitwise import bitwise_and

from contracts.pow2 import pow2

func bits_at{
        bitwise_ptr : BitwiseBuiltin*, range_check_ptr
        }(el : felt, offset : felt, size : felt) -> (result : felt):
    alloc_locals
    let (pre_basic_mask) = pow2(size)
    let basic_mask = pre_basic_mask - 1
    tempvar distance = 251 - offset - size
    let (local multiplier) = pow2(distance)
    tempvar mask = multiplier * basic_mask
    let (masked_bits) = bitwise_and(el, mask)
    let bits = masked_bits / multiplier
    return (result=bits)
end

func bit_at{
        bitwise_ptr : BitwiseBuiltin*, range_check_ptr
        }(el : felt, offset : felt) -> (bit : felt):
    let exp = 250 - offset
    let (mask) = pow2(exp)
    let (result) = bitwise_and(el, mask)
    if result == 0:
        return (bit=0)
    end
    return (bit=1)
end

func append_bits{
        range_check_ptr
        }(pre : felt, offset : felt, el : felt, size : felt) -> (result : felt):
    let distance = 251 - offset - size
    let (multiplier) = pow2(distance)
    let result = pre + multiplier * el
    return (result=result)
end