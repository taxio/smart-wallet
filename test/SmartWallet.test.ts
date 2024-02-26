import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("SmartWallet", function () {
  describe("deployment", function () {
    it("should deploy", async function () {
      const ProxyFactory = await ethers.getContractFactory("ProxyFactory");
      const Proxy = await ethers.getContractFactory("Proxy");
      const Verifier = await ethers.getContractFactory("Verifier");
      const Fallback = await ethers.getContractFactory("FallbackHandler");
      const BaseWallet = await ethers.getContractFactory("BaseWallet");
      const EntryPoint = await ethers.getContractFactory("EntryPoint");

      const proxyFactory = await ProxyFactory.deploy();
      await proxyFactory.deployed();

      const entryPoint = await EntryPoint.deploy();
      await entryPoint.deployed();

      const verifier = await Verifier.deploy();
      await verifier.deployed();
      const fallback = await Fallback.deploy();
      await fallback.deployed();

      const baseWallet = await BaseWallet.deploy();
      await baseWallet.deployed();

      const [owner] = await ethers.getSigners();
      console.log("owner", owner.address);

      const salt = ethers.utils.randomBytes(32);
      const initCode = BaseWallet.interface.encodeFunctionData("initialize", [
        verifier.address,
        "0x",
        fallback.address,
        "0x",
      ]);

      const proxyAddress = await proxyFactory.getAddress(
        owner.address,
        entryPoint.address,
        baseWallet.address,
        initCode,
        salt
      );
      await expect(
        proxyFactory.deploy(
          owner.address,
          entryPoint.address,
          baseWallet.address,
          initCode,
          salt
        )
      )
        .to.emit(proxyFactory, "Deployed")
        .withArgs(proxyAddress);

      const proxy = Proxy.attach(proxyAddress);
      await proxy.deployed();
    });
  });
});
