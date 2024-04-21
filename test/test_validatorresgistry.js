const ValidatorRegistry = artifacts.require("ValidatorRegistry");

contract("ValidatorRegistry", (accounts) => {
  let validatorRegistry = null;
  const owner = accounts[0];
  const validator = accounts[1];

  console.log("Testing ValidatorRegistry contract");

  before(async () => {
    validatorRegistry = await ValidatorRegistry.deployed();
  });

  it("Should add a validator", async () => {
    await validatorRegistry.addValidator(validator, { from: owner });
    const isValid = await validatorRegistry.validators(validator);
    assert(isValid === true);
  });

  it("Should not add a validator if not owner", async () => {
    try {
      await validatorRegistry.addValidator(validator, { from: validator });
    } catch (e) {
      assert(e.message.includes("Only contract owner can call this function"));
      return;
    }
    assert(false);
  });

  it("Should remove a validator", async () => {
    await validatorRegistry.removeValidator(validator, { from: owner });
    const isValid = await validatorRegistry.validators(validator);
    assert(isValid === false);
  });

  it("Should not remove a validator if not owner", async () => {
    try {
      await validatorRegistry.removeValidator(validator, { from: validator });
    } catch (e) {
      assert(e.message.includes("Only contract owner can call this function"));
      return;
    }
    assert(false);
  });
});
