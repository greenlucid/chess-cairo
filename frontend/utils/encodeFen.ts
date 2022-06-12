import { bnToUint256 } from "starknet/dist/utils/uint256"

const charToCode: { [char: string]: string } = {
  r: "11000",
  n: "11001",
  b: "11010",
  q: "11011",
  k: "11100",
  p: "11101",
  R: "10000",
  N: "10001",
  B: "10010",
  Q: "10011",
  K: "10100",
  P: "10101",
}

const passantToCode: { [passant: string]: string } = {
  "-": "1000",
  a: "0000",
  b: "0001",
  c: "0010",
  d: "0011",
  e: "0100",
  f: "0101",
  g: "0110",
  h: "0111",
}

const encodeRow = (row: string) =>
  row
    .split("")
    .map((char) =>
      isNaN(Number(char)) ? charToCode[char] : "0".repeat(Number(char))
    )
    .join("")

const encodePositions = (positions: string) => {
  const rows = positions.split("/")
  const encoded = rows.map((row) => encodeRow(row))
  return encoded.join("")
}

const encodeActiveColor = (char: string) => (char === "w" ? "0" : "1")

const encodeCastlings = (castlings: string) => {
  const lookups = "KQkq"
  const encoded = lookups
    .split("")
    .map((lookup) => (castlings.includes(lookup) ? "1" : "0"))
  return encoded.join("")
}

const encodePassant = (passant: string) => passantToCode[passant[0]]

// what if the other player didn't force a draw?
// this is potentially infinite
// just treat it as 7 bits in the initial state
// at contract level the sky's the limit
const encodeHalfmoveClock = (halfmoveClock: number) => {
  const bin = halfmoveClock.toString(2)
  const padding = "0".repeat(7 - bin.length)
  return `${padding}${bin}`
}

// also potentially infinite
// to consider longest game to auto draw with half-move clock
// won't exceed 6300 moves (< 13 bits)
// this is just for the initial state
// players can keep going beyond if they want
const encodeFullmoveClock = (fullmoveClock: number) => {
  const bin = fullmoveClock.toString(2)
  const padding = "0".repeat(13 - bin.length)
  return `${padding}${bin}`
}

const encodeFen = (fen: string) => {
  const [pos, active, cast, passant, halfmoveClock, fullmoveClock] =
    fen.split(" ")
  return (
    encodePositions(pos) +
    encodeActiveColor(active) +
    encodeCastlings(cast) +
    encodePassant(passant) +
    encodeHalfmoveClock(Number(halfmoveClock)) +
    encodeFullmoveClock(Number(fullmoveClock))
  )
}

const bintohex = (bin: string) => {
  // bundle the bin into 4 length chunks.
  let chunks = []
  if (bin.length % 4 !== 0) {
    const firstChunk = bin.substring(0, bin.length % 4)
    chunks.push(firstChunk)
  }
  for (let i = bin.length % 4; i < bin.length; i += 4) {
    const chunk = bin.substring(i, i + 4)
    chunks.push(chunk)
  }
  console.log(chunks)
  const hex = chunks.map((chunk) => Number.parseInt(chunk, 2).toString(16)).join("")
  return hex
}

const encodingToHex = (encoding: string) => {
  console.log(encoding)
  const padCount = 251 - encoding.length
  const padded = `${encoding}${"0".repeat(padCount)}`
  const hex = bintohex(padded)
  console.log(hex)
  return `0x${hex}`
}

const fullEncodeFen = (fen: string) => {
  return encodingToHex(encodeFen(fen))
}

export default fullEncodeFen
