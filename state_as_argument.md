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
- felt stating the number of FENs following it
- An array of FENs. Each FEN takes 72 felts. The first one corresponds to the initial state, and all the others are the resultant state after a move.

Two felts signaling the status of draw offer of each color for the current round.

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
- `[as_player, only_check, start_x, start_y, end_x, end_y, extra]`
- `[is_valid]`

### surrender
- `[as_player]`
- `[]`

### offer_draw
- `[as_player]`
- `[]`

### force_threefold_draw
- `[as_player, a, b]`
- `[]`

### force_fifty_moves_draw
- `[as_player]`
- `[]`

### write_result
- `[]`
- `[result]`

### force_result
- `[result]`
- `[result]`
