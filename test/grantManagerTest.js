const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("GrantManager", async function () {
  let admin, addr1, addr2;
  let grant, factory;
  let grantManagerContract, grantManager;

  beforeEach(async function () {
    [admin, addr1, addr2] = await ethers.getSigners();

    grant = await ethers.deployContract("Grant");
    factory = await ethers.deployContract("Grant", grant.getAddress());

    grantManagerContract = await ethers.getContractFactory("GrantManager");
    grantManager = await grantManagerContract
      .connect(admin)
      .deploy(factory.getAddress());
  });

  it("should set the totalMatchint pool", async function () {
    await grantManager.setMatchingPool(1000);
    expect(await grantManager.getMatchingPool()).to.equal(1000);
  });

  it("should fail when non-administrator tries to set the totalmatching pool", async function () {
    // admin이 아닌 사용자가 matchingPool을 설정하면 revert
    const tx = grantManager.connect(addr1).setMatchingPool(1000);
    await expect(tx).to.be.reverted;
  });

  it("set the right administrator", async function () {
    expect(await grantManager.owner()).to.equal(admin.address);
  });
});
