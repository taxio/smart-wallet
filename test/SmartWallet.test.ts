import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("SmartWallet", function () {
  describe("deployment", function () {
    it("should deploy", async function () {
      const Proxy = await ethers.getContractFactory("Proxy");
      const Verifier = await ethers.getContractFactory("Verifier");
      const Fallback = await ethers.getContractFactory("FallbackHandler");
      const BaseWallet = await ethers.getContractFactory("BaseWallet");
      const EntryPoint = await ethers.getContractFactory("EntryPoint");

      const entryPoint = await EntryPoint.deploy();
      await entryPoint.deployed();

      const verifier = await Verifier.deploy();
      await verifier.deployed();
      const fallback = await Fallback.deploy();
      await fallback.deployed();

      const baseWallet = await BaseWallet.deploy();
      await baseWallet.deployed();

      const [owner, bundler] = await ethers.getSigners();
      console.log("owner", owner.address);

      // const salt = ethers.utils.randomBytes(32);
      const initCode = BaseWallet.interface.encodeFunctionData("initialize", [
        verifier.address,
        "0x",
        fallback.address,
        "0x",
      ]);
      const proxy = await Proxy.deploy(
        owner.address,
        entryPoint.address,
        baseWallet.address,
        initCode
      );
      await proxy.deployed();
      const proxyAddress = proxy.address;

      await owner.sendTransaction({
        to: proxy.address,
        value: ethers.utils.parseEther("1"),
      });
      expect(await ethers.provider.getBalance(proxy.address)).to.equal(
        ethers.utils.parseEther("1")
      );

      const wallet = BaseWallet.attach(proxy.address);

      // call from Owner
      await wallet.execute(owner.address, ethers.utils.parseEther("0.1"), "0x");
      expect(await ethers.provider.getBalance(proxy.address)).to.equal(
        ethers.utils.parseEther("0.9")
      );

      // call from EntryPoint
    });
  });
});
