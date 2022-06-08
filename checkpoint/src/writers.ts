import { AsyncMySqlPool, CheckpointWriters } from '@snapshot-labs/checkpoint';
import { hexStrArrToStr, toAddress } from './utils';

// i dont know mysql so im just mocking this
const getGame = async ({gameId, mysql}: {gameId: number, mysql: AsyncMySqlPool}) => {
  return {
    gameId,
    state: [0, 1, 2, 4, 5, 6, 7, 8, 9, 10],
    valid: true,
    result: 0
  }
}

export const writers: CheckpointWriters = {
  handleDeploy: async () => {
    // Run logic as at the time Contract was deployed.
    // unused
  },

  handleCreatedGame: async ({ receipt, mysql }) => {
    const gameId = Number(receipt.events[0])
    // const arrLen = BigInt(receipt.events[1]) is unused

    const state = [gameId, ...receipt.events.slice(2).map(s => Number(s))]

    // naive. just check if len is 72 * n + 7
    const valid = (state.length % 72) === 7

    const game = {
      gameId,
      state,
      valid
    }

    await mysql.queryAsync('INSERT IGNORE INTO games SET ?', [game]);
  },

  handleMove: async ({ receipt, mysql }) => {
    const gameId = Number(receipt.events[0])

    const game = await getGame({gameId, mysql})
    // reset draw offers
    game.state[4] = 0
    game.state[5] = 0
    // update fenCount (7th meta value), then append the obtained array.
    game.state[6]++
    game.state = [...game.state, ...receipt.events.slice(1).map(s => Number(s))]
    // todo save
  },

  handleSurrender: async ({ receipt, mysql }) => {
    const gameId = Number(receipt.events[0])
    const asPlayer = Number(receipt.events[1])
    // if player is white, blackwin. otherwise, whitewin 
    const result = asPlayer === 0 ? 2 : 1

    // edit with result and save
  },

  handleOfferDraw: async ({ receipt, mysql }) => {
    const gameId = Number(receipt.events[0])
    const asPlayer = Number(receipt.events[1])

    const game = await getGame({gameId, mysql})
    
    // check if the other player has surrendered
    const otherplayer = asPlayer === 0 ? 1 : 0
    const drawOffers = game.state.slice(4, 6)
    if (drawOffers[otherplayer] === 1) {
      // the other player also offered. write as draw.
      game.result = 3
    } else {
      // write your draw offer
      game.state[4 + asPlayer] = 1
    }
    // edit and save
  },

  handleForceThreefoldDraw: async ({receipt, mysql}) => {
    const gameId = Number(receipt.events[0])
    const game = await getGame({gameId, mysql})

    game.result = 3

    // save
  },

  handleForceFiftyMovesDraw: async ({receipt, mysql}) => {
    const gameId = Number(receipt.events[0])
    const game = await getGame({gameId, mysql})

    game.result = 3

    // save
  },

  handleWriteResult: async ({receipt, mysql}) => {
    const gameId = Number(receipt.events[0])
    const result = Number(receipt.events[1])
    const game = await getGame({gameId, mysql})

    game.result = result

    // save
  },

  handleForceResult: async ({receipt, mysql}) => {
    const gameId = Number(receipt.events[0])
    const result = Number(receipt.events[1])
    const game = await getGame({gameId, mysql})

    game.result = result

    // save
  }
};
