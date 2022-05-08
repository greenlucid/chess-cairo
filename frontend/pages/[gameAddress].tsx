import { NextPage } from "next"
import Head from "next/head"
import { useRouter } from "next/router"

const Game: NextPage = () => {
  const router = useRouter()
  const { gameAddress } = router.query
  return (
    <div>
      <Head>
        <title>chess-cairo</title>
        <meta name="description" content="Decentralized chess" />
        <link rel="icon" href="/king.svg" />
      </Head>
      <div>
        Welcome to game {gameAddress}
      </div>
    </div>
  )
}
export default Game
