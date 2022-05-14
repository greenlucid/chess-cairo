import { NextPage } from "next"
import Head from "next/head"
import { useRouter } from "next/router"
import { useEffect, useState } from "react"
import { Provider } from "starknet"
import decodeFen from "../utils/decodeFen"
import { Chessboard, Pieces, Square } from "react-chessboard"
import { encodeMove2 } from "../utils/encodeMove"
import { connect } from "@argent/get-starknet"
import shortenAddress from "../utils/shortenAddress"

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
  players: Players
  state: State
  finality: number
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
    let res = null
    try {
      res = await provider.callContract({
        contractAddress: address,
        entrypoint: "current_state",
      })
    } catch (e) {
      setChessData(null)
    }

    if (res) {
      const state = parseEncodedFen(res.result[0])
      console.log(state)
      if (state) {
        const getPlayer = async (i: number): Promise<string> => {
          const res = await provider.callContract({
            contractAddress: address,
            entrypoint: "get_player",
            calldata: [i.toString()],
          })
          return res.result[0]
        }
        const [white, black, governor] = await Promise.all([
          getPlayer(0),
          getPlayer(1),
          getPlayer(2),
        ])
        const players = { white, black, governor }
        const finalityRes = await provider.callContract({
          contractAddress: address,
          entrypoint: "get_finality",
          calldata: [],
        })
        const finality = Number(finalityRes.result[0])
        console.log(players)
        setChessData({ state, players, finality })
      } else {
        setChessData(null)
      }
    }
  }

  useEffect(() => {
    if (address && chessData === undefined) {
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
    // promotion
    let extra: number = 0
    // if its pawn crowning move, get it in. otherwise is let as 0
    if ((end < 8 || end >= 56) && ["wP", "bP"].includes(piece)) {
      const promptResponse = prompt(
        "Promotion, type a number: 0 = Rook, 1 == Queen, 2 == Knight, 3 == Bishop"
      )
      const promptNumber = Number(promptResponse)
      if (isNaN(promptNumber)) {
        alert("Error, you should put a number")
        return
      } else if (promptNumber < 0 || promptNumber > 3) {
        alert("Error, number must be [0, 1, 2, 3]")
        return
      } else {
        extra = promptNumber
      }
    }
    const starknet = await connect()
    if (!starknet) {
      throw Error(
        "User rejected wallet selection or silent connect found nothing"
      )
    }

    await starknet.enable({ showModal: true })
    const result = await starknet.account.execute({
      contractAddress: gameAddress,
      entrypoint: "make_move",
      calldata: [encodedMove, chessData.state.activeColor, extra],
    })
    console.log("sent ;)", result)
  }

  const handleWriteResult = async () => {
    const starknet = await connect()
    if (!starknet) {
      throw Error(
        "User rejected wallet selection or silent connect found nothing"
      )
    }
    await starknet.enable({ showModal: true })
    const result = await starknet.account.execute({
      contractAddress: gameAddress,
      entrypoint: "write_result",
      calldata: [],
    })
    console.log("sent write result", result)
  }

  const finalities = ["Pending", "White win", "Black win", "Draw"]

  return (
    <div>
      <p>
        <a
          target="_blank"
          href={`https://goerli.voyager.online/contract/${gameAddress}`}
        >
          {shortenAddress(gameAddress)}
        </a>
      </p>{" "}
      <h3>
        {chessData.state.activeColor === Color.White ? "White" : "Black"} to
        move
      </h3>
      <h3>Players:</h3>
      <ul>
        <li>
          White{" "}
          <a
            target="_blank"
            href={`https://goerli.voyager.online/contract/${chessData.players.white}`}
          >
            {shortenAddress(chessData.players.white)}
          </a>
        </li>
        <li>
          Black{" "}
          <a
            target="_blank"
            href={`https://goerli.voyager.online/contract/${chessData.players.black}`}
          >
            {shortenAddress(chessData.players.black)}
          </a>
        </li>
        <li>
          Governor{" "}
          <a
            target="_blank"
            href={`https://goerli.voyager.online/contract/${chessData.players.governor}`}
          >
            {shortenAddress(chessData.players.governor)}
          </a>
        </li>
      </ul>
      <h3>Move #{chessData.state.fullmoveClock}</h3>
      <h3>Result: {finalities[chessData.finality]}</h3>
      <button onClick={handleWriteResult}>Write Result</button>
      <p>
        Use this button to set the result, when the current position is final
      </p>
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
      <ChessContainer chessData={chessData} gameAddress={gameAddress} />
    </div>
  )
}
export default GamePage
