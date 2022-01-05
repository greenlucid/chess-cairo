const fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

const charToCode = {
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

const passantToCode = {
  "-": "1000",
  a: "0000",
  b: "0001",
  c: "0010",
  d: "0011",
  e: "0100",
  f: "0101",
  g: "0110",
  h: "0111"
}

const encodeRow = (row) => row.split("")
  .map(char => isNaN(char) ? charToCode[char] : "0".repeat(Number(char)))
  .join("")

const encodePositions = (positions) => {
  const rows = positions.split("/")
  const encoded = rows.map(row => encodeRow(row))
  return encoded.join("")
}

const encodeActiveColor = (char) => char === "w" ? "0" : "1"

const encodeCastlings = (castlings) => {
  const lookups = "KQkq"
  const encoded = lookups.split("")
    .map(lookup => castlings.includes(lookup) ? "1" : "0")
  return encoded.join("")
}

const encodePassant = (passant) => passantToCode[passant[0]]

// what if the other player didn't force a draw?
// this is potentially infinite
// just treat it as 7 bits in the initial state
// at contract level the sky's the limit
const encodeHalfmoveClock = (halfmoveClock) => {
  const bin = halfmoveClock.toString(2)
  const padding = "0".repeat(7 - bin.length)
  return `${padding}${bin}`
}

// also potentially infinite
// to consider longest game to auto draw with half-move clock
// won't exceed 6300 moves (< 13 bits)
// this is just for the initial state
// players can keep going beyond if they want
const encodeFullmoveClock = (fullmoveClock) => {
  const bin = fullmoveClock.toString(2)
  const padding = "0".repeat(13 - bin.length)
  return `${padding}${bin}`
}

const encodeFen = (fen) => {
  const [ pos, active, cast, passant,
    halfmoveClock, fullmoveClock ] = fen.split(" ")
  return encodePositions(pos)
    + encodeActiveColor(active)
    + encodeCastlings(cast)
    + encodePassant(passant)
    + encodeHalfmoveClock(halfmoveClock)
    + encodeFullmoveClock(fullmoveClock)
}

// https://stackoverflow.com/questions/39334494/converting-large-numbers-from-binary-to-decimal-and-back-in-javascript/55681265#55681265
const parseBigInt = (str, base=10) => {
  b = BigInt(base)
  var bigint = BigInt(0)
  for (var i = 0; i < str.length; i++) {
    var code = str[str.length-1-i].charCodeAt(0) - 48; if(code >= 10) code -= 39
    bigint += b**BigInt(i) * BigInt(code)
  }
  return bigint
}

const encodingToHex = (encoding) => {
  const padCount = 251 - encoding.length
  const padded = `${encoding}${"0".repeat(padCount)}`
  const bigInt = parseBigInt(padded, 2)
  return `0x${bigInt.toString(16)}`
}

console.log(encodingToHex(encodeFen(fen)))