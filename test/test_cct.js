const CarbonCreditToken = artifacts.require("CarbonCreditToken");
const ERC20 = artifacts.require("ERC20");

contract("CarbonCreditToken", accounts => {
    let token;
    const [admin, recipient, anotherAccount] = accounts;

    beforeEach(async () => {
        let erc20 = await ERC20.new({ from: admin });
        token = await CarbonCreditToken.new(erc20.address, { from: admin });
    });

    it("Should mint tokens correctly", async () => {
        let amount = 1000;
        await token.getCCT(recipient, amount, { from: admin });
        let balance = await token.checkCCT(recipient);
        assert.equal(balance.toNumber(), amount, "The minted amount should reflect in the recipient's balance");
    });

    it("Should return the correct balances", async () => {
        let amount = 500;
        await token.getCCT(recipient, amount, { from: admin });
        let balance = await token.checkCCT(recipient);
        assert.equal(balance.toNumber(), amount, "The balance should be correctly queried");
    });

    it("Should allow token transfer", async () => {
        let mintAmount = 1000;
        let transferAmount = 600;
        await token.getCCT(recipient, mintAmount, { from: admin });
        await token.transferCCT(anotherAccount, transferAmount, { from: recipient });
        let balance = await token.checkCCT(anotherAccount);
        assert.equal(balance.toNumber(), transferAmount, "The transfer amount should reflect in the recipient's balance");
    });

    it("Should prevent transfers exceeding balance", async () => {
        try {
            await token.transferCCT(anotherAccount, 100, { from: recipient });
            assert.fail("The transaction should have failed");
        } catch (error) {
            assert(error.toString().includes("revert"), "Should revert due to insufficient balance");
        }
    });

    it("Should burn tokens correctly", async () => {
        let mintAmount = 1000;
        let burnAmount = 500;
        await token.getCCT(recipient, mintAmount, { from: admin });
        await token.destroyCCT(recipient, burnAmount, { from: recipient });
        let remainingBalance = await token.checkCCT(recipient);
        assert.equal(remainingBalance.toNumber(), mintAmount - burnAmount, "The remaining balance should be correct after burning");
    });

    it("Should prevent burning more tokens than available", async () => {
        let mintAmount = 500;
        let burnAmount = 600;
        await token.getCCT(recipient, mintAmount, { from: admin });
        try {
            await token.destroyCCT(recipient, burnAmount, { from: recipient });
            assert.fail("The transaction should have failed");
        } catch (error) {
            assert(error.toString().includes("revert"), "Should revert due to attempting to burn more tokens than are available");
        }
    });

});