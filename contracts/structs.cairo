struct Square:
    member row : felt
    member col : felt
end

struct Setting:
    member piece : felt
    member square : Square
end

struct Move:
    member origin : Square
    member dest : Square
    member extra : felt
end

# Type codification:
# 0: Just one move/capture
# 1: As many moves as possible/capture
# 2: Only moves (no piece in the final square)
# 3: Only captures (enemy piece in the final square)
# 4: Triggers castling kingside
# 5: Triggers castling queenside
struct Pattern:
    member col_var : felt
    member row_var : felt
    member type : felt
end

struct Recursive_Vector:
    member stop_flag : felt
    member save_flag : felt
    member castle_k_flag : felt
    member castle_q_flag : felt
    member promotion_flag : felt
    member new_reference_square : Square
end

struct Meta:
    member active_color : felt
    member castling_K : felt
    member castling_Q : felt
    member castling_k : felt
    member castling_q : felt
    member passant : Square
end

struct State:
    member positions : felt*
    member active_color : felt
    member castling_K : felt
    member castling_Q : felt
    member castling_k : felt
    member castling_q : felt
    member passant : felt
    member halfmove_clock : felt
    member fullmove_clock : felt
end