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

struct Point:
    member row : felt
    member col : felt
end

struct Move:
    member origin : Point
    member dest : Point
    member extra : felt
end
