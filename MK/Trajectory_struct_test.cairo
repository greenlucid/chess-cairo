%builtins output bitwise

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and, bitwise_xor
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.serialize import serialize_word

# https://www.cairo-lang.org/docs/reference/syntax.html
struct Trajectory:
    member path_size: felt
    member path: felt*
    member child_size: felt
    member child: Trajectory*
end

func main {output_ptr : felt*, bitwise_ptr : BitwiseBuiltin*}():
    alloc_locals

    let (local dummyt: Trajectory*) = alloc()
    let (local root: Trajectory*) = alloc()
    let (local trj_array: Trajectory*) = alloc()
    let (local trj_NE: Trajectory*) = alloc()
    let (local trj_SE: Trajectory*) = alloc()
    let (local trj_SW: Trajectory*) = alloc()
    let (local trj_NW: Trajectory*) = alloc()

    let (local no_path: felt*) = alloc()
    let (local path_NE: felt*) = alloc()
    let (local path_SE: felt*) = alloc()
    let (local path_SW: felt*) = alloc()
    let (local path_NW: felt*) = alloc()

    assert([no_path]) = 35
    assert([path_NE]) = 44
    assert([path_NE+1]) = 53
    assert([path_NE+2]) = 62
    assert([path_SE]) = 28
    assert([path_SE+1]) = 21
    assert([path_SE+2]) = 14
    assert([path_SE+3]) = 07
    assert([path_SW]) = 26
    assert([path_SW+1]) = 17
    assert([path_SW+2]) = 08
    assert([path_NW]) = 42
    assert([path_NW+1]) = 49
    assert([path_NW+2]) = 56
    
    assert trj_array[0] = Trajectory(size=3,path=path_NE,child_size=0,child=dummyt)
    assert trj_array[1] = Trajectory(size=4,path=path_SE,child_size=0,child=dummyt)
    assert trj_array[2] = Trajectory(size=3,path=path_SW,child_size=0,child=dummyt)
    assert trj_array[3] = Trajectory(size=3,path=path_NW,child_size=0,child=dummyt)
    
    assert root[0] = Trajectory(size=1,path=no_path,child_size=4,child=trj_array)
    
    # Mostrar casilla de inicio, usando un index (test)
    let b = root[0].path
    tempvar index = 0
    serialize_word([b+index])
    # Mostrar segunda posición del path de la trayectoria South-West
    let a = root[0].child[2].path[1]  # (2)
    serialize_word(a)


    return()
end