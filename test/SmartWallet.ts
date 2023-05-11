import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";


describe("SmartWallet", () => {
  const deploySmartWallet = async () => {
    const [owner] = await ethers.getSigners();

    const SmartWallet = await ethers.getContractFactory("SmartWallet");
    const smartWallet = await SmartWallet.deploy();

    const Proxy = await ethers.getContractFactory("Proxy");
    const proxy = await Proxy.deploy(owner.address, smartWallet.address);

    const ProxyFactory = await ethers.getContractFactory("ProxyFactory");
    const proxyFactory = await ProxyFactory.deploy();

    const wallet = SmartWallet.attach(proxy.address);

    return { owner, SmartWallet, smartWallet, Proxy, proxy, wallet, ProxyFactory, proxyFactory };
  }

  describe("execute", () => {
    it("send value", async () => {
      const [_, user] = await ethers.getSigners();
      const { owner, wallet } = await loadFixture(deploySmartWallet);

      await owner.sendTransaction({to: wallet.address, value: ethers.utils.parseEther("1")});
      expect(await ethers.provider.getBalance(wallet.address)).to.equal(ethers.utils.parseEther("1"));

      expect(await user.getBalance()).to.equal(ethers.utils.parseEther("10000"));
      await wallet.execute(user.address, ethers.utils.parseEther("1"), "0x");
      expect(await user.getBalance()).to.equal(ethers.utils.parseEther("10001"));
    });

    it("transfer NFT", async () => {
      const [_, user] = await ethers.getSigners();
      const { wallet } = await loadFixture(deploySmartWallet);

      const ERC721 = await ethers.getContractFactory("TestERC721");
      const erc721 = await ERC721.deploy();

      await erc721.mint(wallet.address, 1);
      expect(await erc721.ownerOf(1)).to.equal(wallet.address);

      const callData = erc721.interface.encodeFunctionData(
        "safeTransferFrom(address,address,uint256)",
        [wallet.address, user.address, 1]
      );
      await expect(wallet.execute(erc721.address, 0, callData)).to.not.reverted;
      expect(await erc721.ownerOf(1)).to.equal(user.address);
    });
  });

  describe("static call", () => {
    it("isValidSignature", async () => {
      const { owner, wallet } = await loadFixture(deploySmartWallet);

      const message = "hello";
      const hashMessage = ethers.utils.hashMessage(message);
      const signature = await owner.signMessage(message);

      expect(await wallet.isValidSignature(hashMessage, signature)).to.equal("0x1626ba7e");
    });
  });

  describe("updateOwner", () => {
    it("success", async () => {
      const [_, user] = await ethers.getSigners();
      const { owner, wallet } = await loadFixture(deploySmartWallet);

      expect(await wallet.owner()).to.equal(owner.address);

      await expect(wallet.updateOwner(user.address)).to.not.reverted;

      expect(await wallet.owner()).to.equal(user.address);
    });

    it("failed by non-owner", async () => {
      const [_, user] = await ethers.getSigners();
      const { owner, wallet } = await loadFixture(deploySmartWallet);

      expect(await wallet.owner()).to.equal(owner.address);

      await expect(wallet.connect(user).updateOwner(user.address)).to.be.revertedWith("Only owner can call this function.");
    });
  });

  describe("updateImplementation", () => {
    it("success", async () => {
      const { SmartWallet, wallet } = await loadFixture(deploySmartWallet);

      const newImplementation = await SmartWallet.deploy();

      await expect(wallet.updateImplementation(newImplementation.address)).to.not.reverted;
    });

    it("failed by non-owner", async () => {
      const [_, user] = await ethers.getSigners();
      const { SmartWallet, wallet } = await loadFixture(deploySmartWallet);

      const newImplementation = await SmartWallet.deploy();

      await expect(wallet.connect(user).updateImplementation(newImplementation.address)).to.be.revertedWith("Only owner can call this function.");
    });
  });

  describe("receive value", () => {
    it("emit event", async () => {
      const [_, user] = await ethers.getSigners();
      const { wallet } = await loadFixture(deploySmartWallet);

      expect(await ethers.provider.getBalance(wallet.address)).to.equal(0);

      await expect(user.sendTransaction({
        to: wallet.address,
        value: ethers.utils.parseEther("0.001"),
      })).to.emit(wallet, "Received");

      expect(await ethers.provider.getBalance(wallet.address)).to.equal(ethers.utils.parseEther("0.001"));
    });
  });

  describe("deployment", () => {
    describe("ProxyFactory", () => {
      it("deploy", async () => {
        const { owner, SmartWallet, smartWallet, proxyFactory } = await loadFixture(deploySmartWallet);

        const salt = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("123"));

        const targetAddress = await proxyFactory.getAddress(
          smartWallet.address,
          owner.address,
          salt
        );

        await expect(proxyFactory.deploy(
          smartWallet.address,
          owner.address,
          salt
        )).to.emit(proxyFactory, "ProxyDeployed").withArgs(
          targetAddress,
          smartWallet.address,
          owner.address,
          salt
        );

        const wallet = SmartWallet.attach(targetAddress);
        expect(await wallet.owner()).to.equal(owner.address);

        await expect(proxyFactory.deploy(
          smartWallet.address,
          owner.address,
          salt
        )).to.be.reverted;
      });
    });
  });
});
