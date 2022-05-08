import type { NextPage } from "next"
import Head from "next/head"
import styles from "../styles/Home.module.css"
import { Field, Form, Formik } from "formik"
import { CompiledContract, ContractFactory, Provider, Abi } from "starknet"
import { useState } from "react"
import fullEncodeFen from "../utils/encodeFen"

import chessCompiled from "../../artifacts/chess.json"
import chessAbi from "../../artifacts/abis/chess.json"
import Image from "next/image"

const initialFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

type CreateGameParams = {
  white: string
  black: string
  governor: string
  fen: string
}

const CreateGameForm: React.FC<any> = ({ deployGame, loading }: any) => {
  if (loading) return null
  return (
    <Formik
      initialValues={{
        white:
          "0x01993b026b508a51caf6c599566b46065e1f7e88a514751fd2e46aa6eae601c0",
        black:
          "0x01993b026b508a51caf6c599566b46065e1f7e88a514751fd2e46aa6eae601c0",
        governor:
          "0x01993b026b508a51caf6c599566b46065e1f7e88a514751fd2e46aa6eae601c0",
        fen: initialFen,
      }}
      onSubmit={(values) => deployGame(values)}
    >
      {() => (
        <div>
          <Form>
            <p>White player address</p>
            <Field name="white" />
            <p>Black player address</p>
            <Field name="black" />
            <p>Governor address</p>
            <Field name="governor" />
            <p>FEN</p>
            <Field name="fen" />
            <p />
            <button type="submit">Create game</button>
          </Form>
        </div>
      )}
    </Formik>
  )
}

const CreateGame: React.FC = () => {
  const [loading, setLoading] = useState<boolean>()
  const [gameAddress, setGameAddress] = useState<string>()

  const deployGame = async (values: CreateGameParams) => {
    setLoading(true)
    console.log(values)
    const encodedFen = fullEncodeFen(values.fen)
    console.log(encodedFen)

    const provider = new Provider({ network: "goerli-alpha" })
    console.log(provider)
    const chessCairoFactory = new ContractFactory(
      chessCompiled as CompiledContract,
      provider,
      chessAbi as Abi
    )

    chessCairoFactory
      .deploy([values.white, values.black, values.governor, encodedFen])
      .then((contract) => {
        console.log(contract)
        setLoading(false)
        setGameAddress(contract.address)
      })
      .catch((error) => console.log(error))

  }

  return (
    <div>
      <h2 className={styles.lightEnclosed}>Create game</h2>
      <CreateGameForm deployGame={deployGame} loading={loading} />
      {loading && (
        <img
          src={
            "https://icon-library.com/images/loading-icon-transparent-background/loading-icon-transparent-background-12.jpg"
          }
          height={100}
          width={100}
        />
      )}
      {gameAddress && (
        <>
          <p>Deployed! Click the address to start</p>
          <p>
            <a href={`/${gameAddress}`}>{gameAddress}</a>
          </p>
        </>
      )}
    </div>
  )
}

const Home: NextPage = () => {
  return (
    <div className={styles.chesstile}>
      <Head>
        <title>chess-cairo</title>
        <meta name="description" content="Decentralized chess" />
        <link rel="icon" href="/king.svg" />
      </Head>
      <body>
        <div className={styles.main}>
          <h1 className={`${styles.title} ${styles.enclosed}`}>chess-cairo</h1>

          <p className={`${styles.description} ${styles.lightEnclosed}`}>
            Play chess on-chain.
          </p>

          <CreateGame />
        </div>
      </body>

      <footer className={`${styles.footer}`}>
        <a
          href="https://github.com/greenlucid/chess-cairo"
          target="_blank"
          rel="noopener noreferrer"
        >
          GitHub repository
        </a>
        <a
          href="https://starkware.co/starknet/"
          target="_blank"
          rel="noopener noreferrer"
        >
          Powered by StarkNet
        </a>
        <a
          href="https://twitter.com/matchbox_dao"
          target="_blank"
          rel="noopener noreferrer"
        >
          Join MatchboxDAO!
        </a>
      </footer>
    </div>
  )
}

export default Home