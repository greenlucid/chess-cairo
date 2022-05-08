const prime =
  3618502788666131213697322783095070105623107215331596699973092056135872020481n // 2**251 + 17 * 2**192 + 1

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

const passantToCode: { [char: string]: string } = {
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

const codeToChar = (code: string) =>
  Object.keys(charToCode).find((char) => charToCode[char] === code)

const codeToPassant = (code: string) =>
  Object.keys(passantToCode).find((char) => passantToCode[char] === code)

const decodePositions = (encoding: string, pointer = 0) => {
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

const decodeActiveColor = (encoding: string, pointer: number) => ({
  pointer: pointer + 1,
  fen: encoding[pointer] === "0" ? "w" : "b",
})

const decodeCastlings = (encoding: string, pointer: number) => {
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

const decodePassant = (
  encoding: string,
  pointer: number,
  activeColor: string
) => {
  const passantFirst = codeToPassant(encoding.substring(pointer, pointer + 4))
  let passant = ""
  if (passantFirst === "-") passant = "-"
  else {
    const row = activeColor === "w" ? "6" : "3"
    passant = passantFirst + row
  }
  return { pointer: pointer + 4, fen: passant }
}

const decodeHalfmoveClock = (encoding: string, pointer: number) => {
  const encodedClock = encoding.substring(pointer, pointer + 7)
  return { pointer: pointer + 7, fen: `${parseInt(encodedClock, 2)}` }
}

const decodeFullmoveClock = (encoding: string, pointer: number) => {
  const encodedClock = encoding.substring(pointer, pointer + 13)
  return { pointer: pointer + 13, fen: `${parseInt(encodedClock, 2)}` }
}

const hextobin = (hex: string) => {
  const bin = hex
    .substring(2)
    .split("")
    .map((char) => {
      const binbase = Number.parseInt(char, 16).toString(2)
      const paddingZeroes = "0".repeat(4 - binbase.length)
      return `${paddingZeroes}${binbase}`
    })
    .join("")
  if (bin.length >= 251) return bin.substring(bin.length - 251)
  const paddingZeroes = "0".repeat(251 - bin.length)

  return `${paddingZeroes}${bin}`
}

const rawEncodingToBin = (rawEncoding: string) => {
  const isHex = rawEncoding[1] === "x"
  if (isHex) return hextobin(rawEncoding)
  throw new Error("Numbers are not supported")
}

const decodeFen = (rawEncoding: string) => {
  const encoding = rawEncodingToBin(rawEncoding) as string
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

export default decodeFen
