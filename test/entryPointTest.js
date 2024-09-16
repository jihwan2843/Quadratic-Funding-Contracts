const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("EntryPoint", function () {
  let admin;
  let owner1, addr1, addr2, addr3;
  let owner2, addr4, addr5;
  let owner3, addr6;
  let grant, factory, grantManager, entryPoint;
  let GrantManager, EntryPoint;
  beforeEach(async function () {
    [admin, owner1, owner2, owner3, addr1, addr2, addr3, addr4, addr5, addr6] =
      await ethers.getSigners();

    grant = await ethers.deployContract("Grant");
    factory = await ethers.deployContract("Factory", [grant.getAddress()]);

    GrantManager = await ethers.getContractFactory("GrantManager");
    grantManager = await GrantManager.connect(admin).deploy(
      factory.getAddress()
    );

    EntryPoint = await ethers.getContractFactory("EntryPoint");
    entryPoint = await EntryPoint.connect(admin).deploy(
      grantManager.getAddress(),
      factory.getAddress()
    );
  });

  describe("createGrant", function () {
    it("should create a new grant", async function () {
      // 정적으로 호출하여 반환값만 얻기
      const grantAddr = await entryPoint
        .connect(owner1)
        .createGrant.staticCall("grant", "grant");

      expect(grantAddr).to.be.properAddress;

      await entryPoint.connect(owner1).createGrant("grant", "grant");
      expect(await factory.getGrantbyProsper(owner1.address)).to.equal(
        grantAddr
      );

      const newGrant = await ethers.getContractAt("Grant", grantAddr);
      expect(await newGrant.grantProposer()).to.equal(owner1.address);
      expect(await newGrant.grantProposer()).to.not.equal(owner2.address);

      // grant 내용이 다르더라도 사용자가 2회이상 grant를 만들려고 할때 revert
      await expect(
        entryPoint.connect(owner1).createGrant("grant2", "grant2")
      ).to.be.revertedWith("You have already created the grant");

      // EntryPoint를 통하지 않고 Factory 컨트랙트에 직접 접근하여 grant를 만들 때는 revert
      const tx = factory
        .connect(owner1)
        .createGrant(owner1.address, "grant", "grant");
      await expect(tx).to.be.revertedWith(
        "Direct access by EOA is not allowed"
      );
    });
  });

  describe("funding", function () {
    it("should allow funding the grant when active status", async function () {
      // grant 생성
      const grantAddr = await entryPoint
        .connect(owner1)
        .createGrant.staticCall("grant", "grant");
      await entryPoint.connect(owner1).createGrant("grant", "grant");

      await ethers.provider.send("evm_increaseTime", [604810]);
      await ethers.provider.send("evm_mine");

      const amount = ethers.parseEther("10.0");
      // 10달러 후원
      const fundingAmount = await entryPoint
        .connect(addr1)
        .funding.staticCall(grantAddr, 10, { value: amount });
      //await entryPoint.connect(addr1).funding(grantAddr, 10);
      //const newGrant = await ethers.getContractAt("Grant", grantAddr);
      //expect(await newGrant.balanceOf(addr1.address)).to.equal(fundingAmount);
      expect(ethers.formatEther(fundingAmount)).to.equal("10.0");
    });

    it("should fail when the grant is in pending status", async function () {
      // grant 생성
      const grantAddr = await entryPoint
        .connect(owner1)
        .createGrant.staticCall("grant", "grant");
      await entryPoint.connect(owner1).createGrant("grant", "grant");

      // pending일때 후원
      const tx = entryPoint.connect(addr1).funding(grantAddr, 10);
      await expect(tx).to.be.rejectedWith(
        "The Status of The Grant is not Active"
      );
    });

    it("should fail when funding with zero amount", async function () {
      // grant 생성
      const grantAddr = await entryPoint
        .connect(owner1)
        .createGrant.staticCall("grant", "grant");
      await entryPoint.connect(owner1).createGrant("grant", "grant");

      await ethers.provider.send("evm_increaseTime", [604810]);
      await ethers.provider.send("evm_mine");

      // 0달러 후원
      const tx = entryPoint.connect(addr1).funding(grantAddr, 0);
      await expect(tx).to.be.revertedWith("amount is zero");
    });

    it("should fail when EOA attempts to fund directly", async function () {
      // grant 생성
      const grantAddr = await entryPoint
        .connect(owner1)
        .createGrant.staticCall("grant", "grant");
      await entryPoint.connect(owner1).createGrant("grant", "grant");

      await ethers.provider.send("evm_increaseTime", [604810]);
      await ethers.provider.send("evm_mine");

      // EntryPoint를 통하지 않고 grant 컨트랙트에 직접 접근하여 funding할 때는 revert
      const newGrant = await ethers.getContractAt("Grant", grantAddr);
      const tx = newGrant.funding(addr1.address, 10);
      await expect(tx).to.be.revertedWith(
        "Direct access by EOA is not allowed"
      );
    });
  });

  describe("MatchingPool", function () {
    it("should allow only admin to set the matching pool", async function () {
      await entryPoint.connect(admin).setMatchingPool(10000);
    });

    it("should fail when non admin tries to set the matching pool", async function () {
      const tx = entryPoint.connect(owner1).setMatchingPool(10000);
      await expect(tx).to.be.revertedWith("You are not admin");
    });
  });

  describe("Matching Pool Distribution", function () {
    it("should distribute the matching pool after finishing grant", async function () {
      // 그랜트 생성
      const grantAddr1 = await entryPoint
        .connect(owner1)
        .createGrant.staticCall("grant", "grant");
      await entryPoint.connect(owner1).createGrant("grant", "grant");
      const grantAddr2 = await entryPoint
        .connect(owner2)
        .createGrant.staticCall("grant", "grant");
      await entryPoint.connect(owner2).createGrant("grant2", "grant2");
      const grantAddr3 = await entryPoint
        .connect(owner3)
        .createGrant.staticCall("grant", "grant");
      await entryPoint.connect(owner3).createGrant("grant3", "grant3");
      // 그랜트를 active 상태로 설정
      await ethers.provider.send("evm_increaseTime", [604810]);
      await ethers.provider.send("evm_mine");

      // 후원하기
      await entryPoint.connect(addr1).funding(grantAddr1, 10);
      await entryPoint.connect(addr2).funding(grantAddr1, 10);
      await entryPoint.connect(addr3).funding(grantAddr1, 10);
      await entryPoint.connect(addr4).funding(grantAddr2, 20);
      await entryPoint.connect(addr5).funding(grantAddr2, 20);
      await entryPoint.connect(addr6).funding(grantAddr3, 30);

      // 그랜트를 distributed 상태로 설정
      await ethers.provider.send("evm_increaseTime", [2419200]);
      await ethers.provider.send("evm_mine");

      // 관리자가 매칭풀 금액을 설정
      await entryPoint.connect(admin).setMatchingPool(10000);

      const test = await ethers.getContractAt("Grant", grantAddr1);
      const a = await test.calculateQuadraticFuding.staticCall();
      console.log(a);

      // 관리자가 매칭풀에 있는 자금을 분배
      await entryPoint.connect(admin).matchingDistribute();

      // grant배열을 반환
      const grants = await grantManager.getGrants();
      console.log(grants);
      for (let i = 0; i < grants.length; i++) {
        const amount = await grantManager.getDonationAmount(grants[i]);
        console.log(amount);
      }
      // 분배된 금액의 총합이 9999이다.
    });
  });
});
