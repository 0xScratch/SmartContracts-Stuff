const {expect} = require("chai")
const {ethers} = require("hardhat");

const tokens = (n) => {
    return ethers.utils.parseEther(n.toString(), 'ether')
}

describe('DEX', () => {
    let owner, trader1, trader2, trader3, trader4;
    let dex

    beforeEach(async () => {
        // Setup Accounts
        [owner, trader1, trader2, trader3, trader4] = await ethers.getSigners()

        // Deploy contract
        const DEX = await ethers.getContractFactory('DEX', owner)
        dex = await DEX.deploy(10000, tokens(10), 5000, tokens(20))

        // Setting up the liquidity pool and letting traders buy some tokens..

        // Placing Orders
        let trade = await dex.connect(trader1).purchaseToken_A(20)
        await trade.wait()

        trade = await dex.connect(trader2).purchaseToken_A(30)
        await trade.wait()

        trade = await dex.connect(trader3).purchaseToken_B(40)
        await trade.wait()

        trade = await dex.connect(trader4).purchaseToken_B(50)
        await trade.wait()

        // Executing orders
        trade = await dex.connect(trader1).executeOrder(0, {value: tokens(200)})
        await trade.wait()

        trade = await dex.connect(trader2).executeOrder(1, {value: tokens(300)})
        await trade.wait()

        trade = await dex.connect(trader3).executeOrder(2, {value: tokens(800)})
        await trade.wait()

        trade = await dex.connect(trader4).executeOrder(3, {value: tokens(1000)})
        await trade.wait()
    })

    describe('successfully deployed!!', () => {
        it('checking the current price', async () => {
            trade = await dex.connect(trader1).current_Price_A()
            expect(trade).to.eq(tokens(10))
        })

        it('checking the initial balance', async () => {
            expect(await dex.balance()).to.eq(tokens(2300))
        })

        it('trader got their tokens', async () => {
            expect((await dex.traderRecord(trader1.address)).num_Tokens_A).to.eq(20)
            expect((await dex.traderRecord(trader2.address)).num_Tokens_A).to.eq(30)
            expect((await dex.traderRecord(trader3.address)).num_Tokens_B).to.eq(40)
            expect((await dex.traderRecord(trader4.address)).num_Tokens_B).to.eq(50)
        })

        it('checking the value of constant K', async () => {
            expect(await dex.k()).to.eq(50000000)
        })
    })

    describe('Cancelling and selling Order Works!!', () => {
        it('Order got cancelled', async () => {
            trade = await dex.connect(trader1).purchaseToken_B(5)
            await trade.wait()

            trade = await dex.connect(trader1).cancelOrder(4)
            await trade.wait()

            expect((await dex.traderRecord(trader1.address)).num_Tokens_B).to.eq(0)
        })

        it('Tokens got sold', async () => {
            trade = await dex.connect(trader1).sellToken_A(5)
            await trade.wait()

            trade = await dex.connect(trader1).executeOrder(4)
            await trade.wait()

            expect((await dex.traderRecord(trader1.address)).num_Tokens_A).to.eq(15)
            expect(await dex.balance()).to.eq(tokens(2250))
        })
    })

    describe('Trades got successful!!', () => {
        it('Trade 1 is ok..', async () => {
            trade = await dex.connect(trader1).trade_A_to_B(10)
            await trade.wait()

            expect((await dex.traderRecord(trader1.address)).num_Tokens_A).to.eq(10)
            expect((await dex.traderRecord(trader1.address)).num_Tokens_B).to.eq(5)
            expect(await dex.quantity_A()).to.eq(10010)
            expect(await dex.quantity_B()).to.eq(4995)
        })

        it('Trade 2 is ok..', async () => {
            trade = await dex.connect(trader3).trade_B_to_A(20)
            await trade.wait()

            expect((await dex.traderRecord(trader3.address)).num_Tokens_B).to.eq(20)
            expect((await dex.traderRecord(trader3.address)).num_Tokens_A).to.eq(40)
            expect(await dex.quantity_A()).to.eq(9960)
            expect(await dex.quantity_B()).to.eq(5020)
        })
    })
})