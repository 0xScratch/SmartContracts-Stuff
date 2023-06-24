const {expect} = require("chai")
const {ethers} = require("hardhat")

const tokens = (n) => {
    return ethers.utils.parseEther(n.toString(), 'ether')
}

describe('Multi_Sig', () => {
    let owner1, owner2, owner3, recipient
    let multi_sig
    let rec_initialBalance

    beforeEach(async () => {
        // Setup Accounts
        [owner1, owner2, owner3, recipient] = await ethers.getSigners()

        // Deploy contract
        const Multi_Sig = await ethers.getContractFactory('Multi_Sig', owner1)
        multi_sig = await Multi_Sig.deploy(owner2.address, owner3.address, tokens(50))

        rec_initialBalance = await ethers.provider.getBalance(recipient.address)

        let work = await multi_sig.connect(owner1).add_Amount({value: tokens(50)})
        await work.wait()

        work = await multi_sig.connect(owner2).add_Amount({value: tokens(50)})
        await work.wait()

        work = await multi_sig.connect(owner3).add_Amount({value: tokens(50)})
        await work.wait()
    })

    describe('Deployment Successfull', () => {
        // checks whether the owners get listed in the owner_addresses array
        it('Owners get Listed', async () => {
            expect(await multi_sig.owner_addresses(0)).to.eq(owner1.address)
            expect(await multi_sig.owner_addresses(1)).to.eq(owner2.address)
            expect(await multi_sig.owner_addresses(2)).to.eq(owner3.address)
        })

        // checks whether the owners filled the contract with the required amount
        it('Balance gets updated with the required amount', async () => {
            expect(await multi_sig.balance()).to.eq(tokens(150))
        })

        // checks whether the contract is active or not
        it('Contract is in Active State', async () => {
            expect(await multi_sig.state()).to.eq(1)
        })
    })

    describe('Transaction_1 -> 2 Approvals, 1 Rejection', () => {
        beforeEach(async () => {
            let transact = await multi_sig.connect(owner2).propose_Transaction(tokens(10), recipient.address, ethers.utils.formatBytes32String("Thanks Buddy!!"))
            await transact.wait()

            transact = await multi_sig.connect(owner1).Approve_Transaction()
            await transact.wait()

            transact = await multi_sig.connect(owner3).Reject_Transaction()
            await transact.wait()

            transact = await multi_sig.connect(owner2).implement_Transaction()
            await transact.wait()
        })

        it('Transaction Successful', async () => {
            expect(await multi_sig.balance()).to.eq(tokens(140))
            console.log("Recipient's Balance: ", await ethers.provider.getBalance(recipient.address))
        })
    })

    describe('Transaction_2 -> 2 Rejections, 1 Approval', () => {
        beforeEach(async () => {
            let transact = await multi_sig.connect(owner1).propose_Transaction(tokens(20), recipient.address, ethers.utils.formatBytes32String("Cya"))
            await transact.wait()

            transact = await multi_sig.connect(owner2).Reject_Transaction()
            await transact.wait()

            transact = await multi_sig.connect(owner3).Reject_Transaction()
            await transact.wait()

            transact = await multi_sig.connect(owner1).implement_Transaction()
            await transact.wait()
        })

        it('Transaction Rejected', async() => {
            expect(await multi_sig.balance()).to.eq(tokens(150))
            console.log("Recipient's Balance: ", await ethers.provider.getBalance(recipient.address))
        })
    })

    describe('Ethers funded in the contract', () => {
        beforeEach(async () => {
            let transact = await multi_sig.connect(owner3).Propose_Funding(tokens(50))
            await transact.wait()

            let work = await multi_sig.connect(owner1).add_Amount({value: tokens(50)})
            await work.wait()

            work = await multi_sig.connect(owner2).add_Amount({value: tokens(50)})
            await work.wait()

            work = await multi_sig.connect(owner3).add_Amount({value: tokens(50)})
            await work.wait()
        })

        it('Successful', async () => {
            expect(await multi_sig.balance()).to.eq(tokens(300))
            // expect(await multi_sig.addresses(0)).to.eq(owner1.address)
        })
    })
})