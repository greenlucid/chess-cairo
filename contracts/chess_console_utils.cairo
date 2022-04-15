from structs import (
    Setting,
    Move,
    Square,
    Pattern,
    State
)

from chess_utils import board_index

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

func show_state(state : State):
    show_board(state.positions)
    %{
        print(f'active_color: {ids.state.active_color}')
        print(f'castling_K: {ids.state.castling_K}')
        print(f'castling_Q: {ids.state.castling_Q}')
        print(f'castling_k: {ids.state.castling_k}')
        print(f'castling_q: {ids.state.castling_q}')
        print(f'passant: {ids.state.passant}')
        print(f'halfmove_clock: {ids.state.halfmove_clock}')
        print(f'fullmove_clock: {ids.state.fullmove_clock}')
    %}
    break_line()
    return ()
end

# Show the board on the console
func show_board (board: felt*):
    let a8r = [board]
    let b8r = [board+1]
    let c8r = [board+2]
    let d8r = [board+3]
    let e8r = [board+4]
    let f8r = [board+5]
    let g8r = [board+6]
    let h8r = [board+7]
    let a7r = [board+8]
    let b7r = [board+9]
    let c7r = [board+10]
    let d7r = [board+11]
    let e7r = [board+12]
    let f7r = [board+13]
    let g7r = [board+14]
    let h7r = [board+15]
    let a6r = [board+16]
    let b6r = [board+17]
    let c6r = [board+18]
    let d6r = [board+19]
    let e6r = [board+20]
    let f6r = [board+21]
    let g6r = [board+22]
    let h6r = [board+23]
    let a5r = [board+24]
    let b5r = [board+25]
    let c5r = [board+26]
    let d5r = [board+27]
    let e5r = [board+28]
    let f5r = [board+29]
    let g5r = [board+30]
    let h5r = [board+31]
    let a4r = [board+32]
    let b4r = [board+33]
    let c4r = [board+34]
    let d4r = [board+35]
    let e4r = [board+36]
    let f4r = [board+37]
    let g4r = [board+38]
    let h4r = [board+39]
    let a3r = [board+40]
    let b3r = [board+41]
    let c3r = [board+42]
    let d3r = [board+43]
    let e3r = [board+44]
    let f3r = [board+45]
    let g3r = [board+46]
    let h3r = [board+47]
    let a2r = [board+48]
    let b2r = [board+49]
    let c2r = [board+50]
    let d2r = [board+51]
    let e2r = [board+52]
    let f2r = [board+53]
    let g2r = [board+54]
    let h2r = [board+55]
    let a1r = [board+56]
    let b1r = [board+57]
    let c1r = [board+58]
    let d1r = [board+59]
    let e1r = [board+60]
    let f1r = [board+61]
    let g1r = [board+62]
    let h1r = [board+63]

    %{
        piece_rep = {
            0 : ".",
            16: "R",
            17: "N",
            18: "B",
            19: "Q",
            20: "K",
            21: "P",
            24: "r",
            25: "n",
            26: "b",
            27: "q",
            28: "k",
            29: "p"
        }
        
        print()
        print (piece_rep[ids.a8r],piece_rep[ids.b8r],piece_rep[ids.c8r],piece_rep[ids.d8r],
            piece_rep[ids.e8r],piece_rep[ids.f8r],piece_rep[ids.g8r],piece_rep[ids.h8r])
        print (piece_rep[ids.a7r],piece_rep[ids.b7r],piece_rep[ids.c7r],piece_rep[ids.d7r],
            piece_rep[ids.e7r],piece_rep[ids.f7r],piece_rep[ids.g7r],piece_rep[ids.h7r])
        print (piece_rep[ids.a6r],piece_rep[ids.b6r],piece_rep[ids.c6r],piece_rep[ids.d6r],
            piece_rep[ids.e6r],piece_rep[ids.f6r],piece_rep[ids.g6r],piece_rep[ids.h6r])
        print (piece_rep[ids.a5r],piece_rep[ids.b5r],piece_rep[ids.c5r],piece_rep[ids.d5r],
            piece_rep[ids.e5r],piece_rep[ids.f5r],piece_rep[ids.g5r],piece_rep[ids.h5r])
        print (piece_rep[ids.a4r],piece_rep[ids.b4r],piece_rep[ids.c4r],piece_rep[ids.d4r],
            piece_rep[ids.e4r],piece_rep[ids.f4r],piece_rep[ids.g4r],piece_rep[ids.h4r])
        print (piece_rep[ids.a3r],piece_rep[ids.b3r],piece_rep[ids.c3r],piece_rep[ids.d3r],
            piece_rep[ids.e3r],piece_rep[ids.f3r],piece_rep[ids.g3r],piece_rep[ids.h3r])
        print (piece_rep[ids.a2r],piece_rep[ids.b2r],piece_rep[ids.c2r],piece_rep[ids.d2r],
            piece_rep[ids.e2r],piece_rep[ids.f2r],piece_rep[ids.g2r],piece_rep[ids.h2r])
        print (piece_rep[ids.a1r],piece_rep[ids.b1r],piece_rep[ids.c1r],piece_rep[ids.d1r],
            piece_rep[ids.e1r],piece_rep[ids.f1r],piece_rep[ids.g1r],piece_rep[ids.h1r])
        print()
    %}

    return()
end

func show_pattern (pattern: Pattern):
    tempvar col_var = pattern.col_var + 16
    tempvar row_var = pattern.row_var + 16
    tempvar type = pattern.type
    %{
        print(f'(', ids.col_var - 16, ',', ids.row_var - 16, ',' , ids.type, ')')
    %}
    return()
end

func show_settings (settings: Setting*, settings_size: felt):
    if settings_size == 0:
        return()
    end
    show_settings(settings, settings_size - 1)
    tempvar current_index = (settings_size - 1) * Setting.SIZE
    let current_setting = [settings + current_index]
    let piece = current_setting.piece
    let col = current_setting.square.col
    let row = current_setting.square.row

    %{
        piece_rep = {
            0 : ".",
            16: "R",
            17: "N",
            18: "B",
            19: "Q",
            20: "K",
            21: "P",
            24: "r",
            25: "n",
            26: "b",
            27: "q",
            28: "k",
            29: "p"
        }
        col_rep = {
            0 : "a",
            1 : "b",
            2 : "c",
            3 : "d",
            4 : "e",
            5 : "f",
            6 : "g",
            7 : "h"
        }
        rep = piece_rep[ids.piece] + "->" + col_rep[ids.col] + (str) (8 - ids.row)
        print(rep)
    %}

    return()
end

# info must be pass considering that 0 means no info, and info = 1 -> "R", info = 2 -> "N", info = 3 -> "B", info = 4 -> "Q"
func show_move (moving_piece : felt, move: Move):
    tempvar piece = moving_piece
    tempvar col_i = move.origin.col
    tempvar row_i = move.origin.row
    tempvar col_f = move.dest.col
    tempvar row_f = move.dest.row

    tempvar moving_pawn = (moving_piece - WPawn) * (moving_piece - BPawn) + 1
    tempvar moving_to_eight = (row_f - 8) * (row_f) + 1
    tempvar info_moving_pawn = moving_pawn * moving_to_eight
    if info_moving_pawn == 1:
        tempvar info = move.info + 1
    else:
        tempvar info = move.info
    end
    %{
        piece_rep = {
            16: "R",
            17: "N",
            18: "B",
            19: "Q",
            20: "K",
            21: "P",
            24: "R",
            25: "N",
            26: "B",
            27: "Q",
            28: "K",
            29: "P"
        }
        col_rep = {
            0 : "a",
            1 : "b",
            2 : "c",
            3 : "d",
            4 : "e",
            5 : "f",
            6 : "g",
            7 : "h"
        }
        info_rep = {
            1 : "=R",
            2 : "=N",
            3 : "=B",
            4 : "=Q"    
        }
        if ids.col_f > -1 and ids.col_f < 8 and ids.row_f > -1 and ids.row_f < 8:
            rep = col_rep[ids.col_i] + (str) (8 - ids.row_i) + '-' + col_rep[ids.col_f] + (str) (8 - ids.row_f)
            if ids.info != 0: rep = rep + info_rep[ids.info]
            print(rep)
        else:
            print(f'Error: move not legal')
    %}   
    return()
end

func show_moves (moves_list: Move*, moves_list_size: felt, board: felt*):
    if moves_list_size == 0:
        return()
    end
    let current_move = [moves_list]
    let initial_square = current_move.origin
    let (initial_square_index) = board_index(initial_square)

    let current_piece = [board + initial_square_index]
    show_move(current_piece, current_move)
    # recursive call:
    show_moves(moves_list + Move.SIZE, moves_list_size - 1, board)
    return()
end


func show_square (square: Square):
    tempvar col = square.col
    tempvar row = square.row
    %{
        col_rep = {
            0 : "a",
            1 : "b",
            2 : "c",
            3 : "d",
            4 : "e",
            5 : "f",
            6 : "g",
            7 : "h"
        }
        if ids.col > 7 or ids.row > 7 or ids.col < 0 or ids.row < 0:
            print(f' out_of_bounds') 
        else:
            rep = col_rep[ids.col] + (str) (8 - ids.row)
            print(f'', rep) 
    %}
    
    return()
end

func show_piece(piece: felt):
        %{
        piece_rep = {
            16: "R",
            17: "N",
            18: "B",
            19: "Q",
            20: "K",
            21: "P",
            24: "r",
            25: "n",
            26: "b",
            27: "q",
            28: "k",
            29: "p"
        }
        if (ids.piece > 15 and ids.piece < 22) or (ids.piece > 23 and ids.piece < 30):
            print (piece_rep[ids.piece])
        else:
            print(f'n/p')
        %}
    return()
end

func break_line():
    %{
        print(f'-------------------------------- ')
    %}
    return()
end