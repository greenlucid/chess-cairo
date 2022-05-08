import { NextPage } from "next"
import Head from "next/head"
import { useRouter } from "next/router"
import { useEffect, useState } from "react"
import { Provider } from "starknet"
import decodeFen from "../utils/decodeFen"
import { Chessboard, Pieces, Square } from "react-chessboard"
import { encodeMove2 } from "../utils/encodeMove"
import { connect } from "@argent/get-starknet"

enum PieceType {
  Rook,
  Knight,
  Bishop,
  Queen,
  King,
  Pawn,
}

const squares: Square[] = [
  "a8",
  "b8",
  "c8",
  "d8",
  "e8",
  "f8",
  "g8",
  "h8",
  "a7",
  "b7",
  "c7",
  "d7",
  "e7",
  "f7",
  "g7",
  "h7",
  "a6",
  "b6",
  "c6",
  "d6",
  "e6",
  "f6",
  "g6",
  "h6",
  "a5",
  "b5",
  "c5",
  "d5",
  "e5",
  "f5",
  "g5",
  "h5",
  "a4",
  "b4",
  "c4",
  "d4",
  "e4",
  "f4",
  "g4",
  "h4",
  "a3",
  "b3",
  "c3",
  "d3",
  "e3",
  "f3",
  "g3",
  "h3",
  "a2",
  "b2",
  "c2",
  "d2",
  "e2",
  "f2",
  "g2",
  "h2",
  "a1",
  "b1",
  "c1",
  "d1",
  "e1",
  "f1",
  "g1",
  "h1",
]

const pieceTypeMap: { [char: string]: PieceType } = {
  r: PieceType.Rook,
  n: PieceType.Knight,
  b: PieceType.Bishop,
  q: PieceType.Queen,
  k: PieceType.King,
  p: PieceType.Pawn,
}

enum Color {
  White,
  Black,
  Governor,
}

type Castlings = { [castling: string]: boolean }

type Piece = {
  type: PieceType
  color: Color
}

type Players = {
  white: string
  black: string
  governor: string
}

type Tile = Piece | null

type State = {
  positions: Tile[][]
  activeColor: Color
  castlings: Castlings
  passant: number
  halfmoveClock: number
  fullmoveClock: number
  fen: string
}

type ChessData = {
  //players: Players
  state: State
  //finality: number
}

type Pos = [number | undefined, number | undefined]

const parseEncodedFen = (encodedFen: string): State | null => {
  const fen = decodeFen(encodedFen)
  const [
    fenPositions,
    fenActiveColor,
    fenCastlings,
    fenPassant,
    fenHalfmoveClock,
    fenFullmoveClock,
  ] = fen.split(" ")
  const positions: Tile[][] = []
  for (const fenRow of fenPositions.split("/")) {
    const row = []
    for (const char of fenRow) {
      if (isNaN(Number(char))) {
        const color = char === char.toLowerCase() ? Color.Black : Color.White
        const pieceType = pieceTypeMap[char.toLowerCase()]
        const piece: Piece = { color, type: pieceType }
        row.push(piece)
      } else {
        for (let i = 0; i < Number(char); i++) row.push(null)
      }
    }
    positions.push(row)
  }
  const activeColor = fenActiveColor === "w" ? Color.White : Color.Black
  const castlings = {} // todo
  const passant = 0 // todo
  const halfmoveClock = Number(fenHalfmoveClock)
  const fullmoveClock = Number(fenFullmoveClock)

  return {
    positions,
    activeColor,
    castlings,
    passant,
    halfmoveClock,
    fullmoveClock,
    fen,
  }
}

const useChessData = (address: string) => {
  const [chessData, setChessData] = useState<ChessData | undefined | null>(
    undefined
  )
  const getChessData = async () => {
    const provider = new Provider({ network: "goerli-alpha" })
    const res = await provider.callContract({
      contractAddress: address,
      entrypoint: "current_state",
    })
    if (res) {
      const state = parseEncodedFen(res.result[0])
      console.log(state)
      if (state) {
        setChessData({ state })
      } else {
        setChessData(null)
      }
    }
  }

  useEffect(() => {
    if (address) {
      getChessData()
    }
  }, [address])

  return chessData
}

const ChessGame: React.FC<{ chessData: ChessData; gameAddress: string }> = ({
  chessData,
  gameAddress,
}) => {
  const handleMove = async (source: Square, target: Square, piece: Pieces) => {
    const start = squares.indexOf(source)
    const end = squares.indexOf(target)
    const encodedMove = encodeMove2(start, end)
    console.log(encodedMove)
    const starknet = await connect()
    if (!starknet) {
      throw Error(
        "User rejected wallet selection or silent connect found nothing"
      )
    }

    await starknet.enable({showModal: true})
    const result = await starknet.account.execute({
      contractAddress: gameAddress,
      entrypoint: "make_move",
      calldata: [encodedMove, chessData.state.activeColor],
    })
    console.log("sent ;)", result)
  }

  return (
    <div>
      <h3>{chessData.state.activeColor === Color.White ? "White" : "Black"} to move</h3>
      <h3>Move #{chessData.state.fullmoveClock}</h3>
      <Chessboard
        position={chessData.state.fen}
        onPieceDrop={(source, target, piece) => {
          handleMove(source, target, piece)
          return false
        }}
      />
    </div>
  )
}

const ChessContainer: React.FC<{
  chessData: ChessData | undefined | null
  gameAddress: string | string[] | undefined
}> = ({ chessData, gameAddress }) => {
  if (chessData === undefined) return <div>loading...</div>
  if (chessData === null) return <div>chess game doesn't exist</div>
  if (!gameAddress || typeof gameAddress !== "string") return null

  return <ChessGame chessData={chessData} gameAddress={gameAddress} />
}

const GamePage: NextPage = () => {
  const router = useRouter()
  const { gameAddress } = router.query
  const chessData = useChessData(gameAddress as string)
  return (
    <div>
      <Head>
        <title>chess-cairo</title>
        <meta name="description" content="Decentralized chess" />
        <link rel="icon" href="/king.svg" />
      </Head>
      <h1>Chess game</h1>
      <p>{gameAddress}</p>{" "}
      <ChessContainer chessData={chessData} gameAddress={gameAddress} />
    </div>
  )
}
export default GamePage