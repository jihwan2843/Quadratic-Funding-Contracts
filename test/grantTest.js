const { ethers } = require("hardhat");
const { expect } = require("chai");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

// require(msg.sender.code.length != 0, "You are a EOA");
// 이 코드를 작성하기 전에는 테스트 통과 완료
describe("Grant", function () {
  let Grant;
  let contract;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    Grant = await ethers.getContractFactory("Grant");
    contract = await Grant.deploy();
  });

  // 안건을 만드는 테스트 코드. 과도한 안건제안을 방지하기 위해 한 사용자당 한 개의 안건생성으로 제한
  it("create a new grant with a one proposal per one user", async function () {
    // 첫번째 안건 제안하기
    await contract.connect(owner).propose(owner.address, "grant", "grant");
    expect(await contract.grantProposer()).to.equal(owner.address);

    // 같은 사용자가 두번째 안건 제안하기. revert가 나와야 정상
    const tx2 = contract.propose(owner.address, "grant2", "grant2");
    await expect(tx2).to.be.revertedWith("You already created the grant");

    // 안건의 제안자를 확인
    expect(await contract.connect(owner).grantProposer()).to.equal(
      await ethers.getAddress(owner.address)
    );

    expect(await contract.status()).to.equal("Pending");
  });

  it("should allow funding when active", async function () {
    await contract.propose(owner, "grant", "grant");

    // 상태가 Pending 일때는 후원 불가
    const tx = contract.funding(addr1, 1000);
    expect(await contract.status()).to.equal("Pending");
    await expect(tx).to.be.revertedWith(
      "The Status of The Grant is not Active"
    );

    // Active일때 후원하기
    // 테스트 환경에서 timestamp를 강제로 늘리기
    await ethers.provider.send("evm_increaseTime", [604810]);
    await ethers.provider.send("evm_mine");

    // Grant 상태 확인
    expect(await contract.status()).to.equal("Active");
    // 1000 후원
    const tx1 = await contract.funding(addr1, 1000);
    const receipt = await tx1.wait();
    console.log(receipt.logs);

    //expect(await contract.funding(testAddr1, 1000)).to.equal(1000);
    //expect(await contract.balanceOf(testAddr1)).to.equal(1000);
    //expect(await contract.getTotalAmount()).to.equal(1000);
    //expect(await contract.getTotalSponsors()).to.equal(1);
  });

  it("when Pending, the proposal can be canceld by the owner only", async function () {
    await contract.connect(owner).propose(owner.address, "grant", "grant");
    expect(await contract.status()).to.equal("Pending");

    // Owner 외에는 cancel 할 수 없음
    await expect(contract.connect(addr1).cancel()).to.be.revertedWith(
      "You are not the proposal'owner"
    );
    await contract.connect(owner).cancel();
    expect(await contract.status()).to.equal("Canceld");
  });
});
