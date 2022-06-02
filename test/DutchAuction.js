const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Dutch Auction Contract", () => {
  let ERC721, nft, SafeMath, safemath, Dutch, dutch, owner, addr1, addr2;
  before(async () => {
    ERC721 = await ethers.getContractFactory("ERC721");
    nft = await ERC721.deploy();
    SafeMath = await ethers.getContractFactory("SafeMath");
    safemath = await SafeMath.deploy();

    [owner, addr1, _] = await ethers.getSigners();
    await nft.mint(owner.address, "100");

    Dutch = await ethers.getContractFactory("DutchAuction");
    const blockNumBefore = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(blockNumBefore);
    const timestampBefore = blockBefore.timestamp;

    const twoHours = 2 * 60 * 60;
    dutch = await Dutch.deploy(
      "10000000",
      timestampBefore + twoHours,
      timestampBefore + twoHours + twoHours,
      nft.address,
      "100"
    );

    await nft.approve(dutch.address, "100");
  });

  describe("Deployment", () => {
    it("Should set the contract initializer as the seller of NFT", async () => {
      expect(await dutch.seller()).to.equal(owner.address);
    });
  });

  describe("Contract Interactions", () => {
    it("Auction hasn't started", async () => {
      expect(
        dutch.connect(addr1).buy({ value: "10000000" })
      ).to.be.revertedWith("Auction hasn't started yet");
    });

    it("Should return correct price when auction hasn't started", async () => {
      expect(await dutch.getPrice()).to.equal(await dutch.startingPrice());
    });

    it("Should say bid is not enough", async () => {
      await network.provider.send("evm_increaseTime", [7200]);
      await network.provider.send("evm_mine");
      const price = await dutch.getPrice();
      expect(
        dutch.connect(addr1).buy({ value: price - 1000000 })
      ).to.be.revertedWith("ETH sent is lesser than the price");
    });

    it("Should transfer nft to second address", async () => {
      const price = await dutch.getPrice();
      await dutch.connect(addr1).buy({ value: price });
      expect(await nft.ownerOf("100")).to.equal(addr1.address);
    });

    it("Should close auction", async () => {
      const price = await dutch.getPrice();
      expect(dutch.buy({ value: price })).to.be.revertedWith(
        "Auction has finished"
      );
    });
  });
});
