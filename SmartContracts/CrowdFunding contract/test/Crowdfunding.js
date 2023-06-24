const {expect, waffle} = require("chai")
const {ethers} = require("hardhat")

const tokens = (n) => {
    return ethers.utils.parseEther(n.toString(), 'ether')
}

describe('CrowdFunding', () => {
    let owner1, owner2
    let crowd
    let contributor1, contributor2, contributor3

    beforeEach(async () => {
        // setup Accounts
        [owner1, owner2, contributor1, contributor2, contributor3] = await ethers.getSigners()

        // Deploy contract
        const Crowd = await ethers.getContractFactory('CrowdFunding')
        crowd = await Crowd.deploy()
        await crowd.deployed()
    })

    describe('Campaign_1 -> Solana Project (Success)', () => {
        let campaign_1, timestamp
        beforeEach(async () => {
            campaign_1 = await crowd.connect(owner1).create_Campaign('SolX', tokens(100), 86400)
            await campaign_1.wait()
            const blockNumber = await ethers.provider.getBlockNumber()
            const block = await ethers.provider.getBlock(blockNumber)
            timestamp = block.timestamp

            // Contributions
            campaign_1 = await crowd.connect(contributor1).contribute(0, {value: tokens(40)})
            await campaign_1.wait()

            campaign_1 = await crowd.connect(contributor2).contribute(0, {value: tokens(50)})
            await campaign_1.wait()
        })

        it('Checking name, target_amount, deadline and owner..', async () => {
            expect((await crowd.Campaign_Records(0)).name).to.eq('SolX')
            expect((await crowd.Campaign_Records(0)).target_amount).to.eq(tokens(100))
            expect((await crowd.Campaign_Records(0)).campaign_owner).to.eq(owner1.address)
            expect((await crowd.Campaign_Records(0)).deadline).to.eq(timestamp + 86400)
        })

        it('Status -> ongoing', async () => {
            campaign_1 = await crowd.connect(owner1).check_Status(0)
            expect(campaign_1).to.eq('ongoing')
        })

        it('Making contributions and let the owner withdraw it..', async() => {
            campaign_1 = await crowd.connect(contributor3).contribute(0, {value: tokens(10)})
            await campaign_1.wait()

            expect((await crowd.Campaign_Records(0)).balance).to.eq(tokens(100))

            campaign_1 = await crowd.connect(owner1).withdraw_Owner(0)
            await campaign_1.wait()

            expect((await crowd.Campaign_Records(0)).balance).to.eq(tokens(0))
        })
    })

    describe('Campaign_2 -> Hardhat Project (Failure)', () => {
        let campaign_2

        beforeEach(async () => {
            campaign_2 = await crowd.connect(owner2).create_Campaign('Hard', tokens(70), 86500)
            await campaign_2.wait()

            // contributions
            campaign_2 = await crowd.connect(contributor1).contribute(0, {value: tokens(40)})
            await campaign_2.wait()

            // fastforwarding time
            await ethers.provider.send("evm_increaseTime", [87000])
            await ethers.provider.send("evm_mine")

            // deadline hit
            campaign_2 = await crowd.connect(owner2).hit_deadline(0)
            await campaign_2.wait()
        })

        it('Checking Status -> failed, due to passed deadline', async () => {
            campaign_2 = await crowd.connect(owner2).check_Status(0)
            expect(campaign_2).to.eq('failed')
        })

        it('Any contributor trying to contribute wont success', async () => {
            await expect(crowd.connect(contributor2).contribute(0, {value: tokens(10)})).to.be.revertedWith("You can't call this function in currentState")
        })

        it("Owner won't be able to withdraw any amount", async () => {
            await expect(crowd.connect(owner2).withdraw_Owner(0)).to.be.revertedWith("You can't withdraw the funds")
        })

        it("Contributors can withdraw their funds", async () => {
            expect((await crowd.Campaign_Records(0)).balance).to.eq(tokens(40))
            campaign_2 = await crowd.connect(contributor1).withdraw_Contributor(0)
            await campaign_2.wait()
            expect((await crowd.Campaign_Records(0)).balance).to.eq(tokens(0))
        })
    })
})

