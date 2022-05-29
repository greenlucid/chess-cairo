## Rationales

Pedersen are pretty cheap. Bitwise are pretty expensive.
Storing the moves end figuring out the state dynamically is a bad idea, because many bitwise operations would be needed.
A FEN can be packed into a single felt, but decoding it would take many bitwise operations. It's cheaper to pass the state with unpacked felts as an argument.

Format is the following:

## State

- game id
- white address
- black address
- governor address
- white draw request
- black draw request
- felt stating the number of FENs following it
- An array of FENs. Each FEN takes 72 felts. The first one corresponds to the initial state, and all the others are the resultant state after a move.

## Action

First felt is action type, everything else is dependant on the action type.

0. create_game
1. move
2. surrender
3. offer_draw
4. force_threefold_draw
5. force_fifty_moves_draw
6. write_result
7. force_result

Per action type, listed below their inputs and outputs.

### create_game

Pass the state as with the other functions, but ommitting the first felt for `game_id`.

- `[]`
- `[game_id]`

### move
- `[as_player, only_check, start_y, start_x, end_y, end_x, extra]`
- `[is_valid]`

### surrender
- `[as_player]`
- `[result]`

### offer_draw
- `[as_player]`
- `[result]`

### force_threefold_draw
- `[as_player, a, b]`
- `[result]`

### force_fifty_moves_draw
- `[as_player]`
- `[result]`

### write_result
- `[]`
- `[result]`

### force_result
- `[result]`
- `[result]`

## Events

You use events to handle off-chain state availability. They always include `game_id` as their first argument, and then include other data.

### create_game

Can you pass arrays to events?

`create_game_called(game_id, state_len, state)`

### move

`move` is the `Move` struct.

`move_called(game_id, move)`

### surrender

`surrender_called(game_id, as_player)`

### offer_draw

`offer_draw_called(game_id, as_player)`

### force_threefold_draw

`force_threefold_draw_called(game_id)`

### force_fifty_moves_draw

`force_fifty_moves_draw_called(game_id)`

### write_result

`write_result_called(game_id, result)`

### force_result

`force_result(game_id, result)`
