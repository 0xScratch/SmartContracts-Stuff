// Tests go here..

/*
    here both expect and ethers are functions and specific objects being extracted from chai and hardhat respectively...Make sure expect and ethers also work as a variable..
*/
const { expect } = require("chai");
const { ethers } = require("hardhat");

// It is used to group related tests together and provide a description of what the tests are checking.
describe('Counter', () => {
    let counter

    // The 'beforeEach' function in JavaScript is used in testing frameworks to run a block of code before each test case in a suite of tests.
    beforeEach(async () => {
        // This line uses the 'ethers' library to get the contract factory for a contract called "Counter". A contract factory is a template for creating instances of a smart contract.
        const Counter = await ethers.getContractFactory('Counter')
        // This line uses the contract factory to deploy a new instance of the "Counter" contract, passing in the constructor arguments "My Counter" and 1.
        counter = await Counter.deploy('My Counter', 1)
    })
    
    describe('Deployment', () => {
        // It starts a test case within the "Counter" test suite. The test case is called "stores the count" and it is marked as asynchronous using the async keyword.
        it('sets the initial count', async () => {
            // This line uses the newly created instance of the "Counter" contract to retrieve the current count value using the 'count()' function.
            const count = await counter.count()
            // This line uses the expect assertion library to compare the value of 'count' to the expected value of 1. If the actual value of 'count' is not equal to 1, the test case will fail.
            expect(count).to.equal(1)
        })

        it('sets the initial name', async () => {
            const name = await counter.name()
            expect(name).to.equal('My Counter')
            // or a one-line => expect(await counter.name()).to.equal('My Counter')
        })
    })

    describe('Counting', () => {
        let transaction

        it('reads the count from the "count" public variable', async() => {
            expect(await counter.count()).to.equal(1)
        })

        it('reads the count from the "getCount()" function', async() => {
            expect(await counter.getCount()).to.equal(1)
        })

        it('increments the count', async () => {
            // 1st increment
            transaction = await counter.increment()
            await transaction.wait()

            expect(await counter.count()).to.equal(2)

            // 2nd increment
            transaction = await counter.increment()
            await transaction.wait()

            expect(await counter.count()).to.equal(3)
        })

        it('decrements the count', async () => {
            transaction = await counter.decrement()
            await transaction.wait()

            expect(await counter.count()).to.equal(0)

            // Cannot decrement count below 0
            await expect(counter.decrement()).to.be.reverted
        })

        it('reads the name from the "name" public variable', async() => {
            expect(await counter.name()).to.equal('My Counter')
        })

        it('reads the name from the "getName()" function', async() => {
            expect(await counter.getName()).to.equal('My Counter')
        })

        it('updates the name', async () => {
            transaction = await counter.setName('New Name')
            await transaction.wait()
            expect(await counter.name()).to.equal('New Name')
        })
    })
})