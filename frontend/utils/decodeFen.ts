const prime =
  3618502788666131213697322783095070105623107215331596699973092056135872020481n // 2**251 + 17 * 2**192 + 1

const charToCode: { [char: string]: number } = {
  R: 16,
  N: 17,
  B: 18,
  Q: 19,
  K: 20,
  P: 21,
  r: 24,
  n: 25,
  b: 26,
  q: 27,
  k: 28,
  p: 29,
}

const passantToCode: { [passant: string]: number } = {
  "-": 8,
  a: 0,
  b: 1,
  c: 2,
  d: 3,
  e: 4,
  f: 5,
  g: 6,
  h: 7,
}

const codeToChar = (code: number) =>
  Object.keys(charToCode).find((char) => charToCode[char] === code)

const codeToPassant = (code: number) =>
  Object.keys(passantToCode).find((char) => passantToCode[char] === code)

const decodePositions = (encoding: number[]): string => {
  const rows = []
  let pointer = 0
  while (rows.length < 8) {
    let rowCount = 0,
      emptyCount = 0,
      row = ""
    while (rowCount + emptyCount < 8) {
      const code = encoding[pointer]
      if (code === 0) {
        emptyCount++
        pointer++
      } else {
        const piece = codeToChar(code)
        const text = `${emptyCount === 0 ? "" : emptyCount}${piece}`
        row += text
        rowCount += emptyCount + 1
        emptyCount = 0
        pointer++
      }
    }
    if (emptyCount !== 0) row += `${emptyCount}`
    rows.push(row)
  }

  return rows.join("/")
}

const decodeCastlings = (encoding: number[]): string => {
  const chars = "KQkq"
  let reals = ""
  encoding
    .forEach((bit, i) => {
      if (bit === 1) reals += chars[i]
    })
  return reals.length === 0 ? "-" : reals
}

const decodePassant = (
  code: number,
  activeColor: string
) => {
  const passantFirst = codeToPassant(code)
  let passant = ""
  if (passantFirst === "-") passant = "-"
  else {
    const row = activeColor === "w" ? "6" : "3"
    passant = passantFirst + row
  }
  return passant
}

const decodeFen = (encoding: number[]) => {
  const pos = decodePositions(encoding)
  const color = encoding[64] === 0 ? "w" : "b"
  const castlings = decodeCastlings(encoding.slice(65, 69))
  const passant = decodePassant(encoding[69], color)
  const halfclock = encoding[70]
  const fullclock = encoding[71]
  return [pos, color, castlings, passant, halfclock, fullclock]
    .join(" ")
}

export default decodeFen
