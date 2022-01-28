from starkware.cairo.common.cairo_builtins import BitwiseBuiltin

from src.bit_helper import bits_at

func construct_move(origin : felt, dest : felt, extra : felt)-> (move : felt):
    let result = origin * 256 + dest * 4 + extra
    return (move=result)
end

func dissect_move{
        bitwise_ptr : BitwiseBuiltin*, range_check_ptr
        }(move : felt) -> (origin : felt, dest : felt, extra : felt):
    alloc_locals
    let (local origin) = bits_at(el=move, offset=0, size=6)
    let (local dest) = bits_at(el=move, offset=6, size=6)
    let (local extra) = bits_at(el=move, offset=12, size=2)
    return (origin, dest, extra)
end