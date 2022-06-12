const shortenAddress = (address: string): string => {
  const first = address.substring(0, 6)
  const second = address.substring(address.length - 4)
  return `${first}...${second}`
}

export default shortenAddress