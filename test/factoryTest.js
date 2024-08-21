const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("Factory", function () {
  let owner, addr1, addr2, factoryContract, grantContract, factory, grant;
  // constructor 있을때 테스트 코드 작성
  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    // Grant 컨트랙트 먼저 배포
    grantContract = await ethers.getContractFactory("Grant");
    grant = await grantContract.deploy();

    factoryContract = await ethers.getContractFactory("Factory");
    //                                    Grant컨트랙트 주소 입력
    factory = await factoryContract.deploy(grant.getAddress());
  });

  it("should create a new grant", async function () {
    const tx = await factory.createGrant(owner.address, "grant", "grant");
    const receipt = await tx.wait();

    // Event log를 활용하여 cloneAddr 얻기
    const grantAddr = await receipt.logs[1].args[1];
    const newGrantId = await receipt.logs[1].args[0];

    expect(await factory.getGrantbyGrantId(newGrantId)).to.equal(grantAddr);
    expect(await factory.getGrantbyProsper(owner.address)).to.equal(grantAddr);
    // newGrantId가 grantId 배열에안에 포함되는지 체크
    expect(await factory.getListOfGrantId()).to.include(newGrantId);
  });
});
