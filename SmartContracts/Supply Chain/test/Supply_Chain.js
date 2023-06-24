// Importing the required dependencies
const { expect } = require("chai")
const { ethers } = require("hardhat")

// used for converting wei into ether...Normally indexing the amount in smart contracts..it is wei.
const tokens = (n) => {
    return ethers.utils.parseUnits(n.toString(), 'ether')
}

// Describing the tests
describe('Supply_Chain', () => {
    let owner, seller, buyer, carrier
    let supply

    beforeEach(async () => {
        // Setup Accounts
        [owner, seller, buyer, carrier] = await ethers.getSigners()

        // Deploy Supply Chain
        const Supply_Chain = await ethers.getContractFactory('Supply_Chain', owner)
        supply = await Supply_Chain.deploy()

        // registering the product by the seller
        let product = await supply.connect(seller).register_product("Hat", "X", 20, tokens(5), { value: tokens(1)})
        await product.wait()

        product = await supply.connect(carrier).assign_CarrierToWareHouse(0)
        await product.wait()

        product = await supply.connect(carrier).delivered_by_carrier(0)
        await product.wait()
    })

    describe('Deployment', () => {
        // checks for the owner
        it('Returns Owner', async () => {
            const result = await supply.owner()
            expect(result).to.eq(owner.address)
        })

        // check for the seller
        it('Returns Seller', async () => {
            const result = await supply.records(0)
            expect(result.seller).to.eq(seller.address)
        })

        // checks for the name of the product
        it('Returns the name of the product', async () => {
            expect((await supply.records(0)).name).to.eq("Hat")
        })

        // checks for the quantity of the product
        it('Returns the quantity of the product', async () => {
            expect((await supply.records(0)).quantity).to.eq(20)
        })
        
        // checks for the price of the product
        it('Returns Product Price', async () => {
            const result = await supply.records(0)
            expect(result.priceEach).to.eq(tokens(5))
        })
    })

    describe('Delivering Product to WareHouse', () => {
        // checking the carrier
        it('Carrier has been assigned', async () => {
            expect((await supply.records(0)).carrier).to.eq(carrier.address)
        })

        it('Product Delivered', async () => {
            expect((await supply.records(0)).currentState).to.eq(2)
        })
    })

    describe('Product get Stocked', () => {
        beforeEach(async () => {
            let product = await supply.connect(owner).stock_in_warehouse(0)
            await product.wait()
        })
        // checks the item is stock or not
        it('Item is in stock', async () => {
            expect((await supply.records(0)).currentState).to.eq(3)
        })

        // returns balance
        it('Correct Balance', async () => {
            expect(await supply.getBalance()).to.eq(0)
        })
    })

    describe('Product Bought Successful', () => {
        beforeEach(async () => {
            let product = await supply.connect(owner).stock_in_warehouse(0)
            await product.wait()

            product = await supply.connect(buyer).check_availability('Hat', 5, 'XYZ')
            await product.wait()

            product = await supply.connect(owner).approve_availability(0, tokens(2))
            await product.wait()

            product = await supply.connect(buyer).buy_item(0, { value : tokens(27)})
            await product.wait()

            product = await supply.connect(carrier).assign_Carrier(0)
            await product.wait()

            product = await supply.connect(carrier).item_delivered(0)
            await product.wait()

            product = await supply.connect(buyer).item_received(0)
            await product.wait()
        })

        it('Balance is 0', async () => {
            expect(await supply.getBalance()).to.eq(0)
        })
    })
})