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

# Installation

This project uses [nile](https://github.com/OpenZeppelin/nile). Refer to it if you're lost. You'll also need pyenv, to use python3.7.

- `python3.7 -m venv env`
- `source env/bin/activate`
- `pip install git+https://github.com/OpenZeppelin/nile.git#egg=cairo-nile`
- `echo "WHITE=1234" > .env`

## Running it

Go to notes/useful_commands.txt to find some stuff. `{}` means you paste an address or a big hex.

- `source env/bin/activate` (do this in 2 terminals)
- `nile node`
- `nile setup WHITE`
- `nile compile contracts/chess.cairo`
- `nile deploy chess {white} {white} {white} {initial_fen}`
- `nile send WHITE {chess} make_move 13456 0`

If you got here you can figure out the rest yourself
