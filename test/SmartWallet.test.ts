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

      const [owner] = await ethers.getSigners();
      console.log("owner", owner.address);

      const initCode = BaseWallet.interface.encodeFunctionData("initialize", [
        verifier.address,
        Verifier.interface.encodeFunctionData("initialize", [
          entryPoint.address,
        ]),
        fallback.address,
        "0x",
      ]);

      const proxy = await Proxy.deploy(
        owner.address,
        baseWallet.address,
        initCode
      );
      await proxy.deployed();
    });
  });
});
