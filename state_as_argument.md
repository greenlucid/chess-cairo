Format is the following:

## State

An array of FEN encodings. The first one corresponds to the initial state, and all the others are the resultant state after a move.

Why store the FENs instead of the moves? It takes less work to do a function later.

## Action

First felt is action type, everything else is dependant.

0. move
1. surrender
2. offer_draw
3. force_threefold_draw
4. force_fifty_moves_draw
5. write_result

## Other stuff

There's still a function to rule the result, it's separate.
Players are still going to be written in the players "array" at deployment time.