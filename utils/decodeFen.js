const encoding =
  "0x633adf359c77bdef7bde80000540056b5aab5ac2329d25187d0000040000000"
const prime = 3618502788666131213697322783095070105623107215331596699973092056135872020481n // 2**251 + 17 * 2**192 + 1

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
  h: "0111",
}

const codeToChar = (code) =>
  Object.keys(charToCode).find((char) => charToCode[char] === code)

const codeToPassant = (code) =>
  Object.keys(passantToCode).find((char) => passantToCode[char] === code)

const decodePositions = (encoding, pointer = 0) => {
  const rows = []
  while (rows.length < 8) {
    let rowCount = 0,
      emptyCount = 0,
      row = ""
    while (rowCount + emptyCount < 8) {
      const bit = encoding[pointer]
      if (bit == "0") {
        emptyCount++
        pointer++
      } else {
        const pieceCode = encoding.substring(pointer, pointer + 5)
        const piece = codeToChar(pieceCode)
        const text = `${emptyCount === 0 ? "" : emptyCount}${piece}`
        row += text
        rowCount += emptyCount + 1
        emptyCount = 0
        pointer += 5
      }
    }
    if (emptyCount !== 0) row += `${emptyCount}`
    rows.push(row)
  }

  return { pointer, fen: rows.join("/") }
}

const decodeActiveColor = (encoding, pointer) => ({
  pointer: pointer + 1,
  fen: encoding[pointer] === "0" ? "w" : "b",
})

const decodeCastlings = (encoding, pointer) => {
  const chars = "KQkq"
  let reals = ""
  encoding
    .substring(pointer, pointer + 4)
    .split("")
    .forEach((bit, i) => {
      if (bit === "1") reals += chars[i]
    })
  return { pointer: pointer + 4, fen: reals.length === 0 ? "-" : reals }
}

const decodePassant = (encoding, pointer, activeColor) => {
  const passantFirst = codeToPassant(encoding.substring(pointer, pointer + 4))
  let passant = ""
  if (passantFirst === "-") passant = "-"
  else {
    const row = activeColor === "w" ? "6" : "3"
    passant = passantFirst + row
  }
  return { pointer: pointer + 4, fen: passant }
}

const decodeHalfmoveClock = (encoding, pointer) => {
  const encodedClock = encoding.substring(pointer, pointer + 7)
  return { pointer: pointer + 7, fen: `${parseInt(encodedClock, 2)}` }
}

const decodeFullmoveClock = (encoding, pointer) => {
  const encodedClock = encoding.substring(pointer, pointer + 13)
  return { pointer: pointer + 13, fen: `${parseInt(encodedClock, 2)}` }
}

// https://stackoverflow.com/questions/39334494/converting-large-numbers-from-binary-to-decimal-and-back-in-javascript/55681265#55681265
const parseBigInt = (str, base = 10) => {
  const minusMult = str[0] === "-" ? -1n : 1n
  if (minusMult === -1n) str = str.substring(1)
  b = BigInt(base)
  var bigint = BigInt(0)
  for (var i = 0; i < str.length; i++) {
    let code = str[str.length - 1 - i].charCodeAt(0) - 48
    if (code >= 10) code -= 39
    bigint += b ** BigInt(i) * BigInt(code)
  }
  return bigint * minusMult
}

const hexToBin = (hex) => {
  const bigInt = parseBigInt(hex.substring(2), 16)
  return bigInt.toString(2)
}

const decToBin = (dec) => {
  const bigint = parseBigInt(dec, 10)
  const unsigned = bigint < 0n ? (prime + bigint) : bigInt
  return unsigned.toString(2)
}

const rawEncodingToBin = (rawEncoding) => {
  const isHex = rawEncoding[1] === "x"
  if (isHex) return hexToBin(rawEncoding)
  else return decToBin(rawEncoding)
}

const decodeFen = (rawEncoding) => {
  const encoding = rawEncodingToBin(rawEncoding)
  const pos = decodePositions(encoding)
  const color = decodeActiveColor(encoding, pos.pointer)
  const castlings = decodeCastlings(encoding, color.pointer)
  const passant = decodePassant(encoding, castlings.pointer, color.fen)
  const halfclock = decodeHalfmoveClock(encoding, passant.pointer)
  const fullclock = decodeFullmoveClock(encoding, halfclock.pointer)
  return [pos, color, castlings, passant, halfclock, fullclock]
    .map((thing) => thing.fen)
    .join(" ")
}

console.log(decodeFen(encoding))
