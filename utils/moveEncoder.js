const m = (a, b, c, d, e=0) => a * 2048 + b * 256 + c * 32 + d * 4 + e
// a short game of chess:
console.log(m(6,4,4,4)) // e4
console.log(m(1,5,2,5)) // f7
console.log(m(7,1,5,0)) // Ka3
console.log(m(1,6,3,6)) // g5
console.log(m(7,3,3,7)) // Qh5#