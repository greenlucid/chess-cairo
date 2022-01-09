from starkware.cairo.common.pow import pow
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.bitwise import bitwise_and

func bits_at(el : felt, offset : felt, size : felt) -> (result : felt):
    alloc_locals
    let (basic_mask) = pow(2, size) - 1
    tempvar distance = 251 - offset - size
    let (local multiplier) = pow(2, distance)
    tempvar mask = multiplier * basic_mask
    let (masked_bits) = bitwise_and(el, mask)
    let bits = masked_bits / multiplier
    return (result=bits)
end

func bit_at(el : felt, offset : felt) -> (bit : felt):
    let exp = 251 - offset
    let (mask) = pow(2, exp)
    let (result) = bitwise_and(el, mask)
    if result == 0:
        return (bit=0)
    end
    return (bit=1)
end

func append_bits(pre : felt, offset : felt, el : felt, size : felt) -> (result : felt):
    let distance = 251 - offset - size
    let (multiplier) = pow(2, distance)
    let result = pre + multiplier * el
    return (result=result)
end