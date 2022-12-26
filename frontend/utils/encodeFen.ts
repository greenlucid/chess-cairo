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

const encodeRow = (row: string): number[] => {
  const tileRow: number[] = []
  for (let c of row.split("")) {
    if (isNaN(Number(c))) {
      tileRow.push(charToCode[c])
    } else {
      let zeroes = Number(c)
      for (let i = 0; i < zeroes; i++) tileRow.push(0)
    }
  }
  return tileRow
}

const encodePositions = (positions: string): number[] => {
  const rows = positions.split("/")
  const encoded = rows.map((row) => encodeRow(row))

  return encoded.flat(2)
}

const encodeActiveColor = (char: string) => (char === "w" ? 0 : 1)

const encodeCastlings = (castlings: string): number[] => {
  const lookups = "KQkq"
  const encoded = lookups
    .split("")
    .map((lookup) => (castlings.includes(lookup) ? 1 : 0))
  return encoded
}

const encodePassant = (passant: string) => passantToCode[passant[0]]

const encodeFen = (fen: string) => {
  const [pos, active, cast, passant, halfmoveClock, fullmoveClock] =
    fen.split(" ")
  return [
    encodePositions(pos),
    encodeActiveColor(active),
    encodeCastlings(cast),
    encodePassant(passant),
    Number(halfmoveClock),
    Number(fullmoveClock)
  ].flat(2)
}

export default encodeFen
