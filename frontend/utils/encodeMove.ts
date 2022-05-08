const encodeMove = (a: number, b: number, c: number, d: number, e = 0) =>
  a * 2048 + b * 256 + c * 32 + d * 4 + e

/**
// a short game of chess:
console.log(encodeMove(6,4,4,4)) // e4
console.log(encodeMove(1,5,2,5)) // f7
console.log(encodeMove(7,1,5,0)) // Ka3
console.log(encodeMove(1,6,3,6)) // g5
console.log(encodeMove(7,3,3,7)) // Qh5#
*/
export default encodeMove
