# chess.cairo

A Cairo contract to play chess, with composability in mind.

##  How it works

Every game of chess will be deployed in a single contract. Each contract has who plays as white, as black, who is the governor, and the initial fen state.

## State of chess

Because of threefold repetition, the full state of chess requires the full history of moves, so that any of the players can force a draw if a board state is reached three times. A **board state** is what is commonly referred to as the "state" of chess. That is, whatever can be represented with [Forsyth–Edwards Notation](https://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation), except the fullmove clock and the **halfmove clock** (count of plys since last irreversible action).

### Glossary of *states*

- **board state**: positions, active color, castling rights, passant.
- **fen state**: board state & halfmove clock & fullmove clock.
- **full state**: board state & halfmove clock & move history.

## How the state is stored

In chess.cairo, the contract keeps `initial_state`, an encoded fen state, and `moves`, the array of moves. That means, the contract effectively holds the full state. You can reach the current fen state by iterating through the move history, advancing move by move.
